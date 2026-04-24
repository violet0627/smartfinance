// ==============================================================================
// budget_alert_card.dart - Budget Alert Notification Card Widget
// ==============================================================================
// This widget displays contextual budget alerts/warnings to the user.
// It analyzes the current budget state and generates appropriate alerts:
//
// Alert types:
// 1. Overall budget alerts (exceeded, >=90%, >=80%)
// 2. Category-specific alerts (individual categories over budget or near limit)
// 3. Days remaining alerts (month ending soon with daily budget calculation)
//
// Each alert has a severity level:
// - danger (red): Budget exceeded or categories over budget
// - warning (orange): Approaching limit (>=90%)
// - info (blue): General awareness (>=80%, month ending)
//
// If no alerts are needed, the widget renders nothing (SizedBox.shrink).
//
// Usage: BudgetAlertCard(budget: myBudgetModel)
// ==============================================================================

import 'package:flutter/material.dart';   // For StatelessWidget, Icons, Colors, Container, etc.
import '../models/budget_model.dart';       // For BudgetModel (budget data with categories)
import '../utils/colors.dart';             // For AppColors (danger, warning colors)

// ==============================================================================
// BudgetAlertCard - StatelessWidget That Displays Budget Alerts
// ==============================================================================
// StatelessWidget because the alerts are computed from the budget data each
// time the widget builds - no internal state needed.
// ==============================================================================
class BudgetAlertCard extends StatelessWidget {
  // The budget model containing spending data, limits, and category breakdowns
  final BudgetModel budget;

  // Constructor: requires a BudgetModel to analyze
  // "super.key" passes the widget key to the parent StatelessWidget constructor
  const BudgetAlertCard({super.key, required this.budget});

  // ==============================================================================
  // _generateAlerts - Analyze Budget and Create Alert List
  // ==============================================================================
  // Private method (starts with _) that examines the budget data and generates
  // a list of BudgetAlert objects based on various conditions.
  //
  // Returns: List<BudgetAlert> - all applicable alerts for the current budget
  // ==============================================================================
  List<BudgetAlert> _generateAlerts() {
    // Initialize empty list to collect alerts
    // <BudgetAlert>[] creates a typed empty list (only BudgetAlert objects allowed)
    final alerts = <BudgetAlert>[];

    // Get the overall percentage of budget used (0-100+)
    final percentage = budget.percentageUsed;

    // --- Overall Budget Alerts ---
    // Check conditions from most severe to least severe
    if (budget.isOverBudget) {
      // DANGER: User has spent MORE than their total budget
      alerts.add(BudgetAlert(
        type: AlertType.danger,                       // Red alert
        icon: Icons.error,                            // Error icon (circle with !)
        title: 'Budget Exceeded!',
        message:
            // (-budget.totalRemaining) converts negative remaining to positive overspend amount
            // .toStringAsFixed(2) formats number with 2 decimal places (e.g., "45.67")
            'You\'ve overspent by RM ${(-budget.totalRemaining).toStringAsFixed(2)}. Consider reducing expenses.',
      ));
    } else if (percentage >= 90) {
      // WARNING: 90%+ used but not exceeded yet
      alerts.add(BudgetAlert(
        type: AlertType.warning,                      // Orange alert
        icon: Icons.warning_amber,                    // Warning triangle icon
        title: 'Approaching Budget Limit',
        message:
            // .toStringAsFixed(0) formats percentage with no decimal places
            'You\'ve used ${percentage.toStringAsFixed(0)}% of your budget. Only RM ${budget.totalRemaining.toStringAsFixed(2)} remaining.',
      ));
    } else if (percentage >= 80) {
      // INFO: 80%+ used - informational heads up
      alerts.add(BudgetAlert(
        type: AlertType.info,                         // Blue alert
        icon: Icons.info,                             // Info icon (circle with i)
        title: 'Budget Alert',
        message:
            '${percentage.toStringAsFixed(0)}% of your budget used. You\'re on track but watch your spending.',
      ));
    }

    // --- Category-Specific Alerts ---
    // .where() filters the categories list to find ones that are over budget
    // .toList() converts the filtered Iterable to a List
    final overBudgetCategories =
        budget.categories.where((cat) => cat.isOverBudget).toList();

    // If any categories are over their individual budgets
    if (overBudgetCategories.isNotEmpty) {
      // .map() transforms each category to its name, .join(', ') combines with commas
      final categoryNames =
          overBudgetCategories.map((cat) => cat.categoryName).join(', ');
      alerts.add(BudgetAlert(
        type: AlertType.danger,                       // Red - over budget is serious
        icon: Icons.category,                         // Category icon
        title: 'Category Over Budget',
        // Ternary operator for grammar: "are" for multiple, "is" for single
        message: '$categoryNames ${overBudgetCategories.length > 1 ? "are" : "is"} over budget.',
      ));
    }

    // Find categories that are close to (>=90%) but not over their budget
    final warningCategories = budget.categories
        .where((cat) => !cat.isOverBudget && cat.percentageUsed >= 90)
        .toList();

    if (warningCategories.isNotEmpty) {
      final categoryNames =
          warningCategories.map((cat) => cat.categoryName).join(', ');
      alerts.add(BudgetAlert(
        type: AlertType.warning,                      // Orange - approaching limit
        icon: Icons.category_outlined,                // Outlined category icon (less severe)
        title: 'Category Warning',
        message: '$categoryNames ${warningCategories.length > 1 ? "are" : "is"} approaching the limit.',
      ));
    }

    // --- Days Remaining Alert ---
    // If month is almost over (3 or fewer days) and budget isn't exceeded
    if (budget.daysLeftInMonth <= 3 && !budget.isOverBudget) {
      // Calculate how much can be spent per day for the rest of the month
      final dailyBudget = budget.totalRemaining / budget.daysLeftInMonth;
      alerts.add(BudgetAlert(
        type: AlertType.info,                         // Blue - informational
        icon: Icons.calendar_today,                   // Calendar icon
        title: 'Month Ending Soon',
        message:
            'Only ${budget.daysLeftInMonth} days left. Daily budget: RM ${dailyBudget.toStringAsFixed(2)}.',
      ));
    }

    return alerts;  // Return all generated alerts
  }

  // ==============================================================================
  // build - Render the Alert Cards
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    // Generate all applicable alerts from the budget data
    final alerts = _generateAlerts();

    // If no alerts, render nothing
    // SizedBox.shrink() creates a zero-size widget (invisible, takes no space)
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Render each alert as a styled container in a vertical Column
    return Column(
      // .map() transforms each BudgetAlert into a widget
      children: alerts.map((alert) {
        // Declare color variables for this alert's styling
        Color backgroundColor;  // Background fill color (light tint)
        Color textColor;        // Text and icon color

        // Assign colors based on alert severity
        switch (alert.type) {
          case AlertType.danger:
            backgroundColor = AppColors.danger.withOpacity(0.1);  // Light red (10% opacity)
            textColor = AppColors.danger;                         // Solid red
            break;
          case AlertType.warning:
            backgroundColor = AppColors.warning.withOpacity(0.1); // Light orange (10% opacity)
            textColor = AppColors.warning;                        // Solid orange
            break;
          case AlertType.info:
            backgroundColor = Colors.blue.withOpacity(0.1);       // Light blue (10% opacity)
            textColor = Colors.blue;                              // Solid blue
            break;
        }

        // Build the alert card UI
        return Container(
          margin: const EdgeInsets.only(bottom: 12),    // Space between alerts
          padding: const EdgeInsets.all(16),             // Inner spacing
          decoration: BoxDecoration(
            color: backgroundColor,                     // Tinted background
            borderRadius: BorderRadius.circular(12),    // Rounded corners
            border: Border.all(color: textColor.withOpacity(0.3)),  // Subtle border
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,  // Align icon to top
            children: [
              // Alert icon on the left
              Icon(alert.icon, color: textColor, size: 24),
              const SizedBox(width: 12),                    // Space between icon and text

              // Alert text (title + message) - Expanded takes remaining width
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,  // Left-align text
                  children: [
                    // Alert title (bold)
                    Text(
                      alert.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),              // Space between title and message

                    // Alert message (slightly lighter)
                    Text(
                      alert.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.8),  // Slightly faded text
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),  // .toList() converts the mapped Iterable to a List<Widget>
    );
  }
}

// ==============================================================================
// BudgetAlert - Data Class for a Single Alert
// ==============================================================================
// Simple data class that holds the information needed to display one alert.
// Not a widget - just a plain Dart class that bundles alert data.
// ==============================================================================
class BudgetAlert {
  final AlertType type;     // Severity level (danger, warning, info)
  final IconData icon;      // Material icon to display
  final String title;       // Alert title text
  final String message;     // Alert body/description text

  // Constructor with required named parameters
  BudgetAlert({
    required this.type,
    required this.icon,
    required this.title,
    required this.message,
  });
}

// ==============================================================================
// AlertType - Enum for Alert Severity Levels
// ==============================================================================
// Enums define a fixed set of named values.
// Used in switch statements to determine styling (colors, icons).
// ==============================================================================
enum AlertType {
  danger,    // Most severe - budget exceeded, over budget
  warning,   // Moderate - approaching limits
  info,      // Least severe - general awareness
}
