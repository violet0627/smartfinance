# ==============================================================================
# recurring_transactions.py - Recurring Transaction Routes (API Endpoints)
# ==============================================================================
# This file defines API endpoints for managing recurring (repeating) transactions.
# Recurring transactions are templates that automatically create regular transactions
# on a schedule (daily, weekly, monthly, or yearly).
#
# Examples:
# - Monthly salary: RM3000 income, every month on the 1st
# - Netflix subscription: RM45 expense, every month on the 15th
# - Daily lunch allowance: RM15 expense, every day
# - Annual insurance premium: RM1200 expense, every year on March 1st
#
# URL prefix: /api/recurring (set in app/__init__.py)
# ==============================================================================

from flask import Blueprint, request, jsonify              # Blueprint for grouping, request for input, jsonify for output
from app import db                                          # Database instance
from app.models.recurring_transaction import RecurringTransaction  # RecurringTransaction model
from app.models.transaction import Transaction              # Transaction model (to create actual transactions)
from datetime import datetime                               # For date operations
import logging                                              # Standard Python logging

logger = logging.getLogger(__name__)

# --- Create the Blueprint ---
recurring_bp = Blueprint('recurring', __name__)


# ==================== CREATE ====================

# ==============================================================================
# ROUTE: POST /api/recurring/user/<user_id>
# ==============================================================================
# Called when the user sets up a new recurring transaction.
# Creates the template that will be used to auto-generate transactions.
# ==============================================================================
@recurring_bp.route('/user/<int:user_id>', methods=['POST'])
def create_recurring_transaction(user_id):
    """Create a new recurring transaction"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Request body is required'}), 400

        # --- Validate required fields before any parsing ---
        required_fields = ['name', 'transactionType', 'category', 'amount', 'frequency', 'startDate']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400

        # --- Validate transaction type ---
        if data['transactionType'] not in ['income', 'expense']:
            return jsonify({'error': 'transactionType must be "income" or "expense"'}), 400

        # --- Validate amount ---
        try:
            amount = float(data['amount'])
            if amount <= 0:
                return jsonify({'error': 'Amount must be greater than 0'}), 400
        except (ValueError, TypeError):
            return jsonify({'error': 'Invalid amount format'}), 400

        # --- Parse the start date ---
        try:
            start_date = datetime.strptime(data['startDate'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid startDate format. Use YYYY-MM-DD'}), 400

        next_execution = start_date   # First execution happens on the start date

        # --- Parse optional end date ---
        end_date = None
        if data.get('endDate'):
            try:
                end_date = datetime.strptime(data['endDate'], '%Y-%m-%d').date()
                if end_date <= start_date:
                    return jsonify({'error': 'endDate must be after startDate'}), 400
            except ValueError:
                return jsonify({'error': 'Invalid endDate format. Use YYYY-MM-DD'}), 400

        # --- Create the recurring transaction template ---
        recurring = RecurringTransaction(
            UserId=user_id,
            Name=data['name'],                               # e.g., "Netflix Subscription"
            TransactionType=data['transactionType'],         # "income" or "expense"
            Category=data['category'],                       # e.g., "Entertainment"
            Amount=amount,                                   # Amount per occurrence (e.g., 45.00)
            Description=data.get('description'),             # Optional description
            Frequency=data['frequency'],                     # "daily", "weekly", "monthly", or "yearly"
            StartDate=start_date,                            # When the schedule starts
            EndDate=end_date,                                # Optional end date - None means runs forever
            NextExecution=next_execution,                    # When the next transaction should be created
            IsActive=True                                    # Active by default
        )

        db.session.add(recurring)
        db.session.commit()

        return jsonify({
            'message': 'Recurring transaction created successfully',
            'recurring': recurring.to_dict()
        }), 201
    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to create recurring transaction'}), 500


# ==================== READ ====================

# ==============================================================================
# ROUTE: GET /api/recurring/user/<user_id>
# ==============================================================================
# Called to fetch all recurring transactions for a user.
# Supports optional filter to show only active recurring transactions.
# Example: GET /api/recurring/user/1?active=true
# ==============================================================================
@recurring_bp.route('/user/<int:user_id>', methods=['GET'])
def get_recurring_transactions(user_id):
    """Get all recurring transactions for a user"""
    try:
        # Check if we should only show active recurring transactions
        # request.args.get() reads the "active" query parameter from the URL
        active_only = request.args.get('active', 'false').lower() == 'true'

        query = RecurringTransaction.query.filter_by(UserId=user_id)

        if active_only:
            query = query.filter_by(IsActive=True)   # Only active ones

        # Sort by next execution date (soonest first)
        recurring = query.order_by(RecurringTransaction.NextExecution).all()

        return jsonify({
            'recurring': [r.to_dict() for r in recurring],
            'total': len(recurring)
        }), 200
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch recurring transactions'}), 500


# ==============================================================================
# ROUTE: GET /api/recurring/<recurring_id>
# ==============================================================================
# Called to fetch a single recurring transaction by its ID.
# ==============================================================================
@recurring_bp.route('/<int:recurring_id>', methods=['GET'])
def get_recurring_transaction(recurring_id):
    """Get a specific recurring transaction"""
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        return jsonify(recurring.to_dict()), 200
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch recurring transaction'}), 500


# ==================== UPDATE ====================

# ==============================================================================
# ROUTE: PUT /api/recurring/<recurring_id>
# ==============================================================================
# Called when the user edits an existing recurring transaction.
# Only the provided fields will be updated.
# ==============================================================================
@recurring_bp.route('/<int:recurring_id>', methods=['PUT'])
def update_recurring_transaction(recurring_id):
    """Update a recurring transaction"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Request body is required'}), 400
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        # --- Update each field if provided ---
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
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to update recurring transaction'}), 500


# ==================== DELETE ====================

# ==============================================================================
# ROUTE: DELETE /api/recurring/<recurring_id>
# ==============================================================================
# Called when the user deletes a recurring transaction.
# This removes the template - previously created transactions remain.
# ==============================================================================
@recurring_bp.route('/<int:recurring_id>', methods=['DELETE'])
def delete_recurring_transaction(recurring_id):
    """Delete a recurring transaction"""
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        # Also delete all transactions that were created by this recurring template
        # so they no longer appear in transaction history or on the dashboard
        Transaction.query.filter_by(UserId=recurring.UserId).filter(
            Transaction.Description == f"{recurring.Name} (Recurring)"
        ).delete(synchronize_session=False)

        db.session.delete(recurring)
        db.session.commit()

        return jsonify({'message': 'Recurring transaction deleted successfully'}), 200
    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to delete recurring transaction'}), 500


# ==================== EXECUTION ====================

# ==============================================================================
# ROUTE: POST /api/recurring/<recurring_id>/execute
# ==============================================================================
# Called to manually execute (trigger) a recurring transaction.
# This creates an actual Transaction record from the recurring template.
#
# Steps:
# 1. Create a regular transaction using the recurring template's data
# 2. Update LastExecuted date to today
# 3. Calculate the next execution date
# ==============================================================================
@recurring_bp.route('/<int:recurring_id>/execute', methods=['POST'])
def execute_recurring_transaction(recurring_id):
    """Manually execute a recurring transaction"""
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        # --- Step 1: Guard against duplicate execution today ---
        # Prevent the same recurring transaction from being manually executed more than once
        # on the same day (e.g., if the user presses "Execute Now" multiple times)
        today = datetime.now().date()
        already_executed_today = Transaction.query.filter_by(
            UserId=recurring.UserId,
            Description=f"{recurring.Name} (Recurring)",
            TransactionDate=today
        ).first()

        if already_executed_today:
            return jsonify({'error': 'Already executed today. Only one execution per day is allowed.'}), 409

        # --- Step 2: Create an actual transaction from the template ---
        transaction = Transaction(
            UserId=recurring.UserId,
            TransactionType=recurring.TransactionType,         # income or expense
            Category=recurring.Category,                       # Same category
            Amount=recurring.Amount,                           # Same amount
            Description=f"{recurring.Name} (Recurring)",       # Add "(Recurring)" to description
            TransactionDate=today                              # Transaction date = today
        )

        db.session.add(transaction)

        # --- Step 3: Update the recurring transaction ---
        recurring.LastExecuted = today                                      # Record when it was last executed
        recurring.NextExecution = recurring.calculate_next_execution()     # Calculate next date

        db.session.commit()

        return jsonify({
            'message': 'Recurring transaction executed successfully',
            'transaction': transaction.to_dict(),        # The newly created transaction
            'recurring': recurring.to_dict()              # Updated recurring template
        }), 201
    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to execute recurring transaction'}), 500


# ==============================================================================
# ROUTE: POST /api/recurring/user/<user_id>/execute-due
# ==============================================================================
# Called to execute ALL due recurring transactions for a user at once.
# This checks every active recurring transaction and creates actual transactions
# for any that are due (NextExecution <= today).
#
# This would typically be called:
# - When the user opens the app
# - By a scheduled job (cron) that runs daily
# ==============================================================================
@recurring_bp.route('/user/<int:user_id>/execute-due', methods=['POST'])
def execute_due_recurring_transactions(user_id):
    """Execute all due recurring transactions for a user"""
    try:
        # Get all active recurring transactions for this user
        recurring_list = RecurringTransaction.query.filter_by(
            UserId=user_id,
            IsActive=True
        ).all()

        executed = []       # Track which ones we executed
        today = datetime.now().date()

        # --- Check each recurring transaction ---
        for recurring in recurring_list:
            if recurring.should_execute():     # Check if it's due (see model's should_execute method)
                # Create the actual transaction
                transaction = Transaction(
                    UserId=recurring.UserId,
                    TransactionType=recurring.TransactionType,
                    Category=recurring.Category,
                    Amount=recurring.Amount,
                    Description=f"{recurring.Name} (Recurring)",
                    TransactionDate=today
                )

                db.session.add(transaction)

                # Update the recurring transaction
                recurring.LastExecuted = today
                recurring.NextExecution = recurring.calculate_next_execution()

                # Record what we executed
                executed.append({
                    'recurring': recurring.to_dict(),
                    'transaction': transaction.to_dict()
                })

        # Save all changes at once
        db.session.commit()

        return jsonify({
            'message': f'{len(executed)} recurring transactions executed',
            'executed': executed
        }), 200
    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to execute recurring transactions'}), 500


# ==================== TOGGLE ====================

# ==============================================================================
# ROUTE: POST /api/recurring/<recurring_id>/toggle
# ==============================================================================
# Called to pause/resume a recurring transaction.
# Toggles the IsActive flag: True -> False (pause) or False -> True (resume).
# ==============================================================================
@recurring_bp.route('/<int:recurring_id>/toggle', methods=['POST'])
def toggle_recurring_transaction(recurring_id):
    """Toggle active status of a recurring transaction"""
    try:
        recurring = RecurringTransaction.query.get(recurring_id)

        if not recurring:
            return jsonify({'error': 'Recurring transaction not found'}), 404

        # Toggle the active status (True becomes False, False becomes True)
        recurring.IsActive = not recurring.IsActive
        recurring.UpdatedAt = datetime.utcnow()

        # When resuming (IsActive just became True), if NextExecution date has
        # already passed while the transaction was paused, advance it to the next
        # period. This prevents the paused transaction from auto-executing
        # immediately on resume and creating a duplicate.
        if recurring.IsActive:
            today = datetime.now().date()
            if recurring.NextExecution <= today:
                recurring.LastExecuted = recurring.NextExecution  # Treat missed date as executed
                recurring.NextExecution = recurring.calculate_next_execution()

        db.session.commit()

        # Return appropriate message based on new status
        return jsonify({
            'message': f'Recurring transaction {"activated" if recurring.IsActive else "deactivated"}',
            'recurring': recurring.to_dict()
        }), 200
    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to toggle recurring transaction'}), 500
