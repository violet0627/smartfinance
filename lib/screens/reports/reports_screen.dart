import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'this_month';
  Map<String, dynamic>? _spendingReport;
  Map<String, dynamic>? _budgetReport;
  Map<String, dynamic>? _categoryAnalysis;
  bool _isLoading = false;
  String _error = '';
  int _selectedTab = 0;

  final List<Map<String, String>> _periods = [
    {'label': 'This Month', 'value': 'this_month'},
    {'label': 'Last Month', 'value': 'last_month'},
    {'label': 'Last 3 Months', 'value': 'last_3_months'},
    {'label': 'Last 6 Months', 'value': 'last_6_months'},
    {'label': 'This Year', 'value': 'this_year'},
    {'label': 'Last Year', 'value': 'last_year'},
  ];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Load all reports in parallel
      final results = await Future.wait([
        ApiService.getSpendingReport(userId, period: _selectedPeriod),
        ApiService.getBudgetReport(userId, period: _selectedPeriod),
        ApiService.getCategoryAnalysis(userId, period: _selectedPeriod),
      ]);

      setState(() {
        if (results[0]['success']) {
          _spendingReport = results[0]['report'];
        }
        if (results[1]['success']) {
          _budgetReport = results[1]['report'];
        }
        if (results[2]['success']) {
          _categoryAnalysis = results[2]['report'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadCSV(String type) async {
    try {
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) return;

      String url;
      if (type == 'transactions') {
        url = ApiService.getExportTransactionsUrl(userId, period: _selectedPeriod);
      } else {
        url = ApiService.getExportSpendingReportUrl(userId, period: _selectedPeriod);
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading ${type == "transactions" ? "Transactions" : "Spending Report"} CSV...'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading CSV: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(period['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriod = period['value']!;
                  });
                  _loadReports();
                }
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpendingReportTab() {
    if (_spendingReport == null) {
      return const Center(child: Text('No data available'));
    }

    final summary = _spendingReport!['summary'];
    final categoryBreakdown = _spendingReport!['categoryBreakdown'] as List;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Total Income', summary['totalIncome'], AppColors.income),
                const SizedBox(height: 12),
                _buildSummaryRow('Total Expense', summary['totalExpense'], AppColors.expense),
                const Divider(height: 24),
                _buildSummaryRow('Net Savings', summary['netSavings'],
                    summary['netSavings'] >= 0 ? AppColors.success : AppColors.danger),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Savings Rate'),
                    Text(
                      '${summary['savingsRate'].toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: summary['savingsRate'] >= 0 ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Avg. Daily Expense', style: TextStyle(color: Colors.grey.shade700)),
                    Text(
                      'RM ${summary['avgDailyExpense'].toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transaction Count', style: TextStyle(color: Colors.grey.shade700)),
                    Text(
                      '${summary['transactionCount']}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Category Breakdown
        const Text(
          'Category Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (categoryBreakdown.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('No expense data for this period')),
            ),
          )
        else
          ...categoryBreakdown.map((category) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category['category'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'RM ${category['amount'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: category['percentage'] / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.expense),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${category['count']} transactions',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${category['percentage'].toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildBudgetReportTab() {
    if (_budgetReport == null || (_budgetReport!['budgets'] as List).isEmpty) {
      return const Center(child: Text('No budget data available for this period'));
    }

    final summary = _budgetReport!['summary'];
    final budgets = _budgetReport!['budgets'] as List;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Summary
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Total Budgeted', summary['totalBudgeted'], AppColors.primary),
                const SizedBox(height: 12),
                _buildSummaryRow('Total Spent', summary['totalSpent'], AppColors.expense),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Adherence Rate'),
                    Text(
                      '${summary['adherenceRate'].toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: summary['adherenceRate'] >= 0 ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Monthly Budgets
        const Text(
          'Monthly Budgets',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...budgets.map((budget) {
          final percentage = budget['percentageUsed'];
          Color progressColor;
          if (percentage >= 100) {
            progressColor = AppColors.danger;
          } else if (percentage >= 80) {
            progressColor = AppColors.warning;
          } else {
            progressColor = AppColors.success;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatMonthYear(budget['monthYear']),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: budget['isOverBudget']
                              ? AppColors.danger.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          budget['isOverBudget'] ? 'Over Budget' : 'On Track',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: budget['isOverBudget'] ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (percentage / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RM ${budget['totalSpent'].toStringAsFixed(2)} / RM ${budget['totalBudget'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: progressColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryAnalysisTab() {
    if (_categoryAnalysis == null) {
      return const Center(child: Text('No category analysis available'));
    }

    final categories = _categoryAnalysis!['categories'] as List;
    if (categories.isEmpty) {
      return const Center(child: Text('No expense data for this period'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Expense',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${_categoryAnalysis!['totalExpense'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Category Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...categories.map((category) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              'RM ${category['total'].toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Average', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              'RM ${category['average'].toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Count', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              '${category['count']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Max', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              'RM ${category['max'].toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Min', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              'RM ${category['min'].toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('% of Total', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              '${category['percentage'].toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  String _formatMonthYear(String monthYear) {
    try {
      final date = DateTime.parse('$monthYear-01');
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return monthYear;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: _downloadCSV,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'transactions',
                child: Text('Export Transactions (CSV)'),
              ),
              const PopupMenuItem(
                value: 'spending_report',
                child: Text('Export Spending Report (CSV)'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: TabController(length: 3, vsync: this),
          onTap: (index) => setState(() => _selectedTab = index),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Spending'),
            Tab(text: 'Budget'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReports,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildPeriodSelector(),
                    Expanded(
                      child: TabBarView(
                        controller: TabController(length: 3, vsync: this, initialIndex: _selectedTab),
                        children: [
                          _buildSpendingReportTab(),
                          _buildBudgetReportTab(),
                          _buildCategoryAnalysisTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
