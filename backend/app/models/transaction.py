# ==============================================================================
# transaction.py - Transaction Model (Database Table Definition)
# ==============================================================================
# This file defines the 'Transactions' table in the MySQL database.
# A transaction represents money coming in (income) or going out (expense).
#
# Each transaction belongs to one user (linked via UserId foreign key).
# Examples: "Salary RM3000 income", "Lunch RM15 expense", "Freelance RM500 income"
# ==============================================================================

from app import db              # Import the SQLAlchemy database instance
from datetime import datetime   # For timestamps


class Transaction(db.Model):
    """
    Transaction Model - Represents a single financial transaction (income or expense).

    This maps to the 'Transactions' table in MySQL.
    Each row = one transaction (e.g., "Bought lunch for RM15").
    """

    __tablename__ = 'Transactions'  # The exact table name in MySQL

    # --- Column Definitions ---
    TransactionId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique ID (auto-generated)
    Amount = db.Column(db.Numeric(10, 2), nullable=False)                        # Money amount (e.g., 15.50)
                                                                                  # Numeric(10,2) = up to 10 digits, 2 decimal places
    Category = db.Column(db.String(100), nullable=False)                          # Category (e.g., "Food", "Transport", "Salary")
    Description = db.Column(db.Text)                                              # Optional description (e.g., "Lunch at mamak")
    TransactionDate = db.Column(db.Date, nullable=False)                          # When the transaction happened
    TransactionType = db.Column(db.Enum('income', 'expense'), nullable=False)     # Either 'income' or 'expense'
                                                                                  # Enum restricts values to only these two options
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)                   # When this record was created in the database
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False)  # Which user this transaction belongs to
                                                                                   # ForeignKey links to the Users table's UserId column

    def to_dict(self):
        """
        Convert the Transaction object to a dictionary for JSON API responses.

        float(self.Amount) converts Decimal to float because JSON doesn't support Decimal type.
        .isoformat() converts date/datetime to string format "2025-01-15" or "2025-01-15T10:30:00".
        """
        return {
            'transactionId': self.TransactionId,                                                    # Transaction's unique ID
            'amount': float(self.Amount),                                                           # Amount as a float (e.g., 15.50)
            'category': self.Category,                                                              # Category name (e.g., "Food")
            'description': self.Description,                                                        # Optional description
            'transactionDate': self.TransactionDate.isoformat() if self.TransactionDate else None,  # Date string (e.g., "2025-01-15")
            'transactionType': self.TransactionType,                                                # "income" or "expense"
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,                    # Record creation timestamp
            'userId': self.UserId                                                                   # ID of the user who owns this
        }
