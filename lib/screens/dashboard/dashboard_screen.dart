// ==============================================================================
// dashboard_screen.dart - Main Dashboard / Home Screen
// ==============================================================================
// This is the primary screen users see after logging in. It displays:
//
// - Personalized greeting (Good morning/afternoon/evening)
// - Email verification banner (if email not verified)
// - Financial summary cards (balance, income, expenses) with gradient styling
// - Budget progress card with progress bar and over-budget warning
// - Investment portfolio card with profit/loss display
// - Gamification card (level progress from LevelProgressWidget)
// - Goals progress card
// - Upcoming bills card (from recurring transactions)
// - Quick action grid (6 shortcuts to main features)
// - Recent transactions list (last 5 transactions)
// - Logout button
// - Bottom navigation bar (Home, Analytics, Budget, Portfolio)
//
// Data Loading:
// All data is loaded in _loadData() which fetches from multiple API endpoints.
// Each section has its own try-catch so a failure in one doesn't break others.
// Pull-to-refresh (RefreshIndicator) reloads all data.
// Shimmer skeletons are shown during loading.
//
// Usage: DashboardScreen() — navigated to after successful login
// ==============================================================================

import 'package:flutter/material.dart';                    // For StatefulWidget, Scaffold, etc.
import 'package:intl/intl.dart';                            // For DateFormat (date formatting)
import 'package:shared_preferences/shared_preferences.dart'; // For reading stored user data
import '../../models/transaction_model.dart';                // For TransactionModel
import '../../models/budget_model.dart';                     // For BudgetModel
import '../../models/investment_model.dart';                 // For PortfolioSummary
import '../../models/gamification_model.dart';               // For UserStats
import '../../services/api_service.dart';                    // For all API calls
import '../../services/notification_service.dart';           // For budget alerts and bill reminders
import '../../utils/categories.dart';                        // For TransactionCategories (icons/colors)
import '../../utils/colors.dart';                            // For AppColors
import '../../utils/investment_types.dart';                   // For InvestmentTypes icon helper
import '../../widgets/level_progress_widget.dart';           // For LevelProgressWidget (gamification)
import '../../widgets/goal_progress_card.dart';              // For GoalProgressCard
import '../../widgets/email_verification_banner.dart';       // For EmailVerificationBanner
import '../../widgets/shimmer_loading.dart';                  // For skeleton loading placeholders
import '../../widgets/dashboard_summary_card.dart';          // For AnimatedDashboardCard, QuickActionCard
import '../../utils/app_gradients.dart';                     // For gradient definitions
import '../auth/login_screen.dart';                          // For LoginScreen (logout destination)
import '../transactions/add_transaction_screen.dart';        // For AddTransactionScreen
import '../transactions/recurring_transactions_screen.dart'; // For RecurringTransactionsScreen (upcoming bills)
import '../transactions/transaction_history_screen.dart';    // For TransactionHistoryScreen
import '../budgets/budget_overview_screen.dart';             // For BudgetOverviewScreen
import '../budgets/create_budget_screen.dart';               // For CreateBudgetScreen
import '../investments/portfolio_overview_screen.dart';      // For PortfolioOverviewScreen
import '../analytics/analytics_screen.dart';                 // For AnalyticsScreen
import '../gamification/achievements_screen.dart';           // For AchievementsScreen
import '../reports/reports_screen.dart';                     // For ReportsScreen
import '../settings/settings_screen.dart';                   // For SettingsScreen
import '../goals/goals_screen.dart';                         // For GoalsScreen

// ==============================================================================
// DashboardScreen - StatefulWidget for Main Dashboard
// ==============================================================================
// StatefulWidget because it manages:
// - Multiple data objects fetched from APIs (transactions, budget, portfolio, etc.)
// - Loading state for shimmer skeletons
// - Bottom navigation bar selected index
// - User info (name, email, verification status)
// ==============================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;                          // Bottom nav bar selected tab index
  List<TransactionModel> _recentTransactions = []; // Last 5 transactions for display
  Map<String, dynamic>? _summary;                  // Financial summary (balance, income, expense)
  BudgetModel? _currentBudget;                     // Current month's budget (null if none)
  PortfolioSummary? _portfolio;                    // Investment portfolio summary
  UserStats? _userStats;                           // Gamification stats (level, XP, achievements)
  Map<String, dynamic>? _goalsSummary;             // Goals overview data
  List<Map<String, dynamic>> _upcomingBills = [];  // Upcoming recurring transactions
  bool _isLoading = true;                          // Whether data is being loaded (initial only)
  String _userName = '';                           // User's full name from SharedPreferences
  String _userEmail = '';                          // User's email for verification banner
  bool _emailVerified = true;                      // Default true to avoid flash of banner

  // ScrollController preserves the user's scroll position when returning from sub-screens.
  // Without this, every _loadData() rebuild would jump back to the top of the page.
  final ScrollController _scrollController = ScrollController();

  // ==============================================================================
  // _toDouble - Safely Convert Dynamic Values to Double
  // ==============================================================================
  // API responses may return numbers as int, double, String, or null.
  // This helper handles all cases to prevent type errors.
  // ==============================================================================
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;                 // null → 0.0
    if (value is num) return value.toDouble();     // int or double → double
    if (value is String) return double.tryParse(value) ?? 0.0;  // String → parse or 0.0
    return 0.0;                                    // Anything else → 0.0
  }

  // ==============================================================================
  // _getGreeting - Return Time-Appropriate Greeting
  // ==============================================================================
  // Returns "Good morning", "Good afternoon", or "Good evening" based on
  // the current hour of the day.
  // ==============================================================================
  String _getGreeting() {
    final hour = DateTime.now().hour;              // 0-23
    if (hour < 12) {
      return 'Good morning';                       // Before noon
    } else if (hour < 17) {
      return 'Good afternoon';                     // Noon to 5 PM
    } else {
      return 'Good evening';                       // After 5 PM
    }
  }

  // ==============================================================================
  // initState - Initialize Dashboard
  // ==============================================================================
  @override
  void initState() {
    super.initState();
    NotificationService.initialize();              // Set up local notifications
    _loadData();                                   // Fetch all dashboard data
  }

  // dispose() — free resources when this widget is removed from the widget tree
  @override
  void dispose() {
    _scrollController.dispose(); // Prevent memory leak from the ScrollController
    super.dispose();
  }

  // ==============================================================================
  // _loadData - Fetch All Dashboard Data from APIs
  // ==============================================================================
  // Loads data from multiple API endpoints. Each section is wrapped in its own
  // try-catch so that a failure in one (e.g., portfolio) doesn't prevent others
  // (e.g., transactions) from loading.
  //
  // Called on:
  // - Initial load (initState)
  // - Pull-to-refresh (RefreshIndicator)
  // - Returning from other screens (.then((_) => _loadData(silent: true)))
  // ==============================================================================
  // silent: true = refresh data in the background without showing the loading skeleton.
  // Used when returning from sub-screens so the scroll position is preserved.
  // silent: false (default) = show skeleton on first load and pull-to-refresh.
  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true); // Show shimmer only on initial/pull-refresh

    try {
      // Get the current user's ID from stored JWT token
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;                                    // No user logged in
      }

      // Get user name from SharedPreferences (saved during login)
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('userFullName') ?? 'User';
      });

      // --- Load Recent Transactions ---
      try {
        final transactionsResult = await ApiService.getUserTransactions(
          userId,
          limit: 5,                                // Only get the 5 most recent
        );

        if (transactionsResult['success']) {
          final transactionsList = transactionsResult['transactions'] as List;
          setState(() {
            // Convert each JSON map to a TransactionModel object
            _recentTransactions = transactionsList
                .map((json) => TransactionModel.fromJson(json))
                .toList();
          });
        }
      } catch (e) {
        debugPrint('Error loading transactions: $e');   // Log but don't crash
      }

      // --- Load Financial Summary (balance, total income, total expense) ---
      try {
        final summaryResult = await ApiService.getTransactionSummary(userId);
        if (summaryResult['success']) {
          setState(() {
            _summary = summaryResult;
          });
        }
      } catch (e) {
        debugPrint('Error loading summary: $e');
      }

      // --- Load Current Month's Budget ---
      try {
        final budgetResult = await ApiService.getCurrentBudget(userId);
        if (budgetResult['success'] && budgetResult['budget'] != null) {
          final budget = BudgetModel.fromJson(budgetResult['budget']);
          setState(() {
            _currentBudget = budget;
          });

          // Send budget alerts for critical situations (over budget or 90%+ used)
          if (budget.isOverBudget || budget.percentageUsed >= 90) {
            await NotificationService.checkBudgetAndAlert(budget);
          }
        }
      } catch (e) {
        debugPrint('Error loading budget: $e');
      }

      // --- Load Investment Portfolio Summary ---
      try {
        final portfolioResult = await ApiService.getPortfolioSummary(userId);
        if (portfolioResult['success'] && portfolioResult['portfolio'] != null) {
          setState(() {
            _portfolio = PortfolioSummary.fromJson(portfolioResult['portfolio']);
          });
        }
      } catch (e) {
        debugPrint('Error loading portfolio: $e');
      }

      // --- Load Gamification Stats (level, XP, achievements) ---
      try {
        final statsResult = await ApiService.getUserStats(userId);
        if (statsResult['success'] && statsResult['stats'] != null) {
          setState(() {
            _userStats = UserStats.fromJson(statsResult['stats']);
          });
        }
      } catch (e) {
        debugPrint('Error loading stats: $e');
      }

      // --- Load Goals Summary ---
      try {
        final goalsResult = await ApiService.getGoalsSummary(userId);
        if (goalsResult['success']) {
          setState(() {
            _goalsSummary = goalsResult['summary'];
          });
        }
      } catch (e) {
        debugPrint('Error loading goals: $e');
      }

      // --- Load Upcoming Bills (from recurring transactions) ---
      try {
        final recurringResult = await ApiService.getRecurringTransactions(userId);
        if (recurringResult['success']) {
          // Convert to List<Map<String, dynamic>> for the notification service
          final recurringList = List<Map<String, dynamic>>.from(recurringResult['recurring'] ?? []);
          // Filter to only upcoming (due within 7 days)
          final upcomingReminders = await NotificationService.getUpcomingReminders(recurringList);
          setState(() {
            _upcomingBills = upcomingReminders;
          });
        }
      } catch (e) {
        debugPrint('Error loading recurring transactions: $e');
      }

      // --- Check Email Verification Status ---
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
        debugPrint('Error checking email verification: $e');
      }
    } catch (e) {
      print('Error in _loadData: $e');             // Catch-all for unexpected errors
    } finally {
      // Always stop the loading spinner (only matters when silent: false)
      // "finally" runs whether try succeeded or catch was triggered
      if (!silent) setState(() => _isLoading = false);
    }
  }

  // ==============================================================================
  // _handleLogout - Show Confirmation Dialog and Log Out
  // ==============================================================================
  // Shows an AlertDialog asking the user to confirm logout.
  // If confirmed, calls ApiService.logout() to clear the JWT token,
  // then navigates to LoginScreen (replacing the current route).
  // ==============================================================================
  Future<void> _handleLogout() async {
    // showDialog<bool> returns the value passed to Navigator.pop()
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),   // Cancel → return false
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),    // Confirm → return true
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,              // Red button for destructive action
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.logout();                   // Clear stored token and user data
      if (!mounted) return;
      // Navigate to login, replacing the dashboard (can't go back)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ==============================================================================
  // build - Render the Dashboard Screen UI
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,       // Light grey background

      // --- App Bar ---
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,                              // No shadow under the app bar
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Settings gear icon in the top-right
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Navigate to settings, reload data when returning
              // .then() is called when the user comes back from SettingsScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _loadData(silent: true));
            },
          ),
        ],
      ),

      // --- Body: Loading Skeletons or Dashboard Content ---
      body: _isLoading
          // Show shimmer skeleton placeholders while loading
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skeleton for the greeting text
                  SkeletonBox(
                    width: 200,
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 24),
                  const DashboardCardSkeleton(),    // Skeleton for a card
                  const SizedBox(height: 24),
                  const DashboardCardSkeleton(),
                  const SizedBox(height: 24),
                  const DashboardCardSkeleton(),
                ],
              ),
            )
          // RefreshIndicator wraps the content for pull-to-refresh
          : RefreshIndicator(
              onRefresh: _loadData,                // Pull down to reload all data (shows skeleton)
              child: SingleChildScrollView(
                // AlwaysScrollableScrollPhysics ensures pull-to-refresh works
                // even when content fits on screen
                controller: _scrollController,     // Preserves scroll position across silent refreshes
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Personalized Greeting ---
                    // Shows "Good morning, John!" using the first name only
                    Text(
                      '${_getGreeting()}, ${_userName.split(' ')[0]}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // --- Email Verification Banner ---
                    // Only shown if email is not verified
                    if (!_emailVerified && _userEmail.isNotEmpty) ...[
                      // FutureBuilder to get the userId asynchronously
                      FutureBuilder<int?>(
                        future: ApiService.getCurrentUserId(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return EmailVerificationBanner(
                              userId: snapshot.data!,
                              email: _userEmail,
                              onVerified: _loadData,   // Reload after verification
                            );
                          }
                          return const SizedBox.shrink();  // Empty widget if no userId
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- Financial Summary Section ---
                    Text(
                      'Financial Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Balance Card (full width, primary gradient)
                    AnimatedDashboardCard(
                      title: 'Current Balance',
                      amount: 'RM ${_toDouble(_summary?['balance'] ?? 0).toStringAsFixed(2)}',
                      subtitle: 'Total available funds',
                      icon: Icons.account_balance_wallet,
                      gradient: AppGradients.balanceCardGradient,
                    ),
                    const SizedBox(height: 16),

                    // Income and Expense Cards (side by side)
                    Row(
                      children: [
                        // Income Card (left half)
                        Expanded(
                          child: AnimatedDashboardCard(
                            title: 'Income',
                            amount: 'RM ${_toDouble(_summary?['totalIncome'] ?? 0).toStringAsFixed(2)}',
                            icon: Icons.trending_up,
                            gradient: AppGradients.incomeCardGradient,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Expense Card (right half)
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

                    // --- Budget Progress Card (conditional) ---
                    // Only shown if the user has a budget set up
                    if (_currentBudget != null) ...[
                      _buildBudgetCard(),
                      const SizedBox(height: 24),
                    ],

                    // --- Investment Portfolio Card (conditional) ---
                    // Only shown if the user has investments and the portfolio isn't empty
                    if (_portfolio != null && !_portfolio!.isEmpty) ...[
                      _buildPortfolioCard(),
                      const SizedBox(height: 24),
                    ],

                    // --- Gamification Progress Card (conditional) ---
                    // Only shown if user stats are loaded
                    if (_userStats != null) ...[
                      _buildGamificationCard(),
                      const SizedBox(height: 24),
                    ],

                    // --- Goals Progress Card (conditional) ---
                    // Only shown if the user has at least one goal
                    if (_goalsSummary != null && _goalsSummary!['totalGoals'] > 0) ...[
                      GoalProgressCard(
                        summary: _goalsSummary!,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GoalsScreen()),
                          ).then((_) => _loadData(silent: true));
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- Upcoming Bills Card (conditional) ---
                    // Only shown if there are upcoming recurring transactions
                    if (_upcomingBills.isNotEmpty) ...[
                      _buildUpcomingBillsCard(),
                      const SizedBox(height: 24),
                    ],

                    // --- Quick Actions Grid ---
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Row 1: Add Transaction + History
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            title: 'Add Transaction',
                            icon: Icons.add_circle,
                            color: AppColors.primary,
                            onTap: () async {
                              // Navigate to add transaction, reload if added successfully
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddTransactionScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadData(silent: true); // Refresh without scroll reset
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
                              ).then((_) => _loadData(silent: true));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 2: Analytics + Budget
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            title: 'Analytics',
                            icon: Icons.bar_chart,
                            color: const Color(0xFF7C3AED),    // Violet — distinct from primary purple-blue
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
                            color: const Color(0xFFFF9800),    // Orange
                            onTap: () {
                              // Navigate to overview if budget exists, create screen if not
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _currentBudget != null
                                      ? const BudgetOverviewScreen()
                                      : const CreateBudgetScreen(),
                                ),
                              ).then((_) => _loadData(silent: true));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 3: Reports + Portfolio
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            title: 'Reports',
                            icon: Icons.description,
                            color: const Color(0xFF00BCD4),    // Cyan
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
                            color: const Color(0xFF4CAF50),    // Green
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PortfolioOverviewScreen(),
                                ),
                              ).then((_) => _loadData(silent: true));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 4: Goals + Achievements
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            title: 'Goals',
                            icon: Icons.flag,
                            color: const Color(0xFFDB2777),    // Rose/Pink — aspirational, unique
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GoalsScreen(),
                                ),
                              ).then((_) => _loadData(silent: true));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            title: 'Achievements',
                            icon: Icons.emoji_events,
                            color: const Color(0xFFD97706),    // Amber/Gold — fitting for achievements
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AchievementsScreen(),
                                ),
                              ).then((_) => _loadData(silent: true));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Recent Transactions Section ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        // "View All" link (only if there are transactions)
                        if (_recentTransactions.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TransactionHistoryScreen(),
                                ),
                              ).then((_) => _loadData(silent: true));
                            },
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Transaction list or empty state
                    _recentTransactions.isEmpty
                        // Empty state: icon + message + CTA button
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 56,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No transactions yet',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap below to record your first transaction',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  // CTA button — gives user a clear next action
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AddTransactionScreen(),
                                        ),
                                      );
                                      if (result == true) _loadData(silent: true);
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Transaction'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        // Transaction cards list
                        : Column(
                            // .map() transforms each TransactionModel into a card widget
                            children: _recentTransactions.map((transaction) {
                              // Get icon and color for the transaction's category
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
                                    // Category icon with colored background
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
                                    // Category name and date
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
                                    // Amount (red for expense, green for income)
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

                    // --- Logout Button ---
                    SizedBox(
                      width: double.infinity,          // Full width button
                      child: ElevatedButton(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,   // Red for destructive action
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

      // --- Bottom Navigation Bar ---
      // Provides tab navigation between Home, Analytics, Budget, and Portfolio
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,              // Highlighted tab
        onTap: (index) async {
          setState(() => _selectedIndex = index);
          // Navigate to the appropriate screen based on the tapped tab
          switch (index) {
            case 0:
              // Home tab — already on dashboard, do nothing
              break;
            case 1:
              // Analytics tab
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnalyticsScreen(),
                ),
              );
              // Reset to home tab when returning from analytics
              setState(() => _selectedIndex = 0);
              break;
            case 2:
              // Budget tab — shows overview or create screen
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _currentBudget != null
                      ? const BudgetOverviewScreen()
                      : const CreateBudgetScreen(),
                ),
              );
              _loadData(silent: true);              // Refresh without scroll reset
              setState(() => _selectedIndex = 0);  // Reset to home tab
              break;
            case 3:
              // Portfolio tab
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PortfolioOverviewScreen(),
                ),
              );
              _loadData(silent: true);
              setState(() => _selectedIndex = 0);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,       // Fixed tabs (no shifting animation)
        selectedItemColor: AppColors.primary,      // Purple for selected tab
        unselectedItemColor: Colors.grey,          // Grey for unselected tabs
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

  // ==============================================================================
  // _buildBudgetCard - Monthly Budget Progress Card
  // ==============================================================================
  // Displays the current month's budget with:
  // - Month name and percentage badge
  // - Spent vs remaining amounts
  // - Linear progress bar (green < 80%, orange < 100%, red >= 100%)
  // - Total budget and days remaining
  // - Over-budget warning banner (if applicable)
  // Tapping navigates to BudgetOverviewScreen.
  // ==============================================================================
  Widget _buildBudgetCard() {
    final budget = _currentBudget!;                // ! asserts budget is not null
    final percentage = budget.percentageUsed;       // How much of the budget is used

    // Choose progress bar color based on usage percentage
    Color progressColor;
    if (percentage >= 100) {
      progressColor = AppColors.danger;            // Red: over budget
    } else if (percentage >= 80) {
      progressColor = AppColors.warning;           // Orange: approaching limit
    } else {
      progressColor = AppColors.success;           // Green: healthy spending
    }

    return GestureDetector(
      onTap: () {
        // Navigate to budget overview when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BudgetOverviewScreen(),
          ),
        ).then((_) => _loadData(silent: true));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),   // Subtle shadow
              blurRadius: 10,
              offset: const Offset(0, 4),              // Shadow below the card
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: month name + percentage badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  // Parse the monthYear string ("2025-01") to get the month name
                  '${DateFormat('MMMM').format(DateTime.parse('${budget.monthYear}-01'))} Budget',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                // Percentage badge (pill-shaped)
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

            // Spent vs Remaining amounts
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
                        // Red if over budget, green if under
                        color: budget.isOverBudget ? AppColors.danger : AppColors.income,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar showing budget usage
            LinearProgressIndicator(
              // .clamp(0.0, 1.0) ensures value stays between 0% and 100%
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),

            // Footer: total budget and days remaining
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

            // Over-budget warning (only shown when budget is exceeded)
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
                        // Negate totalRemaining to show positive overspend amount
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

  // ==============================================================================
  // _buildPortfolioCard - Investment Portfolio Summary Card
  // ==============================================================================
  // Displays the investment portfolio with:
  // - Title and percentage change badge (+/- with color)
  // - Current portfolio value
  // - Total profit or loss amount
  // - Total invested and asset count
  // Tapping navigates to PortfolioOverviewScreen.
  // ==============================================================================
  Widget _buildPortfolioCard() {
    final portfolio = _portfolio!;
    // Green for profit, red for loss
    final profitColor = portfolio.isProfit ? AppColors.success : AppColors.danger;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PortfolioOverviewScreen(),
          ),
        ).then((_) => _loadData(silent: true));
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
            // Header: title + percentage change badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Investment Portfolio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                // Percentage change badge with up/down arrow icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: profitColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        // Get appropriate icon (up/down/neutral arrow) based on change
                        InvestmentTypes.getIconForPerformance(portfolio.percentageChange),
                        size: 14,
                        color: profitColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        // Show "+" prefix for positive changes
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

            // Current value and profit/loss
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
                      // .abs() shows absolute value (remove negative sign for losses)
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

            // Footer: total invested and asset count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Invested: RM ${portfolio.totalInvested.toStringAsFixed(2)}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Text(
                  // Pluralize "asset" → "assets" if more than 1
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

  // ==============================================================================
  // _buildGamificationCard - User Progress / Gamification Card
  // ==============================================================================
  // Displays the user's gamification progress (level, XP) using the
  // LevelProgressWidget in compact mode. Tapping navigates to AchievementsScreen.
  // ==============================================================================
  Widget _buildGamificationCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AchievementsScreen(),
          ),
        ).then((_) => _loadData(silent: true));
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
                // Forward arrow indicating tappable card
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 16),
            // Compact level progress widget showing level badge and XP bar
            LevelProgressWidget(
              stats: _userStats!,
              compact: true,                       // Compact mode for dashboard
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================================
  // _buildUpcomingBillsCard - Upcoming Bills / Recurring Transactions Card
  // ==============================================================================
  // Displays up to 3 upcoming recurring transactions (bills) with:
  // - Bill name and icon (income/expense arrow)
  // - Due date countdown (highlighted red if due within 3 days)
  // - Amount and exact due date
  // - "View all" link if more than 3 bills
  // ==============================================================================
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
          // Header: bell icon + title + count badge
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
              // Badge showing number of upcoming bills
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

          // Bill list (max 3 items)
          ListView.separated(
            shrinkWrap: true,                      // Don't take infinite height
            physics: const NeverScrollableScrollPhysics(),  // Disable scrolling (parent scrolls)
            itemCount: _upcomingBills.length > 3 ? 3 : _upcomingBills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bill = _upcomingBills[index];
              final daysUntil = bill['daysUntil'] as int;          // Days until due
              final nextExecution = bill['nextExecution'] as DateTime;
              final amount = (bill['amount'] ?? 0.0).toDouble();
              final type = bill['type']?.toString() ?? 'expense';
              final isIncome = type.toLowerCase() == 'income';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  // Red border if due within 3 days (urgent)
                  border: Border.all(
                    color: daysUntil <= 3 ? AppColors.danger.withOpacity(0.3) : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Income/expense direction icon
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

                    // Bill name and due date countdown
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
                            overflow: TextOverflow.ellipsis,   // Truncate long names
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                // Red clock icon if due within 3 days
                                color: daysUntil <= 3 ? AppColors.danger : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                // Human-readable due date text
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

                    // Amount and date
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

          // "View all" link (only shown if more than 3 upcoming bills)
          if (_upcomingBills.length > 3) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to recurring transactions screen
                  // Use direct push — named routes are not registered in main.dart
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecurringTransactionsScreen(),
                    ),
                  ).then((_) => _loadData(silent: true));
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
