from flask import Blueprint, request, jsonify
from app import db
from app.models.transaction import Transaction
from datetime import datetime, date

transactions_bp = Blueprint('transactions', __name__)

@transactions_bp.route('/', methods=['POST'])
def create_transaction():
    """Create a new transaction"""
    try:
        data = request.get_json()

        # Validate required fields
        required_fields = ['amount', 'category', 'transactionDate', 'transactionType', 'userId']
        for field in required_fields:
            if field not in data or data[field] is None:
                return jsonify({'error': f'{field} is required'}), 400

        # Validate transaction type
        if data['transactionType'] not in ['income', 'expense']:
            return jsonify({'error': 'transactionType must be "income" or "expense"'}), 400

        # Validate amount
        try:
            amount = float(data['amount'])
            if amount <= 0:
                return jsonify({'error': 'Amount must be greater than 0'}), 400
        except ValueError:
            return jsonify({'error': 'Invalid amount format'}), 400

        # Parse date
        try:
            transaction_date = datetime.strptime(data['transactionDate'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400

        # Create new transaction
        new_transaction = Transaction(
            Amount=amount,
            Category=data['category'],
            Description=data.get('description', ''),
            TransactionDate=transaction_date,
            TransactionType=data['transactionType'],
            UserId=data['userId']
        )

        db.session.add(new_transaction)
        db.session.commit()

        return jsonify({
            'message': 'Transaction created successfully',
            'transaction': new_transaction.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to create transaction: {str(e)}'}), 500

@transactions_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_transactions(user_id):
    """Get all transactions for a user"""
    try:
        # Get query parameters for filtering
        transaction_type = request.args.get('type')  # income or expense
        category = request.args.get('category')
        start_date = request.args.get('startDate')
        end_date = request.args.get('endDate')
        limit = request.args.get('limit', type=int)

        # Build query
        query = Transaction.query.filter_by(UserId=user_id)

        if transaction_type:
            query = query.filter_by(TransactionType=transaction_type)

        if category:
            query = query.filter_by(Category=category)

        if start_date:
            query = query.filter(Transaction.TransactionDate >= start_date)

        if end_date:
            query = query.filter(Transaction.TransactionDate <= end_date)

        # Order by date descending
        query = query.order_by(Transaction.TransactionDate.desc(), Transaction.CreatedAt.desc())

        if limit:
            query = query.limit(limit)

        transactions = query.all()

        return jsonify({
            'transactions': [t.to_dict() for t in transactions],
            'count': len(transactions)
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to fetch transactions: {str(e)}'}), 500

@transactions_bp.route('/<int:transaction_id>', methods=['GET'])
def get_transaction(transaction_id):
    """Get a specific transaction"""
    try:
        transaction = Transaction.query.get(transaction_id)
        if not transaction:
            return jsonify({'error': 'Transaction not found'}), 404

        return jsonify({'transaction': transaction.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': f'Failed to fetch transaction: {str(e)}'}), 500

@transactions_bp.route('/<int:transaction_id>', methods=['PUT'])
def update_transaction(transaction_id):
    """Update a transaction"""
    try:
        transaction = Transaction.query.get(transaction_id)
        if not transaction:
            return jsonify({'error': 'Transaction not found'}), 404

        data = request.get_json()

        # Update fields if provided
        if 'amount' in data:
            try:
                amount = float(data['amount'])
                if amount <= 0:
                    return jsonify({'error': 'Amount must be greater than 0'}), 400
                transaction.Amount = amount
            except ValueError:
                return jsonify({'error': 'Invalid amount format'}), 400

        if 'category' in data:
            transaction.Category = data['category']

        if 'description' in data:
            transaction.Description = data['description']

        if 'transactionDate' in data:
            try:
                transaction.TransactionDate = datetime.strptime(data['transactionDate'], '%Y-%m-%d').date()
            except ValueError:
                return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400

        if 'transactionType' in data:
            if data['transactionType'] not in ['income', 'expense']:
                return jsonify({'error': 'transactionType must be "income" or "expense"'}), 400
            transaction.TransactionType = data['transactionType']

        db.session.commit()

        return jsonify({
            'message': 'Transaction updated successfully',
            'transaction': transaction.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to update transaction: {str(e)}'}), 500

@transactions_bp.route('/<int:transaction_id>', methods=['DELETE'])
def delete_transaction(transaction_id):
    """Delete a transaction"""
    try:
        transaction = Transaction.query.get(transaction_id)
        if not transaction:
            return jsonify({'error': 'Transaction not found'}), 404

        db.session.delete(transaction)
        db.session.commit()

        return jsonify({'message': 'Transaction deleted successfully'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to delete transaction: {str(e)}'}), 500

@transactions_bp.route('/user/<int:user_id>/summary', methods=['GET'])
def get_transaction_summary(user_id):
    """Get transaction summary for a user"""
    try:
        # Get date range from query params
        start_date = request.args.get('startDate')
        end_date = request.args.get('endDate')

        # Build query
        query = Transaction.query.filter_by(UserId=user_id)

        if start_date:
            query = query.filter(Transaction.TransactionDate >= start_date)
        if end_date:
            query = query.filter(Transaction.TransactionDate <= end_date)

        transactions = query.all()

        # Calculate summary
        total_income = sum(float(t.Amount) for t in transactions if t.TransactionType == 'income')
        total_expense = sum(float(t.Amount) for t in transactions if t.TransactionType == 'expense')
        balance = total_income - total_expense

        # Category breakdown
        expense_by_category = {}
        for t in transactions:
            if t.TransactionType == 'expense':
                expense_by_category[t.Category] = expense_by_category.get(t.Category, 0) + float(t.Amount)

        return jsonify({
            'totalIncome': total_income,
            'totalExpense': total_expense,
            'balance': balance,
            'transactionCount': len(transactions),
            'expenseByCategory': expense_by_category
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to generate summary: {str(e)}'}), 500
