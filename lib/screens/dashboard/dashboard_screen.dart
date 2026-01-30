import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';
import '../../models/investment_model.dart';
import '../../models/gamification_model.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/categories.dart';
import '../../utils/colors.dart';
import '../../utils/investment_types.dart';
import '../../widgets/level_progress_widget.dart';
import '../../widgets/goal_progress_card.dart';
import '../../widgets/email_verification_banner.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/dashboard_summary_card.dart';
import '../../utils/app_gradients.dart';
import '../auth/login_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transaction_history_screen.dart';
import '../budgets/budget_overview_screen.dart';
import '../budgets/create_budget_screen.dart';
import '../investments/portfolio_overview_screen.dart';
import '../analytics/analytics_screen.dart';
import '../gamification/achievements_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../goals/goals_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<TransactionModel> _recentTransactions = [];
  Map<String, dynamic>? _summary;
  BudgetModel? _currentBudget;
  PortfolioSummary? _portfolio;
  UserStats? _userStats;
  Map<String, dynamic>? _goalsSummary;
  List<Map<String, dynamic>> _upcomingBills = [];
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  bool _emailVerified = true; // Default to true to avoid showing banner unnecessarily

  // Helper function to safely convert dynamic values to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Get time-appropriate greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get user name from shared preferences
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('userFullName') ?? 'User';
      });

      // Load recent transactions
      try {
        final transactionsResult = await ApiService.getUserTransactions(
          userId,
          limit: 5,
        );

        if (transactionsResult['success']) {
          final transactionsList = transactionsResult['transactions'] as List;
          setState(() {
            _recentTransactions = transactionsList
                .map((json) => TransactionModel.fromJson(json))
                .toList();
          });
        }
      } catch (e) {
        print('Error loading transactions: $e');
      }

      // Load summary
      try {
        final summaryResult = await ApiService.getTransactionSummary(userId);
        if (summaryResult['success']) {
          setState(() {
            _summary = summaryResult;
          });
        }
      } catch (e) {
        print('Error loading summary: $e');
      }

      // Load current budget
      try {
        final budgetResult = await ApiService.getCurrentBudget(userId);
        if (budgetResult['success'] && budgetResult['budget'] != null) {
          final budget = BudgetModel.fromJson(budgetResult['budget']);
          setState(() {
            _currentBudget = budget;
          });

          // Check budget and send alerts if needed (only for critical alerts on dashboard)
          if (budget.isOverBudget || budget.percentageUsed >= 90) {
            await NotificationService.checkBudgetAndAlert(budget);
          }
        }
      } catch (e) {
        print('Error loading budget: $e');
      }

      // Load portfolio summary
      try {
        final portfolioResult = await ApiService.getPortfolioSummary(userId);
        if (portfolioResult['success'] && portfolioResult['portfolio'] != null) {
          setState(() {
            _portfolio = PortfolioSummary.fromJson(portfolioResult['portfolio']);
          });
        }
      } catch (e) {
        print('Error loading portfolio: $e');
      }

      // Load user stats (gamification)
      try {
        final statsResult = await ApiService.getUserStats(userId);
        if (statsResult['success'] && statsResult['stats'] != null) {
          setState(() {
            _userStats = UserStats.fromJson(statsResult['stats']);
          });
        }
      } catch (e) {
        print('Error loading stats: $e');
      }

      // Load goals summary
      try {
        final goalsResult = await ApiService.getGoalsSummary(userId);
        if (goalsResult['success']) {
          setState(() {
            _goalsSummary = goalsResult['summary'];
          });
        }
      } catch (e) {
        print('Error loading goals: $e');
      }

      // Load recurring transactions for upcoming bills
      try {
        final recurringResult = await ApiService.getRecurringTransactions(userId);
        if (recurringResult['success']) {
          final recurringList = List<Map<String, dynamic>>.from(recurringResult['recurring'] ?? []);
          final upcomingReminders = await NotificationService.getUpcomingReminders(recurringList);
          setState(() {
            _upcomingBills = upcomingReminders;
          });
        }
      } catch (e) {
        print('Error loading recurring transactions: $e');
      }

      // Check email verification status
      try {
        final userEmail = prefs.getString('userEmail') ?? '';
        final verificationResult = await ApiService.checkVerificationStatus(userId);

        setState(() {
          _userEmail = userEmail;
          if (verificationResult['success']) {
            _emailVerified = verificationResult['emailVerified'] ?? true;
          }
        });
      } catch (e) {
        print('Error checking email verification: $e');
      }
    } catch (e) {
      print('Error in _loadData: $e');
    } finally {
      // Always stop loading, even if there's an error
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                    width: 200,
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 24),
                  const DashboardCardSkeleton(),
                  const SizedBox(height: 24),
                  const DashboardCardSkeleton(),
                  const SizedBox(height: 24),
                  const DashboardCardSkeleton(),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, ${_userName.split(' ')[0]}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Email Verification Banner
                    if (!_emailVerified && _userEmail.isNotEmpty) ...[
                      FutureBuilder<int?>(
                        future: ApiService.getCurrentUserId(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return EmailVerificationBanner(
                              userId: snapshot.data!,
                              email: _userEmail,
                              onVerified: _loadData,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Financial Summary with Beautiful Gradient Cards
                    Text(
                      'Financial Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Balance Card (Primary)
                    AnimatedDashboardCard(
                      title: 'Current Balance',
                      amount: 'RM ${_toDouble(_summary?['balance'] ?? 0).toStringAsFixed(2)}',
                      subtitle: 'Total available funds',
                      icon: Icons.account_balance_wallet,
                      gradient: AppGradients.balanceCardGradient,
                    ),
                    const SizedBox(height: 16),
                    // Income and Expense Row
                    Row(
                      children: [
                        // Income Card
                        Expanded(
                          child: AnimatedDashboardCard(
                            title: 'Income',
                            amount: 'RM ${_toDouble(_summary?['totalIncome'] ?? 0).toStringAsFixed(2)}',
                            icon: Icons.trending_up,
                            gradient: AppGradients.incomeCardGradient,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Expense Card
                        Expanded(
                          child: AnimatedDashboardCard(
                            title: 'Expenses',
                            amount: 'RM ${_toDouble(_summary?['totalExpense'] ?? 0).toStringAsFixed(2)}',
                            icon: Icons.trending_down,
                            gradient: AppGradients.expenseCardGradient,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Budget Progress Card
                    if (_currentBudget != null) ...[
                      _buildBudgetCard(),
                      const SizedBox(height: 24),
                    ],
                    // Investment Portfolio Card
                    if (_portfolio != null && !_portfolio!.isEmpty) ...[
                      _buildPortfolioCard(),
                      const SizedBox(height: 24),
                    ],
                    // Gamification Card
                    if (_userStats != null) ...[
                      _buildGamificationCard(),
                      const SizedBox(height: 24),
                    ],
                    // Goals Card
                    if (_goalsSummary != null && _goalsSummary!['totalGoals'] > 0) ...[
                      GoalProgressCard(
                        summary: _goalsSummary!,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GoalsScreen()),
                          ).then((_) => _loadData());
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Upcoming Bills Card
                    if (_upcomingBills.isNotEmpty) ...[
                      _buildUpcomingBillsCard(),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            title: 'Add Transaction',
                            icon: Icons.add_circle,
                            color: AppColors.primary,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddTransactionScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadData();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            title: 'History',
                            icon: Icons.history,
                            color: AppColors.secondary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TransactionHistoryScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            title: 'Analytics',
                            icon: Icons.bar_chart,
                            color: const Color(0xFF9C27B0),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AnalyticsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            title: 'Budget',
                            icon: Icons.account_balance_wallet,
                            color: const Color(0xFFFF9800),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _currentBudget != null
                                      ? const BudgetOverviewScreen()
                                      : const CreateBudgetScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            title: 'Reports',
                            icon: Icons.description,
                            color: const Color(0xFF00BCD4),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReportsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            title: 'Portfolio',
                            icon: Icons.trending_up,
                            color: const Color(0xFF4CAF50),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PortfolioOverviewScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            title: 'Goals',
                            icon: Icons.flag,
                            color: const Color(0xFF9C27B0),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GoalsScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            title: 'Achievements',
                            icon: Icons.emoji_events,
                            color: const Color(0xFFFF9800),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AchievementsScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (_recentTransactions.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TransactionHistoryScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _recentTransactions.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No transactions yet',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: _recentTransactions.map((transaction) {
                              final categoryInfo = TransactionCategories.getCategoryInfo(
                                transaction.category,
                                transaction.transactionType,
                              );
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: categoryInfo.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        categoryInfo.icon,
                                        color: categoryInfo.color,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction.category,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('dd MMM yyyy')
                                                .format(transaction.transactionDate),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${transaction.isExpense ? "-" : "+"}RM ${transaction.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: transaction.isExpense
                                            ? AppColors.expense
                                            : AppColors.income,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) async {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              // Navigate to Analytics
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnalyticsScreen(),
                ),
              );
              // Reset to home when returning
              setState(() => _selectedIndex = 0);
              break;
            case 2:
              // Navigate to Budget
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _currentBudget != null
                      ? const BudgetOverviewScreen()
                      : const CreateBudgetScreen(),
                ),
              );
              _loadData();
              // Reset to home when returning
              setState(() => _selectedIndex = 0);
              break;
            case 3:
              // Navigate to Portfolio/Investments
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PortfolioOverviewScreen(),
                ),
              );
              _loadData();
              // Reset to home when returning
              setState(() => _selectedIndex = 0);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Portfolio',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'RM ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard() {
    final budget = _currentBudget!;
    final percentage = budget.percentageUsed;

    Color progressColor;
    if (percentage >= 100) {
      progressColor = AppColors.danger;
    } else if (percentage >= 80) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.success;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BudgetOverviewScreen(),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('MMMM').format(DateTime.parse('${budget.monthYear}-01'))} Budget',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      'RM ${budget.totalSpent.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      'RM ${budget.totalRemaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: budget.isOverBudget ? AppColors.danger : AppColors.income,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RM ${budget.totalBudget.toStringAsFixed(2)} total',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Text(
                  '${budget.daysLeftInMonth} days left',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            if (budget.isOverBudget) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Over budget by RM ${(-budget.totalRemaining).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard() {
    final portfolio = _portfolio!;
    final profitColor = portfolio.isProfit ? AppColors.success : AppColors.danger;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PortfolioOverviewScreen(),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Investment Portfolio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: profitColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        InvestmentTypes.getIconForPerformance(portfolio.percentageChange),
                        size: 14,
                        color: profitColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${portfolio.percentageChange > 0 ? "+" : ""}${portfolio.percentageChange.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: profitColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Value',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      'RM ${portfolio.currentValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      portfolio.isProfit ? 'Total Profit' : 'Total Loss',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      'RM ${portfolio.totalProfitLoss.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: profitColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Invested: RM ${portfolio.totalInvested.toStringAsFixed(2)}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Text(
                  '${portfolio.totalAssets} ${portfolio.totalAssets > 1 ? "assets" : "asset"}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AchievementsScreen(),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 16),
            LevelProgressWidget(
              stats: _userStats!,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBillsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Bills',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_upcomingBills.length}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _upcomingBills.length > 3 ? 3 : _upcomingBills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bill = _upcomingBills[index];
              final daysUntil = bill['daysUntil'] as int;
              final nextExecution = bill['nextExecution'] as DateTime;
              final amount = (bill['amount'] ?? 0.0).toDouble();
              final type = bill['type']?.toString() ?? 'expense';
              final isIncome = type.toLowerCase() == 'income';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: daysUntil <= 3 ? AppColors.danger.withOpacity(0.3) : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isIncome ? AppColors.income : AppColors.expense).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? AppColors.income : AppColors.expense,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill['name'] ?? 'Unnamed',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: daysUntil <= 3 ? AppColors.danger : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                daysUntil == 0
                                    ? 'Due today'
                                    : daysUntil == 1
                                        ? 'Due tomorrow'
                                        : 'Due in $daysUntil days',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: daysUntil <= 3 ? AppColors.danger : Colors.grey.shade600,
                                  fontWeight: daysUntil <= 3 ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RM ${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isIncome ? AppColors.income : AppColors.expense,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd').format(nextExecution),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          if (_upcomingBills.length > 3) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to recurring transactions screen
                  Navigator.pushNamed(context, '/recurring-transactions').then((_) => _loadData());
                },
                child: Text(
                  'View all ${_upcomingBills.length} upcoming bills',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
