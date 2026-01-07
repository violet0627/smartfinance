import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/investment_model.dart';

class AnalyticsService {
  /// Get spending trends data for line chart
  static Map<String, double> getSpendingTrends(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final trends = <String, double>{};

    // Group transactions by month
    final filteredTransactions = transactions.where((t) =>
        t.transactionType == 'expense' &&
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1))));

    for (var transaction in filteredTransactions) {
      final monthKey = '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}';
      trends[monthKey] = (trends[monthKey] ?? 0.0) + transaction.amount;
    }

    return trends;
  }

  /// Get category breakdown for pie chart
  static Map<String, double> getCategoryBreakdown(
    List<TransactionModel> transactions,
    String type, // 'expense' or 'income'
    DateTime startDate,
    DateTime endDate,
  ) {
    final breakdown = <String, double>{};

    final filteredTransactions = transactions.where((t) =>
        t.transactionType == type &&
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1))));

    for (var transaction in filteredTransactions) {
      breakdown[transaction.category] =
          (breakdown[transaction.category] ?? 0.0) + transaction.amount;
    }

    return breakdown;
  }

  /// Get monthly income vs expense data
  static Map<String, Map<String, double>> getIncomeVsExpense(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final data = <String, Map<String, double>>{};

    final filteredTransactions = transactions.where((t) =>
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1))));

    for (var transaction in filteredTransactions) {
      final monthKey = '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}';

      if (!data.containsKey(monthKey)) {
        data[monthKey] = {'income': 0.0, 'expense': 0.0};
      }

      if (transaction.isExpense) {
        data[monthKey]!['expense'] = data[monthKey]!['expense']! + transaction.amount;
      } else {
        data[monthKey]!['income'] = data[monthKey]!['income']! + transaction.amount;
      }
    }

    return data;
  }

  /// Get budget vs actual spending data
  static Map<String, Map<String, double>> getBudgetVsActual(
    BudgetModel? budget,
  ) {
    if (budget == null) return {};

    final data = <String, Map<String, double>>{};

    for (var category in budget.categories) {
      data[category.categoryName] = {
        'budgeted': category.allocatedAmount,
        'actual': category.spentAmount,
      };
    }

    return data;
  }

  /// Get investment performance over time
  static Map<String, double> getInvestmentPerformance(
    List<InvestmentModel> investments,
  ) {
    final performance = <String, double>{};

    // Group by purchase month and calculate total value
    for (var investment in investments) {
      final monthKey = '${investment.purchaseDate.year}-${investment.purchaseDate.month.toString().padLeft(2, '0')}';
      performance[monthKey] = (performance[monthKey] ?? 0.0) + investment.currentValue;
    }

    return performance;
  }

  /// Calculate daily average spending
  static double getDailyAverageSpending(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final expenses = transactions.where((t) =>
        t.transactionType == 'expense' &&
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1))));

    if (expenses.isEmpty) return 0.0;

    final totalExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final days = endDate.difference(startDate).inDays + 1;

    return totalExpense / days;
  }

  /// Get top spending categories
  static List<MapEntry<String, double>> getTopCategories(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
    int limit,
  ) {
    final breakdown = getCategoryBreakdown(transactions, 'expense', startDate, endDate);

    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(limit).toList();
  }

  /// Calculate savings rate
  static double getSavingsRate(
    double totalIncome,
    double totalExpense,
  ) {
    if (totalIncome == 0) return 0.0;
    final savings = totalIncome - totalExpense;
    return (savings / totalIncome) * 100;
  }

  /// Get spending by day of week
  static Map<String, double> getSpendingByDayOfWeek(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final spendingByDay = <String, double>{
      'Mon': 0.0,
      'Tue': 0.0,
      'Wed': 0.0,
      'Thu': 0.0,
      'Fri': 0.0,
      'Sat': 0.0,
      'Sun': 0.0,
    };

    final expenses = transactions.where((t) =>
        t.transactionType == 'expense' &&
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1))));

    for (var transaction in expenses) {
      final dayIndex = transaction.transactionDate.weekday - 1;
      final dayName = weekdayNames[dayIndex];
      spendingByDay[dayName] = spendingByDay[dayName]! + transaction.amount;
    }

    return spendingByDay;
  }

  /// Get time range presets
  static Map<String, DateTime> getTimeRange(String range) {
    final now = DateTime.now();
    DateTime startDate;

    switch (range) {
      case '1M':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3M':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6M':
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case '1Y':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case 'ALL':
        startDate = DateTime(2000, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1); // Current month
    }

    return {'start': startDate, 'end': now};
  }
}
