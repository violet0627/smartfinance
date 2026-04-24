# ==============================================================================
# recurring_transaction.py - Recurring Transaction Model (Database Table Definition)
# ==============================================================================
# This file defines the 'recurringtransactions' table in the MySQL database.
# A recurring transaction is one that repeats automatically on a schedule.
#
# Examples:
# - Monthly salary: RM3000 income, every month
# - Netflix subscription: RM45 expense, every month
# - Daily lunch: RM15 expense, every day
# - Annual insurance: RM1200 expense, every year
#
# The system automatically creates regular transactions when the scheduled
# date arrives, so users don't have to manually log them every time.
# ==============================================================================

from app import db                        # Import the SQLAlchemy database instance
from datetime import datetime, timedelta  # For timestamps and date calculations


class RecurringTransaction(db.Model):
    """
    Recurring Transaction Model - Represents an automated, repeating transaction.

    Maps to the 'recurringtransactions' table in MySQL.
    Each row = one recurring transaction template (e.g., "Monthly Netflix RM45").

    When the NextExecution date arrives, the system should create a regular
    Transaction based on this template, then calculate the next execution date.
    """

    __tablename__ = 'recurringtransactions'  # The exact table name in MySQL (lowercase)

    # --- Column Definitions ---
    RecurringId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique ID
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
        # Which user created this recurring transaction.
    Name = db.Column(db.String(255), nullable=False)                # Name/label (e.g., "Netflix", "Salary", "Rent")
    TransactionType = db.Column(db.String(20), nullable=False)     # "income" or "expense"
    Category = db.Column(db.String(50), nullable=False)            # Category (e.g., "Entertainment", "Salary")
    Amount = db.Column(db.Numeric(15, 2), nullable=False)          # Amount per occurrence (e.g., 45.00)
    Description = db.Column(db.Text)                               # Optional description
    Frequency = db.Column(db.String(20), nullable=False)           # How often: "daily", "weekly", "monthly", or "yearly"
    StartDate = db.Column(db.Date, nullable=False)                 # When the recurring schedule starts
    EndDate = db.Column(db.Date)                                   # Optional end date (None = runs forever)
    LastExecuted = db.Column(db.Date)                              # Date when a transaction was last auto-created
    NextExecution = db.Column(db.Date, nullable=False)             # When the next transaction should be created
    IsActive = db.Column(db.Boolean, default=True)                 # Is this recurring transaction still active?
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)    # Record creation time
    UpdatedAt = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)  # Last modification time

    def calculate_next_execution(self):
        """
        Calculate when the next transaction should be automatically created.

        Uses the last execution date (or start date if never executed) as the
        base, then adds the appropriate time interval based on frequency.

        Returns:
            date: The next date when a transaction should be created.
        """
        # Use LastExecuted if available, otherwise use StartDate (for first-time execution)
        base_date = self.LastExecuted or self.StartDate

        if self.Frequency == 'daily':
            # Add 1 day to the base date
            return base_date + timedelta(days=1)

        elif self.Frequency == 'weekly':
            # Add 7 days (1 week) to the base date
            return base_date + timedelta(weeks=1)

        elif self.Frequency == 'monthly':
            # Add 1 month to the base date.
            # timedelta doesn't have a "months" option, so we calculate manually.
            month = base_date.month   # Current month (1-12)
            year = base_date.year     # Current year

            if month == 12:
                # If December, next month is January of next year
                month = 1
                year += 1
            else:
                # Otherwise, just add 1 to the month
                month += 1

            # Replace the month and year in the base date, keeping the same day
            return base_date.replace(year=year, month=month)

        elif self.Frequency == 'yearly':
            # Add 1 year to the base date
            return base_date.replace(year=base_date.year + 1)

        else:
            # Unknown frequency - return the base date unchanged (shouldn't happen)
            return base_date

    def should_execute(self):
        """
        Check if this recurring transaction should be executed now.

        A transaction should execute if ALL of these are true:
        1. IsActive is True (not paused or stopped)
        2. Today's date is >= NextExecution date (the scheduled time has come)
        3. Today's date is <= EndDate (if an end date is set)

        Returns:
            bool: True if the transaction should be created now.
        """
        # If the recurring transaction is paused/stopped, don't execute
        if not self.IsActive:
            return False

        today = datetime.now().date()  # Get today's date (without time)

        # If today is before the next scheduled execution, it's not time yet
        if today < self.NextExecution:
            return False

        # If there's an end date and we've passed it, don't execute
        if self.EndDate and today > self.EndDate:
            return False

        # All checks passed - this transaction should be created
        return True

    def to_dict(self):
        """Convert RecurringTransaction to dictionary for JSON API responses."""
        return {
            'recurringId': self.RecurringId,                                                  # Unique ID
            'userId': self.UserId,                                                            # Owner's user ID
            'name': self.Name,                                                                # Transaction name
            'transactionType': self.TransactionType,                                          # "income" or "expense"
            'category': self.Category,                                                        # Category name
            'amount': float(self.Amount),                                                     # Amount as float
            'description': self.Description,                                                  # Optional description
            'frequency': self.Frequency,                                                      # "daily", "weekly", "monthly", "yearly"
            'startDate': self.StartDate.isoformat() if self.StartDate else None,              # Schedule start date
            'endDate': self.EndDate.isoformat() if self.EndDate else None,                    # Optional end date
            'lastExecuted': self.LastExecuted.isoformat() if self.LastExecuted else None,     # Last execution date
            'nextExecution': self.NextExecution.isoformat() if self.NextExecution else None,  # Next scheduled date
            'isActive': self.IsActive,                                                        # Is it active?
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,              # Creation timestamp
            'updatedAt': self.UpdatedAt.isoformat() if self.UpdatedAt else None               # Last update timestamp
        }

    def __repr__(self):
        """String representation for debugging."""
        return f'<RecurringTransaction {self.Name} - {self.Frequency}>'
