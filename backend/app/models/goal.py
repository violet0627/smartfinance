# ==============================================================================
# goal.py - Financial Goal Model (Database Table Definition)
# ==============================================================================
# This file defines the 'Goals' table in the MySQL database.
# A goal represents a savings target the user is working towards.
#
# Examples:
# - "Emergency Fund" - Target: RM10,000, Current: RM3,500
# - "Vacation to Japan" - Target: RM5,000, Deadline: Dec 2025
# - "Down Payment for House" - Target: RM50,000, Priority: High
# ==============================================================================

from app import db              # Import the SQLAlchemy database instance
from datetime import datetime   # For timestamps and date calculations


class Goal(db.Model):
    """
    Financial Goal Model - Tracks user savings goals.

    Maps to the 'Goals' table in MySQL.
    Each row = one savings goal with target amount, current progress, and deadline.
    """

    __tablename__ = 'Goals'  # The exact table name in MySQL

    # --- Column Definitions ---
    GoalId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique ID (auto-generated)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
        # Which user owns this goal
        # ondelete='CASCADE' means: if the user is deleted from the Users table,
        # all their goals are automatically deleted too (at the DATABASE level,
        # not just Python level)

    GoalName = db.Column(db.String(100), nullable=False)                         # Name of the goal (e.g., "Emergency Fund")
    Description = db.Column(db.Text, nullable=True)                              # Optional description of the goal
    TargetAmount = db.Column(db.Numeric(15, 2), nullable=False)                  # How much money to save (e.g., 10000.00)
    CurrentAmount = db.Column(db.Numeric(15, 2), default=0.00)                   # How much saved so far (starts at 0)
    StartDate = db.Column(db.Date, nullable=False, default=datetime.utcnow)      # When the user started saving
    Deadline = db.Column(db.Date, nullable=False)                                # Target date to reach the goal
    Status = db.Column(db.Enum('active', 'completed', 'abandoned'), default='active')  # Current status of the goal
        # 'active' = still working on it
        # 'completed' = reached the target amount
        # 'abandoned' = user gave up on this goal
    Category = db.Column(db.String(50), nullable=True)    # Goal category (e.g., 'Emergency Fund', 'Vacation', 'Home', 'Education')
    Priority = db.Column(db.Enum('low', 'medium', 'high'), default='medium')  # How important this goal is
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)               # When the record was created
    UpdatedAt = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)  # Last modification time

    # --- Relationships ---
    # This creates a two-way link between Goal and User.
    # - goal.user -> returns the User object who owns this goal
    # - user.goals -> returns all Goal objects belonging to that user
    # db.backref() creates the reverse relationship automatically.
    user = db.relationship('User', backref=db.backref('goals', lazy=True, cascade='all, delete-orphan'))

    def to_dict(self):
        """
        Convert Goal to dictionary for JSON API responses.

        This method also calculates some COMPUTED fields that aren't stored in the database:
        - progressPercentage: how close to the target (0-100%)
        - remainingAmount: how much more to save
        - daysRemaining: days until the deadline
        - isOverdue: whether the deadline has passed
        """

        # Calculate days remaining until deadline.
        # self.Deadline is a date object, datetime.now().date() is today's date.
        # Subtracting two dates gives a timedelta object; .days gives the number of days.
        # Positive = days left, Negative = overdue
        days_remaining = (self.Deadline - datetime.now().date()).days if self.Deadline else 0

        # Calculate progress as a percentage (0 to 100).
        # Formula: (current / target) * 100
        # min(..., 100) caps it at 100% (in case current exceeds target).
        # The 'if' guard prevents division by zero when target is 0.
        progress_percentage = min((float(self.CurrentAmount) / float(self.TargetAmount) * 100), 100) if self.TargetAmount > 0 else 0

        return {
            'goalId': self.GoalId,                                                        # Goal's unique ID
            'userId': self.UserId,                                                        # Owner's user ID
            'goalName': self.GoalName,                                                    # Goal name
            'description': self.Description,                                              # Optional description
            'targetAmount': float(self.TargetAmount),                                     # Target amount as float
            'currentAmount': float(self.CurrentAmount),                                   # Current savings as float
            'startDate': self.StartDate.isoformat() if self.StartDate else None,          # Start date string
            'deadline': self.Deadline.isoformat() if self.Deadline else None,              # Deadline string
            'status': self.Status,                                                        # "active", "completed", or "abandoned"
            'category': self.Category,                                                    # Goal category
            'priority': self.Priority,                                                    # "low", "medium", or "high"
            'progressPercentage': round(progress_percentage, 2),                          # Progress % (rounded to 2 decimals)
            'remainingAmount': float(self.TargetAmount - self.CurrentAmount),              # How much left to save
            'daysRemaining': days_remaining,                                              # Days until deadline
            'isOverdue': days_remaining < 0 if self.Status == 'active' else False,        # True if past deadline and still active
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,          # Creation timestamp
            'updatedAt': self.UpdatedAt.isoformat() if self.UpdatedAt else None           # Last update timestamp
        }

    def __repr__(self):
        """
        String representation for debugging.
        When you print a Goal object, it shows: <Goal Emergency Fund - active>
        This is helpful when debugging in the Python console.
        """
        return f'<Goal {self.GoalName} - {self.Status}>'
