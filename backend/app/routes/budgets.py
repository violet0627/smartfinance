# ==============================================================================
# budgets.py - Budget Routes (API Endpoints for Budget Management)
# ==============================================================================
# This file defines ALL the budget-related API endpoints.
# Budgets let users set spending limits for each month and track their spending
# against those limits by category.
#
# Example: A user sets a RM2000 budget for January 2025:
# - Food: RM500
# - Transport: RM300
# - Entertainment: RM200
# - Bills: RM700
# - Other: RM300
#
# The system then tracks actual spending against these allocations.
#
# URL prefix: /api/budgets (set in app/__init__.py)
# ==============================================================================

from flask import Blueprint, request, jsonify       # Blueprint for grouping, request for input, jsonify for output
from app import db                                   # Database instance
from app.models.budget import Budget, BudgetCategory # Budget and BudgetCategory models
from app.models.transaction import Transaction       # Transaction model (to calculate actual spending)
from datetime import datetime                        # For date operations
from sqlalchemy import func                          # SQL aggregate functions (SUM, COUNT, etc.)

# --- Create the Blueprint ---
budgets_bp = Blueprint('budgets', __name__)


# ==============================================================================
# ROUTE: POST /api/budgets/
# ==============================================================================
# Called when the user creates a new budget for a month.
# The Flutter app sends the total budget and category allocations.
# ==============================================================================
@budgets_bp.route('/', methods=['POST'])
def create_budget():
    """Create a new budget with categories"""
    try:
        data = request.get_json()

        # --- Step 1: Validate required fields ---
        required_fields = ['monthYear', 'totalBudget', 'userId', 'categories']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400

        # --- Step 2: Validate monthYear format ---
        # Must be "YYYY-MM" format (e.g., "2025-01" for January 2025)
        try:
            datetime.strptime(data['monthYear'], '%Y-%m')  # This will throw ValueError if format is wrong
        except ValueError:
            return jsonify({'error': 'Invalid monthYear format. Use YYYY-MM'}), 400

        # --- Step 3: Check if a budget already exists for this month ---
        # Each user can only have ONE budget per month
        existing = Budget.query.filter_by(
            UserId=data['userId'],
            MonthYear=data['monthYear']
        ).first()
        if existing:
            return jsonify({'error': 'Budget for this month already exists'}), 409  # 409 = Conflict

        # --- Step 4: Validate that category amounts add up to total ---
        # e.g., if totalBudget = 2000, then Food(500) + Transport(300) + ... must = 2000
        category_total = sum(float(cat['allocatedAmount']) for cat in data['categories'])
        if abs(category_total - float(data['totalBudget'])) > 0.01:   # Allow tiny floating-point difference
            return jsonify({'error': 'Category allocations must sum to total budget'}), 400

        # --- Step 5: Create the Budget record ---
        new_budget = Budget(
            MonthYear=data['monthYear'],                         # e.g., "2025-01"
            BudgetPeriod=data.get('budgetPeriod', 'Monthly'),    # Default to "Monthly"
            TotalBudget=data['totalBudget'],                     # Total budget amount
            UserId=data['userId']                                # Which user owns this budget
        )
        db.session.add(new_budget)
        db.session.flush()    # flush() assigns the BudgetId without fully committing
                              # We need BudgetId to create the categories below

        # --- Step 6: Create BudgetCategory records ---
        # Each category gets its own row linked to this budget
        for cat_data in data['categories']:
            category = BudgetCategory(
                CategoryName=cat_data['categoryName'],        # e.g., "Food", "Transport"
                AllocatedAmount=cat_data['allocatedAmount'],  # How much is budgeted for this category
                SpentAmount=0.00,                              # No spending yet (just created)
                BudgetId=new_budget.BudgetId                  # Link to the parent budget
            )
            db.session.add(category)

        # --- Step 7: Commit all changes ---
        db.session.commit()  # Saves both the budget and all categories at once

        return jsonify({
            'message': 'Budget created successfully',
            'budget': new_budget.to_dict()       # Includes categories in the response
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to create budget: {str(e)}'}), 500


# ==============================================================================
# ROUTE: GET /api/budgets/user/<user_id>
# ==============================================================================
# Called to fetch ALL budgets for a user (all months).
# Ordered by month (newest first).
# ==============================================================================
@budgets_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_budgets(user_id):
    """Get all budgets for a user"""
    try:
        # Get all budgets for this user, sorted by month (newest first)
        budgets = Budget.query.filter_by(UserId=user_id).order_by(Budget.MonthYear.desc()).all()
        return jsonify({
            'budgets': [b.to_dict() for b in budgets],   # Convert each budget to dict
            'count': len(budgets)
        }), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch budgets: {str(e)}'}), 500


# ==============================================================================
# ROUTE: GET /api/budgets/user/<user_id>/current
# ==============================================================================
# Called to fetch the budget for the CURRENT month.
# Also auto-updates spending amounts from actual transactions.
# Used by the dashboard to show "this month's budget progress".
# ==============================================================================
@budgets_bp.route('/user/<int:user_id>/current', methods=['GET'])
def get_current_budget(user_id):
    """Get current month's budget for a user"""
    try:
        # Get current month in "YYYY-MM" format (e.g., "2025-01")
        current_month = datetime.now().strftime('%Y-%m')

        # Find the budget for this month
        budget = Budget.query.filter_by(
            UserId=user_id,
            MonthYear=current_month
        ).first()

        if not budget:
            return jsonify({'budget': None, 'message': 'No budget set for current month'}), 200

        # Update spending amounts from actual transaction data
        _update_budget_spending(budget)

        return jsonify({'budget': budget.to_dict()}), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch current budget: {str(e)}'}), 500


# ==============================================================================
# ROUTE: GET /api/budgets/<budget_id>
# ==============================================================================
# Called to fetch a specific budget by its ID.
# ==============================================================================
@budgets_bp.route('/<int:budget_id>', methods=['GET'])
def get_budget(budget_id):
    """Get a specific budget"""
    try:
        budget = Budget.query.get(budget_id)
        if not budget:
            return jsonify({'error': 'Budget not found'}), 404

        # Update spending amounts from actual transaction data
        _update_budget_spending(budget)

        return jsonify({'budget': budget.to_dict()}), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch budget: {str(e)}'}), 500


# ==============================================================================
# ROUTE: PUT /api/budgets/<budget_id>
# ==============================================================================
# Called when the user edits an existing budget.
# Can update the total budget, period, and category allocations.
# ==============================================================================
@budgets_bp.route('/<int:budget_id>', methods=['PUT'])
def update_budget(budget_id):
    """Update a budget"""
    try:
        budget = Budget.query.get(budget_id)
        if not budget:
            return jsonify({'error': 'Budget not found'}), 404

        data = request.get_json()

        # --- Update budget-level fields ---
        if 'totalBudget' in data:
            budget.TotalBudget = data['totalBudget']
        if 'budgetPeriod' in data:
            budget.BudgetPeriod = data['budgetPeriod']

        # --- Update categories if provided ---
        if 'categories' in data:
            # Delete ALL existing categories for this budget (replace strategy)
            BudgetCategory.query.filter_by(BudgetId=budget_id).delete()

            # Create new categories from the request data
            for cat_data in data['categories']:
                category = BudgetCategory(
                    CategoryName=cat_data['categoryName'],
                    AllocatedAmount=cat_data['allocatedAmount'],
                    SpentAmount=cat_data.get('spentAmount', 0.00),  # Keep existing spending if provided
                    BudgetId=budget_id
                )
                db.session.add(category)

        db.session.commit()
        return jsonify({
            'message': 'Budget updated successfully',
            'budget': budget.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to update budget: {str(e)}'}), 500


# ==============================================================================
# ROUTE: DELETE /api/budgets/<budget_id>
# ==============================================================================
# Called when the user deletes a budget.
# This also deletes all associated BudgetCategory records (via cascade).
# ==============================================================================
@budgets_bp.route('/<int:budget_id>', methods=['DELETE'])
def delete_budget(budget_id):
    """Delete a budget"""
    try:
        budget = Budget.query.get(budget_id)
        if not budget:
            return jsonify({'error': 'Budget not found'}), 404

        db.session.delete(budget)    # Cascade will also delete related BudgetCategory rows
        db.session.commit()

        return jsonify({'message': 'Budget deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to delete budget: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/budgets/<budget_id>/refresh
# ==============================================================================
# Called to manually refresh the spending amounts for a budget.
# Recalculates how much has been spent in each category based on actual
# transactions for that month.
# ==============================================================================
@budgets_bp.route('/<int:budget_id>/refresh', methods=['POST'])
def refresh_budget_spending(budget_id):
    """Refresh spending amounts based on actual transactions"""
    try:
        budget = Budget.query.get(budget_id)
        if not budget:
            return jsonify({'error': 'Budget not found'}), 404

        _update_budget_spending(budget)   # Recalculate spending from transactions

        return jsonify({
            'message': 'Budget spending refreshed',
            'budget': budget.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to refresh budget: {str(e)}'}), 500


# ==============================================================================
# HELPER FUNCTION: _update_budget_spending
# ==============================================================================
# This is a PRIVATE helper function (prefixed with _ by convention).
# It's not an API endpoint - it's called by other routes above.
#
# It recalculates how much has been spent in each budget category by
# looking at actual expense transactions for that month.
#
# Example: If the budget is for "2025-01" and there are Food expenses
# totaling RM350, it updates the Food category's SpentAmount to 350.
# ==============================================================================
def _update_budget_spending(budget):
    """Helper function to update budget spending from transactions"""
    try:
        # --- Step 1: Calculate the date range for this budget's month ---
        # MonthYear is like "2025-01", so we split it into year and month
        year, month = budget.MonthYear.split('-')
        start_date = f"{year}-{month}-01"     # First day of the month (e.g., "2025-01-01")

        # Calculate the first day of the NEXT month (used as upper bound)
        if month == '12':
            # If December, next month is January of next year
            end_date = f"{int(year)+1}-01-01"
        else:
            # Otherwise, just increment the month (with zero-padding)
            end_date = f"{year}-{int(month)+1:02d}-01"   # :02d formats as 2 digits (e.g., "02")

        # --- Step 2: Get all expense transactions for this user in this month ---
        transactions = Transaction.query.filter(
            Transaction.UserId == budget.UserId,
            Transaction.TransactionType == 'expense',       # Only expenses count against budget
            Transaction.TransactionDate >= start_date,      # From first of month
            Transaction.TransactionDate < end_date          # Up to (but not including) first of next month
        ).all()

        # --- Step 3: Sum up spending by category ---
        # Creates a dict like: {"Food": 350.00, "Transport": 150.00}
        spending_by_category = {}
        for trans in transactions:
            category = trans.Category
            spending_by_category[category] = spending_by_category.get(category, 0) + float(trans.Amount)

        # --- Step 4: Update each BudgetCategory's SpentAmount ---
        for budget_cat in budget.categories:   # budget.categories is the relationship from Budget model
            spent = spending_by_category.get(budget_cat.CategoryName, 0)  # Get spending or 0 if no transactions
            budget_cat.SpentAmount = spent

        # --- Step 5: Save the updates ---
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        raise e   # Re-raise the error so the calling route can handle it
