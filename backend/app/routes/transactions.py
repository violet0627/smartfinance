# ==============================================================================
# transactions.py - Transaction Routes (API Endpoints for Income & Expenses)
# ==============================================================================
# This file defines ALL the transaction-related API endpoints.
# Transactions are the core of SmartFinance - every income and expense is a transaction.
#
# CRUD Operations:
# - CREATE: Add a new transaction (POST /)
# - READ:   Get transactions for a user (GET /user/<id>), get one (GET /<id>)
# - UPDATE: Edit a transaction (PUT /<id>)
# - DELETE: Remove a transaction (DELETE /<id>)
# - SUMMARY: Get totals and category breakdown (GET /user/<id>/summary)
#
# URL prefix: /api/transactions (set in app/__init__.py)
# ==============================================================================

from flask import Blueprint, request, jsonify      # Blueprint for grouping routes, request for incoming data, jsonify for JSON responses
from app import db                                  # Database instance
from app.models.transaction import Transaction      # Transaction model (database table)
from datetime import datetime, date                 # For parsing and working with dates

# --- Create the Blueprint ---
# All routes in this file are grouped under 'transactions'.
# Full URL example: /api/transactions/user/1
transactions_bp = Blueprint('transactions', __name__)


# ==============================================================================
# ROUTE: POST /api/transactions/
# ==============================================================================
# Called when the user adds a new income or expense in the Flutter app.
# The app sends the transaction details (amount, category, date, type) as JSON.
# ==============================================================================
@transactions_bp.route('/', methods=['POST'])
def create_transaction():
    """Create a new transaction"""
    try:
        # --- Step 1: Get the JSON data from the request body ---
        # Example data from Flutter:
        # {"amount": 45.50, "category": "Food", "transactionDate": "2025-01-15",
        #  "transactionType": "expense", "userId": 1, "description": "Lunch at KFC"}
        data = request.get_json()

        # --- Step 2: Validate all required fields are present ---
        required_fields = ['amount', 'category', 'transactionDate', 'transactionType', 'userId']
        for field in required_fields:
            if field not in data or data[field] is None:   # Check key exists AND is not None
                return jsonify({'error': f'{field} is required'}), 400

        # --- Step 3: Validate transaction type ---
        # Only "income" or "expense" are allowed values
        if data['transactionType'] not in ['income', 'expense']:
            return jsonify({'error': 'transactionType must be "income" or "expense"'}), 400

        # --- Step 4: Validate and convert amount ---
        try:
            amount = float(data['amount'])          # Convert to float (handles strings like "45.50")
            if amount <= 0:
                return jsonify({'error': 'Amount must be greater than 0'}), 400
        except ValueError:
            return jsonify({'error': 'Invalid amount format'}), 400

        # --- Step 5: Parse the date string into a Python date object ---
        # datetime.strptime() converts a string to a datetime object using a format.
        # '%Y-%m-%d' means "YYYY-MM-DD" format (e.g., "2025-01-15")
        # .date() extracts just the date part (without time)
        try:
            transaction_date = datetime.strptime(data['transactionDate'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400

        # --- Step 6: Create the Transaction object ---
        new_transaction = Transaction(
            Amount=amount,
            Category=data['category'],                    # e.g., "Food", "Transport", "Salary"
            Description=data.get('description', ''),      # Optional description (default: empty string)
            TransactionDate=transaction_date,
            TransactionType=data['transactionType'],      # "income" or "expense"
            UserId=data['userId']                         # Which user owns this transaction
        )

        # --- Step 7: Save to database ---
        db.session.add(new_transaction)      # Stage for saving
        db.session.commit()                   # Actually save to MySQL

        # --- Step 8: Return success with the created transaction ---
        return jsonify({
            'message': 'Transaction created successfully',
            'transaction': new_transaction.to_dict()   # Convert to dictionary for JSON
        }), 201  # 201 = Created

    except Exception as e:
        db.session.rollback()   # Undo any partial database changes
        return jsonify({'error': f'Failed to create transaction: {str(e)}'}), 500


# ==============================================================================
# ROUTE: GET /api/transactions/user/<user_id>
# ==============================================================================
# Called to fetch all transactions for a specific user.
# Supports optional filtering by type, category, date range, and limit.
#
# Query parameters (optional, added to URL):
# - type: "income" or "expense"
# - category: "Food", "Transport", etc.
# - startDate: "2025-01-01" (filter from this date)
# - endDate: "2025-01-31" (filter up to this date)
# - limit: 10 (maximum number of results)
#
# Example: GET /api/transactions/user/1?type=expense&category=Food&limit=10
# ==============================================================================
@transactions_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_transactions(user_id):
    """Get all transactions for a user"""
    try:
        # --- Step 1: Read optional filter parameters from the URL ---
        # request.args.get() reads query parameters from the URL (after the ?)
        transaction_type = request.args.get('type')       # "income" or "expense" (or None)
        category = request.args.get('category')           # Category name (or None)
        start_date = request.args.get('startDate')        # Start date string (or None)
        end_date = request.args.get('endDate')            # End date string (or None)
        limit = request.args.get('limit', type=int)       # Max results as integer (or None)

        # --- Step 2: Build the database query ---
        # Start with all transactions for this user
        query = Transaction.query.filter_by(UserId=user_id)

        # Add filters only if they were provided
        if transaction_type:
            query = query.filter_by(TransactionType=transaction_type)  # Filter by income/expense

        if category:
            query = query.filter_by(Category=category)                 # Filter by category

        if start_date:
            query = query.filter(Transaction.TransactionDate >= start_date)  # From this date

        if end_date:
            query = query.filter(Transaction.TransactionDate <= end_date)    # Up to this date

        # --- Step 3: Sort and limit results ---
        # Order by date descending (newest first), then by creation time
        query = query.order_by(Transaction.TransactionDate.desc(), Transaction.CreatedAt.desc())

        if limit:
            query = query.limit(limit)   # Only return the first N results

        # --- Step 4: Execute the query ---
        transactions = query.all()       # .all() runs the query and returns a list of Transaction objects

        # --- Step 5: Return the results ---
        return jsonify({
            'transactions': [t.to_dict() for t in transactions],   # Convert each transaction to dict
            'count': len(transactions)                               # Total number of results
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to fetch transactions: {str(e)}'}), 500


# ==============================================================================
# ROUTE: GET /api/transactions/<transaction_id>
# ==============================================================================
# Called to fetch a single transaction by its ID.
# ==============================================================================
@transactions_bp.route('/<int:transaction_id>', methods=['GET'])
def get_transaction(transaction_id):
    """Get a specific transaction"""
    try:
        # Look up transaction by primary key
        transaction = Transaction.query.get(transaction_id)
        if not transaction:
            return jsonify({'error': 'Transaction not found'}), 404

        return jsonify({'transaction': transaction.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': f'Failed to fetch transaction: {str(e)}'}), 500


# ==============================================================================
# ROUTE: PUT /api/transactions/<transaction_id>
# ==============================================================================
# Called when the user edits an existing transaction.
# PUT method is used for updates (as opposed to POST for creation).
# Only the fields that are included in the request body will be updated.
# ==============================================================================
@transactions_bp.route('/<int:transaction_id>', methods=['PUT'])
def update_transaction(transaction_id):
    """Update a transaction"""
    try:
        # --- Step 1: Find the existing transaction ---
        transaction = Transaction.query.get(transaction_id)
        if not transaction:
            return jsonify({'error': 'Transaction not found'}), 404

        data = request.get_json()

        # --- Step 2: Update each field IF it was provided in the request ---
        # This allows partial updates (only change what's needed)
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

        # --- Step 3: Save changes ---
        db.session.commit()

        return jsonify({
            'message': 'Transaction updated successfully',
            'transaction': transaction.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to update transaction: {str(e)}'}), 500


# ==============================================================================
# ROUTE: DELETE /api/transactions/<transaction_id>
# ==============================================================================
# Called when the user deletes a transaction.
# This permanently removes the transaction from the database.
# ==============================================================================
@transactions_bp.route('/<int:transaction_id>', methods=['DELETE'])
def delete_transaction(transaction_id):
    """Delete a transaction"""
    try:
        transaction = Transaction.query.get(transaction_id)
        if not transaction:
            return jsonify({'error': 'Transaction not found'}), 404

        db.session.delete(transaction)   # Mark for deletion
        db.session.commit()               # Actually delete from database

        return jsonify({'message': 'Transaction deleted successfully'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to delete transaction: {str(e)}'}), 500


# ==============================================================================
# ROUTE: GET /api/transactions/user/<user_id>/summary
# ==============================================================================
# Called to get a financial summary for a user.
# Returns total income, total expenses, balance, and expense breakdown by category.
# Used by the dashboard screen in the Flutter app.
#
# Optional query parameters:
# - startDate: Filter from this date
# - endDate: Filter up to this date
# ==============================================================================
@transactions_bp.route('/user/<int:user_id>/summary', methods=['GET'])
def get_transaction_summary(user_id):
    """Get transaction summary for a user"""
    try:
        # --- Step 1: Get optional date range filters ---
        start_date = request.args.get('startDate')
        end_date = request.args.get('endDate')

        # --- Step 2: Build query with optional filters ---
        query = Transaction.query.filter_by(UserId=user_id)

        if start_date:
            query = query.filter(Transaction.TransactionDate >= start_date)
        if end_date:
            query = query.filter(Transaction.TransactionDate <= end_date)

        transactions = query.all()

        # --- Step 3: Calculate totals ---
        # sum() adds up all amounts for transactions of each type
        # float(t.Amount) converts Decimal to float for calculation
        total_income = sum(float(t.Amount) for t in transactions if t.TransactionType == 'income')
        total_expense = sum(float(t.Amount) for t in transactions if t.TransactionType == 'expense')
        balance = total_income - total_expense   # Net balance (positive = surplus, negative = deficit)

        # --- Step 4: Calculate expense breakdown by category ---
        # Creates a dictionary like: {"Food": 350.00, "Transport": 150.00, "Entertainment": 75.00}
        expense_by_category = {}
        for t in transactions:
            if t.TransactionType == 'expense':
                # .get(key, default) returns the current value or 0 if the key doesn't exist yet
                expense_by_category[t.Category] = expense_by_category.get(t.Category, 0) + float(t.Amount)

        # --- Step 5: Return the summary ---
        return jsonify({
            'totalIncome': total_income,
            'totalExpense': total_expense,
            'balance': balance,
            'transactionCount': len(transactions),
            'expenseByCategory': expense_by_category
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to generate summary: {str(e)}'}), 500
