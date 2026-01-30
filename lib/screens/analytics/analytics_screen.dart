import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';
import '../../services/api_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/colors.dart';
import '../../widgets/charts/spending_trend_chart.dart';
import '../../widgets/charts/category_pie_chart.dart';
import '../../widgets/charts/income_expense_bar_chart.dart';
import '../../widgets/charts/budget_comparison_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedRange = '6M';
  List<TransactionModel> _transactions = [];
  BudgetModel? _currentBudget;
  bool _isLoading = true;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    // Get time range
    final range = AnalyticsService.getTimeRange(_selectedRange);
    _startDate = range['start']!;
    _endDate = range['end']!;

    // Load transactions
    final transactionsResult = await ApiService.getUserTransactions(userId);
    if (transactionsResult['success']) {
      final transactionsList = transactionsResult['transactions'] as List;
      setState(() {
        _transactions = transactionsList
            .map((json) => TransactionModel.fromJson(json))
            .toList();
      });
    }

    // Load current budget
    final budgetResult = await ApiService.getCurrentBudget(userId);
    if (budgetResult['success'] && budgetResult['budget'] != null) {
      setState(() {
        _currentBudget = BudgetModel.fromJson(budgetResult['budget']);
      });
    }

    setState(() => _isLoading = false);
  }

  void _changeRange(String range) {
    setState(() {
      _selectedRange = range;
    });
    _loadData();
  }

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
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Range Selector
                    _buildTimeRangeSelector(),
                    const SizedBox(height: 24),

                    // Summary Cards
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // Spending Trend Chart
                    _buildChartSection(
                      'Spending Trend',
                      Icons.trending_up,
                      _buildSpendingTrendChart(),
                    ),
                    const SizedBox(height: 24),

                    // Income vs Expense Chart
                    _buildChartSection(
                      'Income vs Expense',
                      Icons.compare_arrows,
                      _buildIncomeExpenseChart(),
                    ),
                    const SizedBox(height: 24),

                    // Category Breakdown
                    _buildChartSection(
                      'Expense Breakdown',
                      Icons.pie_chart,
                      _buildCategoryPieChart(),
                    ),
                    const SizedBox(height: 24),

                    // Budget Comparison
                    if (_currentBudget != null) ...[
                      _buildChartSection(
                        'Budget vs Actual',
                        Icons.assessment,
                        _buildBudgetComparisonChart(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Top Spending Categories
                    _buildTopCategories(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimeRangeSelector() {
    final ranges = ['1M', '3M', '6M', '1Y', 'ALL'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ranges.map((range) {
            final isSelected = _selectedRange == range;
            return GestureDetector(
              onTap: () => _changeRange(range),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
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

  Widget _buildSummaryCards() {
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

    final totalExpense = expenseData.values.fold(0.0, (sum, val) => sum + val);
    final totalIncome = incomeData.values.fold(0.0, (sum, val) => sum + val);
    final netSavings = totalIncome - totalExpense;
    final savingsRate = AnalyticsService.getSavingsRate(totalIncome, totalExpense);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Income',
                'RM ${totalIncome.toStringAsFixed(2)}',
                Icons.arrow_downward,
                AppColors.income,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Spent',
                'RM ${totalExpense.toStringAsFixed(2)}',
                Icons.arrow_upward,
                AppColors.expense,
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
                netSavings >= 0 ? AppColors.success : AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Savings Rate',
                '${savingsRate.toStringAsFixed(1)}%',
                Icons.percent,
                savingsRate >= 20 ? AppColors.success : (savingsRate >= 10 ? AppColors.warning : AppColors.danger),
              ),
            ),
          ],
        ),
      ],
    );
  }

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
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(String title, IconData icon, Widget chart) {
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
          SizedBox(
            height: 250,
            child: chart,
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendChart() {
    final trendData = AnalyticsService.getSpendingTrends(
      _transactions,
      _startDate,
      _endDate,
    );

    if (trendData.isEmpty) {
      return _buildEmptyChartState('No spending data', 'Add transactions to see your spending trends');
    }

    final maxY = trendData.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return SpendingTrendChart(
      trendData: trendData,
      maxY: maxY,
    );
  }

  Widget _buildIncomeExpenseChart() {
    final data = AnalyticsService.getIncomeVsExpense(
      _transactions,
      _startDate,
      _endDate,
    );

    if (data.isEmpty) {
      return _buildEmptyChartState('No data available', 'Add income and expense transactions to see comparison');
    }

    double maxY = 0;
    for (var monthData in data.values) {
      final maxValue = monthData.values.reduce((a, b) => a > b ? a : b);
      if (maxValue > maxY) maxY = maxValue;
    }
    maxY = maxY * 1.2;

    return IncomeExpenseBarChart(
      data: data,
      maxY: maxY,
    );
  }

  Widget _buildCategoryPieChart() {
    final categoryData = AnalyticsService.getCategoryBreakdown(
      _transactions,
      'expense',
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

  Widget _buildBudgetComparisonChart() {
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

  Widget _buildTopCategories() {
    final topCategories = AnalyticsService.getTopCategories(
      _transactions,
      _startDate,
      _endDate,
      5,
    );

    if (topCategories.isEmpty) {
      return const SizedBox.shrink();
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
              const Icon(Icons.star, size: 20, color: AppColors.warning),
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
          ...topCategories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'RM ${category.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
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

  Widget _buildEmptyChartState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
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
              subtitle,
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
