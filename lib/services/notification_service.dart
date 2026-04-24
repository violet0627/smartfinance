import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/budget_model.dart';
import '../models/gamification_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Prevents re-initializing if called multiple times
  static bool _initialized = false;

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

    await _notifications.show(notificationId, title, body, notificationDetails);
  }

  // Notification ID ranges: overall budget 1000-1002, categories 2000+
  static Future<void> checkBudgetAndAlert(BudgetModel budget) async {
    final percentage = budget.percentageUsed;

    if (budget.isOverBudget) {
      await showBudgetAlert(
        title: '🚨 Budget Exceeded!',
        body: 'You\'ve spent RM ${budget.totalSpent.toStringAsFixed(2)} of your RM ${budget.totalBudget.toStringAsFixed(2)} budget.',
        notificationId: 1000,
      );
    } else if (percentage >= 90 && percentage < 100) {
      await showBudgetAlert(
        title: '⚠️ Budget Warning',
        body: 'You\'ve used ${percentage.toStringAsFixed(0)}% of your monthly budget. RM ${budget.totalRemaining.toStringAsFixed(2)} remaining.',
        notificationId: 1001,
      );
    } else if (percentage >= 80 && percentage < 90) {
      await showBudgetAlert(
        title: '📊 Budget Alert',
        body: 'You\'ve spent ${percentage.toStringAsFixed(0)}% of your budget. Watch your spending!',
        notificationId: 1002,
      );
    }

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

  static Future<void> showTrackingReminder() async {
    await initialize();
    await showBudgetAlert(
      title: '💡 Don\'t forget!',
      body: 'Have you logged all your expenses today?',
      notificationId: 4000,
    );
  }

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

  // Notification IDs start at 5000, one per achievement
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

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancel(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  // Android 13+ (API 33+) requires the POST_NOTIFICATIONS runtime permission.
  // resolvePlatformSpecificImplementation<T>() returns null on the other platform — ?. skips it safely.
  static Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return result ?? true;
  }

  // Notification ID formula: 10000 + recurringId — avoids collisions with budget (1000-2000)
  // and gamification (3000-5000) ranges.
  // Note: currently shows an immediate notification. In production, use zonedSchedule() instead.
  static Future<void> scheduleRecurringReminder({
    required int recurringId,
    required String name,
    required double amount,
    required String type,
    required DateTime nextExecution,
    int daysBeforeReminder = 1,
  }) async {
    await initialize();

    final reminderDate = nextExecution.subtract(Duration(days: daysBeforeReminder));
    if (reminderDate.isBefore(DateTime.now())) return;

    final notificationId = 10000 + recurringId;

    const androidDetails = AndroidNotificationDetails(
      'recurring_reminders',
      'Bill Reminders',
      channelDescription: 'Reminders for upcoming recurring transactions',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Bill Reminder',
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

    final typeEmoji = type.toLowerCase() == 'income' ? '💰' : '💸';
    final title = 'Upcoming $type: $name';
    final body = '$typeEmoji RM ${amount.toStringAsFixed(2)} due on ${DateFormat('MMM dd, yyyy').format(nextExecution)}';

    try {
      await _notifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: json.encode({
          'type': 'recurring_reminder',
          'recurringId': recurringId,
          'name': name,
        }),
      );
      debugPrint('Scheduled reminder for $name (ID: $notificationId) on $reminderDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  static Future<void> cancelRecurringReminder(int recurringId) async {
    await initialize();
    final notificationId = 10000 + recurringId;
    await _notifications.cancel(notificationId);
    debugPrint('Cancelled reminder for recurring transaction $recurringId');
  }

  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('notifications_enabled') ?? true,
      'daysBeforeReminder': prefs.getInt('days_before_reminder') ?? 1,
      'soundEnabled': prefs.getBool('notification_sound') ?? true,
      'vibrationEnabled': prefs.getBool('notification_vibration') ?? true,
    };
  }

  static Future<void> saveNotificationSettings({
    bool? enabled,
    int? daysBeforeReminder,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled != null) await prefs.setBool('notifications_enabled', enabled);
    if (daysBeforeReminder != null) await prefs.setInt('days_before_reminder', daysBeforeReminder);
    if (soundEnabled != null) await prefs.setBool('notification_sound', soundEnabled);
    if (vibrationEnabled != null) await prefs.setBool('notification_vibration', vibrationEnabled);
  }

  static Future<void> scheduleAllRecurringReminders(List<Map<String, dynamic>> recurringList) async {
    final settings = await getNotificationSettings();
    if (settings['enabled'] != true) return;

    final daysBeforeReminder = settings['daysBeforeReminder'] as int;

    for (var recurring in recurringList) {
      // to_dict() returns camelCase keys; DB may return isActive as bool true or int 1
      final isActive = recurring['isActive'] == true || recurring['isActive'] == 1;
      if (!isActive) continue;

      try {
        final nextExecutionStr = recurring['nextExecution'];
        if (nextExecutionStr == null) continue;

        final nextExecution = DateTime.parse(nextExecutionStr);

        await scheduleRecurringReminder(
          recurringId: recurring['recurringId'],
          name: recurring['name'] ?? 'Unnamed',
          amount: (recurring['amount'] ?? 0.0).toDouble(),
          type: recurring['transactionType'] ?? 'expense',
          nextExecution: nextExecution,
          daysBeforeReminder: daysBeforeReminder,
        );
      } catch (e) {
        debugPrint('Error scheduling reminder for recurring ${recurring['RecurringId']}: $e');
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getUpcomingReminders(
    List<Map<String, dynamic>> recurringList,
  ) async {
    final List<Map<String, dynamic>> upcomingReminders = [];
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    for (var recurring in recurringList) {
      // to_dict() returns camelCase keys; DB may return isActive as bool true or int 1
      final isActive = recurring['isActive'] == true || recurring['isActive'] == 1;
      if (!isActive) continue;

      try {
        final nextExecutionStr = recurring['nextExecution'];
        if (nextExecutionStr == null) continue;

        final nextExecution = DateTime.parse(nextExecutionStr);

        if (nextExecution.isAfter(now) && nextExecution.isBefore(thirtyDaysFromNow)) {
          upcomingReminders.add({
            'recurringId': recurring['recurringId'],
            'name': recurring['name'],
            'amount': recurring['amount'],
            'type': recurring['transactionType'],
            'category': recurring['category'],
            'nextExecution': nextExecution,
            'daysUntil': nextExecution.difference(now).inDays,
          });
        }
      } catch (e) {
        debugPrint('Error processing recurring ${recurring['RecurringId']}: $e');
      }
    }

    upcomingReminders.sort((a, b) =>
      (a['nextExecution'] as DateTime).compareTo(b['nextExecution'] as DateTime)
    );

    return upcomingReminders;
  }

  static Future<void> sendTestNotification() async {
    await initialize();
    await showBudgetAlert(
      title: 'Test Notification',
      body: 'Bill reminders are working! You will be notified before your recurring transactions are due.',
      notificationId: 999999,
    );
  }
}
