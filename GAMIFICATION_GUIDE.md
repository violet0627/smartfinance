# Gamification System Guide

## Overview
The SmartFinance app includes a comprehensive **Gamification System** that transforms financial management into an engaging, rewarding experience. Users earn XP, unlock achievements, build streaks, and level up as they develop healthy financial habits.

---

## Features

### 1. Experience Points (XP) System
**Earn XP by**:
- Unlocking achievements (varies by achievement)
- Completing financial actions
- Maintaining streaks

**XP Benefits**:
- Accumulates over time
- Drives level progression
- Reflects overall engagement
- Visible on dashboard and achievements screen

### 2. Level System
**Exponential Progression**:
- Level 1: 0 XP
- Level 2: 100 XP
- Level 3: 250 XP (100 + 150)
- Level 4: 475 XP (100 + 150 + 225)
- Each level requires 1.5x more XP than previous increment

**Level Titles**:
- **Beginner** (Level 1-4): Blue badge
- **Intermediate** (Level 5-9): Orange badge
- **Advanced** (Level 10-14): Red badge
- **Expert** (Level 15-19): Deep Orange badge
- **Master** (Level 20+): Purple badge

**Visual Indicators**:
- Circular level badge with current level number
- Progress bar showing XP toward next level
- Level title and color-coded design
- Total XP display

### 3. Achievements System
**Achievement Categories**:
- **Easy**: Entry-level achievements (green badge)
- **Medium**: Moderate challenges (orange badge)
- **Hard**: Difficult goals (red badge)
- **Expert**: Elite accomplishments (purple badge)

**Achievement Types**:
1. **First Step** (Easy, 10 XP): Record your first transaction
2. **Budget Beginner** (Easy, 15 XP): Create your first budget
3. **Investment Initiate** (Easy, 20 XP): Make your first investment
4. **Week Warrior** (Medium, 50 XP): Maintain 7-day tracking streak
5. **Habit Hero** (Hard, 100 XP): Maintain 30-day tracking streak
6. **Budget Master** (Hard, 75 XP): Stay within budget for a month
7. **Expense Expert** (Expert, 150 XP): Record 100 transactions

**Achievement Display**:
- Badge icon (locked/unlocked)
- Achievement name and description
- XP reward
- Unlock criteria
- Progress bar (for incomplete achievements)
- Unlock date (for completed achievements)
- Difficulty level indicator

### 4. Habit Streaks
**Streak Types**:
- **Daily Tracking**: Track transactions daily
- Future: Budget adherence, investment monitoring, etc.

**Streak Mechanics**:
- **Continues**: Activity on consecutive days (+1 day)
- **Breaks**: Activity gap of 2+ days (resets to 1)
- **Maintains**: Multiple activities in same day (no change)

**Streak Tracking**:
- Current streak count
- Longest streak achieved
- Last activity date
- Active status (updated today or yesterday)

**Streak Milestones**:
- 7 days: Unlocks "Week Warrior" achievement
- 30 days: Unlocks "Habit Hero" achievement
- Notifications at key milestones

### 5. Leaderboard
**Features**:
- Top 10 users by total XP
- Rank, user ID, XP, and level displayed
- Competitive element
- Updated in real-time

**Use Cases**:
- Compare progress with others
- Motivate consistent engagement
- Celebrate top performers

### 6. Notifications
**Achievement Unlocks**:
- "🏆 Achievement Unlocked!"
- Shows achievement name and XP earned
- Triggered automatically after actions

**Level Ups**:
- "⭐ Level Up!"
- Congratulates reaching new level
- Triggered when XP threshold crossed

**Streak Milestones**:
- "🔥 Streak Milestone!"
- Celebrates streak achievements
- Triggered at 7, 30+ days

---

## User Experience Flow

### Viewing Progress on Dashboard

1. **Open Dashboard**
2. **Scroll to "Your Progress" Card**
3. **See**:
   - Current level badge
   - Level title (Beginner, Intermediate, etc.)
   - XP progress bar
   - XP toward next level
   - Total XP earned
   - Achievements unlocked count
   - Current and longest streaks

4. **Tap Card** → Navigate to Achievements Screen

### Exploring Achievements

1. **Navigate to Achievements Screen** (via Dashboard card or direct navigation)
2. **View Header Stats**:
   - X / Y Achievements Unlocked
   - Overall completion percentage
   - Visual progress bar

3. **Filter by Difficulty**:
   - Tap All/Easy/Medium/Hard/Expert chips
   - List updates instantly

4. **Review Individual Achievements**:
   - **Locked**: Gray badge with lock icon, progress bar showing completion %
   - **Unlocked**: Colored badge, unlock date, full XP awarded

5. **Pull to Refresh** to update progress

### Earning XP and Unlocking Achievements

1. **Perform Financial Actions**:
   - Add transaction → Triggers streak update + achievement check
   - Create budget → Checks "Budget Beginner" achievement
   - Add investment → Checks "Investment Initiate" achievement

2. **Automatic Processing**:
   - Streak updated (if transaction added)
   - Backend checks all achievement criteria
   - Unlocks eligible achievements
   - Calculates new total XP
   - Recalculates level if threshold crossed

3. **Receive Notifications**:
   - Achievement unlock notification(s)
   - Level up notification (if applicable)
   - Streak milestone notification (at 7, 30 days)

4. **View Updates**:
   - Refresh Dashboard to see new level/XP
   - Open Achievements to see newly unlocked badges

---

## Technical Implementation

### Backend (Python Flask)

#### Database Models

**Achievement** (`backend/app/models/achievement.py`):
```python
class Achievement(db.Model):
    AchievementId = db.Column(db.Integer, primary_key=True)
    Name = db.Column(db.String(255), nullable=False)
    Description = db.Column(db.Text)
    BadgeIcon = db.Column(db.String(255))
    XpReward = db.Column(db.Integer, default=0)
    UnlockCriteria = db.Column(db.Text)
    DifficultyLevel = db.Column(db.Enum('easy', 'medium', 'hard', 'expert'))
```

**UserAchievement** (`backend/app/models/achievement.py`):
```python
class UserAchievement(db.Model):
    UserAchievementId = db.Column(db.Integer, primary_key=True)
    IsUnlocked = db.Column(db.Boolean, default=False)
    Progress = db.Column(db.Integer, default=0)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'))
    AchievementId = db.Column(db.Integer, db.ForeignKey('Achievements.AchievementId'))
    UnlockedAt = db.Column(db.DateTime)
    achievement = db.relationship('Achievement')
```

**HabitStreak** (`backend/app/models/achievement.py`):
```python
class HabitStreak(db.Model):
    StreakId = db.Column(db.Integer, primary_key=True)
    CurrentStreak = db.Column(db.Integer, default=0)
    LongestStreak = db.Column(db.Integer, default=0)
    LastActivity = db.Column(db.Date)
    StreakType = db.Column(db.String(50), nullable=False)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'))
```

#### API Endpoints (`backend/app/routes/gamification.py`)

1. **GET `/api/gamification/achievements`**
   - Returns: All available achievements
   - Use: Display achievement catalog

2. **GET `/api/gamification/user/<user_id>/achievements`**
   - Returns: User's achievement progress
   - Includes: Unlocked and locked achievements with progress
   - Use: Achievements screen data

3. **GET `/api/gamification/user/<user_id>/stats`**
   - Returns: User's gamification stats
   - Includes: Total XP, level, XP progress, achievement count, streaks
   - Use: Dashboard display

4. **POST `/api/gamification/user/<user_id>/check-achievements`**
   - Checks: All achievement criteria
   - Unlocks: Eligible achievements
   - Returns: Newly unlocked achievements
   - Use: Called after transactions, budgets, investments

5. **GET `/api/gamification/user/<user_id>/streaks`**
   - Returns: All user streaks
   - Use: Streak tracking display

6. **POST `/api/gamification/user/<user_id>/streaks/update`**
   - Body: `{ "streakType": "daily_tracking" }`
   - Updates: Streak continuation or breaking
   - Returns: Updated streak data
   - Use: Called after transaction added

7. **GET `/api/gamification/leaderboard`**
   - Returns: Top 10 users by XP
   - Use: Leaderboard display

#### Level Calculation Algorithm

```python
def calculate_level(total_xp):
    level = 1
    xp_needed = 0
    increment = 100

    while total_xp >= xp_needed:
        xp_needed += increment
        level += 1
        increment = int(increment * 1.5)  # Exponential growth

    return level - 1, xp_needed - increment
```

**Example**:
- 0 XP → Level 1
- 100 XP → Level 2
- 250 XP → Level 3
- 475 XP → Level 4
- 787 XP → Level 5

#### Achievement Unlock Logic

```python
# Check criteria based on achievement type
if 'First Step' in achievement.Name:
    progress = min(transaction_count, 1)
    should_unlock = transaction_count >= 1
elif '7-day' in achievement.UnlockCriteria:
    progress = min(current_daily_streak, 7)
    should_unlock = current_daily_streak >= 7
# ... more criteria checks

if should_unlock and not user_ach.IsUnlocked:
    user_ach.IsUnlocked = True
    user_ach.UnlockedAt = datetime.utcnow()
    newly_unlocked.append({ achievement, xpEarned })
```

#### Streak Update Logic

```python
if streak.LastActivity:
    days_since_last = (today - streak.LastActivity).days

    if days_since_last == 0:
        pass  # Already tracked today
    elif days_since_last == 1:
        streak.CurrentStreak += 1  # Continue!
        if streak.CurrentStreak > streak.LongestStreak:
            streak.LongestStreak = streak.CurrentStreak
    else:
        streak.CurrentStreak = 1  # Broken
        streak.LastActivity = today
```

### Frontend (Flutter/Dart)

#### Models (`lib/models/gamification_model.dart`)

**Achievement**:
```dart
class Achievement {
  final int achievementId;
  final String name;
  final String description;
  final String badgeIcon;
  final int xpReward;
  final String unlockCriteria;
  final String difficultyLevel;
}
```

**UserAchievement**:
```dart
class UserAchievement {
  final bool isUnlocked;
  final int progress;
  final Achievement? achievement;

  double get progressPercentage {
    // Extracts target from unlock criteria
    // Returns completion percentage
  }
}
```

**UserStats**:
```dart
class UserStats {
  final int totalXp;
  final int level;
  final int xpForNextLevel;
  final int xpProgressInLevel;
  final int achievementsUnlocked;
  final int longestStreak;

  double get levelProgress => (xpProgressInLevel / xpForNextLevel * 100);
  int get currentDailyStreak => currentStreaks['daily_tracking'] ?? 0;
}
```

**HabitStreak**:
```dart
class HabitStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivity;

  bool get isActive => DateTime.now().difference(lastActivity!).inDays <= 1;
}
```

#### API Service (`lib/services/api_service.dart`)

```dart
static Future<Map<String, dynamic>> getUserAchievements(int userId);
static Future<Map<String, dynamic>> getUserStats(int userId);
static Future<Map<String, dynamic>> checkAchievements(int userId);
static Future<Map<String, dynamic>> updateStreak(int userId, {String streakType});
static Future<Map<String, dynamic>> getLeaderboard();
```

#### Achievements Screen (`lib/screens/gamification/achievements_screen.dart`)

**Features**:
- Header with unlock progress (X/Y achievements)
- Progress bar showing overall completion
- Difficulty filter chips (All, Easy, Medium, Hard, Expert)
- Achievement cards with:
  - Badge icon (color-coded by difficulty)
  - Lock icon (if not unlocked)
  - Name, description, XP reward
  - Progress bar (if incomplete)
  - Unlock date (if complete)
- Pull-to-refresh functionality

#### Level Progress Widget (`lib/widgets/level_progress_widget.dart`)

**Two Modes**:

1. **Compact** (for Dashboard):
   - Level badge
   - Level number and title
   - Progress bar
   - XP progress text
   - Total XP badge

2. **Full** (for dedicated screens):
   - Large level badge
   - Level number and title
   - Total XP display
   - XP to next level
   - Detailed progress bar
   - Stats cards (Achievements, Best Streak, Daily Streak)

#### Notification Service (`lib/services/notification_service.dart`)

**New Methods**:
```dart
static Future<void> showAchievementUnlocked({
  required String achievementName,
  required int xpEarned,
});

static Future<void> showLevelUp({
  required int newLevel,
});

static Future<void> showStreakMilestone({
  required int streakDays,
});

static Future<void> checkAndNotifyAchievements(List<NewAchievement> newlyUnlocked);
```

#### Integration in Transaction Flow (`lib/screens/transactions/add_transaction_screen.dart`)

After successful transaction creation:
```dart
// Update streak
await ApiService.updateStreak(userId);

// Check achievements
final achievementResult = await ApiService.checkAchievements(userId);
if (achievementResult['success']) {
  final newlyUnlocked = ...;
  if (newlyUnlocked.isNotEmpty) {
    await NotificationService.checkAndNotifyAchievements(newlyUnlocked);
  }
}
```

---

## Best Practices

### For Users

1. **Track Daily**:
   - Add at least one transaction per day
   - Builds daily tracking streak
   - Unlocks streak achievements

2. **Complete Actions**:
   - Create first budget (Budget Beginner)
   - Add first investment (Investment Initiate)
   - Record first transaction (First Step)

3. **Monitor Progress**:
   - Check Dashboard "Your Progress" card regularly
   - View Achievements screen to see what's next
   - Aim for higher difficulty achievements

4. **Stay Consistent**:
   - Don't break streaks
   - Daily tracking is key to many achievements
   - Consistent engagement = faster leveling

5. **Compete**:
   - Check leaderboard for ranking
   - Compare XP with top users
   - Strive for top 10 placement

### For Developers

1. **Achievement Design**:
   - Clear, achievable criteria
   - Appropriate XP rewards
   - Balanced difficulty levels
   - Meaningful descriptions

2. **Testing**:
   - Test achievement unlock logic
   - Verify streak continuation/breaking
   - Check notification delivery
   - Validate level calculations

3. **Performance**:
   - Achievement checks should be fast
   - Don't block user transactions
   - Use try-catch for gamification calls
   - Fail silently if gamification errors

4. **User Experience**:
   - Notifications should be celebratory
   - Progress bars must be accurate
   - Visual feedback on unlocks
   - Clear criteria explanations

---

## Future Enhancements

### 1. Financial Challenges
- Weekly spending challenges
- Savings goals with XP rewards
- Budget adherence challenges
- Investment diversification tasks

### 2. Social Features
- Friend comparisons
- Achievement sharing
- Challenge friends
- Team leaderboards

### 3. Advanced Achievements
- Investment return milestones
- Budget consistency streaks
- Category-specific achievements
- Time-based challenges (monthly, yearly)

### 4. Reward System
- Virtual badges collection
- Profile customization unlocks
- Premium feature access
- Real-world rewards integration

### 5. Analytics Integration
- XP earned over time chart
- Achievement unlock timeline
- Streak visualization
- Level progression graph

### 6. Gamification Settings
- Notification preferences
- Achievement difficulty filter
- Private/public leaderboard toggle
- XP multiplier events

---

## Troubleshooting

### Achievements Not Unlocking
**Solution**:
- Ensure criteria are met (check unlock requirements)
- Refresh Achievements screen
- Verify backend is running and connected

### Streak Not Updating
**Solution**:
- Transaction must be added successfully
- Check streak update API call
- Verify date/time is correct
- Ensure user_id is valid

### Notifications Not Showing
**Solution**:
- Check notification permissions
- Verify NotificationService is initialized
- Check platform-specific settings (Android/iOS)
- Test on physical device (web notifications may differ)

### Level Not Increasing
**Solution**:
- Verify XP calculation is correct
- Check achievement XP rewards were added
- Refresh Dashboard
- Review level calculation algorithm

### Dashboard Progress Card Not Appearing
**Solution**:
- Ensure user stats are loaded
- Check API response for errors
- Verify UserStats model parsing
- Refresh Dashboard (pull down)

---

## Examples

### Example 1: New User Journey

**Day 1**:
- Register account
- Add first transaction → **"First Step" unlocked (10 XP)**
- Level 1 → Progress toward Level 2: 10/100 XP
- Daily streak: 1 day

**Day 2**:
- Add transaction → Daily streak: 2 days
- Create first budget → **"Budget Beginner" unlocked (15 XP)**
- Total XP: 25, still Level 1

**Day 3-7**:
- Continue adding transactions daily
- Day 7 streak reached → **"Week Warrior" unlocked (50 XP)**
- Total XP: 75, still Level 1

**Day 8**:
- Add investment → **"Investment Initiate" unlocked (20 XP)**
- Total XP: 95, still Level 1

**Day 9**:
- Continue tracking, more transactions
- Add another 5 XP from micro-achievements
- Total XP: 100 → **Level Up to Level 2!** 🎉

### Example 2: Achievement Progress Tracking

**User viewing Achievements**:

**Locked Achievements**:
- **Budget Master** (Hard, 75 XP)
  - Progress: 0%
  - Criteria: "Stay within budget for one month"
  - Status: User hasn't created budget yet

- **Expense Expert** (Expert, 150 XP)
  - Progress: 35% (35/100 transactions)
  - Criteria: "Record 100 transactions"
  - Status: In progress

**Unlocked Achievements**:
- **First Step** (Easy, 10 XP)
  - Unlocked on: Jan 1, 2026
  - Status: ✓ Complete

### Example 3: Streak Scenario

**Scenario A: Streak Continues**
- Monday: Add transaction → Streak: 1 day
- Tuesday: Add transaction → Streak: 2 days
- Wednesday: Add transaction → Streak: 3 days
- Result: Continues daily

**Scenario B: Streak Breaks**
- Monday: Add transaction → Streak: 5 days
- Tuesday: No activity
- Wednesday: No activity
- Thursday: Add transaction → Streak resets to 1 day
- Result: Broken due to 2-day gap

**Scenario C: Multiple Same-Day Activities**
- Monday: Add 3 transactions → Streak: 1 day
- Result: No change, already tracked today

---

## Summary

The Gamification System transforms SmartFinance from a simple expense tracker into an **engaging financial management game**. Users are motivated to:

- **Track consistently** → Build streaks
- **Complete actions** → Unlock achievements
- **Earn XP** → Level up
- **Compete** → Climb leaderboard
- **Stay engaged** → Develop healthy financial habits

The system is fully integrated with:
- **Backend**: 7 API endpoints, 3 database models, achievement logic
- **Frontend**: Achievements screen, level widget, notifications
- **User Flow**: Automatic checking after transactions, real-time updates

Users enjoy a **gamified financial journey** where every transaction, budget, and investment brings them closer to the next achievement, level, and milestone!

**Next Steps**: Use the system to build healthy financial habits, unlock all achievements, and reach Master level (20+)! 🏆
