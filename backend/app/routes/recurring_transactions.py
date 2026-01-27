from flask import Blueprint, request, jsonify
from app import db
from app.models.recurring_transaction import RecurringTransaction
from app.models.transaction import Transaction
from datetime import datetime, timedelta

recurring_bp = Blueprint('recurring', __name__)

# ==================== CREATE ====================

@recurring_bp.route('/user/<int:user_id>', methods=['POST'])
def create_recurring_transaction(user_id):
    """Create a new recurring transaction"""
    try:
        data = request.get_json()

        # Calculate first execution date
        start_date = datetime.strptime(data.get('startDate'), '%Y-%m-%d').date()
        next_execution = start_date

        recurring = RecurringTransaction(
            UserId=user_id,
            Name=data.get('name'),
            TransactionType=data.get('transactionType'),
            Category=data.get('category'),
            Amount=data.get('amount'),
            Description=data.get('description'),
            Frequency=data.get('frequency'),
            StartDate=start_date,
            EndDate=datetime.strptime(data.get('endDate'), '%Y-%m-%d').date() if data.get('endDate') else None,
            NextExecution=next_execution,
            IsActive=True
        )

        db.session.add(recurring)
        db.session.commit()

        return jsonify({
            'message': 'Recurring transaction created successfully',
            'recurring': recurring.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to create recurring transaction: {str(e)}'}), 500


# ==================== READ ====================

@recurring_bp.route('/user/<int:user_id>', methods=['GET'])
def get_recurring_transactions(user_id):
    """Get all recurring transactions for a user"""
    try:
        active_only = request.args.get('active', 'false').lower() == 'true'

        query = RecurringTransaction.query.filter_by(UserId=user_id)

        if active_only:
            query = query.filter_by(IsActive=True)

        recurring = query.order_by(RecurringTransaction.NextExecution).all()

        return jsonify({
            'recurring': [r.to_dict() for r in recurring],
            'total': len(recurring)
        }), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch recurring transactions: {str(e)}'}), 500


@recurring_bp.route('/<int:recurring_id>', methods=['GET'])
def get_recurring_transaction(recurring_id):
    """Get a specific recurring transaction"""
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        return jsonify(recurring.to_dict()), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch recurring transaction: {str(e)}'}), 500


# ==================== UPDATE ====================

@recurring_bp.route('/<int:recurring_id>', methods=['PUT'])
def update_recurring_transaction(recurring_id):
    """Update a recurring transaction"""
    try:
        data = request.get_json()
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        # Update fields
        if 'name' in data:
            recurring.Name = data['name']
        if 'transactionType' in data:
            recurring.TransactionType = data['transactionType']
        if 'category' in data:
            recurring.Category = data['category']
        if 'amount' in data:
            recurring.Amount = data['amount']
        if 'description' in data:
            recurring.Description = data['description']
        if 'frequency' in data:
            recurring.Frequency = data['frequency']
        if 'startDate' in data:
            recurring.StartDate = datetime.strptime(data['startDate'], '%Y-%m-%d').date()
        if 'endDate' in data:
            recurring.EndDate = datetime.strptime(data['endDate'], '%Y-%m-%d').date() if data['endDate'] else None
        if 'isActive' in data:
            recurring.IsActive = data['isActive']

        recurring.UpdatedAt = datetime.utcnow()
        db.session.commit()

        return jsonify({
            'message': 'Recurring transaction updated successfully',
            'recurring': recurring.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to update recurring transaction: {str(e)}'}), 500


# ==================== DELETE ====================

@recurring_bp.route('/<int:recurring_id>', methods=['DELETE'])
def delete_recurring_transaction(recurring_id):
    """Delete a recurring transaction"""
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        db.session.delete(recurring)
        db.session.commit()

        return jsonify({'message': 'Recurring transaction deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to delete recurring transaction: {str(e)}'}), 500


# ==================== EXECUTION ====================

@recurring_bp.route('/<int:recurring_id>/execute', methods=['POST'])
def execute_recurring_transaction(recurring_id):
    """Manually execute a recurring transaction"""
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        # Create actual transaction
        transaction = Transaction(
            UserId=recurring.UserId,
            TransactionType=recurring.TransactionType,
            Category=recurring.Category,
            Amount=recurring.Amount,
            Description=f"{recurring.Name} (Recurring)",
            TransactionDate=datetime.now().date()
        )

        db.session.add(transaction)

        # Update recurring transaction
        recurring.LastExecuted = datetime.now().date()
        recurring.NextExecution = recurring.calculate_next_execution()

        db.session.commit()

        return jsonify({
            'message': 'Recurring transaction executed successfully',
            'transaction': transaction.to_dict(),
            'recurring': recurring.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to execute recurring transaction: {str(e)}'}), 500


@recurring_bp.route('/user/<int:user_id>/execute-due', methods=['POST'])
def execute_due_recurring_transactions(user_id):
    """Execute all due recurring transactions for a user"""
    try:
        recurring_list = RecurringTransaction.query.filter_by(
            UserId=user_id,
            IsActive=True
        ).all()

        executed = []
        today = datetime.now().date()

        for recurring in recurring_list:
            if recurring.should_execute():
                # Create actual transaction
                transaction = Transaction(
                    UserId=recurring.UserId,
                    TransactionType=recurring.TransactionType,
                    Category=recurring.Category,
                    Amount=recurring.Amount,
                    Description=f"{recurring.Name} (Recurring)",
                    TransactionDate=today
                )

                db.session.add(transaction)

                # Update recurring transaction
                recurring.LastExecuted = today
                recurring.NextExecution = recurring.calculate_next_execution()

                executed.append({
                    'recurring': recurring.to_dict(),
                    'transaction': transaction.to_dict()
                })

        db.session.commit()

        return jsonify({
            'message': f'{len(executed)} recurring transactions executed',
            'executed': executed
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to execute recurring transactions: {str(e)}'}), 500


# ==================== TOGGLE ====================

@recurring_bp.route('/<int:recurring_id>/toggle', methods=['POST'])
def toggle_recurring_transaction(recurring_id):
    """Toggle active status of a recurring transaction"""
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        recurring.IsActive = not recurring.IsActive
        recurring.UpdatedAt = datetime.utcnow()
        db.session.commit()

        return jsonify({
            'message': f'Recurring transaction {"activated" if recurring.IsActive else "deactivated"}',
            'recurring': recurring.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to toggle recurring transaction: {str(e)}'}), 500
