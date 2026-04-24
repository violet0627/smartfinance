from flask import Blueprint, request, jsonify
from app import db
from app.models.recurring_transaction import RecurringTransaction
from app.models.transaction import Transaction
from datetime import datetime

recurring_bp = Blueprint('recurring', __name__)


@recurring_bp.route('/user/<int:user_id>', methods=['POST'])
def create_recurring_transaction(user_id):
    try:
        data = request.get_json()

        required_fields = ['name', 'transactionType', 'category', 'amount', 'frequency', 'startDate']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400

        if data['transactionType'] not in ['income', 'expense']:
            return jsonify({'error': 'transactionType must be "income" or "expense"'}), 400

        try:
            amount = float(data['amount'])
            if amount <= 0:
                return jsonify({'error': 'Amount must be greater than 0'}), 400
        except (ValueError, TypeError):
            return jsonify({'error': 'Invalid amount format'}), 400

        try:
            start_date = datetime.strptime(data['startDate'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid startDate format. Use YYYY-MM-DD'}), 400

        next_execution = start_date

        end_date = None
        if data.get('endDate'):
            try:
                end_date = datetime.strptime(data['endDate'], '%Y-%m-%d').date()
                if end_date <= start_date:
                    return jsonify({'error': 'endDate must be after startDate'}), 400
            except ValueError:
                return jsonify({'error': 'Invalid endDate format. Use YYYY-MM-DD'}), 400

        recurring = RecurringTransaction(
            UserId=user_id,
            Name=data['name'],
            TransactionType=data['transactionType'],
            Category=data['category'],
            Amount=amount,
            Description=data.get('description'),
            Frequency=data['frequency'],
            StartDate=start_date,
            EndDate=end_date,
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
        return jsonify({'error': 'Failed to create recurring transaction'}), 500


@recurring_bp.route('/user/<int:user_id>', methods=['GET'])
def get_recurring_transactions(user_id):
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
        return jsonify({'error': 'Failed to fetch recurring transactions'}), 500


@recurring_bp.route('/<int:recurring_id>', methods=['GET'])
def get_recurring_transaction(recurring_id):
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        return jsonify(recurring.to_dict()), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch recurring transaction'}), 500


@recurring_bp.route('/<int:recurring_id>', methods=['PUT'])
def update_recurring_transaction(recurring_id):
    try:
        data = request.get_json()
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

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
        return jsonify({'error': 'Failed to update recurring transaction'}), 500


@recurring_bp.route('/<int:recurring_id>', methods=['DELETE'])
def delete_recurring_transaction(recurring_id):
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        Transaction.query.filter_by(UserId=recurring.UserId).filter(
            Transaction.Description == f"{recurring.Name} (Recurring)"
        ).delete(synchronize_session=False)

        db.session.delete(recurring)
        db.session.commit()

        return jsonify({'message': 'Recurring transaction deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to delete recurring transaction'}), 500


@recurring_bp.route('/<int:recurring_id>/execute', methods=['POST'])
def execute_recurring_transaction(recurring_id):
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        today = datetime.now().date()
        already_executed_today = Transaction.query.filter_by(
            UserId=recurring.UserId,
            Description=f"{recurring.Name} (Recurring)",
            TransactionDate=today
        ).first()

        if already_executed_today:
            return jsonify({'error': 'Already executed today. Only one execution per day is allowed.'}), 409

        transaction = Transaction(
            UserId=recurring.UserId,
            TransactionType=recurring.TransactionType,
            Category=recurring.Category,
            Amount=recurring.Amount,
            Description=f"{recurring.Name} (Recurring)",
            TransactionDate=today
        )

        db.session.add(transaction)
        recurring.LastExecuted = today
        recurring.NextExecution = recurring.calculate_next_execution()
        db.session.commit()

        return jsonify({
            'message': 'Recurring transaction executed successfully',
            'transaction': transaction.to_dict(),
            'recurring': recurring.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to execute recurring transaction'}), 500


@recurring_bp.route('/user/<int:user_id>/execute-due', methods=['POST'])
def execute_due_recurring_transactions(user_id):
    try:
        recurring_list = RecurringTransaction.query.filter_by(
            UserId=user_id,
            IsActive=True
        ).all()

        executed = []
        today = datetime.now().date()

        for recurring in recurring_list:
            if recurring.should_execute():
                transaction = Transaction(
                    UserId=recurring.UserId,
                    TransactionType=recurring.TransactionType,
                    Category=recurring.Category,
                    Amount=recurring.Amount,
                    Description=f"{recurring.Name} (Recurring)",
                    TransactionDate=today
                )

                db.session.add(transaction)
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
        return jsonify({'error': 'Failed to execute recurring transactions'}), 500


@recurring_bp.route('/<int:recurring_id>/toggle', methods=['POST'])
def toggle_recurring_transaction(recurring_id):
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        recurring.IsActive = not recurring.IsActive
        recurring.UpdatedAt = datetime.utcnow()

        # On resume, advance NextExecution past today to avoid an immediate duplicate execution
        if recurring.IsActive:
            today = datetime.now().date()
            if recurring.NextExecution <= today:
                recurring.LastExecuted = recurring.NextExecution
                recurring.NextExecution = recurring.calculate_next_execution()

        db.session.commit()

        return jsonify({
            'message': f'Recurring transaction {"activated" if recurring.IsActive else "deactivated"}',
            'recurring': recurring.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to toggle recurring transaction'}), 500
