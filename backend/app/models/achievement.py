from app import db
from datetime import datetime

class Achievement(db.Model):
    __tablename__ = 'Achievements'

    AchievementId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    Name = db.Column(db.String(255), nullable=False)
    Description = db.Column(db.Text)
    BadgeIcon = db.Column(db.String(255))
    XpReward = db.Column(db.Integer, default=0)
    UnlockCriteria = db.Column(db.Text)
    DifficultyLevel = db.Column(db.Enum('easy', 'medium', 'hard', 'expert'), default='easy')

    def to_dict(self):
        """Convert achievement object to dictionary"""
        return {
            'achievementId': self.AchievementId,
            'name': self.Name,
            'description': self.Description,
            'badgeIcon': self.BadgeIcon,
            'xpReward': self.XpReward,
            'unlockCriteria': self.UnlockCriteria,
            'difficultyLevel': self.DifficultyLevel
        }


class UserAchievement(db.Model):
    __tablename__ = 'UserAchievements'

    UserAchievementId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    IsUnlocked = db.Column(db.Boolean, default=False)
    Progress = db.Column(db.Integer, default=0)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False)
    AchievementId = db.Column(db.Integer, db.ForeignKey('Achievements.AchievementId'), nullable=False)
    UnlockedAt = db.Column(db.DateTime)

    # Relationships
    achievement = db.relationship('Achievement', backref='user_achievements')

    def to_dict(self):
        """Convert user achievement object to dictionary"""
        return {
            'userAchievementId': self.UserAchievementId,
            'isUnlocked': self.IsUnlocked,
            'progress': self.Progress,
            'userId': self.UserId,
            'achievementId': self.AchievementId,
            'unlockedAt': self.UnlockedAt.isoformat() if self.UnlockedAt else None,
            'achievement': self.achievement.to_dict() if self.achievement else None
        }


class HabitStreak(db.Model):
    __tablename__ = 'HabitStreaks'

    StreakId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    CurrentStreak = db.Column(db.Integer, default=0)
    LongestStreak = db.Column(db.Integer, default=0)
    LastActivity = db.Column(db.Date)
    StreakType = db.Column(db.String(50), nullable=False)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False)

    def to_dict(self):
        """Convert habit streak object to dictionary"""
        return {
            'streakId': self.StreakId,
            'currentStreak': self.CurrentStreak,
            'longestStreak': self.LongestStreak,
            'lastActivity': self.LastActivity.isoformat() if self.LastActivity else None,
            'streakType': self.StreakType,
            'userId': self.UserId
        }
