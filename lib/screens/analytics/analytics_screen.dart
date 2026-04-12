// ==============================================================================
// analytics_screen.dart - Spending Analytics & Charts Screen
// ==============================================================================
// This screen gives users a visual overview of their finances for a chosen period.
//
// What it shows:
// - Time range selector: 1M / 3M / 6M / 1Y / ALL
// - Summary cards: Total Income, Total Spent, Net Savings, Savings Rate
// - Spending Trend Line Chart — spending over time
// - Income vs Expense Bar Chart — monthly grouped comparison
// - Category Pie Chart — expense breakdown by category (tappable slices)
// - Budget vs Actual Comparison — only shown when a budget is active
// - Top 5 Spending Categories — ranked list
//
// Architecture:
// All chart calculations are delegated to AnalyticsService (analytics_service.dart).
// AnalyticsScreen only handles API fetching and UI composition — it passes raw data
// to each chart widget, keeping the logic and UI separate.
//
// Each chart is a separate reusable widget in widgets/charts/ — this keeps the
// build() method readable and each chart independently testable.
// ==============================================================================

import 'package:flutter/material.dart';                          // For Scaffold, RefreshIndicator, etc.
import '../../models/transaction_model.dart';                    // For TransactionModel data class
import '../../models/budget_model.dart';                         // For BudgetModel data class
import '../../services/api_service.dart';                        // For API calls
import '../../services/analytics_service.dart';                  // For chart data calculation logic
import '../../utils/colors.dart';                                 // For AppColors constants
import '../../widgets/charts/spending_trend_chart.dart';          // Line chart widget
import '../../widgets/charts/category_pie_chart.dart';            // Pie chart widget
import '../../widgets/charts/income_expense_bar_chart.dart';      // Bar chart widget
import '../../widgets/charts/budget_comparison_chart.dart';       // Budget comparison chart widget

// ==============================================================================
// AnalyticsScreen — StatefulWidget
// ==============================================================================
// StatefulWidget because it manages:
// - _selectedRange: the active time period filter
// - _transactions: the list fetched from the API
// - _currentBudget: the active budget (may be null)
// - _isLoading: controls the loading spinner
// - _startDate / _endDate: computed from _selectedRange, passed to chart widgets
// ==============================================================================
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedRange = '6M';              // Default time range: last 6 months
  List<TransactionModel> _transactions = []; // All transactions fetched from the API
  BudgetModel? _currentBudget;               // Current month's budget (null if no budget set)
  bool _isLoading = true;                    // True while data is loading

  // _startDate and _endDate are derived from _selectedRange.
  // They are passed to AnalyticsService methods to filter transactions to the chosen period.
  // Initialised to DateTime.now() — overwritten in _loadData() before first use.
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // ==============================================================================
  // initState - Called Once When the Widget Is First Built
  // ==============================================================================
  @override
  void initState() {
    super.initState();    // Always call super first
    _loadData();          // Fetch transactions and budget on screen open
  }

  // ==============================================================================
  // _loadData - Fetch All Data Needed by the Charts
  // ==============================================================================
  // Called on first load and whenever the user changes the time range.
  // Sequential (not parallel) because:
  // 1. Both calls are fast enough that sequential is acceptable.
  // 2. The budget call failing should NOT block the transaction charts.
  // ==============================================================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);   // Show spinner

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    // AnalyticsService.getTimeRange converts "6M" to actual start/end DateTime objects
    // e.g., '6M' -> {start: 6 months ago, end: today}
    final range = AnalyticsService.getTimeRange(_selectedRange);
    _startDate = range['start']!; // '!' asserts non-null
    _endDate = range['end']!;

    // Load all user transactions (filtering by date happens in AnalyticsService)
    final transactionsResult = await ApiService.getUserTransactions(userId);
    if (transactionsResult['success']) {
      final transactionsList = transactionsResult['transactions'] as List;
      setState(() {
        // Convert each JSON map to a TransactionModel
        _transactions = transactionsList
            .map((json) => TransactionModel.fromJson(json))
            .toList();
      });
    }

    // Load current month's budget (for the Budget vs Actual chart)
    final budgetResult = await ApiService.getCurrentBudget(userId);
    if (budgetResult['success'] && budgetResult['budget'] != null) {
      setState(() {
        _currentBudget = BudgetModel.fromJson(budgetResult['budget']);
      });
    }

    setState(() => _isLoading = false);
  }

  // ==============================================================================
  // _changeRange - Update the Selected Time Range and Refresh All Charts
  // ==============================================================================
  // Called when the user taps a range button (1M / 3M / 6M / 1Y / ALL).
  // setState() updates _selectedRange so the button highlights correctly,
  // then _loadData() re-fetches transactions and recomputes all chart data
  // for the new date window.
  // ==============================================================================
  void _changeRange(String range) {
    setState(() {
      _selectedRange = range;   // Highlight the tapped button
    });
    _loadData();                // Re-fetch and re-render all charts
  }

  // ==============================================================================
  // build - Assemble the Full Analytics Screen
  // ==============================================================================
  // While loading: shows a centered spinner.
  // After loading: shows a scrollable column of charts wrapped in RefreshIndicator
  // so the user can pull down to refresh all data.
  //
  // The charts are built by private helpers (_buildTimeRangeSelector, _buildSummaryCards,
  // etc.) to keep this method readable. Each helper either returns a chart widget or
  // _buildEmptyChartState() when there is no data.
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData, // Pull-to-refresh
              child: SingleChildScrollView(
                // AlwaysScrollableScrollPhysics ensures pull-to-refresh works
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time range buttons: 1M | 3M | 6M | 1Y | ALL
                    _buildTimeRangeSelector(),
                    const SizedBox(height: 24),

                    // 4 summary cards: Income, Spending, Net Savings, Savings Rate
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // Line chart showing spending trend over time
                    _buildChartSection(
                      'Spending Trend',
                      Icons.trending_up,
                      _buildSpendingTrendChart(),
                    ),
                    const SizedBox(height: 24),

                    // Bar chart comparing income vs expenses by month
                    _buildChartSection(
                      'Income vs Expense',
                      Icons.compare_arrows,
                      _buildIncomeExpenseChart(),
                    ),
                    const SizedBox(height: 24),

                    // Pie chart showing expense distribution by category.
                    // height: null — CategoryPieChart manages its own height internally
                    // (200px donut + natural legend height) to avoid empty whitespace.
                    _buildChartSection(
                      'Expense Breakdown',
                      Icons.pie_chart,
                      _buildCategoryPieChart(),
                      height: null,
                    ),
                    const SizedBox(height: 24),

                    // Budget comparison chart - only shown when a budget is set
                    if (_currentBudget != null) ...[
                      _buildChartSection(
                        'Budget vs Actual',
                        Icons.assessment,
                        _buildBudgetComparisonChart(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Ranked list of the top 5 spending categories
                    _buildTopCategories(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // _buildTimeRangeSelector creates the horizontal scrollable range buttons
  Widget _buildTimeRangeSelector() {
    final ranges = ['1M', '3M', '6M', '1Y', 'ALL']; // Available time ranges

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Scroll horizontally if screen is narrow
        child: Row(
          children: ranges.map((range) {
            final isSelected = _selectedRange == range;
            return GestureDetector(
              onTap: () => _changeRange(range), // Update range on tap
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  // Filled background for selected; transparent for others
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  range,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // _buildSummaryCards creates 4 metric cards in a 2x2 grid layout
  Widget _buildSummaryCards() {
    // getCategoryBreakdown returns Map<category, totalAmount> filtered to the date range
    final expenseData = AnalyticsService.getCategoryBreakdown(
      _transactions,
      'expense',
      _startDate,
      _endDate,
    );
    final incomeData = AnalyticsService.getCategoryBreakdown(
      _transactions,
      'income',
      _startDate,
      _endDate,
    );

    // Sum all expense category amounts: .fold accumulates the sum starting at 0.0
    final totalExpense = expenseData.values.fold(0.0, (sum, val) => sum + val);
    final totalIncome = incomeData.values.fold(0.0, (sum, val) => sum + val);
    final netSavings = totalIncome - totalExpense; // Positive = saved money
    // getSavingsRate returns the percentage of income that was saved
    final savingsRate = AnalyticsService.getSavingsRate(totalIncome, totalExpense);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Income',
                'RM ${totalIncome.toStringAsFixed(2)}',
                Icons.arrow_downward, // Downward = money coming in
                AppColors.income,     // Green
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Spent',
                'RM ${totalExpense.toStringAsFixed(2)}',
                Icons.arrow_upward, // Upward = money going out
                AppColors.expense,  // Red
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Net Savings',
                'RM ${netSavings.toStringAsFixed(2)}',
                Icons.savings,
                netSavings >= 0 ? AppColors.success : AppColors.danger, // Green if saved, red if deficit
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Savings Rate',
                '${savingsRate.toStringAsFixed(1)}%',
                Icons.percent,
                // Color coding: green 20%+, orange 10-19%, red under 10%
                savingsRate >= 20 ? AppColors.success : (savingsRate >= 10 ? AppColors.warning : AppColors.danger),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // _buildSummaryCard creates one metric card with icon, label, and colored value
  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color, // Color matches the metric's meaning
            ),
          ),
        ],
      ),
    );
  }

  // _buildChartSection wraps a chart widget in a white card with title and icon.
  // height — when provided, the chart is placed in a SizedBox of that exact height.
  //          Pass null for self-sizing charts like CategoryPieChart that manage their
  //          own height internally (avoids empty whitespace from over-allocation).
  Widget _buildChartSection(String title, IconData icon, Widget chart, {double? height = 250}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisSize.min — don't expand the card taller than its content
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // When height is provided, constrain the chart to that exact height.
          // When null, the chart sizes itself (used for pie chart with dynamic legend).
          if (height != null)
            SizedBox(height: height, child: chart)
          else
            chart,
        ],
      ),
    );
  }

  // _buildSpendingTrendChart prepares data and returns the SpendingTrendChart widget
  Widget _buildSpendingTrendChart() {
    // getSpendingTrends returns Map<date, totalSpend> for each period in range
    final trendData = AnalyticsService.getSpendingTrends(
      _transactions,
      _startDate,
      _endDate,
    );

    if (trendData.isEmpty) {
      return _buildEmptyChartState('No spending data', 'Add transactions to see your spending trends');
    }

    // Calculate max Y value with 20% headroom so bars/lines don't touch the top
    // .reduce compares all values and returns the largest
    final maxY = trendData.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return SpendingTrendChart(
      trendData: trendData,
      maxY: maxY,
    );
  }

  // _buildIncomeExpenseChart prepares data and returns the IncomeExpenseBarChart widget
  Widget _buildIncomeExpenseChart() {
    // getIncomeVsExpense returns Map<month, {income: X, expense: Y}>
    final data = AnalyticsService.getIncomeVsExpense(
      _transactions,
      _startDate,
      _endDate,
    );

    if (data.isEmpty) {
      return _buildEmptyChartState('No data available', 'Add income and expense transactions to see comparison');
    }

    // Find the largest value across all months to set the chart's Y axis maximum
    double maxY = 0;
    for (var monthData in data.values) {
      final maxValue = monthData.values.reduce((a, b) => a > b ? a : b);
      if (maxValue > maxY) maxY = maxValue;
    }
    maxY = maxY * 1.2; // Add 20% headroom

    return IncomeExpenseBarChart(
      data: data,
      maxY: maxY,
    );
  }

  // _buildCategoryPieChart prepares expense data and returns the CategoryPieChart widget
  Widget _buildCategoryPieChart() {
    final categoryData = AnalyticsService.getCategoryBreakdown(
      _transactions,
      'expense', // Only show expense categories in the pie chart
      _startDate,
      _endDate,
    );

    if (categoryData.isEmpty) {
      return _buildEmptyChartState('No expense data', 'Add expense transactions to see category breakdown');
    }

    return CategoryPieChart(
      categoryData: categoryData,
      type: 'expense',
    );
  }

  // _buildBudgetComparisonChart prepares budget data and returns the BudgetComparisonChart widget
  Widget _buildBudgetComparisonChart() {
    // getBudgetVsActual compares budget allocation vs actual spending per category
    final data = AnalyticsService.getBudgetVsActual(_currentBudget);

    if (data.isEmpty) {
      return _buildEmptyChartState('No budget data', 'Create a budget to compare with actual spending');
    }

    double maxY = 0;
    for (var categoryData in data.values) {
      final maxValue = categoryData.values.reduce((a, b) => a > b ? a : b);
      if (maxValue > maxY) maxY = maxValue;
    }
    maxY = maxY * 1.2;

    return BudgetComparisonChart(
      data: data,
      maxY: maxY,
    );
  }

  // _buildTopCategories shows a ranked list of the top 5 expense categories
  Widget _buildTopCategories() {
    // getTopCategories returns the N highest-spending categories as MapEntry list (sorted)
    final topCategories = AnalyticsService.getTopCategories(
      _transactions,
      _startDate,
      _endDate,
      5, // Get top 5 categories
    );

    if (topCategories.isEmpty) {
      return const SizedBox.shrink(); // Return empty widget if no data
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, size: 20, color: AppColors.warning), // Star icon
              const SizedBox(width: 8),
              const Text(
                'Top 5 Spending Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // .asMap().entries gives MapEntry<index, value> so we can show rank numbers
          ...topCategories.asMap().entries.map((entry) {
            final index = entry.key;         // 0-based index (0 = #1, 1 = #2, etc.)
            final category = entry.value;    // MapEntry<String, double> (category name, amount)
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  // Rank number circle
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}', // Display 1-based rank number
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Category name
                  Expanded(
                    child: Text(
                      category.key, // The category name (key of MapEntry)
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Spending amount
                  Text(
                    'RM ${category.value.toStringAsFixed(2)}', // The total amount (value of MapEntry)
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense, // Red for expense
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // _buildEmptyChartState shows a placeholder when there's no data for a chart
  Widget _buildEmptyChartState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined, // Empty bar chart icon
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle, // Helpful instruction text
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
