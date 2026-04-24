// ==============================================================================
// analytics_service.dart - Client-Side Analytics & Data Processing
// ==============================================================================
// This service processes financial data LOCALLY on the device (no API calls).
// It takes raw transaction, budget, and investment data and calculates:
// - Spending trends over time (for line charts)
// - Category breakdowns (for pie charts)
// - Income vs expense comparisons (for bar charts)
// - Budget vs actual spending (for comparison charts)
// - Investment performance
// - Daily average spending
// - Top spending categories
// - Savings rate
// - Spending by day of week
//
// All methods are static - called like: AnalyticsService.getSpendingTrends(...)
// ==============================================================================

import '../models/transaction_model.dart';    // Transaction data model
import '../models/budget_model.dart';         // Budget data model
import '../models/investment_model.dart';     // Investment data model

class AnalyticsService {

  // ==============================================================================
  // getSpendingTrends - Monthly Spending Data for Line Charts
  // ==============================================================================
  // Groups EXPENSE transactions by month and sums the amounts.
  // Returns a Map where keys are month strings ("2025-01") and values are totals.
  //
  // Example output: {"2025-01": 1500.00, "2025-02": 1200.00, "2025-03": 1800.00}
  //
  // The date filtering uses .subtract(1 day) and .add(1 day) to make the
  // range inclusive on both ends (isAfter and isBefore are exclusive).
  // ==============================================================================
  static Map<String, double> getSpendingTrends(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final trends = <String, double>{};   // Empty map to accumulate monthly totals

    // Filter: only expenses within the date range
    final filteredTransactions = transactions.where((t) =>
        t.transactionType == 'expense' &&
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1))));

    // Group by month and sum amounts
    for (var transaction in filteredTransactions) {
      // Build month key: "2025-01", "2025-02", etc.
      // .padLeft(2, '0') ensures single-digit months get a leading zero (1 -> "01")
      final monthKey = '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}';
      // ?? 0.0 means: if this key doesn't exist yet, start from 0
      trends[monthKey] = (trends[monthKey] ?? 0.0) + transaction.amount;
    }

    return trends;
  }

  // ==============================================================================
  // getCategoryBreakdown - Spending/Income by Category for Pie Charts
  // ==============================================================================
  // Groups transactions by category and sums amounts.
  // The 'type' parameter specifies "expense" or "income".
  //
  // Example output: {"Food": 500.00, "Transport": 300.00, "Entertainment": 200.00}
  // ==============================================================================
  static Map<String, double> getCategoryBreakdown(
    List<TransactionModel> transactions,
    String type, // 'expense' or 'income'
    DateTime startDate,
    DateTime endDate,
  ) {
    final breakdown = <String, double>{};

    // Filter by type and date range
    final filteredTransactions = transactions.where((t) =>
        t.transactionType == type &&
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1))));

    // Group by category name and sum amounts
    for (var transaction in filteredTransactions) {
      breakdown[transaction.category] =
          (breakdown[transaction.category] ?? 0.0) + transaction.amount;
    }

    return breakdown;
  }

  // ==============================================================================
  // getIncomeVsExpense - Monthly Income vs Expense for Bar Charts
  // ==============================================================================
  // Groups ALL transactions by month, separating income and expense totals.
  // Returns a nested Map: {month -> {type -> amount}}
  //
  // Example output:
  // {
  //   "2025-01": {"income": 5000.00, "expense": 3200.00},
  //   "2025-02": {"income": 5000.00, "expense": 2800.00},
  // }
  //
  // The ! after data[monthKey] is the null assertion operator.
  // We know it's not null because we just initialized it on line 65-67.
  // ==============================================================================
  static Map<String, Map<String, double>> getIncomeVsExpense(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final data = <String, Map<String, double>>{};

    // Filter by date range (no type filter - we want both income and expense)
    final filteredTransactions = transactions.where((t) =>
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1))));

    for (var transaction in filteredTransactions) {
      final monthKey = '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}';

      // Initialize the month entry if it doesn't exist yet
      if (!data.containsKey(monthKey)) {
        data[monthKey] = {'income': 0.0, 'expense': 0.0};
      }

      // Add the amount to the correct type (income or expense)
      if (transaction.isExpense) {
        data[monthKey]!['expense'] = data[monthKey]!['expense']! + transaction.amount;
        // The ! after data[monthKey] asserts it's not null (we initialized it above)
        // The ! after ['expense'] asserts the key exists (we initialized it above)
      } else {
        data[monthKey]!['income'] = data[monthKey]!['income']! + transaction.amount;
      }
    }

    return data;
  }

  // ==============================================================================
  // getBudgetVsActual - Budget Allocated vs Actually Spent per Category
  // ==============================================================================
  // Compares how much was budgeted vs how much was actually spent for each
  // category in a budget. Used for budget adherence charts.
  //
  // Example output:
  // {
  //   "Food":      {"budgeted": 500.00, "actual": 450.00},
  //   "Transport": {"budgeted": 300.00, "actual": 320.00},   // Over budget!
  // }
  // ==============================================================================
  static Map<String, Map<String, double>> getBudgetVsActual(
    BudgetModel? budget,
  ) {
    if (budget == null) return {};   // No budget = no data

    final data = <String, Map<String, double>>{};

    // Loop through each budget category and extract allocated vs spent
    for (var category in budget.categories) {
      data[category.categoryName] = {
        'budgeted': category.allocatedAmount,   // How much was planned
        'actual': category.spentAmount,         // How much was actually spent
      };
    }

    return data;
  }

  // ==============================================================================
  // getInvestmentPerformance - Investment Values by Purchase Month
  // ==============================================================================
  // Groups investments by the month they were purchased and sums their
  // current values. Used for investment performance charts.
  //
  // Example output: {"2024-06": 10000.00, "2024-12": 5000.00}
  // ==============================================================================
  static Map<String, double> getInvestmentPerformance(
    List<InvestmentModel> investments,
  ) {
    final performance = <String, double>{};

    // Group by purchase month and calculate total current value
    for (var investment in investments) {
      final monthKey = '${investment.purchaseDate.year}-${investment.purchaseDate.month.toString().padLeft(2, '0')}';
      performance[monthKey] = (performance[monthKey] ?? 0.0) + investment.currentValue;
      // currentValue is a computed property on InvestmentModel (quantity * currentPrice)
    }

    return performance;
  }

  // ==============================================================================
  // getDailyAverageSpending - Average Amount Spent Per Day
  // ==============================================================================
  // Calculates the average daily expense over a date range.
  // Formula: total expenses / number of days in range
  //
  // .fold() is Dart's version of reduce/accumulate:
  // Starting from 0.0, it adds each transaction's amount
  // ==============================================================================
  static double getDailyAverageSpending(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Filter to only expenses in the date range
    final expenses = transactions.where((t) =>
        t.transactionType == 'expense' &&
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1))));

    if (expenses.isEmpty) return 0.0;    // No expenses = RM0 per day

    // Sum all expense amounts using .fold()
    // fold(initialValue, combiner): starts at 0.0, adds each amount
    final totalExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);

    // Calculate number of days in the range (+1 to include both start and end days)
    final days = endDate.difference(startDate).inDays + 1;

    return totalExpense / days;   // Average = total / days
  }

  // ==============================================================================
  // getTopCategories - Highest Spending Categories (Sorted)
  // ==============================================================================
  // Returns the top N spending categories sorted by amount (highest first).
  // Uses getCategoryBreakdown() internally, then sorts and limits.
  //
  // The ..sort() is the cascade operator with sort:
  // It sorts the list IN PLACE and returns the list itself
  //
  // .take(limit) returns only the first N items from the sorted list
  //
  // Returns List<MapEntry> which has .key (category name) and .value (amount)
  // ==============================================================================
  static List<MapEntry<String, double>> getTopCategories(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
    int limit,              // How many top categories to return
  ) {
    // Get the full category breakdown
    final breakdown = getCategoryBreakdown(transactions, 'expense', startDate, endDate);

    // Sort by amount descending (highest spending first)
    // ..sort() is the cascade operator - sorts in place AND returns the list
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));   // b before a = descending order

    // Return only the top N entries
    return sortedEntries.take(limit).toList();
  }

  // ==============================================================================
  // getSavingsRate - Percentage of Income Saved
  // ==============================================================================
  // Calculates what percentage of income was saved (not spent).
  // Formula: ((income - expense) / income) * 100
  //
  // Example: Income RM5000, Expense RM3500
  //   Savings = 5000 - 3500 = 1500
  //   Rate = (1500 / 5000) * 100 = 30%
  // ==============================================================================
  static double getSavingsRate(
    double totalIncome,
    double totalExpense,
  ) {
    if (totalIncome == 0) return 0.0;    // Can't calculate savings rate with zero income
    final savings = totalIncome - totalExpense;
    return (savings / totalIncome) * 100;
  }

  // ==============================================================================
  // getSpendingByDayOfWeek - Spending Patterns by Weekday
  // ==============================================================================
  // Shows which days of the week the user spends the most.
  // Returns a Map with weekday names and total spending for each.
  //
  // Example output: {"Mon": 200.0, "Tue": 150.0, ..., "Sun": 300.0}
  //
  // DateTime.weekday returns 1 (Monday) through 7 (Sunday)
  // We subtract 1 to get 0-based index for the weekdayNames list
  // ==============================================================================
  static Map<String, double> getSpendingByDayOfWeek(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Initialize all days to 0.0
    final spendingByDay = <String, double>{
      'Mon': 0.0,
      'Tue': 0.0,
      'Wed': 0.0,
      'Thu': 0.0,
      'Fri': 0.0,
      'Sat': 0.0,
      'Sun': 0.0,
    };

    // Filter to only expenses in the date range
    final expenses = transactions.where((t) =>
        t.transactionType == 'expense' &&
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1))));

    // Add each expense amount to the correct day of week
    for (var transaction in expenses) {
      final dayIndex = transaction.transactionDate.weekday - 1;   // weekday is 1-7, convert to 0-6
      final dayName = weekdayNames[dayIndex];                      // Convert index to name
      spendingByDay[dayName] = spendingByDay[dayName]! + transaction.amount;
      // ! asserts the key exists (we initialized all 7 days above)
    }

    return spendingByDay;
  }

  // ==============================================================================
  // getTimeRange - Convert Time Period String to Date Range
  // ==============================================================================
  // Converts shorthand time period strings (like "1M", "3M", "1Y") into
  // actual DateTime start and end dates.
  //
  // Used by the analytics screen to let users select different time periods.
  //
  // Note: DateTime handles month overflow automatically:
  // DateTime(2025, -2, 15) = DateTime(2024, 10, 15) (goes back to October 2024)
  // ==============================================================================
  static Map<String, DateTime> getTimeRange(String range) {
    final now = DateTime.now();
    DateTime startDate;

    switch (range) {
      case '1M':                                                // Last 1 month
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3M':                                                // Last 3 months
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6M':                                                // Last 6 months
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case '1Y':                                                // Last 1 year
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case 'ALL':                                               // All time (since year 2000)
        startDate = DateTime(2000, 1, 1);
        break;
      default:                                                  // Default: current month
        startDate = DateTime(now.year, now.month, 1);           // First day of current month
    }

    return {'start': startDate, 'end': now};   // Returns both start and end dates
  }
}
