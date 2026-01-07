from flask import Blueprint, request, jsonify
from app import db
from app.models.budget import Budget, BudgetCategory
from app.models.transaction import Transaction
from datetime import datetime
from sqlalchemy import func

budgets_bp = Blueprint('budgets', __name__)

@budgets_bp.route('/', methods=['POST'])
def create_budget():
    """Create a new budget with categories"""
    try:
        data = request.get_json()

        # Validate required fields
        required_fields = ['monthYear', 'totalBudget', 'userId', 'categories']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400

        # Validate monthYear format (YYYY-MM)
        try:
            datetime.strptime(data['monthYear'], '%Y-%m')
        except ValueError:
            return jsonify({'error': 'Invalid monthYear format. Use YYYY-MM'}), 400

        # Check if budget for this month already exists
        existing = Budget.query.filter_by(
            UserId=data['userId'],
            MonthYear=data['monthYear']
        ).first()
        if existing:
            return jsonify({'error': 'Budget for this month already exists'}), 409

        # Validate total budget matches category sum
        category_total = sum(float(cat['allocatedAmount']) for cat in data['categories'])
        if abs(category_total - float(data['totalBudget'])) > 0.01:
            return jsonify({'error': 'Category allocations must sum to total budget'}), 400

        # Create budget
        new_budget = Budget(
            MonthYear=data['monthYear'],
            BudgetPeriod=data.get('budgetPeriod', 'Monthly'),
            TotalBudget=data['totalBudget'],
            UserId=data['userId']
        )
        db.session.add(new_budget)
        db.session.flush()

        # Create categories
        for cat_data in data['categories']:
            category = BudgetCategory(
                CategoryName=cat_data['categoryName'],
                AllocatedAmount=cat_data['allocatedAmount'],
                SpentAmount=0.00,
                BudgetId=new_budget.BudgetId
            )
            db.session.add(category)

        db.session.commit()

        return jsonify({
            'message': 'Budget created successfully',
            'budget': new_budget.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to create budget: {str(e)}'}), 500

@budgets_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_budgets(user_id):
    """Get all budgets for a user"""
    try:
        budgets = Budget.query.filter_by(UserId=user_id).order_by(Budget.MonthYear.desc()).all()
        return jsonify({
            'budgets': [b.to_dict() for b in budgets],
            'count': len(budgets)
        }), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch budgets: {str(e)}'}), 500

@budgets_bp.route('/user/<int:user_id>/current', methods=['GET'])
def get_current_budget(user_id):
    """Get current month's budget for a user"""
    try:
        current_month = datetime.now().strftime('%Y-%m')
        budget = Budget.query.filter_by(
            UserId=user_id,
            MonthYear=current_month
        ).first()

        if not budget:
            return jsonify({'budget': None, 'message': 'No budget set for current month'}), 200

        # Update spent amounts based on transactions
        _update_budget_spending(budget)

        return jsonify({'budget': budget.to_dict()}), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch current budget: {str(e)}'}), 500

@budgets_bp.route('/<int:budget_id>', methods=['GET'])
def get_budget(budget_id):
    """Get a specific budget"""
    try:
        budget = Budget.query.get(budget_id)
        if not budget:
            return jsonify({'error': 'Budget not found'}), 404

        # Update spent amounts
        _update_budget_spending(budget)

        return jsonify({'budget': budget.to_dict()}), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch budget: {str(e)}'}), 500

@budgets_bp.route('/<int:budget_id>', methods=['PUT'])
def update_budget(budget_id):
    """Update a budget"""
    try:
        budget = Budget.query.get(budget_id)
        if not budget:
            return jsonify({'error': 'Budget not found'}), 404

        data = request.get_json()

        # Update budget fields
        if 'totalBudget' in data:
            budget.TotalBudget = data['totalBudget']
        if 'budgetPeriod' in data:
            budget.BudgetPeriod = data['budgetPeriod']

        # Update categories if provided
        if 'categories' in data:
            # Delete existing categories
            BudgetCategory.query.filter_by(BudgetId=budget_id).delete()

            # Add new categories
            for cat_data in data['categories']:
                category = BudgetCategory(
                    CategoryName=cat_data['categoryName'],
                    AllocatedAmount=cat_data['allocatedAmount'],
                    SpentAmount=cat_data.get('spentAmount', 0.00),
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

@budgets_bp.route('/<int:budget_id>', methods=['DELETE'])
def delete_budget(budget_id):
    """Delete a budget"""
    try:
        budget = Budget.query.get(budget_id)
        if not budget:
            return jsonify({'error': 'Budget not found'}), 404

        db.session.delete(budget)
        db.session.commit()

        return jsonify({'message': 'Budget deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to delete budget: {str(e)}'}), 500

@budgets_bp.route('/<int:budget_id>/refresh', methods=['POST'])
def refresh_budget_spending(budget_id):
    """Refresh spending amounts based on actual transactions"""
    try:
        budget = Budget.query.get(budget_id)
        if not budget:
            return jsonify({'error': 'Budget not found'}), 404

        _update_budget_spending(budget)

        return jsonify({
            'message': 'Budget spending refreshed',
            'budget': budget.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to refresh budget: {str(e)}'}), 500

def _update_budget_spending(budget):
    """Helper function to update budget spending from transactions"""
    try:
        # Parse month/year
        year, month = budget.MonthYear.split('-')
        start_date = f"{year}-{month}-01"

        # Calculate last day of month
        if month == '12':
            end_date = f"{int(year)+1}-01-01"
        else:
            end_date = f"{year}-{int(month)+1:02d}-01"

        # Get all expense transactions for this month
        transactions = Transaction.query.filter(
            Transaction.UserId == budget.UserId,
            Transaction.TransactionType == 'expense',
            Transaction.TransactionDate >= start_date,
            Transaction.TransactionDate < end_date
        ).all()

        # Calculate spending by category
        spending_by_category = {}
        for trans in transactions:
            category = trans.Category
            spending_by_category[category] = spending_by_category.get(category, 0) + float(trans.Amount)

        # Update budget categories
        for budget_cat in budget.categories:
            spent = spending_by_category.get(budget_cat.CategoryName, 0)
            budget_cat.SpentAmount = spent

        db.session.commit()
    except Exception as e:
        db.session.rollback()
        raise e
