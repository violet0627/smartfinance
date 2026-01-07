from flask import Blueprint, request, jsonify, send_file
from app import db
from app.models.transaction import Transaction
from app.models.budget import Budget, BudgetCategory
from app.models.investment import Investment
from datetime import datetime, timedelta
from sqlalchemy import func, extract
import csv
import io
import json

reports_bp = Blueprint('reports', __name__)


def get_date_range(period_type, custom_start=None, custom_end=None):
    """Get start and end dates based on period type"""
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
        # Default to this month
        start_date = today.replace(day=1)
        end_date = today

    return start_date, end_date


@reports_bp.route('/user/<int:user_id>/spending-report', methods=['GET'])
def get_spending_report(user_id):
    """Generate comprehensive spending report"""
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        # Get all transactions in period
        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date
        ).order_by(Transaction.TransactionDate.desc()).all()

        # Calculate totals
        total_income = sum(t.Amount for t in transactions if t.TransactionType == 'income')
        total_expense = sum(t.Amount for t in transactions if t.TransactionType == 'expense')
        net_savings = total_income - total_expense

        # Category breakdown
        category_breakdown = {}
        for t in transactions:
            if t.TransactionType == 'expense':
                if t.Category not in category_breakdown:
                    category_breakdown[t.Category] = {
                        'amount': 0,
                        'count': 0,
                        'transactions': []
                    }
                category_breakdown[t.Category]['amount'] += t.Amount
                category_breakdown[t.Category]['count'] += 1
                category_breakdown[t.Category]['transactions'].append({
                    'date': t.TransactionDate.isoformat(),
                    'amount': t.Amount,
                    'description': t.Description
                })

        # Sort categories by amount
        sorted_categories = sorted(
            category_breakdown.items(),
            key=lambda x: x[1]['amount'],
            reverse=True
        )

        # Daily spending pattern
        daily_spending = {}
        for t in transactions:
            if t.TransactionType == 'expense':
                date_key = t.TransactionDate.isoformat()
                if date_key not in daily_spending:
                    daily_spending[date_key] = 0
                daily_spending[date_key] += t.Amount

        # Calculate averages
        days_in_period = (end_date - start_date).days + 1
        avg_daily_expense = total_expense / days_in_period if days_in_period > 0 else 0

        # Savings rate
        savings_rate = (net_savings / total_income * 100) if total_income > 0 else 0

        return jsonify({
            'period': {
                'type': period_type,
                'startDate': start_date.isoformat(),
                'endDate': end_date.isoformat(),
                'days': days_in_period
            },
            'summary': {
                'totalIncome': total_income,
                'totalExpense': total_expense,
                'netSavings': net_savings,
                'savingsRate': savings_rate,
                'transactionCount': len(transactions),
                'avgDailyExpense': avg_daily_expense
            },
            'categoryBreakdown': [
                {
                    'category': cat,
                    'amount': data['amount'],
                    'count': data['count'],
                    'percentage': (data['amount'] / total_expense * 100) if total_expense > 0 else 0,
                    'transactions': data['transactions']
                }
                for cat, data in sorted_categories
            ],
            'dailySpending': daily_spending
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@reports_bp.route('/user/<int:user_id>/budget-report', methods=['GET'])
def get_budget_report(user_id):
    """Generate budget adherence report"""
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        # Get budgets in period
        budgets = Budget.query.filter(
            Budget.UserId == user_id
        ).all()

        # Filter budgets by month-year in range
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

        # Analyze each budget
        budget_analysis = []
        for budget in relevant_budgets:
            category_performance = []
            for cat in budget.categories:
                category_performance.append({
                    'category': cat.CategoryName,
                    'budgeted': cat.BudgetedAmount,
                    'spent': cat.SpentAmount,
                    'remaining': cat.BudgetedAmount - cat.SpentAmount,
                    'percentageUsed': (cat.SpentAmount / cat.BudgetedAmount * 100) if cat.BudgetedAmount > 0 else 0,
                    'status': 'over' if cat.SpentAmount > cat.BudgetedAmount else 'under'
                })

            budget_analysis.append({
                'monthYear': budget.MonthYear,
                'totalBudget': budget.TotalBudget,
                'totalSpent': sum(cat.SpentAmount for cat in budget.categories),
                'totalRemaining': budget.TotalBudget - sum(cat.SpentAmount for cat in budget.categories),
                'percentageUsed': (sum(cat.SpentAmount for cat in budget.categories) / budget.TotalBudget * 100) if budget.TotalBudget > 0 else 0,
                'categoryPerformance': category_performance,
                'isOverBudget': sum(cat.SpentAmount for cat in budget.categories) > budget.TotalBudget
            })

        # Overall statistics
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
                'totalBudgeted': total_budgeted,
                'totalSpent': total_spent,
                'adherenceRate': adherence_rate,
                'budgetCount': len(budget_analysis)
            },
            'budgets': budget_analysis
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@reports_bp.route('/user/<int:user_id>/category-analysis', methods=['GET'])
def get_category_analysis(user_id):
    """Generate detailed category analysis report"""
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        # Get transactions
        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date,
            Transaction.TransactionType == 'expense'
        ).all()

        # Category analysis
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

            # Monthly trend
            month_key = t.TransactionDate.strftime('%Y-%m')
            if month_key not in category_data[t.Category]['monthly_trend']:
                category_data[t.Category]['monthly_trend'][month_key] = 0
            category_data[t.Category]['monthly_trend'][month_key] += t.Amount

        # Calculate averages
        for cat in category_data:
            if category_data[cat]['count'] > 0:
                category_data[cat]['average'] = category_data[cat]['total'] / category_data[cat]['count']
            if category_data[cat]['min'] == float('inf'):
                category_data[cat]['min'] = 0

        # Sort by total spending
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
            'totalExpense': total_expense,
            'categories': [
                {
                    'name': cat,
                    'total': data['total'],
                    'count': data['count'],
                    'average': data['average'],
                    'max': data['max'],
                    'min': data['min'],
                    'percentage': (data['total'] / total_expense * 100) if total_expense > 0 else 0,
                    'monthlyTrend': data['monthly_trend']
                }
                for cat, data in sorted_categories
            ]
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@reports_bp.route('/user/<int:user_id>/export/transactions', methods=['GET'])
def export_transactions_csv(user_id):
    """Export transactions to CSV"""
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        # Get transactions
        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date
        ).order_by(Transaction.TransactionDate.desc()).all()

        # Create CSV in memory
        output = io.StringIO()
        writer = csv.writer(output)

        # Write header
        writer.writerow(['Date', 'Type', 'Category', 'Amount', 'Description'])

        # Write data
        for t in transactions:
            writer.writerow([
                t.TransactionDate.strftime('%Y-%m-%d'),
                t.TransactionType.capitalize(),
                t.Category,
                f'{t.Amount:.2f}',
                t.Description or ''
            ])

        # Prepare file for download
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
        return jsonify({'error': str(e)}), 500


@reports_bp.route('/user/<int:user_id>/export/spending-report', methods=['GET'])
def export_spending_report_csv(user_id):
    """Export spending report to CSV"""
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        # Get spending report data
        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date,
            Transaction.TransactionType == 'expense'
        ).all()

        # Category breakdown
        category_breakdown = {}
        for t in transactions:
            if t.Category not in category_breakdown:
                category_breakdown[t.Category] = {'amount': 0, 'count': 0}
            category_breakdown[t.Category]['amount'] += t.Amount
            category_breakdown[t.Category]['count'] += 1

        total_expense = sum(data['amount'] for data in category_breakdown.values())

        # Create CSV
        output = io.StringIO()
        writer = csv.writer(output)

        # Write summary
        writer.writerow(['Spending Report'])
        writer.writerow(['Period', f'{start_date} to {end_date}'])
        writer.writerow(['Total Expense', f'{total_expense:.2f}'])
        writer.writerow([])

        # Write category breakdown
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
        return jsonify({'error': str(e)}), 500
