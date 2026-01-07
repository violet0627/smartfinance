import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../utils/colors.dart';

class BudgetAlertCard extends StatelessWidget {
  final BudgetModel budget;

  const BudgetAlertCard({super.key, required this.budget});

  List<BudgetAlert> _generateAlerts() {
    final alerts = <BudgetAlert>[];
    final percentage = budget.percentageUsed;

    // Overall budget alerts
    if (budget.isOverBudget) {
      alerts.add(BudgetAlert(
        type: AlertType.danger,
        icon: Icons.error,
        title: 'Budget Exceeded!',
        message:
            'You\'ve overspent by RM ${(-budget.totalRemaining).toStringAsFixed(2)}. Consider reducing expenses.',
      ));
    } else if (percentage >= 90) {
      alerts.add(BudgetAlert(
        type: AlertType.warning,
        icon: Icons.warning_amber,
        title: 'Approaching Budget Limit',
        message:
            'You\'ve used ${percentage.toStringAsFixed(0)}% of your budget. Only RM ${budget.totalRemaining.toStringAsFixed(2)} remaining.',
      ));
    } else if (percentage >= 80) {
      alerts.add(BudgetAlert(
        type: AlertType.info,
        icon: Icons.info,
        title: 'Budget Alert',
        message:
            '${percentage.toStringAsFixed(0)}% of your budget used. You\'re on track but watch your spending.',
      ));
    }

    // Category-specific alerts
    final overBudgetCategories =
        budget.categories.where((cat) => cat.isOverBudget).toList();
    if (overBudgetCategories.isNotEmpty) {
      final categoryNames =
          overBudgetCategories.map((cat) => cat.categoryName).join(', ');
      alerts.add(BudgetAlert(
        type: AlertType.danger,
        icon: Icons.category,
        title: 'Category Over Budget',
        message: '$categoryNames ${overBudgetCategories.length > 1 ? "are" : "is"} over budget.',
      ));
    }

    final warningCategories = budget.categories
        .where((cat) => !cat.isOverBudget && cat.percentageUsed >= 90)
        .toList();
    if (warningCategories.isNotEmpty) {
      final categoryNames =
          warningCategories.map((cat) => cat.categoryName).join(', ');
      alerts.add(BudgetAlert(
        type: AlertType.warning,
        icon: Icons.category_outlined,
        title: 'Category Warning',
        message: '$categoryNames ${warningCategories.length > 1 ? "are" : "is"} approaching the limit.',
      ));
    }

    // Days left warning
    if (budget.daysLeftInMonth <= 3 && !budget.isOverBudget) {
      final dailyBudget = budget.totalRemaining / budget.daysLeftInMonth;
      alerts.add(BudgetAlert(
        type: AlertType.info,
        icon: Icons.calendar_today,
        title: 'Month Ending Soon',
        message:
            'Only ${budget.daysLeftInMonth} days left. Daily budget: RM ${dailyBudget.toStringAsFixed(2)}.',
      ));
    }

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _generateAlerts();

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: alerts.map((alert) {
        Color backgroundColor;
        Color textColor;

        switch (alert.type) {
          case AlertType.danger:
            backgroundColor = AppColors.danger.withOpacity(0.1);
            textColor = AppColors.danger;
            break;
          case AlertType.warning:
            backgroundColor = AppColors.warning.withOpacity(0.1);
            textColor = AppColors.warning;
            break;
          case AlertType.info:
            backgroundColor = Colors.blue.withOpacity(0.1);
            textColor = Colors.blue;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(alert.icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class BudgetAlert {
  final AlertType type;
  final IconData icon;
  final String title;
  final String message;

  BudgetAlert({
    required this.type,
    required this.icon,
    required this.title,
    required this.message,
  });
}

enum AlertType {
  danger,
  warning,
  info,
}
