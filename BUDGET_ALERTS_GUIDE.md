# Budget Alerts and Notifications Guide

## Overview
The SmartFinance app includes a comprehensive budget alert system that helps users stay on track with their spending. The system provides both **in-app visual alerts** and **push notifications** to warn users when they're approaching or exceeding their budget limits.

---

## Features

### 1. Real-Time Budget Monitoring
- Automatically tracks spending against budget in real-time
- Updates budget progress when new transactions are added
- Checks budget status on dashboard load and budget screen views

### 2. Multi-Level Alert System

#### Overall Budget Alerts
- **80% Warning (Info)**: Blue alert when you've used 80% of your monthly budget
- **90% Warning (Caution)**: Yellow alert when approaching budget limit
- **100%+ Alert (Danger)**: Red alert when budget is exceeded

#### Category-Specific Alerts
- Tracks each category's spending separately
- Alerts when category budget reaches 90% or is exceeded
- Shows which categories are over budget

#### Time-Based Alerts
- Warns when there are only 3 days left in the month
- Calculates and suggests daily spending limit based on remaining budget
- Helps with end-of-month budget planning

### 3. Visual In-App Alerts
Located in **Budget Overview Screen**, the alert cards show:
- Alert type (danger/warning/info) with color coding
- Clear icon representation
- Alert title and detailed message
- Actionable insights

**Alert Types:**
```
🚨 Red (Danger): Budget exceeded, immediate action needed
⚠️ Yellow (Warning): Approaching limit, watch spending
ℹ️ Blue (Info): General budget information and tips
```

### 4. Push Notifications
Triggered automatically when:
- Budget reaches 80%, 90%, or 100%
- Any category budget is exceeded
- Category budget reaches 90%
- New transaction causes budget threshold to be crossed

---

## How It Works

### Notification Service (`lib/services/notification_service.dart`)

**Main Functions:**

1. **`initialize()`** - Sets up notification channels for Android and iOS
2. **`checkBudgetAndAlert(budget)`** - Analyzes budget and sends appropriate alerts
3. **`showBudgetAlert()`** - Displays a notification with title and message
4. **`showDailySummary()`** - Shows daily spending summary (future enhancement)
5. **`showTrackingReminder()`** - Reminds users to log expenses (future enhancement)

**Notification IDs:**
- 1000-1999: Overall budget alerts
- 2000-2999: Category-specific alerts
- 3000-3999: Daily summaries
- 4000-4999: Reminders

### Budget Alert Widget (`lib/widgets/budget_alert_card.dart`)

**Alert Generation Logic:**
```dart
1. Check overall budget percentage
   - If >= 100%: Show "Budget Exceeded" danger alert
   - If >= 90%: Show "Approaching Limit" warning alert
   - If >= 80%: Show "Budget Alert" info alert

2. Check all categories
   - Find categories that are over budget
   - Find categories at 90%+ usage
   - Generate alerts for each

3. Check days remaining
   - If <= 3 days left and not over budget
   - Calculate suggested daily spending
   - Show "Month Ending Soon" info alert
```

### Integration Points

#### 1. Dashboard Screen
- Initializes notification service on startup
- Checks budget when loading (only for critical alerts 90%+)
- Shows budget card with current status
- Navigates to detailed budget overview

#### 2. Budget Overview Screen
- Displays all relevant alerts at the top
- Shows full category breakdown
- Automatically checks budget on load
- Sends notifications for all applicable thresholds

#### 3. Add Transaction Screen
- Checks budget after adding expense transactions
- Only triggers alerts if new spending crosses threshold (80%+ or 90%+)
- Prevents alert spam from small transactions

---

## Alert Examples

### Example 1: Overall Budget Warning
```
📊 Budget Alert
You've spent 85% of your budget. Watch your spending!
```

### Example 2: Budget Exceeded
```
🚨 Budget Exceeded!
You've spent RM 2,150.00 of your RM 2,000.00 budget.
```

### Example 3: Category Over Budget
```
🚨 Food & Dining Over Budget
You've exceeded your Food & Dining budget by RM 75.50.
```

### Example 4: Category Warning
```
⚠️ Transportation Warning
92% of Transportation budget used. RM 40.00 remaining.
```

### Example 5: Month Ending Soon
```
ℹ️ Month Ending Soon
Only 3 days left. Daily budget: RM 66.67.
```

---

## User Benefits

### 1. Proactive Spending Management
- Alerts help users make informed spending decisions
- Early warnings prevent budget overruns
- Category-specific insights show where overspending occurs

### 2. Financial Awareness
- Real-time feedback on spending habits
- Visual progress indicators
- Clear understanding of budget status

### 3. Goal Achievement
- Helps users stick to their financial plans
- Encourages mindful spending
- Supports long-term financial goals

---

## Technical Implementation

### Dependencies
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
```

### Setup Required

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### Notification Channels
- **Android**: "budget_alerts" channel with high priority
- **iOS**: Default alert configuration with sound and badge

---

## Future Enhancements

### 1. Daily Spending Summary
- End-of-day notification with total spending
- Compare to daily budget target
- Show trending categories

### 2. Smart Alerts
- Machine learning to predict budget overruns
- Personalized threshold recommendations
- Spending pattern analysis

### 3. Customizable Notifications
- User-defined alert thresholds
- Choose which categories to monitor
- Set quiet hours for notifications

### 4. Weekly Reports
- Weekly spending summary notifications
- Compare week-over-week spending
- Category spending trends

### 5. Achievement Notifications
- Celebrate staying within budget
- Streak notifications for budget adherence
- Savings milestone alerts

---

## Testing the Alert System

### Test Scenario 1: Approaching Budget Limit
1. Create a budget with RM 1,000 total
2. Add transactions totaling RM 850 (85%)
3. **Expected**: Blue info alert appears on budget overview
4. **Expected**: Notification sent about 85% usage

### Test Scenario 2: Exceeding Budget
1. Create a budget with RM 500 total
2. Add transactions totaling RM 550
3. **Expected**: Red danger alert with exact overspend amount
4. **Expected**: "Budget Exceeded" notification

### Test Scenario 3: Category Alert
1. Set Food & Dining budget to RM 200
2. Add food transactions totaling RM 185 (92.5%)
3. **Expected**: Yellow warning for Food & Dining category
4. **Expected**: Category-specific notification

### Test Scenario 4: After Transaction
1. Have budget at 75% usage
2. Add transaction that pushes it to 82%
3. **Expected**: Notification triggered immediately after transaction
4. **Expected**: Dashboard shows updated alert on next refresh

---

## Best Practices

### For Users
1. **Review alerts regularly** - Check budget overview screen frequently
2. **Set realistic budgets** - Avoid setting budgets too low or too high
3. **Enable notifications** - Don't disable budget alert notifications
4. **Act on warnings** - Adjust spending when you receive 80-90% alerts
5. **Track daily** - Add transactions daily to get accurate real-time alerts

### For Developers
1. **Avoid notification spam** - Only send notifications for significant changes
2. **Use appropriate thresholds** - 80%, 90%, 100% are good defaults
3. **Clear messaging** - Alerts should be actionable and specific
4. **Performance** - Check budget efficiently, cache when possible
5. **User control** - Provide settings to customize alert preferences (future)

---

## Troubleshooting

### Notifications Not Appearing
1. Check notification permissions are granted
2. Verify notification service is initialized
3. Ensure device notification settings allow app notifications
4. Test on physical device (emulator may have issues)

### Alerts Not Showing in App
1. Verify budget exists and has data
2. Check budget percentage calculation
3. Ensure BudgetAlertCard widget is included in UI
4. Refresh budget data with pull-to-refresh

### Duplicate Notifications
1. Check if multiple screens are calling checkBudgetAndAlert
2. Verify notification IDs are unique
3. Consider implementing debouncing for rapid updates

---

## Code Examples

### Initialize Notifications
```dart
@override
void initState() {
  super.initState();
  NotificationService.initialize();
  _loadData();
}
```

### Check Budget and Alert
```dart
final budget = BudgetModel.fromJson(budgetData);
await NotificationService.checkBudgetAndAlert(budget);
```

### Show Alert Card
```dart
BudgetAlertCard(budget: _currentBudget!)
```

### Manual Notification
```dart
await NotificationService.showBudgetAlert(
  title: 'Custom Alert',
  body: 'Your custom message',
  notificationId: 5000,
);
```

---

## Summary

The budget alert and notification system is a powerful tool for helping users maintain financial discipline. By providing timely, relevant alerts at multiple levels (overall budget, category budgets, time-based), users can make informed decisions about their spending and stay on track with their financial goals.

The system balances being informative without being intrusive, using smart thresholds and clear messaging to guide users toward better financial habits.
