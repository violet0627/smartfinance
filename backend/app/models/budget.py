# ==============================================================================
# budget.py - Budget and BudgetCategory Models (Database Table Definitions)
# ==============================================================================
# This file defines TWO tables:
# 1. 'Budgets' - A user's monthly budget plan (e.g., "January 2025 - RM2000 total")
# 2. 'BudgetCategories' - Individual category limits within a budget
#    (e.g., "Food: RM500", "Transport: RM300")
#
# Relationship: One Budget has MANY BudgetCategories (one-to-many).
# Example:
#   Budget: "Jan 2025 - RM2000"
#     ├── BudgetCategory: "Food - RM500 allocated, RM320 spent"
#     ├── BudgetCategory: "Transport - RM300 allocated, RM150 spent"
#     └── BudgetCategory: "Entertainment - RM200 allocated, RM50 spent"
# ==============================================================================

from app import db              # Import the SQLAlchemy database instance
from datetime import datetime   # For timestamps


class Budget(db.Model):
    """
    Budget Model - Represents a user's budget plan for a specific month/period.

    Maps to the 'Budgets' table in MySQL.
    Each row = one budget plan (e.g., "January 2025 budget of RM2000").
    """

    __tablename__ = 'Budgets'  # The exact table name in MySQL

    # --- Column Definitions ---
    BudgetId = db.Column(db.Integer, primary_key=True, autoincrement=True)     # Unique ID (auto-generated)
    MonthYear = db.Column(db.String(7), nullable=False)                         # Month and year (e.g., "2025-01" for January 2025)
                                                                                 # Format: "YYYY-MM" (7 characters)
    BudgetPeriod = db.Column(db.String(50), nullable=False)                     # Budget period type (e.g., "monthly", "weekly")
    TotalBudget = db.Column(db.Numeric(10, 2), nullable=False)                  # Total budget amount (e.g., 2000.00)
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)                 # When this budget was created
    UpdatedAt = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)  # Last update time
                                                                                             # onupdate=datetime.utcnow auto-updates this
                                                                                             # whenever the record is modified
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False)  # Which user owns this budget

    # --- Relationships ---
    # One budget has many categories.
    # cascade='all, delete-orphan' means: if the budget is deleted, all its categories are also deleted.
    categories = db.relationship('BudgetCategory', backref='budget', lazy=True, cascade='all, delete-orphan')

    def to_dict(self):
        """
        Convert Budget object to a dictionary for JSON API responses.

        The 'categories' field includes all budget categories as a list of dictionaries.
        This is done using a list comprehension: [cat.to_dict() for cat in self.categories]
        which calls to_dict() on each BudgetCategory object.
        """
        return {
            'budgetId': self.BudgetId,                                                    # Budget's unique ID
            'monthYear': self.MonthYear,                                                  # Month-year string (e.g., "2025-01")
            'budgetPeriod': self.BudgetPeriod,                                            # Period type (e.g., "monthly")
            'totalBudget': float(self.TotalBudget),                                       # Total amount as float
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,          # Creation timestamp
            'updatedAt': self.UpdatedAt.isoformat() if self.UpdatedAt else None,          # Last update timestamp
            'userId': self.UserId,                                                        # Owner's user ID
            'categories': [cat.to_dict() for cat in self.categories]                      # List of category breakdowns
        }


class BudgetCategory(db.Model):
    """
    BudgetCategory Model - Represents one spending category within a budget.

    Maps to the 'BudgetCategories' table in MySQL.
    Each row = one category limit (e.g., "Food: RM500 allocated, RM320 spent").

    This is a CHILD table of Budgets (linked via BudgetId foreign key).
    """

    __tablename__ = 'BudgetCategories'  # The exact table name in MySQL

    # --- Column Definitions ---
    BudgetCategoryId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique ID (auto-generated)
    CategoryName = db.Column(db.String(100), nullable=False)                         # Name of the category (e.g., "Food", "Transport")
    AllocatedAmount = db.Column(db.Numeric(10, 2), nullable=False)                   # How much was budgeted (e.g., 500.00)
    SpentAmount = db.Column(db.Numeric(10, 2), default=0.00)                         # How much has been spent so far (starts at 0)
    BudgetId = db.Column(db.Integer, db.ForeignKey('Budgets.BudgetId'), nullable=False)  # Which budget this category belongs to

    def to_dict(self):
        """Convert BudgetCategory to dictionary for JSON responses."""
        return {
            'budgetCategoryId': self.BudgetCategoryId,          # Category's unique ID
            'categoryName': self.CategoryName,                  # Category name (e.g., "Food")
            'allocatedAmount': float(self.AllocatedAmount),     # Budgeted amount as float
            'spentAmount': float(self.SpentAmount),             # Amount spent as float
            'budgetId': self.BudgetId                           # Parent budget's ID
        }
