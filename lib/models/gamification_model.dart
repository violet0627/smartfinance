class Achievement {
  final int achievementId;
  final String name;
  final String description;
  final String badgeIcon;
  final int xpReward;
  final String unlockCriteria;
  final String difficultyLevel;

  Achievement({
    required this.achievementId,
    required this.name,
    required this.description,
    required this.badgeIcon,
    required this.xpReward,
    required this.unlockCriteria,
    required this.difficultyLevel,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      achievementId: json['achievementId'],
      name: json['name'],
      description: json['description'] ?? '',
      badgeIcon: json['badgeIcon'] ?? '',
      xpReward: json['xpReward'] ?? 0,
      unlockCriteria: json['unlockCriteria'] ?? '',
      difficultyLevel: json['difficultyLevel'] ?? 'easy',
    );
  }
}

class UserAchievement {
  final int? userAchievementId;
  final bool isUnlocked;
  final int progress;
  final int userId;
  final int achievementId;
  final DateTime? unlockedAt;
  final Achievement? achievement;

  UserAchievement({
    this.userAchievementId,
    required this.isUnlocked,
    required this.progress,
    required this.userId,
    required this.achievementId,
    this.unlockedAt,
    this.achievement,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      userAchievementId: json['userAchievementId'],
      isUnlocked: json['isUnlocked'] ?? false,
      progress: json['progress'] ?? 0,
      userId: json['userId'],
      achievementId: json['achievementId'],
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
      achievement: json['achievement'] != null
          ? Achievement.fromJson(json['achievement'])
          : null,
    );
  }

  double get progressPercentage {
    if (achievement == null) return 0.0;

    // Extract target from unlock criteria (simplified)
    int target = 1;
    if (achievement!.unlockCriteria.contains('100')) {
      target = 100;
    } else if (achievement!.unlockCriteria.contains('30')) {
      target = 30;
    } else if (achievement!.unlockCriteria.contains('7')) {
      target = 7;
    }

    return (progress / target * 100).clamp(0.0, 100.0);
  }
}

class UserStats {
  final int totalXp;
  final int level;
  final int xpForNextLevel;
  final int xpProgressInLevel;
  final int achievementsUnlocked;
  final int totalAchievements;
  final int longestStreak;
  final Map<String, int> currentStreaks;

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

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalXp: json['totalXp'] ?? 0,
      level: json['level'] ?? 1,
      xpForNextLevel: json['xpForNextLevel'] ?? 100,
      xpProgressInLevel: json['xpProgressInLevel'] ?? 0,
      achievementsUnlocked: json['achievementsUnlocked'] ?? 0,
      totalAchievements: json['totalAchievements'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      currentStreaks: Map<String, int>.from(json['currentStreaks'] ?? {}),
    );
  }

  double get levelProgress {
    if (xpForNextLevel == 0) return 0.0;
    return (xpProgressInLevel / xpForNextLevel * 100).clamp(0.0, 100.0);
  }

  int get currentDailyStreak {
    return currentStreaks['daily_tracking'] ?? 0;
  }
}

class HabitStreak {
  final int streakId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivity;
  final String streakType;
  final int userId;

  HabitStreak({
    required this.streakId,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivity,
    required this.streakType,
    required this.userId,
  });

  factory HabitStreak.fromJson(Map<String, dynamic> json) {
    return HabitStreak(
      streakId: json['streakId'],
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'])
          : null,
      streakType: json['streakType'],
      userId: json['userId'],
    );
  }

  bool get isActive {
    if (lastActivity == null) return false;
    final today = DateTime.now();
    final difference = today.difference(lastActivity!).inDays;
    return difference <= 1; // Active if updated today or yesterday
  }
}

class NewAchievement {
  final Achievement achievement;
  final int xpEarned;

  NewAchievement({
    required this.achievement,
    required this.xpEarned,
  });

  factory NewAchievement.fromJson(Map<String, dynamic> json) {
    return NewAchievement(
      achievement: Achievement.fromJson(json['achievement']),
      xpEarned: json['xpEarned'] ?? 0,
    );
  }
}
