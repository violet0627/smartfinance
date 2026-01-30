import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../services/export_service.dart';
import '../../utils/colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'this_month';
  Map<String, dynamic>? _spendingReport;
  Map<String, dynamic>? _budgetReport;
  Map<String, dynamic>? _categoryAnalysis;
  bool _isLoading = false;
  String _error = '';
  int _selectedTab = 0;
  late TabController _tabController;

  // Helper function to safely convert dynamic values to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _exportToPDF(String type) async {
    if (_spendingReport == null && _budgetReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      String? filePath;
      if (type == 'spending') {
        if (_spendingReport != null) {
          filePath = await ExportService.exportReportToPDF(
            summary: _spendingReport!['summary'] ?? {},
            categoryBreakdown: _spendingReport!['categories'] != null
                ? List<Map<String, dynamic>>.from(_spendingReport!['categories'])
                : null,
            filename: 'spending_report_${_selectedPeriod}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
          );
        }
      } else if (type == 'budget') {
        if (_budgetReport != null) {
          filePath = await ExportService.exportBudgetReportToPDF(
            budgetData: _budgetReport!,
            filename: 'budget_report_${_selectedPeriod}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
          );
        }
      }

      // Close loading
      if (!mounted) return;
      Navigator.pop(context);

      if (filePath != null) {
        // Show success dialog with options
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exported ${type == "spending" ? "spending report" : "budget report"} to PDF'),
                const SizedBox(height: 8),
                Text(
                  'File: ${filePath!.split('/').last}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${ExportService.getFileSize(filePath!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await ExportService.shareFile(
                    filePath!,
                    subject: 'SmartFinance Report Export',
                  );
                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File shared successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export report'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingReportTab() {
    if (_spendingReport == null) {
      return _buildEmptyState(
        'No Spending Data',
        'Add some transactions to see your spending report',
        Icons.receipt_long_outlined,
      );
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
                _buildSummaryRow('Total Income', _toDouble(summary['totalIncome']), AppColors.income),
                const SizedBox(height: 12),
                _buildSummaryRow('Total Expense', _toDouble(summary['totalExpense']), AppColors.expense),
                const Divider(height: 24),
                _buildSummaryRow('Net Savings', _toDouble(summary['netSavings']),
                    _toDouble(summary['netSavings']) >= 0 ? AppColors.success : AppColors.danger),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Savings Rate'),
                    Text(
                      '${_toDouble(summary['savingsRate']).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _toDouble(summary['savingsRate']) >= 0 ? AppColors.success : AppColors.danger,
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
                      'RM ${_toDouble(summary['avgDailyExpense']).toStringAsFixed(2)}',
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

        // Pie Chart
        if (categoryBreakdown.isNotEmpty) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spending Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: categoryBreakdown.map<PieChartSectionData>((category) {
                          final percentage = _toDouble(category['percentage']);
                          final colors = [
                            AppColors.primary,
                            AppColors.expense,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                            Colors.amber,
                            Colors.pink,
                            Colors.indigo,
                          ];
                          final colorIndex = categoryBreakdown.indexOf(category) % colors.length;

                          return PieChartSectionData(
                            color: colors[colorIndex],
                            value: percentage,
                            title: '${percentage.toStringAsFixed(1)}%',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: categoryBreakdown.map<Widget>((category) {
                      final colors = [
                        AppColors.primary,
                        AppColors.expense,
                        Colors.orange,
                        Colors.purple,
                        Colors.teal,
                        Colors.amber,
                        Colors.pink,
                        Colors.indigo,
                      ];
                      final colorIndex = categoryBreakdown.indexOf(category) % colors.length;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colors[colorIndex],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            category['category'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Category Breakdown
        const Text(
          'Category Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (categoryBreakdown.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No expense data for this period',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
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
                          'RM ${_toDouble(category['amount']).toStringAsFixed(2)}',
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
                      value: _toDouble(category['percentage']) / 100,
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
                          '${_toDouble(category['percentage']).toStringAsFixed(1)}%',
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
      return _buildEmptyState(
        'No Budget Data',
        'Create a budget to track your spending against your goals',
        Icons.account_balance_wallet_outlined,
      );
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
                _buildSummaryRow('Total Budgeted', _toDouble(summary['totalBudgeted']), AppColors.primary),
                const SizedBox(height: 12),
                _buildSummaryRow('Total Spent', _toDouble(summary['totalSpent']), AppColors.expense),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Adherence Rate'),
                    Text(
                      '${_toDouble(summary['adherenceRate']).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _toDouble(summary['adherenceRate']) >= 0 ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Budget Distribution Pie Chart
        if (budgets.isNotEmpty && budgets.first['categories'] != null) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Budget Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: (budgets.first['categories'] as List).map<PieChartSectionData>((category) {
                          final totalBudget = _toDouble(summary['totalBudgeted']);
                          final categoryBudget = _toDouble(category['budget']);
                          final percentage = totalBudget > 0 ? (categoryBudget / totalBudget * 100) : 0.0;

                          final colors = [
                            AppColors.primary,
                            AppColors.success,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                            Colors.amber,
                            Colors.pink,
                            Colors.indigo,
                          ];
                          final colorIndex = (budgets.first['categories'] as List).indexOf(category) % colors.length;

                          return PieChartSectionData(
                            color: colors[colorIndex],
                            value: percentage.toDouble(),
                            title: '${percentage.toStringAsFixed(1)}%',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: (budgets.first['categories'] as List).map<Widget>((category) {
                      final colors = [
                        AppColors.primary,
                        AppColors.success,
                        Colors.orange,
                        Colors.purple,
                        Colors.teal,
                        Colors.amber,
                        Colors.pink,
                        Colors.indigo,
                      ];
                      final colorIndex = (budgets.first['categories'] as List).indexOf(category) % colors.length;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colors[colorIndex],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            category['categoryName'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

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
                    value: (_toDouble(percentage) / 100).clamp(0.0, 1.0),
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
                        'RM ${_toDouble(budget['totalSpent']).toStringAsFixed(2)} / RM ${_toDouble(budget['totalBudget']).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${_toDouble(percentage).toStringAsFixed(0)}%',
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
      return _buildEmptyState(
        'No Category Data',
        'Add expense transactions to see category analysis',
        Icons.pie_chart_outline,
      );
    }

    final categories = _categoryAnalysis!['categories'] as List;
    if (categories.isEmpty) {
      return _buildEmptyState(
        'No Expenses This Period',
        'No expense transactions found for the selected time period',
        Icons.category_outlined,
      );
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
                  'RM ${_toDouble(_categoryAnalysis!['totalExpense']).toStringAsFixed(2)}',
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
                              'RM ${_toDouble(category['total']).toStringAsFixed(2)}',
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
                              'RM ${_toDouble(category['average']).toStringAsFixed(2)}',
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
                              'RM ${_toDouble(category['max']).toStringAsFixed(2)}',
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
                              'RM ${_toDouble(category['min']).toStringAsFixed(2)}',
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
                              '${_toDouble(category['percentage']).toStringAsFixed(1)}%',
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
          'RM ${_toDouble(amount).toStringAsFixed(2)}',
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
          PopupMenuButton<Map<String, String>>(
            icon: const Icon(Icons.download),
            onSelected: (value) {
              final type = value['type']!;
              final format = value['format']!;
              if (format == 'csv') {
                _downloadCSV(type);
              } else {
                _exportToPDF(type);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: {'type': 'transactions', 'format': 'csv'},
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Transactions (CSV)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: {'type': 'spending_report', 'format': 'csv'},
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Spending Report (CSV)'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: {'type': 'spending', 'format': 'pdf'},
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Spending Report (PDF)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: {'type': 'budget', 'format': 'pdf'},
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Budget Report (PDF)'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
                        controller: _tabController,
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
