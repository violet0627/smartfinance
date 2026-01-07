from flask import Blueprint, request, jsonify
from app import db
from app.models.achievement import Achievement, UserAchievement, HabitStreak
from app.models.transaction import Transaction
from app.models.budget import Budget
from app.models.investment import Investment
from datetime import datetime, date, timedelta
from sqlalchemy import func

gamification_bp = Blueprint('gamification', __name__)

# XP to Level mapping (exponential growth)
def calculate_level(total_xp):
    """Calculate user level based on total XP"""
    # Level 1: 0 XP, Level 2: 100 XP, Level 3: 250 XP, Level 4: 500 XP, etc.
    level = 1
    xp_needed = 0
    increment = 100

    while total_xp >= xp_needed:
        xp_needed += increment
        level += 1
        increment = int(increment * 1.5)  # Exponential growth

    return level - 1, xp_needed - increment


@gamification_bp.route('/achievements', methods=['GET'])
def get_all_achievements():
    """Get all available achievements"""
    try:
        achievements = Achievement.query.all()
        return jsonify({
            'achievements': [achievement.to_dict() for achievement in achievements],
            'count': len(achievements)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@gamification_bp.route('/user/<int:user_id>/achievements', methods=['GET'])
def get_user_achievements(user_id):
    """Get user's achievement progress"""
    try:
        # Get all achievements
        all_achievements = Achievement.query.all()

        # Get user's achievement progress
        user_achievements_dict = {}
        user_achievements = UserAchievement.query.filter_by(UserId=user_id).all()

        for ua in user_achievements:
            user_achievements_dict[ua.AchievementId] = ua

        # Combine data
        result = []
        for achievement in all_achievements:
            user_ach = user_achievements_dict.get(achievement.AchievementId)

            if user_ach:
                result.append(user_ach.to_dict())
            else:
                # Create default progress entry
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
        return jsonify({'error': str(e)}), 500


@gamification_bp.route('/user/<int:user_id>/stats', methods=['GET'])
def get_user_stats(user_id):
    """Get user gamification stats (XP, level, achievements)"""
    try:
        # Calculate total XP from unlocked achievements
        unlocked_achievements = UserAchievement.query.filter_by(
            UserId=user_id,
            IsUnlocked=True
        ).all()

        total_xp = 0
        unlocked_count = 0

        for ua in unlocked_achievements:
            if ua.achievement:
                total_xp += ua.achievement.XpReward or 0
                unlocked_count += 1

        # Calculate level
        level, xp_for_next_level = calculate_level(total_xp)
        xp_for_current_level = 0
        temp_level = 1
        increment = 100

        while temp_level < level:
            xp_for_current_level += increment
            temp_level += 1
            increment = int(increment * 1.5)

        xp_progress_in_level = total_xp - xp_for_current_level
        xp_needed_for_next = xp_for_next_level - xp_for_current_level

        # Get total achievements count
        total_achievements = Achievement.query.count()

        # Get longest streak
        streaks = HabitStreak.query.filter_by(UserId=user_id).all()
        longest_streak = max([s.LongestStreak for s in streaks], default=0)
        current_streaks = {s.StreakType: s.CurrentStreak for s in streaks}

        return jsonify({
            'totalXp': total_xp,
            'level': level,
            'xpForNextLevel': xp_needed_for_next,
            'xpProgressInLevel': xp_progress_in_level,
            'achievementsUnlocked': unlocked_count,
            'totalAchievements': total_achievements,
            'longestStreak': longest_streak,
            'currentStreaks': current_streaks
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@gamification_bp.route('/user/<int:user_id>/check-achievements', methods=['POST'])
def check_and_unlock_achievements(user_id):
    """Check user progress and unlock eligible achievements"""
    try:
        newly_unlocked = []

        # Get user's current achievement progress
        user_achievements = {ua.AchievementId: ua for ua in
                           UserAchievement.query.filter_by(UserId=user_id).all()}

        # Get all achievements
        all_achievements = Achievement.query.all()

        # Count user data for criteria checking
        transaction_count = Transaction.query.filter_by(UserId=user_id).count()
        budget_count = Budget.query.filter_by(UserId=user_id).count()
        investment_count = Investment.query.filter_by(UserId=user_id).count()

        # Get streaks
        daily_streak = HabitStreak.query.filter_by(
            UserId=user_id,
            StreakType='daily_tracking'
        ).first()

        current_daily_streak = daily_streak.CurrentStreak if daily_streak else 0

        # Check budget adherence
        current_budget = Budget.query.filter_by(UserId=user_id).order_by(Budget.CreatedAt.desc()).first()
        within_budget = False
        if current_budget:
            total_spent = sum(cat.SpentAmount for cat in current_budget.categories)
            within_budget = total_spent <= current_budget.TotalBudget

        # Calculate savings rate (simplified - need income/expense data)
        # This would need transaction type filtering

        # Check each achievement
        for achievement in all_achievements:
            # Skip if already unlocked
            if achievement.AchievementId in user_achievements:
                if user_achievements[achievement.AchievementId].IsUnlocked:
                    continue
                user_ach = user_achievements[achievement.AchievementId]
            else:
                # Create new user achievement entry
                user_ach = UserAchievement(
                    UserId=user_id,
                    AchievementId=achievement.AchievementId,
                    IsUnlocked=False,
                    Progress=0
                )
                db.session.add(user_ach)

            # Check unlock criteria
            should_unlock = False
            progress = 0

            if 'First Step' in achievement.Name or '1 transaction' in achievement.UnlockCriteria:
                progress = min(transaction_count, 1)
                should_unlock = transaction_count >= 1
            elif 'Budget Beginner' in achievement.Name or '1 budget' in achievement.UnlockCriteria:
                progress = min(budget_count, 1)
                should_unlock = budget_count >= 1
            elif 'Investment Initiate' in achievement.Name or '1 investment' in achievement.UnlockCriteria:
                progress = min(investment_count, 1)
                should_unlock = investment_count >= 1
            elif '7-day' in achievement.UnlockCriteria or '7 consecutive' in achievement.UnlockCriteria:
                progress = min(current_daily_streak, 7)
                should_unlock = current_daily_streak >= 7
            elif '30-day' in achievement.UnlockCriteria or '30 consecutive' in achievement.UnlockCriteria:
                progress = min(current_daily_streak, 30)
                should_unlock = current_daily_streak >= 30
            elif 'Budget Master' in achievement.Name:
                progress = 1 if within_budget else 0
                should_unlock = within_budget
            elif '100 transactions' in achievement.UnlockCriteria:
                progress = min(transaction_count, 100)
                should_unlock = transaction_count >= 100

            user_ach.Progress = progress

            if should_unlock and not user_ach.IsUnlocked:
                user_ach.IsUnlocked = True
                user_ach.UnlockedAt = datetime.utcnow()
                newly_unlocked.append({
                    'achievement': achievement.to_dict(),
                    'xpEarned': achievement.XpReward
                })

        db.session.commit()

        return jsonify({
            'newlyUnlocked': newly_unlocked,
            'count': len(newly_unlocked)
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


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
        return jsonify({'error': str(e)}), 500


@gamification_bp.route('/user/<int:user_id>/streaks/update', methods=['POST'])
def update_streak(user_id):
    """Update user's streak (called when transaction is added)"""
    try:
        data = request.get_json()
        streak_type = data.get('streakType', 'daily_tracking')

        # Get or create streak
        streak = HabitStreak.query.filter_by(
            UserId=user_id,
            StreakType=streak_type
        ).first()

        if not streak:
            streak = HabitStreak(
                UserId=user_id,
                StreakType=streak_type,
                CurrentStreak=0,
                LongestStreak=0
            )
            db.session.add(streak)

        today = date.today()

        # Check if streak continues
        if streak.LastActivity:
            days_since_last = (today - streak.LastActivity).days

            if days_since_last == 0:
                # Already tracked today, no change
                pass
            elif days_since_last == 1:
                # Streak continues!
                streak.CurrentStreak += 1
                streak.LastActivity = today

                if streak.CurrentStreak > streak.LongestStreak:
                    streak.LongestStreak = streak.CurrentStreak
            else:
                # Streak broken
                streak.CurrentStreak = 1
                streak.LastActivity = today
        else:
            # First activity
            streak.CurrentStreak = 1
            streak.LastActivity = today
            streak.LongestStreak = 1

        db.session.commit()

        return jsonify({
            'message': 'Streak updated successfully',
            'streak': streak.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@gamification_bp.route('/leaderboard', methods=['GET'])
def get_leaderboard():
    """Get global leaderboard (top users by XP)"""
    try:
        # Get top 10 users by total XP
        user_xp = db.session.query(
            UserAchievement.UserId,
            func.sum(Achievement.XpReward).label('total_xp')
        ).join(
            Achievement,
            UserAchievement.AchievementId == Achievement.AchievementId
        ).filter(
            UserAchievement.IsUnlocked == True
        ).group_by(
            UserAchievement.UserId
        ).order_by(
            func.sum(Achievement.XpReward).desc()
        ).limit(10).all()

        leaderboard = []
        for rank, (user_id, total_xp) in enumerate(user_xp, 1):
            level, _ = calculate_level(int(total_xp) if total_xp else 0)
            leaderboard.append({
                'rank': rank,
                'userId': user_id,
                'totalXp': int(total_xp) if total_xp else 0,
                'level': level
            })

        return jsonify({
            'leaderboard': leaderboard,
            'count': len(leaderboard)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
