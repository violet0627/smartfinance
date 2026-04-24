# ==============================================================================
# achievement.py - Achievement, UserAchievement, and HabitStreak Models
# ==============================================================================
# This file defines THREE tables for the gamification system:
#
# 1. 'Achievements' - Master list of all possible achievements
#    (e.g., "First Transaction", "Budget Master", "Saving Streak")
#
# 2. 'UserAchievements' - Tracks which achievements each user has unlocked
#    (links Users to Achievements with progress and unlock status)
#
# 3. 'HabitStreaks' - Tracks user activity streaks
#    (e.g., "5-day login streak", "10-day transaction logging streak")
#
# Together, these create the app's gamification system that motivates users
# to keep using the app through XP, badges, and streaks.
# ==============================================================================

from app import db              # Import the SQLAlchemy database instance
from datetime import datetime   # For timestamps


class Achievement(db.Model):
    """
    Achievement Model - Defines a possible achievement/badge users can earn.

    Maps to the 'Achievements' table in MySQL.
    This is the MASTER LIST of achievements (same for all users).
    Each row = one achievement definition (e.g., "First Transaction - 50 XP").

    Think of this as a catalog: it defines WHAT achievements exist,
    not WHO has earned them (that's in UserAchievements).
    """

    __tablename__ = 'Achievements'  # The exact table name in MySQL

    # --- Column Definitions ---
    AchievementId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique ID (auto-generated)
    Name = db.Column(db.String(255), nullable=False)                              # Achievement name (e.g., "First Transaction")
    Description = db.Column(db.Text)                                              # What the achievement is about
    BadgeIcon = db.Column(db.String(255))                                         # Icon name/path for the badge display
    XpReward = db.Column(db.Integer, default=0)                                   # XP points awarded when unlocked (e.g., 50)
    UnlockCriteria = db.Column(db.Text)                                           # Description of how to unlock (e.g., "Add 1 transaction")
    DifficultyLevel = db.Column(db.Enum('easy', 'medium', 'hard', 'expert'), default='easy')  # How hard it is to earn

    def to_dict(self):
        """Convert Achievement to dictionary for JSON API responses."""
        return {
            'achievementId': self.AchievementId,        # Achievement's unique ID
            'name': self.Name,                          # Achievement name
            'description': self.Description,            # Description text
            'badgeIcon': self.BadgeIcon,                # Icon identifier
            'xpReward': self.XpReward,                  # XP reward amount
            'unlockCriteria': self.UnlockCriteria,      # How to unlock
            'difficultyLevel': self.DifficultyLevel     # Difficulty level
        }


class UserAchievement(db.Model):
    """
    UserAchievement Model - Tracks a specific user's progress toward an achievement.

    Maps to the 'UserAchievements' table in MySQL.
    This is a JUNCTION TABLE (also called "bridge" or "linking" table) that
    connects Users to Achievements in a many-to-many relationship:
    - One user can have many achievements
    - One achievement can be earned by many users

    Each row = one user's progress on one achievement.
    Example: "User 1 has unlocked 'First Transaction'" or "User 2 is 50% done with 'Budget Master'"
    """

    __tablename__ = 'UserAchievements'  # The exact table name in MySQL

    # --- Column Definitions ---
    UserAchievementId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique ID
    IsUnlocked = db.Column(db.Boolean, default=False)                                 # Has the user earned this? (True/False)
    Progress = db.Column(db.Integer, default=0)                                       # Progress percentage (0-100)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False)      # Which user
    AchievementId = db.Column(db.Integer, db.ForeignKey('Achievements.AchievementId'), nullable=False)  # Which achievement
    UnlockedAt = db.Column(db.DateTime)                                               # When it was unlocked (None if not yet)

    # --- Relationships ---
    # This creates a link so we can access the full Achievement details from a UserAchievement.
    # user_achievement.achievement -> returns the Achievement object
    # achievement.user_achievements -> returns all UserAchievement records for that achievement
    achievement = db.relationship('Achievement', backref='user_achievements')

    def to_dict(self):
        """
        Convert to dictionary for JSON API responses.

        Includes the full achievement details (name, description, etc.)
        nested inside, so the Flutter app gets all the info in one response.
        """
        return {
            'userAchievementId': self.UserAchievementId,                                      # Record's unique ID
            'isUnlocked': self.IsUnlocked,                                                    # True if earned
            'progress': self.Progress,                                                        # Progress (0-100)
            'userId': self.UserId,                                                            # User's ID
            'achievementId': self.AchievementId,                                              # Achievement's ID
            'unlockedAt': self.UnlockedAt.isoformat() if self.UnlockedAt else None,           # When unlocked
            'achievement': self.achievement.to_dict() if self.achievement else None            # Full achievement details (nested)
        }


class HabitStreak(db.Model):
    """
    HabitStreak Model - Tracks consecutive days a user performs an activity.

    Maps to the 'HabitStreaks' table in MySQL.
    Each row = one streak tracker for one user for one activity type.

    Example: User 1's "daily_login" streak:
    - CurrentStreak: 5 (logged in 5 days in a row)
    - LongestStreak: 12 (best streak ever was 12 days)
    - LastActivity: 2025-01-15 (last time they logged in)
    """

    __tablename__ = 'HabitStreaks'  # The exact table name in MySQL

    # --- Column Definitions ---
    StreakId = db.Column(db.Integer, primary_key=True, autoincrement=True)       # Unique ID
    CurrentStreak = db.Column(db.Integer, default=0)                             # Current consecutive days (resets if a day is missed)
    LongestStreak = db.Column(db.Integer, default=0)                             # Best streak ever (never resets)
    LastActivity = db.Column(db.Date)                                            # Date of last activity (used to check if streak continues)
    StreakType = db.Column(db.String(50), nullable=False)                        # Type of streak (e.g., "daily_login", "transaction_logging")
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False)  # Which user this streak belongs to

    def to_dict(self):
        """Convert HabitStreak to dictionary for JSON API responses."""
        return {
            'streakId': self.StreakId,                                                    # Streak's unique ID
            'currentStreak': self.CurrentStreak,                                         # Current streak count
            'longestStreak': self.LongestStreak,                                         # Best streak ever
            'lastActivity': self.LastActivity.isoformat() if self.LastActivity else None, # Last activity date
            'streakType': self.StreakType,                                                # Type of streak
            'userId': self.UserId                                                        # Owner's user ID
        }
