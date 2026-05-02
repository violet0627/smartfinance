# ==============================================================================
# gamification.py - Gamification Routes (API Endpoints for XP, Achievements, Streaks)
# ==============================================================================
# This file defines ALL the gamification-related API endpoints.
# Gamification adds game-like elements to motivate users to manage their finances.
#
# Features:
# - ACHIEVEMENTS: Badges users earn for milestones (e.g., "First Transaction", "Budget Master")
# - XP (Experience Points): Earned by unlocking achievements, used to determine level
# - LEVELS: Based on total XP (Level 1 = 0 XP, Level 2 = 100 XP, etc.)
# - STREAKS: Consecutive days of tracking finances
# - LEADERBOARD: Ranking of users by total XP
#
# URL prefix: /api/gamification (set in app/__init__.py)
# ==============================================================================

from flask import Blueprint, request, jsonify          # Blueprint for grouping, request for input, jsonify for output
from app import db                                      # Database instance
from app.models.achievement import Achievement, UserAchievement, HabitStreak  # Gamification models
from app.models.transaction import Transaction          # Transaction model (to check milestones)
from app.models.budget import Budget                    # Budget model (to check milestones)
from app.models.investment import Investment            # Investment model (to check milestones)
from datetime import datetime, date, timedelta          # For date operations
from sqlalchemy import func                             # SQL aggregate functions (SUM, COUNT)
import logging                                          # Standard Python logging — writes errors to console/file

# logger for this module — each route file has its own logger named after the file
logger = logging.getLogger(__name__)

# --- Create the Blueprint ---
gamification_bp = Blueprint('gamification', __name__)


# ==============================================================================
# HELPER FUNCTION: calculate_level
# ==============================================================================
# Calculates the user's level based on their total XP.
# Uses exponential growth - each level requires more XP than the last.
#
# Level progression:
# - Level 1: 0 XP needed
# - Level 2: 100 XP needed (increment = 100)
# - Level 3: 250 XP needed (increment = 150, which is 100 * 1.5)
# - Level 4: 475 XP needed (increment = 225, which is 150 * 1.5)
# - Level 5: 812 XP needed (increment = 337, which is 225 * 1.5)
# - ...and so on (each increment is 1.5x the previous one)
#
# Args:
#     total_xp (int): The user's total XP earned from achievements.
#
# Returns:
#     tuple: (level, xp_needed_for_next_level)
# ==============================================================================
def calculate_level(total_xp):
    """Calculate user level based on total XP"""
    level = 1               # Everyone starts at level 1
    xp_needed = 0           # Running total of XP needed to reach each level
    increment = 100          # First increment is 100 XP

    # Keep incrementing level as long as the user has enough XP
    while total_xp >= xp_needed:
        xp_needed += increment                 # Add the increment to reach the next level
        level += 1                              # Move to next level
        increment = int(increment * 1.5)        # Next level requires 1.5x more XP

    # We overshot by 1 level in the loop, so subtract 1.
    # Return xp_needed (the total XP threshold for the next level).
    # Returning xp_needed - increment was wrong: it produced a negative value
    # for users with 0 XP (e.g., 100 - 150 = -50), causing "0 / -50 XP" in the UI.
    return level - 1, xp_needed


# ==============================================================================
# ROUTE: GET /api/gamification/achievements
# ==============================================================================
# Returns ALL available achievements in the system.
# This is a master list of what achievements exist (not user-specific).
# ==============================================================================
@gamification_bp.route('/achievements', methods=['GET'])
def get_all_achievements():
    """Get all available achievements"""
    try:
        achievements = Achievement.query.all()       # Get every achievement from the database
        return jsonify({
            'achievements': [achievement.to_dict() for achievement in achievements],
            'count': len(achievements)
        }), 200
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch achievements'}), 500


# ==============================================================================
# ROUTE: GET /api/gamification/user/<user_id>/achievements
# ==============================================================================
# Returns the user's progress on all achievements.
# Combines the master achievement list with the user's individual progress.
# Achievements the user hasn't started yet get default values (progress=0, locked).
# ==============================================================================
@gamification_bp.route('/user/<int:user_id>/achievements', methods=['GET'])
def get_user_achievements(user_id):
    """Get user's achievement progress"""
    try:
        # --- Step 1: Get all achievements (master list) ---
        all_achievements = Achievement.query.all()

        # --- Step 2: Get the user's progress on achievements ---
        # Create a dictionary for quick lookup: {AchievementId: UserAchievement}
        user_achievements_dict = {}
        user_achievements = UserAchievement.query.filter_by(UserId=user_id).all()

        for ua in user_achievements:
            user_achievements_dict[ua.AchievementId] = ua

        # --- Step 3: Combine master list with user's progress ---
        result = []
        for achievement in all_achievements:
            user_ach = user_achievements_dict.get(achievement.AchievementId)

            if user_ach:
                # User has progress on this achievement
                result.append(user_ach.to_dict())
            else:
                # User hasn't started this achievement - show default (locked) state
                result.append({
                    'userAchievementId': None,
                    'isUnlocked': False,
                    'progress': 0,
                    'userId': user_id,
                    'achievementId': achievement.AchievementId,
                    'unlockedAt': None,
                    'achievement': achievement.to_dict()
                })

        return jsonify({
            'userAchievements': result,
            'count': len(result)
        }), 200
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch user achievements'}), 500


# ==============================================================================
# ROUTE: GET /api/gamification/user/<user_id>/stats
# ==============================================================================
# Returns the user's gamification statistics:
# - Total XP, current level, XP progress toward next level
# - Number of achievements unlocked vs total
# - Longest streak and current streaks
# Used by the gamification dashboard screen.
# ==============================================================================
@gamification_bp.route('/user/<int:user_id>/stats', methods=['GET'])
def get_user_stats(user_id):
    """Get user gamification stats (XP, level, achievements)"""
    try:
        # --- Step 1: Calculate total XP from unlocked achievements ---
        unlocked_achievements = UserAchievement.query.filter_by(
            UserId=user_id,
            IsUnlocked=True       # Only count unlocked (earned) achievements
        ).all()

        total_xp = 0
        unlocked_count = 0

        for ua in unlocked_achievements:
            if ua.achievement:                          # Make sure the achievement relationship exists
                total_xp += ua.achievement.XpReward or 0   # Add XP reward (or 0 if None)
                unlocked_count += 1

        # --- Step 2: Calculate level from total XP ---
        level, xp_for_next_level = calculate_level(total_xp)

        # Calculate XP progress within the current level
        # We need to figure out how much XP was needed to reach the current level
        xp_for_current_level = 0
        temp_level = 1
        increment = 100

        while temp_level < level:
            xp_for_current_level += increment
            temp_level += 1
            increment = int(increment * 1.5)

        xp_progress_in_level = total_xp - xp_for_current_level         # How much XP into current level
        xp_needed_for_next = xp_for_next_level - xp_for_current_level  # XP needed to level up

        # --- Step 3: Get total achievements count ---
        total_achievements = Achievement.query.count()    # Total achievements available

        # --- Step 4: Get streak data ---
        streaks = HabitStreak.query.filter_by(UserId=user_id).all()
        longest_streak = max([s.LongestStreak for s in streaks], default=0)  # Longest ever streak
        current_streaks = {s.StreakType: s.CurrentStreak for s in streaks}    # Current streaks by type

        # --- Step 5: Return all stats ---
        return jsonify({
            'totalXp': total_xp,                               # Total XP earned
            'level': level,                                     # Current level
            'xpForNextLevel': xp_needed_for_next,              # XP needed to reach next level
            'xpProgressInLevel': xp_progress_in_level,          # XP progress within current level
            'achievementsUnlocked': unlocked_count,             # Achievements earned
            'totalAchievements': total_achievements,            # Total achievements available
            'longestStreak': longest_streak,                    # Longest streak ever
            'currentStreaks': current_streaks                   # Current active streaks
        }), 200
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch user stats'}), 500


# ==============================================================================
# ROUTE: POST /api/gamification/user/<user_id>/check-achievements
# ==============================================================================
# This is the MAIN achievement checking endpoint.
# Called after the user performs an action (e.g., adds a transaction).
# It checks all achievements and unlocks any that the user has earned.
#
# Achievement criteria checked:
# - Transaction count (1, 100)
# - Budget count (1)
# - Investment count (1)
# - Daily tracking streak (7 days, 30 days)
# - Budget adherence (staying within budget)
# ==============================================================================
@gamification_bp.route('/user/<int:user_id>/check-achievements', methods=['POST'])
def check_and_unlock_achievements(user_id):
    """Check user progress and unlock eligible achievements"""
    try:
        newly_unlocked = []   # Track achievements unlocked in this check

        # --- Step 1: Get user's current achievement progress ---
        # Create a lookup dict: {AchievementId: UserAchievement}
        user_achievements = {ua.AchievementId: ua for ua in
                           UserAchievement.query.filter_by(UserId=user_id).all()}

        # --- Step 2: Get all available achievements ---
        all_achievements = Achievement.query.all()

        # --- Step 3: Count user's data for criteria checking ---
        transaction_count = Transaction.query.filter_by(UserId=user_id).count()  # Total transactions
        budget_count = Budget.query.filter_by(UserId=user_id).count()            # Total budgets
        investment_count = Investment.query.filter_by(UserId=user_id).count()     # Total investments

        # --- Step 4: Get streak data ---
        daily_streak = HabitStreak.query.filter_by(
            UserId=user_id,
            StreakType='daily_tracking'
        ).first()

        current_daily_streak = daily_streak.CurrentStreak if daily_streak else 0

        # --- Step 5: Check budget adherence ---
        current_budget = Budget.query.filter_by(UserId=user_id).order_by(Budget.CreatedAt.desc()).first()
        within_budget = False
        if current_budget:
            total_spent = sum(cat.SpentAmount for cat in current_budget.categories)
            within_budget = total_spent <= current_budget.TotalBudget   # True if under budget

        # --- Step 6: Check each achievement ---
        for achievement in all_achievements:
            # Skip if already unlocked
            if achievement.AchievementId in user_achievements:
                if user_achievements[achievement.AchievementId].IsUnlocked:
                    continue   # Already earned, skip to next achievement
                user_ach = user_achievements[achievement.AchievementId]
            else:
                # Create a new UserAchievement entry (user hasn't seen this achievement before)
                user_ach = UserAchievement(
                    UserId=user_id,
                    AchievementId=achievement.AchievementId,
                    IsUnlocked=False,
                    Progress=0
                )
                db.session.add(user_ach)

            # --- Check if achievement criteria are met ---
            should_unlock = False
            progress = 0

            # Check different achievement types by name/criteria
            if 'First Step' in achievement.Name or '1 transaction' in achievement.UnlockCriteria:
                progress = min(transaction_count, 1)          # Progress: 0 or 1
                should_unlock = transaction_count >= 1         # Unlock if at least 1 transaction

            elif 'Budget Beginner' in achievement.Name or '1 budget' in achievement.UnlockCriteria:
                progress = min(budget_count, 1)
                should_unlock = budget_count >= 1

            elif 'Investment Initiate' in achievement.Name or '1 investment' in achievement.UnlockCriteria:
                progress = min(investment_count, 1)
                should_unlock = investment_count >= 1

            elif '7-day' in achievement.UnlockCriteria or '7 consecutive' in achievement.UnlockCriteria:
                progress = min(current_daily_streak, 7)       # Progress out of 7
                should_unlock = current_daily_streak >= 7

            elif '30-day' in achievement.UnlockCriteria or '30 consecutive' in achievement.UnlockCriteria:
                progress = min(current_daily_streak, 30)      # Progress out of 30
                should_unlock = current_daily_streak >= 30

            elif 'Budget Master' in achievement.Name:
                progress = 1 if within_budget else 0
                should_unlock = within_budget

            elif '100 transactions' in achievement.UnlockCriteria:
                progress = min(transaction_count, 100)        # Progress out of 100
                should_unlock = transaction_count >= 100

            # Update progress
            user_ach.Progress = progress

            # --- Unlock achievement if criteria met ---
            if should_unlock and not user_ach.IsUnlocked:
                user_ach.IsUnlocked = True
                user_ach.UnlockedAt = datetime.utcnow()
                newly_unlocked.append({
                    'achievement': achievement.to_dict(),
                    'xpEarned': achievement.XpReward
                })

        # --- Step 7: Save all changes ---
        db.session.commit()

        return jsonify({
            'newlyUnlocked': newly_unlocked,       # List of achievements just earned
            'count': len(newly_unlocked)            # How many new achievements
        }), 200
    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to check achievements'}), 500


# ==============================================================================
# ROUTE: GET /api/gamification/user/<user_id>/streaks
# ==============================================================================
# Returns all habit streaks for a user.
# A streak tracks consecutive days of performing an action.
# ==============================================================================
@gamification_bp.route('/user/<int:user_id>/streaks', methods=['GET'])
def get_user_streaks(user_id):
    """Get user's habit streaks"""
    try:
        streaks = HabitStreak.query.filter_by(UserId=user_id).all()
        return jsonify({
            'streaks': [streak.to_dict() for streak in streaks],
            'count': len(streaks)
        }), 200
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch streaks'}), 500


# ==============================================================================
# ROUTE: POST /api/gamification/user/<user_id>/streaks/update
# ==============================================================================
# Called when the user adds a transaction (indicating they're tracking finances).
# Updates the daily tracking streak:
# - If last activity was yesterday: streak continues (+1)
# - If last activity was today: no change (already tracked today)
# - If last activity was 2+ days ago: streak broken (reset to 1)
# - If first ever activity: start streak at 1
# ==============================================================================
@gamification_bp.route('/user/<int:user_id>/streaks/update', methods=['POST'])
def update_streak(user_id):
    """Update user's streak (called when transaction is added)"""
    try:
        data = request.get_json() or {}   # default to empty dict if body is missing
        streak_type = data.get('streakType', 'daily_tracking')  # Default to daily tracking

        # --- Step 1: Get or create the streak record ---
        streak = HabitStreak.query.filter_by(
            UserId=user_id,
            StreakType=streak_type
        ).first()

        if not streak:
            # First time - create a new streak record
            streak = HabitStreak(
                UserId=user_id,
                StreakType=streak_type,
                CurrentStreak=0,
                LongestStreak=0
            )
            db.session.add(streak)

        today = date.today()

        # --- Step 2: Check if the streak continues ---
        if streak.LastActivity:
            days_since_last = (today - streak.LastActivity).days   # How many days since last activity

            if days_since_last == 0:
                # Already tracked today - no change needed
                pass
            elif days_since_last == 1:
                # Last activity was yesterday - streak continues!
                streak.CurrentStreak += 1
                streak.LastActivity = today

                # Update longest streak if current is now the record
                if streak.CurrentStreak > streak.LongestStreak:
                    streak.LongestStreak = streak.CurrentStreak
            else:
                # Streak broken (2+ days gap) - reset to 1
                streak.CurrentStreak = 1
                streak.LastActivity = today
        else:
            # First ever activity - start the streak
            streak.CurrentStreak = 1
            streak.LastActivity = today
            streak.LongestStreak = 1

        # --- Step 3: Save changes ---
        db.session.commit()

        return jsonify({
            'message': 'Streak updated successfully',
            'streak': streak.to_dict()
        }), 200
    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to update streak'}), 500


# ==============================================================================
# ROUTE: GET /api/gamification/leaderboard
# ==============================================================================
# Returns the global leaderboard showing top 10 users ranked by total XP.
# Uses a SQL JOIN to combine UserAchievement and Achievement tables,
# then groups by user and sums up XP rewards.
# ==============================================================================
@gamification_bp.route('/leaderboard', methods=['GET'])
def get_leaderboard():
    """Get global leaderboard (top users by XP)"""
    try:
        # --- Build a complex SQL query to get top 10 users by XP ---
        # db.session.query() creates a custom query (not using a model directly)
        # This query:
        # 1. JOINs UserAchievement with Achievement (to get XP rewards)
        # 2. FILTERs for only unlocked achievements
        # 3. GROUPs by UserId (combines all achievements per user)
        # 4. SUMs up the XP rewards
        # 5. ORDERs by total XP (highest first)
        # 6. LIMITs to top 10
        user_xp = db.session.query(
            UserAchievement.UserId,                              # Select the user's ID
            func.sum(Achievement.XpReward).label('total_xp')    # Sum their XP rewards
        ).join(
            Achievement,                                          # JOIN with Achievement table
            UserAchievement.AchievementId == Achievement.AchievementId  # ON this condition
        ).filter(
            UserAchievement.IsUnlocked == True                   # Only count unlocked achievements
        ).group_by(
            UserAchievement.UserId                               # Group results by user
        ).order_by(
            func.sum(Achievement.XpReward).desc()                # Highest XP first
        ).limit(10).all()                                        # Top 10 only

        # --- Build the leaderboard response ---
        leaderboard = []
        for rank, (user_id, total_xp) in enumerate(user_xp, 1):  # enumerate starts counting from 1
            level, _ = calculate_level(int(total_xp) if total_xp else 0)
            leaderboard.append({
                'rank': rank,                                    # Position on leaderboard (1, 2, 3...)
                'userId': user_id,                               # The user's ID
                'totalXp': int(total_xp) if total_xp else 0,   # Their total XP
                'level': level                                   # Their level
            })

        return jsonify({
            'leaderboard': leaderboard,
            'count': len(leaderboard)
        }), 200
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch leaderboard'}), 500
