# ==============================================================================
# user_settings.py - User Settings Model (Database Table Definition)
# ==============================================================================
# This file defines the 'UserSettings' table in the MySQL database.
# It stores each user's personal preferences for the app.
#
# Each user has exactly ONE settings record (one-to-one relationship).
# If a user hasn't configured settings yet, default values are used.
#
# Settings categories:
# - Notifications: What alerts to receive, quiet hours
# - Display: Currency, theme (light/dark), language
# - Budget alerts: When to warn about overspending
# - Privacy: Leaderboard visibility
# ==============================================================================

from app import db              # Import the SQLAlchemy database instance
from datetime import datetime   # For timestamps


class UserSettings(db.Model):
    """
    UserSettings Model - Stores a user's app preferences.

    Maps to the 'UserSettings' table in MySQL.
    Each row = one user's settings (one-to-one with Users table).
    """

    __tablename__ = 'UserSettings'  # The exact table name in MySQL

    # --- Column Definitions ---
    SettingId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique ID
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False, unique=True)
        # Which user these settings belong to.
        # unique=True ensures each user can only have ONE settings record.

    # --- Notification Preferences ---
    EnableNotifications = db.Column(db.Boolean, default=True)           # Master switch: enable/disable all notifications
    EnableBudgetAlerts = db.Column(db.Boolean, default=True)            # Get alerts when budget is near limit
    EnableAchievementAlerts = db.Column(db.Boolean, default=True)       # Get alerts when earning achievements
    EnableStreakAlerts = db.Column(db.Boolean, default=True)            # Get alerts about streaks
    QuietHoursStart = db.Column(db.Time, nullable=True)                 # Don't send notifications after this time (e.g., 22:00)
    QuietHoursEnd = db.Column(db.Time, nullable=True)                   # Resume notifications after this time (e.g., 08:00)

    # --- Budget Alert Thresholds ---
    # Note: Currency is always RM (Malaysian Ringgit — app is Malaysia-only).
    # Theme is always Light mode. Language is always English. These are not stored
    # in the database because they are fixed for this app's target market.
    # These define at what percentage of budget usage to show warnings.
    # For example, if budget is RM1000:
    # - At RM800 spent (80%) -> yellow "warning" alert
    # - At RM900 spent (90%) -> orange "danger" alert
    # - At RM1000 spent (100%) -> red "critical" alert
    BudgetWarningThreshold = db.Column(db.Integer, default=80)          # Yellow warning at this % (default: 80%)
    BudgetDangerThreshold = db.Column(db.Integer, default=90)           # Orange danger at this % (default: 90%)
    BudgetCriticalThreshold = db.Column(db.Integer, default=100)        # Red critical at this % (default: 100%)

    # --- Privacy Settings ---
    ShowInLeaderboard = db.Column(db.Boolean, default=True)             # Whether to show user on the gamification leaderboard

    # --- Timestamps ---
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)         # When settings were first created
    UpdatedAt = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)  # Last modification time

    def to_dict(self):
        """
        Convert UserSettings to dictionary for JSON API responses.

        The .strftime('%H:%M') converts time objects to strings like "22:00".
        This is needed because JSON doesn't have a native time type.
        """
        return {
            'settingId': self.SettingId,                                                     # Settings record ID
            'userId': self.UserId,                                                           # Owner's user ID
            'enableNotifications': self.EnableNotifications,                                  # Notifications on/off
            'enableBudgetAlerts': self.EnableBudgetAlerts,                                    # Budget alerts on/off
            'enableAchievementAlerts': self.EnableAchievementAlerts,                          # Achievement alerts on/off
            'enableStreakAlerts': self.EnableStreakAlerts,                                     # Streak alerts on/off
            'quietHoursStart': self.QuietHoursStart.strftime('%H:%M') if self.QuietHoursStart else None,  # Quiet start time
            'quietHoursEnd': self.QuietHoursEnd.strftime('%H:%M') if self.QuietHoursEnd else None,        # Quiet end time
            'budgetWarningThreshold': self.BudgetWarningThreshold,                           # Warning % threshold
            'budgetDangerThreshold': self.BudgetDangerThreshold,                             # Danger % threshold
            'budgetCriticalThreshold': self.BudgetCriticalThreshold,                         # Critical % threshold
            'showInLeaderboard': self.ShowInLeaderboard,                                     # Leaderboard visibility
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,             # Creation timestamp
            'updatedAt': self.UpdatedAt.isoformat() if self.UpdatedAt else None              # Last update timestamp
        }
