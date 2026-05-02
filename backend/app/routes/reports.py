# ==============================================================================
# reports.py - Reports Routes (API Endpoints for Financial Reports & Analytics)
# ==============================================================================
# This file defines API endpoints for generating financial reports.
# Reports provide deep analysis of the user's financial data.
#
# Available Reports:
# 1. SPENDING REPORT: Income vs expense, savings rate, category breakdown
# 2. BUDGET REPORT: Budget adherence, over/under budget categories
# 3. CATEGORY ANALYSIS: Detailed stats per category (avg, min, max, trends)
# 4. CSV EXPORT: Download transactions or spending reports as CSV files
#
# Time Periods:
# - this_month, last_month, last_3_months, last_6_months
# - this_year, last_year
# - custom (specify startDate and endDate)
#
# URL prefix: /api/reports (set in app/__init__.py)
# ==============================================================================

from flask import Blueprint, request, jsonify, send_file   # send_file for CSV downloads
from app import db                                          # Database instance
from app.models.transaction import Transaction              # Transaction model
from app.models.budget import Budget, BudgetCategory        # Budget models
from app.models.investment import Investment                 # Investment model
from datetime import datetime, timedelta                    # For date calculations
from sqlalchemy import func, extract                        # SQL functions
import csv                                                  # For creating CSV files
import io                                                   # For in-memory file operations
import logging                                              # Standard Python logging

logger = logging.getLogger(__name__)

# --- Create the Blueprint ---
reports_bp = Blueprint('reports', __name__)


# ==============================================================================
# HELPER FUNCTION: get_date_range
# ==============================================================================
# Converts a period type string (like "this_month") into actual start/end dates.
# Used by all report endpoints to determine what time period to analyze.
#
# Args:
#     period_type (str): The period type (e.g., "this_month", "last_3_months")
#     custom_start (str): Custom start date in "YYYY-MM-DD" format (optional)
#     custom_end (str): Custom end date in "YYYY-MM-DD" format (optional)
#
# Returns:
#     tuple: (start_date, end_date) as Python date objects
# ==============================================================================
def get_date_range(period_type, custom_start=None, custom_end=None):
    """Get start and end dates based on period type"""
    today = datetime.now().date()    # Get today's date

    if period_type == 'this_month':
        # From the 1st of this month to today
        start_date = today.replace(day=1)         # Replace day with 1 (e.g., Jan 15 -> Jan 1)
        end_date = today

    elif period_type == 'last_month':
        # The entire previous month
        first_day_this_month = today.replace(day=1)
        end_date = first_day_this_month - timedelta(days=1)    # Last day of previous month
        start_date = end_date.replace(day=1)                    # First day of previous month

    elif period_type == 'last_3_months':
        # Last 90 days
        end_date = today
        start_date = today - timedelta(days=90)

    elif period_type == 'last_6_months':
        # Last 180 days
        end_date = today
        start_date = today - timedelta(days=180)

    elif period_type == 'this_year':
        # From January 1st of this year to today
        start_date = today.replace(month=1, day=1)
        end_date = today

    elif period_type == 'last_year':
        # The entire previous year (Jan 1 to Dec 31)
        last_year = today.year - 1
        start_date = datetime(last_year, 1, 1).date()
        end_date = datetime(last_year, 12, 31).date()

    elif period_type == 'custom' and custom_start and custom_end:
        # User-specified date range
        start_date = datetime.strptime(custom_start, '%Y-%m-%d').date()
        end_date = datetime.strptime(custom_end, '%Y-%m-%d').date()

    else:
        # Default to this month
        start_date = today.replace(day=1)
        end_date = today

    return start_date, end_date


# ==============================================================================
# ROUTE: GET /api/reports/user/<user_id>/spending-report
# ==============================================================================
# Generates a comprehensive spending report with:
# - Total income, expenses, and net savings
# - Savings rate percentage
# - Category breakdown with transaction counts and percentages
# - Daily spending pattern
# - Average daily expense
#
# Query parameters:
# - period: "this_month", "last_month", "last_3_months", etc.
# - startDate, endDate: For custom date ranges
# ==============================================================================
@reports_bp.route('/user/<int:user_id>/spending-report', methods=['GET'])
def get_spending_report(user_id):
    """Generate comprehensive spending report"""
    try:
        # --- Step 1: Parse date range from query parameters ---
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        # --- Step 2: Get all transactions in the period ---
        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date
        ).order_by(Transaction.TransactionDate.desc()).all()

        # --- Step 3: Calculate totals ---
        total_income = sum(t.Amount for t in transactions if t.TransactionType == 'income')
        total_expense = sum(t.Amount for t in transactions if t.TransactionType == 'expense')
        net_savings = total_income - total_expense    # Positive = saved money, Negative = overspent

        # --- Step 4: Build category breakdown ---
        # Groups expenses by category with amounts, counts, and individual transactions
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

        # Sort categories by amount (highest spending first)
        sorted_categories = sorted(
            category_breakdown.items(),
            key=lambda x: x[1]['amount'],    # Sort by the 'amount' value
            reverse=True                      # Descending order (highest first)
        )

        # --- Step 5: Build daily spending pattern ---
        # Creates a dict like: {"2025-01-15": 45.50, "2025-01-16": 23.00}
        daily_spending = {}
        for t in transactions:
            if t.TransactionType == 'expense':
                date_key = t.TransactionDate.isoformat()
                if date_key not in daily_spending:
                    daily_spending[date_key] = 0
                daily_spending[date_key] += t.Amount

        # --- Step 6: Calculate averages and rates ---
        days_in_period = (end_date - start_date).days + 1    # Number of days in the period
        avg_daily_expense = total_expense / days_in_period if days_in_period > 0 else 0
        savings_rate = (net_savings / total_income * 100) if total_income > 0 else 0

        # --- Step 7: Return the complete report ---
        # float() converts Python Decimal (from MySQL NUMERIC columns) to a plain float
        # that Flask's jsonify can serialize. Without this, jsonify raises TypeError.
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
                'savingsRate': float(savings_rate),          # Percentage of income saved
                'transactionCount': len(transactions),
                'avgDailyExpense': float(avg_daily_expense)  # Average daily spending
            },
            'categoryBreakdown': [
                {
                    'category': cat,
                    'amount': float(data['amount']),          # float() for Decimal serialization
                    'count': data['count'],
                    'percentage': float((data['amount'] / total_expense * 100) if total_expense > 0 else 0),
                    'transactions': [
                        {**txn, 'amount': float(txn['amount'])}  # Convert each transaction's amount too
                        for txn in data['transactions']
                    ]
                }
                for cat, data in sorted_categories           # List comprehension from sorted data
            ],
            'dailySpending': {k: float(v) for k, v in daily_spending.items()}  # Convert daily amounts
        }), 200
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch financial summary'}), 500


# ==============================================================================
# ROUTE: GET /api/reports/user/<user_id>/budget-report
# ==============================================================================
# Generates a budget adherence report showing:
# - How well the user stuck to their budget
# - Per-category performance (over/under budget)
# - Overall adherence rate
# ==============================================================================
@reports_bp.route('/user/<int:user_id>/budget-report', methods=['GET'])
def get_budget_report(user_id):
    """Generate budget adherence report"""
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        # --- Get all budgets for the user ---
        budgets = Budget.query.filter(
            Budget.UserId == user_id
        ).all()

        # --- Filter budgets that fall within the date range ---
        relevant_budgets = []
        for budget in budgets:
            # Convert MonthYear "2025-01" to a date for comparison
            budget_date = datetime.strptime(f'{budget.MonthYear}-01', '%Y-%m-%d').date()
            if start_date <= budget_date <= end_date:
                relevant_budgets.append(budget)

        if not relevant_budgets:
            return jsonify({
                'message': 'No budgets found for the specified period',
                'budgets': []
            }), 200

        # --- Analyze each budget ---
        budget_analysis = []
        for budget in relevant_budgets:
            # Analyze each category within the budget
            category_performance = []
            for cat in budget.categories:
                # Use AllocatedAmount — this is the correct column name on BudgetCategory model
                # float() converts Decimal (from MySQL NUMERIC) to a serializable float
                allocated = float(cat.AllocatedAmount)
                spent_cat = float(cat.SpentAmount)
                category_performance.append({
                    'category': cat.CategoryName,
                    'budgeted': allocated,                                   # How much was allocated
                    'allocated': allocated,                                  # Alias — matches export_service.dart key
                    'spent': spent_cat,                                      # How much was actually spent
                    'remaining': allocated - spent_cat,                      # How much is left
                    'percentageUsed': (spent_cat / allocated * 100) if allocated > 0 else 0,
                    'status': 'over' if spent_cat > allocated else 'under'   # Over or under budget
                })

            # Calculate budget-level totals
            total_spent = float(sum(cat.SpentAmount for cat in budget.categories))
            total_budget = float(budget.TotalBudget)

            budget_analysis.append({
                'monthYear': budget.MonthYear,
                'totalBudget': total_budget,
                'totalSpent': total_spent,
                'totalRemaining': total_budget - total_spent,
                'percentageUsed': (total_spent / total_budget * 100) if total_budget > 0 else 0,
                'categoryPerformance': category_performance,
                'isOverBudget': total_spent > total_budget                  # True if over budget
            })

        # --- Overall statistics across all budgets in the period ---
        total_budgeted = sum(b['totalBudget'] for b in budget_analysis)
        total_spent = sum(b['totalSpent'] for b in budget_analysis)
        # Adherence rate: how much of the budget was NOT spent (higher = better)
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
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch analytics data'}), 500


# ==============================================================================
# ROUTE: GET /api/reports/user/<user_id>/category-analysis
# ==============================================================================
# Generates detailed category analysis with:
# - Total, count, average, min, max per category
# - Monthly trend for each category
# - Percentage of total spending
# ==============================================================================
@reports_bp.route('/user/<int:user_id>/category-analysis', methods=['GET'])
def get_category_analysis(user_id):
    """Generate detailed category analysis report"""
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        # --- Get expense transactions in the period ---
        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date,
            Transaction.TransactionType == 'expense'         # Only analyze expenses
        ).all()

        # --- Build detailed stats for each category ---
        category_data = {}
        for t in transactions:
            if t.Category not in category_data:
                category_data[t.Category] = {
                    'total': 0,
                    'count': 0,
                    'average': 0,
                    'max': 0,
                    'min': float('inf'),         # Start with infinity so any value is smaller
                    'monthly_trend': {}           # Spending per month for trend analysis
                }

            category_data[t.Category]['total'] += t.Amount
            category_data[t.Category]['count'] += 1
            category_data[t.Category]['max'] = max(category_data[t.Category]['max'], t.Amount)  # Track highest
            category_data[t.Category]['min'] = min(category_data[t.Category]['min'], t.Amount)  # Track lowest

            # Build monthly trend: {"2025-01": 350, "2025-02": 420}
            month_key = t.TransactionDate.strftime('%Y-%m')    # Format: "2025-01"
            if month_key not in category_data[t.Category]['monthly_trend']:
                category_data[t.Category]['monthly_trend'][month_key] = 0
            category_data[t.Category]['monthly_trend'][month_key] += t.Amount

        # --- Calculate averages and fix min values ---
        for cat in category_data:
            if category_data[cat]['count'] > 0:
                category_data[cat]['average'] = category_data[cat]['total'] / category_data[cat]['count']
            if category_data[cat]['min'] == float('inf'):
                category_data[cat]['min'] = 0                  # No transactions = min of 0

        # --- Sort by total spending (highest first) ---
        sorted_categories = sorted(
            category_data.items(),
            key=lambda x: x[1]['total'],
            reverse=True
        )

        # Calculate grand total for percentage calculations
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
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch budget report'}), 500


# ==============================================================================
# ROUTE: GET /api/reports/user/<user_id>/export/transactions
# ==============================================================================
# Exports transactions to a CSV file for download.
# The user can open this in Excel, Google Sheets, etc.
#
# CSV format:
# Date, Type, Category, Amount, Description
# 2025-01-15, Expense, Food, 45.50, Lunch at KFC
# ==============================================================================
@reports_bp.route('/user/<int:user_id>/export/transactions', methods=['GET'])
def export_transactions_csv(user_id):
    """Export transactions to CSV"""
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        # --- Get transactions ---
        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date
        ).order_by(Transaction.TransactionDate.desc()).all()

        # --- Create CSV in memory ---
        # io.StringIO() creates a text buffer in memory (like a virtual file)
        output = io.StringIO()
        writer = csv.writer(output)      # csv.writer writes CSV-formatted rows

        # Write the header row
        writer.writerow(['Date', 'Type', 'Category', 'Amount', 'Description'])

        # Write each transaction as a row
        for t in transactions:
            writer.writerow([
                t.TransactionDate.strftime('%Y-%m-%d'),     # Format date
                t.TransactionType.capitalize(),              # "Income" or "Expense"
                t.Category,
                f'{t.Amount:.2f}',                           # Format to 2 decimal places
                t.Description or ''                          # Empty string if no description
            ])

        # --- Convert to bytes and prepare for download ---
        # CSV was written as text (StringIO), but send_file needs bytes (BytesIO)
        output.seek(0)                                       # Go back to the start of the buffer
        byte_output = io.BytesIO()
        byte_output.write(output.getvalue().encode('utf-8')) # Convert text to UTF-8 bytes
        byte_output.seek(0)

        filename = f'transactions_{start_date}_{end_date}.csv'

        # --- Send the file as a download ---
        # send_file() sends the file to the browser/app for download
        return send_file(
            byte_output,
            mimetype='text/csv',                # Tell the browser it's a CSV file
            as_attachment=True,                  # Force download (not display in browser)
            download_name=filename               # Suggested filename for the download
        )
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to export transactions'}), 500


# ==============================================================================
# ROUTE: GET /api/reports/user/<user_id>/export/spending-report
# ==============================================================================
# Exports a spending summary report as a CSV file.
# Includes a summary section and category breakdown table.
# ==============================================================================
@reports_bp.route('/user/<int:user_id>/export/spending-report', methods=['GET'])
def export_spending_report_csv(user_id):
    """Export spending report to CSV"""
    try:
        period_type = request.args.get('period', 'this_month')
        custom_start = request.args.get('startDate')
        custom_end = request.args.get('endDate')

        start_date, end_date = get_date_range(period_type, custom_start, custom_end)

        # --- Get expense transactions ---
        transactions = Transaction.query.filter(
            Transaction.UserId == user_id,
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate <= end_date,
            Transaction.TransactionType == 'expense'
        ).all()

        # --- Build category breakdown ---
        category_breakdown = {}
        for t in transactions:
            if t.Category not in category_breakdown:
                category_breakdown[t.Category] = {'amount': 0, 'count': 0}
            category_breakdown[t.Category]['amount'] += t.Amount
            category_breakdown[t.Category]['count'] += 1

        total_expense = sum(data['amount'] for data in category_breakdown.values())

        # --- Create CSV with summary and breakdown ---
        output = io.StringIO()
        writer = csv.writer(output)

        # Write summary section
        writer.writerow(['Spending Report'])                              # Title
        writer.writerow(['Period', f'{start_date} to {end_date}'])       # Date range
        writer.writerow(['Total Expense', f'{total_expense:.2f}'])       # Total
        writer.writerow([])                                               # Empty row as separator

        # Write category breakdown table
        writer.writerow(['Category', 'Amount', 'Count', 'Percentage'])   # Table header
        sorted_categories = sorted(category_breakdown.items(), key=lambda x: x[1]['amount'], reverse=True)
        for cat, data in sorted_categories:
            percentage = (data['amount'] / total_expense * 100) if total_expense > 0 else 0
            writer.writerow([cat, f'{data["amount"]:.2f}', data['count'], f'{percentage:.1f}%'])

        # --- Convert to bytes and send ---
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
        logger.error(str(e))
        return jsonify({'error': 'Failed to generate monthly report'}), 500
