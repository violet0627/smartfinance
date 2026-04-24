// ==============================================================================
// gamification_model.dart - Gamification Data Models
// ==============================================================================
// This file defines FIVE related models for the gamification (rewards) feature:
//
// 1. Achievement - A badge/reward that can be earned (e.g., "Log 100 transactions")
// 2. UserAchievement - Tracks a user's progress toward an achievement
// 3. UserStats - Overall gamification stats (XP, level, streaks, achievements)
// 4. HabitStreak - Tracks consecutive days of activity (daily tracking streaks)
// 5. NewAchievement - Represents a newly unlocked achievement (for notifications)
//
// These models support a gamification system that rewards users with XP and
// achievements for using the app consistently (logging transactions, budgets, etc.)
// ==============================================================================

// ==============================================================================
// Achievement - Represents a Badge/Reward Definition
// ==============================================================================
// Defines what an achievement IS - its name, description, and unlock criteria.
// This is the "template" - UserAchievement tracks if a specific user has it.
//
// Example: Achievement(name: "Century Club", criteria: "Log 100 transactions",
//          xpReward: 500, difficulty: "hard")
// ==============================================================================
class Achievement {
  final int achievementId;       // Unique ID for this achievement
  final String name;             // Achievement name (e.g., "Century Club")
  final String description;      // What this achievement is (e.g., "Log 100 transactions")
  final String badgeIcon;        // Icon name/emoji for the badge display
  final int xpReward;            // How much XP the user gets for unlocking this
  final String unlockCriteria;   // Text description of how to unlock (e.g., "Log 100 transactions")
  final String difficultyLevel;  // Difficulty: "easy", "medium", "hard"

  // --- Constructor ---
  Achievement({
    required this.achievementId,
    required this.name,
    required this.description,
    required this.badgeIcon,
    required this.xpReward,
    required this.unlockCriteria,
    required this.difficultyLevel,
  });

  // --- fromJson ---
  // Creates an Achievement from JSON data received from the API.
  // Uses ?? (null coalescing) to provide default values if fields are missing.
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      achievementId: json['achievementId'],
      name: json['name'],
      description: json['description'] ?? '',            // Default to empty string if null
      badgeIcon: json['badgeIcon'] ?? '',                 // Default to empty string if null
      xpReward: json['xpReward'] ?? 0,                   // Default to 0 XP if null
      unlockCriteria: json['unlockCriteria'] ?? '',       // Default to empty string if null
      difficultyLevel: json['difficultyLevel'] ?? 'easy', // Default to "easy" if null
    );
  }
}

// ==============================================================================
// UserAchievement - Tracks a User's Progress Toward an Achievement
// ==============================================================================
// Links a user to an achievement and tracks their progress.
// Example: User #1 has made 75 out of 100 transactions needed for "Century Club"
//
// Relationship:
//   UserAchievement -> Achievement (each UserAchievement references one Achievement)
// ==============================================================================
class UserAchievement {
  final int? userAchievementId;    // Unique ID for this user-achievement record
  final bool isUnlocked;           // Has the user unlocked this achievement?
  final int progress;              // Current progress count (e.g., 75 out of 100)
  final int userId;                // Which user this belongs to
  final int achievementId;         // Which achievement this tracks
  final DateTime? unlockedAt;      // When it was unlocked (null if not yet unlocked)
  final Achievement? achievement;  // The achievement details (nested object from API)

  // --- Constructor ---
  UserAchievement({
    this.userAchievementId,
    required this.isUnlocked,
    required this.progress,
    required this.userId,
    required this.achievementId,
    this.unlockedAt,
    this.achievement,
  });

  // --- fromJson ---
  // Creates a UserAchievement from JSON. Note how it handles nested objects:
  // The 'achievement' field is itself a JSON object, so we parse it with
  // Achievement.fromJson() to create a nested Achievement object.
  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      userAchievementId: json['userAchievementId'],
      isUnlocked: json['isUnlocked'] ?? false,      // Default: not unlocked
      progress: json['progress'] ?? 0,                // Default: no progress
      userId: json['userId'],
      achievementId: json['achievementId'],
      unlockedAt: json['unlockedAt'] != null          // Parse date string if present
          ? DateTime.parse(json['unlockedAt'])
          : null,                                      // Keep as null if not unlocked
      achievement: json['achievement'] != null         // Parse nested Achievement if present
          ? Achievement.fromJson(json['achievement'])
          : null,                                      // Keep as null if not included
    );
  }

  // --- Computed Property: progressPercentage ---
  // Calculates how close the user is to unlocking this achievement (0-100%).
  //
  // How it works:
  // 1. If no achievement details available, return 0%
  // 2. Extract the target number from the unlock criteria text
  //    (e.g., "Log 100 transactions" -> target = 100)
  // 3. Calculate: (current progress / target) * 100
  // 4. .clamp(0.0, 100.0) ensures result stays between 0% and 100%
  //
  // Note: This is a simplified parser - it looks for specific numbers
  // in the criteria text (100, 30, 7) and defaults to 1 for simple achievements.
  double get progressPercentage {
    if (achievement == null) return 0.0;   // Can't calculate without achievement details

    // Extract target from unlock criteria (simplified)
    int target = 1;                                               // Default target is 1
    if (achievement!.unlockCriteria.contains('100')) {
      target = 100;    // e.g., "Log 100 transactions"
    } else if (achievement!.unlockCriteria.contains('30')) {
      target = 30;     // e.g., "30 day streak"
    } else if (achievement!.unlockCriteria.contains('7')) {
      target = 7;      // e.g., "7 day streak"
    }
    // The ! after achievement is the null assertion operator:
    // It tells Dart "I'm sure this is not null" (we already checked above)

    return (progress / target * 100).clamp(0.0, 100.0);   // Percentage, capped at 0-100
  }
}

// ==============================================================================
// UserStats - Overall Gamification Statistics
// ==============================================================================
// Contains all gamification data for a user: XP, level, achievements, streaks.
// This is the main data shown on the Gamification/Rewards screen.
//
// Example:
//   Level 5 | 1250 XP | 3/10 achievements | 7-day streak
// ==============================================================================
class UserStats {
  final int totalXp;                       // Total XP earned across all time
  final int level;                         // Current level (calculated from XP)
  final int xpForNextLevel;                // Total XP needed to reach next level
  final int xpProgressInLevel;             // XP earned within the current level
  final int achievementsUnlocked;          // How many achievements the user has unlocked
  final int totalAchievements;             // Total number of achievements available
  final int longestStreak;                 // Longest streak the user has ever had
  final Map<String, int> currentStreaks;   // Current active streaks by type
  // Example: {"daily_tracking": 7, "budget_adherence": 3}

  // --- Constructor ---
  UserStats({
    required this.totalXp,
    required this.level,
    required this.xpForNextLevel,
    required this.xpProgressInLevel,
    required this.achievementsUnlocked,
    required this.totalAchievements,
    required this.longestStreak,
    required this.currentStreaks,
  });

  // --- fromJson ---
  // Creates UserStats from JSON. Note the Map parsing:
  // Map<String, int>.from() converts a dynamic map to a typed Map<String, int>
  // The ?? {} provides an empty map as fallback if currentStreaks is null
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalXp: json['totalXp'] ?? 0,                        // Default: 0 XP
      level: json['level'] ?? 1,                             // Default: Level 1
      xpForNextLevel: json['xpForNextLevel'] ?? 100,         // Default: 100 XP to next level
      xpProgressInLevel: json['xpProgressInLevel'] ?? 0,     // Default: 0 progress
      achievementsUnlocked: json['achievementsUnlocked'] ?? 0,
      totalAchievements: json['totalAchievements'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      currentStreaks: Map<String, int>.from(json['currentStreaks'] ?? {}),
      // Map<String, int>.from() creates a typed map from the JSON dynamic map
      // json['currentStreaks'] might be: {"daily_tracking": 7, "budget_adherence": 3}
    );
  }

  // --- Computed Property: levelProgress ---
  // How far through the current level the user is (0-100%).
  // Used to display a progress bar on the gamification screen.
  // Example: 50 XP progress out of 200 XP needed = 25%
  double get levelProgress {
    if (xpForNextLevel == 0) return 0.0;   // Avoid division by zero
    return (xpProgressInLevel / xpForNextLevel * 100).clamp(0.0, 100.0);
    // .clamp(0.0, 100.0) ensures the value stays between 0% and 100%
  }

  // --- Computed Property: currentDailyStreak ---
  // Quick access to the daily tracking streak count.
  // Looks up "daily_tracking" in the currentStreaks map.
  // Returns 0 if no daily tracking streak exists.
  int get currentDailyStreak {
    return currentStreaks['daily_tracking'] ?? 0;
    // ?? 0 means: if the key doesn't exist in the map, return 0
  }
}

// ==============================================================================
// HabitStreak - Tracks Consecutive Days of Activity
// ==============================================================================
// Represents a streak record (e.g., "7-day daily tracking streak").
// The app tracks different types of streaks (daily logging, budget adherence, etc.)
//
// Example: HabitStreak(streakType: "daily_tracking", currentStreak: 7,
//          longestStreak: 14, lastActivity: today)
// ==============================================================================
class HabitStreak {
  final int streakId;             // Unique ID for this streak record
  final int currentStreak;        // Current consecutive days count
  final int longestStreak;        // All-time best streak for this type
  final DateTime? lastActivity;   // When the user last performed this activity
  final String streakType;        // Type of streak (e.g., "daily_tracking")
  final int userId;               // Which user this streak belongs to

  // --- Constructor ---
  HabitStreak({
    required this.streakId,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivity,
    required this.streakType,
    required this.userId,
  });

  // --- fromJson ---
  factory HabitStreak.fromJson(Map<String, dynamic> json) {
    return HabitStreak(
      streakId: json['streakId'],
      currentStreak: json['currentStreak'] ?? 0,     // Default: 0 days
      longestStreak: json['longestStreak'] ?? 0,     // Default: 0 days
      lastActivity: json['lastActivity'] != null     // Parse date if present
          ? DateTime.parse(json['lastActivity'])
          : null,
      streakType: json['streakType'],
      userId: json['userId'],
    );
  }

  // --- Computed Property: isActive ---
  // Checks if the streak is still active (not broken).
  // A streak is active if the user performed the activity today or yesterday.
  // If more than 1 day has passed, the streak is considered broken.
  bool get isActive {
    if (lastActivity == null) return false;   // No activity recorded = not active
    final today = DateTime.now();
    final difference = today.difference(lastActivity!).inDays;   // Days since last activity
    // ! is the null assertion operator - we already checked lastActivity != null above
    return difference <= 1; // Active if updated today (0 days) or yesterday (1 day)
  }
}

// ==============================================================================
// NewAchievement - Represents a Newly Unlocked Achievement
// ==============================================================================
// Used for showing achievement unlock notifications/popups.
// When the backend detects a new achievement was unlocked, it returns this
// data so the app can show a congratulatory message.
//
// Example: "Congratulations! You unlocked 'Century Club' and earned 500 XP!"
// ==============================================================================
class NewAchievement {
  final Achievement achievement;   // The achievement that was unlocked
  final int xpEarned;             // How much XP was earned from this unlock

  // --- Constructor ---
  NewAchievement({
    required this.achievement,
    required this.xpEarned,
  });

  // --- fromJson ---
  // Parses the nested achievement object and the XP reward.
  // json['achievement'] is a nested JSON object that gets parsed by Achievement.fromJson()
  factory NewAchievement.fromJson(Map<String, dynamic> json) {
    return NewAchievement(
      achievement: Achievement.fromJson(json['achievement']),   // Parse nested Achievement
      xpEarned: json['xpEarned'] ?? 0,                         // Default: 0 XP
    );
  }
}
