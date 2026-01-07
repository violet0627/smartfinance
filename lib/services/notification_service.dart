import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/budget_model.dart';
import '../models/gamification_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initializationSettings);
    _initialized = true;
  }

  /// Show budget alert notification
  static Future<void> showBudgetAlert({
    required String title,
    required String body,
    required int notificationId,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Alerts for budget spending and limits',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Budget Alert',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
    );
  }

  /// Check budget status and show alerts
  static Future<void> checkBudgetAndAlert(BudgetModel budget) async {
    final percentage = budget.percentageUsed;

    // Alert for overall budget
    if (percentage >= 100 && !budget.isOverBudget) {
      // First time exceeding budget
      await showBudgetAlert(
        title: '🚨 Budget Exceeded!',
        body: 'You\'ve spent RM ${budget.totalSpent.toStringAsFixed(2)} of your RM ${budget.totalBudget.toStringAsFixed(2)} budget.',
        notificationId: 1000,
      );
    } else if (percentage >= 90 && percentage < 100) {
      // Approaching limit (90%)
      await showBudgetAlert(
        title: '⚠️ Budget Warning',
        body: 'You\'ve used ${percentage.toStringAsFixed(0)}% of your monthly budget. RM ${budget.totalRemaining.toStringAsFixed(2)} remaining.',
        notificationId: 1001,
      );
    } else if (percentage >= 80 && percentage < 90) {
      // Caution (80%)
      await showBudgetAlert(
        title: '📊 Budget Alert',
        body: 'You\'ve spent ${percentage.toStringAsFixed(0)}% of your budget. Watch your spending!',
        notificationId: 1002,
      );
    }

    // Check category budgets
    int categoryAlertId = 2000;
    for (var category in budget.categories) {
      if (category.isOverBudget) {
        await showBudgetAlert(
          title: '🚨 ${category.categoryName} Over Budget',
          body: 'You\'ve exceeded your ${category.categoryName} budget by RM ${(-category.remaining).toStringAsFixed(2)}.',
          notificationId: categoryAlertId++,
        );
      } else if (category.percentageUsed >= 90) {
        await showBudgetAlert(
          title: '⚠️ ${category.categoryName} Warning',
          body: '${category.percentageUsed.toStringAsFixed(0)}% of ${category.categoryName} budget used. RM ${category.remaining.toStringAsFixed(2)} remaining.',
          notificationId: categoryAlertId++,
        );
      }
    }
  }

  /// Show daily spending summary
  static Future<void> showDailySummary({
    required double todaySpending,
    required double monthlyBudget,
  }) async {
    await initialize();

    await showBudgetAlert(
      title: '📈 Daily Summary',
      body: 'You spent RM ${todaySpending.toStringAsFixed(2)} today. Monthly budget: RM ${monthlyBudget.toStringAsFixed(2)}.',
      notificationId: 3000,
    );
  }

  /// Show reminder to track expenses
  static Future<void> showTrackingReminder() async {
    await initialize();

    await showBudgetAlert(
      title: '💡 Don\'t forget!',
      body: 'Have you logged all your expenses today?',
      notificationId: 4000,
    );
  }

  /// Show achievement unlock notification
  static Future<void> showAchievementUnlocked({
    required String achievementName,
    required int xpEarned,
    required int notificationId,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'achievement_unlocked',
      'Achievements',
      channelDescription: 'Notifications for unlocked achievements',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Achievement Unlocked',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      '🏆 Achievement Unlocked!',
      '$achievementName - $xpEarned XP earned!',
      notificationDetails,
    );
  }

  /// Show level up notification
  static Future<void> showLevelUp({
    required int newLevel,
    required int notificationId,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'level_up',
      'Level Up',
      channelDescription: 'Notifications for level progression',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Level Up',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      '⭐ Level Up!',
      'Congratulations! You\'ve reached Level $newLevel!',
      notificationDetails,
    );
  }

  /// Show streak milestone notification
  static Future<void> showStreakMilestone({
    required int streakDays,
    required int notificationId,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'streak_milestone',
      'Streak Milestones',
      channelDescription: 'Notifications for streak achievements',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Streak Milestone',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      '🔥 Streak Milestone!',
      'Amazing! You\'re on a $streakDays-day streak!',
      notificationDetails,
    );
  }

  /// Check for newly unlocked achievements and show notifications
  static Future<void> checkAndNotifyAchievements(List<NewAchievement> newlyUnlocked) async {
    if (newlyUnlocked.isEmpty) return;

    int notificationId = 5000;
    for (var newAchievement in newlyUnlocked) {
      await showAchievementUnlocked(
        achievementName: newAchievement.achievement.name,
        xpEarned: newAchievement.xpEarned,
        notificationId: notificationId++,
      );
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancel(int notificationId) async {
    await _notifications.cancel(notificationId);
  }
}
