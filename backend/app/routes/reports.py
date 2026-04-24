from flask import Blueprint, request, jsonify, send_file
from app import db
from app.models.transaction import Transaction
from app.models.budget import Budget, BudgetCategory
from app.models.investment import Investment
from datetime import datetime, timedelta
from sqlalchemy import func, extract
import csv
import io

reports_bp = Blueprint('reports', __name__)


def get_date_range(period_type, custom_start=None, custom_end=None):
    today = datetime.now().date()

    if period_type == 'this_month':
        start_date = today.replace(day=1)
        end_date = today

    elif period_type == 'last_month':
        first_day_this_month = today.replace(day=1)
        end_date = first_day_this_month - timedelta(days=1)
        start_date = end_date.replace(day=1)

    elif period_type == 'last_3_months':
        end_date = today
        start_date = today - timedelta(days=90)

    elif period_type == 'last_6_months':
        end_date = today
        start_date = today - timedelta(days=180)

    elif period_type == 'this_year':
        start_date = today.replace(month=1, day=1)
        end_date = today

    elif period_type == 'last_year':
        last_year = today.year - 1
        start_date = datetime(last_year, 1, 1).date()
        end_date = datetime(last_year, 12, 31).date()

    elif period_type == 'custom' and custom_start and custom_end:
        start_date = datetime.strptime(custom_start, '%Y-%m-%d').date()
        end_date = datetime.strptime(custom_end, '%Y-%m-%d').date()

    else:
        start_date = today.replace(day=1)
        end_date = today

    return start_date, end_date


@reports_bp.route('/user/<int:user_id>/spending-report', methods=['GET'])
def get_spending_report(user_id):
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date
        ).order_by(Transaction.TransactionDate.desc()).all()

        total_income = sum(t.Amount for t in transactions if t.TransactionType == 'income')
        total_expense = sum(t.Amount for t in transactions if t.TransactionType == 'expense')
        net_savings = total_income - total_expense

        category_breakdown = {}
        for t in transactions:
            if t.TransactionType == 'expense':
                if t.Category not in category_breakdown:
                    category_breakdown[t.Category] = {'amount': 0, 'count': 0, 'transactions': []}
                category_breakdown[t.Category]['amount'] += t.Amount
                category_breakdown[t.Category]['count'] += 1
                category_breakdown[t.Category]['transactions'].append({
                    'date': t.TransactionDate.isoformat(),
                    'amount': t.Amount,
                    'description': t.Description
                })

        sorted_categories = sorted(
            category_breakdown.items(),
            key=lambda x: x[1]['amount'],
            reverse=True
        )

        daily_spending = {}
        for t in transactions:
            if t.TransactionType == 'expense':
                date_key = t.TransactionDate.isoformat()
                if date_key not in daily_spending:
                    daily_spending[date_key] = 0
                daily_spending[date_key] += t.Amount

        days_in_period = (end_date - start_date).days + 1
        avg_daily_expense = total_expense / days_in_period if days_in_period > 0 else 0
        savings_rate = (net_savings / total_income * 100) if total_income > 0 else 0

        # float() converts Decimal (MySQL NUMERIC columns) to JSON-serializable float
        return jsonify({
            'period': {
                'type': period_type,
                'startDate': start_date.isoformat(),
                'endDate': end_date.isoformat(),
                'days': days_in_period
            },
            'summary': {
                'totalIncome': float(total_income),
                'totalExpense': float(total_expense),
                'netSavings': float(net_savings),
                'savingsRate': float(savings_rate),
                'transactionCount': len(transactions),
                'avgDailyExpense': float(avg_daily_expense)
            },
            'categoryBreakdown': [
                {
                    'category': cat,
                    'amount': float(data['amount']),
                    'count': data['count'],
                    'percentage': float((data['amount'] / total_expense * 100) if total_expense > 0 else 0),
                    'transactions': [
                        {**txn, 'amount': float(txn['amount'])}
                        for txn in data['transactions']
                    ]
                }
                for cat, data in sorted_categories
            ],
            'dailySpending': {k: float(v) for k, v in daily_spending.items()}
        }), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch financial summary'}), 500


@reports_bp.route('/user/<int:user_id>/budget-report', methods=['GET'])
def get_budget_report(user_id):
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        budgets = Budget.query.filter(Budget.UserId == user_id).all()

        relevant_budgets = []
        for budget in budgets:
            budget_date = datetime.strptime(f'{budget.MonthYear}-01', '%Y-%m-%d').date()
            if start_date <= budget_date <= end_date:
                relevant_budgets.append(budget)

        if not relevant_budgets:
            return jsonify({
                'message': 'No budgets found for the specified period',
                'budgets': []
            }), 200

        budget_analysis = []
        for budget in relevant_budgets:
            category_performance = []
            for cat in budget.categories:
                allocated = float(cat.AllocatedAmount)
                spent_cat = float(cat.SpentAmount)
                category_performance.append({
                    'category': cat.CategoryName,
                    'budgeted': allocated,
                    'allocated': allocated,  # alias used by export_service.dart
                    'spent': spent_cat,
                    'remaining': allocated - spent_cat,
                    'percentageUsed': (spent_cat / allocated * 100) if allocated > 0 else 0,
                    'status': 'over' if spent_cat > allocated else 'under'
                })

            total_spent = float(sum(cat.SpentAmount for cat in budget.categories))
            total_budget = float(budget.TotalBudget)

            budget_analysis.append({
                'monthYear': budget.MonthYear,
                'totalBudget': total_budget,
                'totalSpent': total_spent,
                'totalRemaining': total_budget - total_spent,
                'percentageUsed': (total_spent / total_budget * 100) if total_budget > 0 else 0,
                'categoryPerformance': category_performance,
                'isOverBudget': total_spent > total_budget
            })

        total_budgeted = sum(b['totalBudget'] for b in budget_analysis)
        total_spent = sum(b['totalSpent'] for b in budget_analysis)
        adherence_rate = ((total_budgeted - total_spent) / total_budgeted * 100) if total_budgeted > 0 else 0

        return jsonify({
            'period': {
                'type': period_type,
                'startDate': start_date.isoformat(),
                'endDate': end_date.isoformat()
            },
            'summary': {
                'totalBudgeted': float(total_budgeted),
                'totalSpent': float(total_spent),
                'adherenceRate': float(adherence_rate),
                'budgetCount': len(budget_analysis)
            },
            'budgets': budget_analysis
        }), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch analytics data'}), 500


@reports_bp.route('/user/<int:user_id>/category-analysis', methods=['GET'])
def get_category_analysis(user_id):
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date,
            Transaction.TransactionType == 'expense'
        ).all()

        category_data = {}
        for t in transactions:
            if t.Category not in category_data:
                category_data[t.Category] = {
                    'total': 0,
                    'count': 0,
                    'average': 0,
                    'max': 0,
                    'min': float('inf'),
                    'monthly_trend': {}
                }

            category_data[t.Category]['total'] += t.Amount
            category_data[t.Category]['count'] += 1
            category_data[t.Category]['max'] = max(category_data[t.Category]['max'], t.Amount)
            category_data[t.Category]['min'] = min(category_data[t.Category]['min'], t.Amount)

            month_key = t.TransactionDate.strftime('%Y-%m')
            if month_key not in category_data[t.Category]['monthly_trend']:
                category_data[t.Category]['monthly_trend'][month_key] = 0
            category_data[t.Category]['monthly_trend'][month_key] += t.Amount

        for cat in category_data:
            if category_data[cat]['count'] > 0:
                category_data[cat]['average'] = category_data[cat]['total'] / category_data[cat]['count']
            if category_data[cat]['min'] == float('inf'):
                category_data[cat]['min'] = 0

        sorted_categories = sorted(
            category_data.items(),
            key=lambda x: x[1]['total'],
            reverse=True
        )

        total_expense = sum(data['total'] for _, data in sorted_categories)

        return jsonify({
            'period': {
                'type': period_type,
                'startDate': start_date.isoformat(),
                'endDate': end_date.isoformat()
            },
            'totalExpense': float(total_expense),
            'categories': [
                {
                    'name': cat,
                    'total': float(data['total']),
                    'count': data['count'],
                    'average': float(data['average']),
                    'max': float(data['max']),
                    'min': float(data['min']),
                    'percentage': float((data['total'] / total_expense * 100) if total_expense > 0 else 0),
                    'monthlyTrend': {k: float(v) for k, v in data['monthly_trend'].items()}
                }
                for cat, data in sorted_categories
            ]
        }), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch budget report'}), 500


@reports_bp.route('/user/<int:user_id>/export/transactions', methods=['GET'])
def export_transactions_csv(user_id):
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date
        ).order_by(Transaction.TransactionDate.desc()).all()

        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(['Date', 'Type', 'Category', 'Amount', 'Description'])

        for t in transactions:
            writer.writerow([
                t.TransactionDate.strftime('%Y-%m-%d'),
                t.TransactionType.capitalize(),
                t.Category,
                f'{t.Amount:.2f}',
                t.Description or ''
            ])

        output.seek(0)
        byte_output = io.BytesIO()
        byte_output.write(output.getvalue().encode('utf-8'))
        byte_output.seek(0)

        filename = f'transactions_{start_date}_{end_date}.csv'

        return send_file(
            byte_output,
            mimetype='text/csv',
            as_attachment=True,
            download_name=filename
        )
    except Exception as e:
        return jsonify({'error': 'Failed to export transactions'}), 500


@reports_bp.route('/user/<int:user_id>/export/spending-report', methods=['GET'])
def export_spending_report_csv(user_id):
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date,
            Transaction.TransactionType == 'expense'
        ).all()

        category_breakdown = {}
        for t in transactions:
            if t.Category not in category_breakdown:
                category_breakdown[t.Category] = {'amount': 0, 'count': 0}
            category_breakdown[t.Category]['amount'] += t.Amount
            category_breakdown[t.Category]['count'] += 1

        total_expense = sum(data['amount'] for data in category_breakdown.values())

        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(['Spending Report'])
        writer.writerow(['Period', f'{start_date} to {end_date}'])
        writer.writerow(['Total Expense', f'{total_expense:.2f}'])
        writer.writerow([])
        writer.writerow(['Category', 'Amount', 'Count', 'Percentage'])

        sorted_categories = sorted(category_breakdown.items(), key=lambda x: x[1]['amount'], reverse=True)
        for cat, data in sorted_categories:
            percentage = (data['amount'] / total_expense * 100) if total_expense > 0 else 0
            writer.writerow([cat, f'{data["amount"]:.2f}', data['count'], f'{percentage:.1f}%'])

        output.seek(0)
        byte_output = io.BytesIO()
        byte_output.write(output.getvalue().encode('utf-8'))
        byte_output.seek(0)

        filename = f'spending_report_{start_date}_{end_date}.csv'

        return send_file(
            byte_output,
            mimetype='text/csv',
            as_attachment=True,
            download_name=filename
        )
    except Exception as e:
        return jsonify({'error': 'Failed to generate monthly report'}), 500
