from app import db
from datetime import datetime

class UserSettings(db.Model):
    __tablename__ = 'UserSettings'

    SettingId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False, unique=True)

    # Notification Preferences
    EnableNotifications = db.Column(db.Boolean, default=True)
    EnableBudgetAlerts = db.Column(db.Boolean, default=True)
    EnableAchievementAlerts = db.Column(db.Boolean, default=True)
    EnableStreakAlerts = db.Column(db.Boolean, default=True)
    QuietHoursStart = db.Column(db.Time, nullable=True)
    QuietHoursEnd = db.Column(db.Time, nullable=True)

    # Display Preferences
    Currency = db.Column(db.String(10), default='RM')
    ThemeMode = db.Column(db.Enum('light', 'dark', 'system'), default='system')
    Language = db.Column(db.String(10), default='en')

    # Alert Thresholds
    BudgetWarningThreshold = db.Column(db.Integer, default=80)
    BudgetDangerThreshold = db.Column(db.Integer, default=90)
    BudgetCriticalThreshold = db.Column(db.Integer, default=100)

    # Privacy Settings
    ShowInLeaderboard = db.Column(db.Boolean, default=True)

    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)
    UpdatedAt = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        """Convert user settings to dictionary"""
        return {
            'settingId': self.SettingId,
            'userId': self.UserId,
            'enableNotifications': self.EnableNotifications,
            'enableBudgetAlerts': self.EnableBudgetAlerts,
            'enableAchievementAlerts': self.EnableAchievementAlerts,
            'enableStreakAlerts': self.EnableStreakAlerts,
            'quietHoursStart': self.QuietHoursStart.strftime('%H:%M') if self.QuietHoursStart else None,
            'quietHoursEnd': self.QuietHoursEnd.strftime('%H:%M') if self.QuietHoursEnd else None,
            'currency': self.Currency,
            'themeMode': self.ThemeMode,
            'language': self.Language,
            'budgetWarningThreshold': self.BudgetWarningThreshold,
            'budgetDangerThreshold': self.BudgetDangerThreshold,
            'budgetCriticalThreshold': self.BudgetCriticalThreshold,
            'showInLeaderboard': self.ShowInLeaderboard,
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,
            'updatedAt': self.UpdatedAt.isoformat() if self.UpdatedAt else None
        }
