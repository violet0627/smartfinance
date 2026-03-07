// budget_overview_screen.dart
// This screen shows the current month's budget: total spent vs budget, days remaining,
// per-category breakdowns with progress bars, and alert cards for over-budget categories.
// Users can edit or delete the budget from the app bar menu, or create a new one.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:intl/intl.dart'; // DateFormat for formatting month/year strings
import '../../models/budget_model.dart'; // BudgetModel and BudgetCategoryModel data classes
import '../../services/api_service.dart'; // Backend API calls
import '../../services/notification_service.dart'; // Push notifications for budget alerts
import '../../utils/categories.dart'; // TransactionCategories for category icons/colors
import '../../utils/colors.dart'; // AppColors constants
import '../../widgets/budget_alert_card.dart'; // Widget that shows budget warning alerts
import 'create_budget_screen.dart'; // Screen for creating/editing budgets

// BudgetOverviewScreen shows the current budget status
class BudgetOverviewScreen extends StatefulWidget {
  const BudgetOverviewScreen({super.key});

  @override
  State<BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<BudgetOverviewScreen> {
  BudgetModel? _currentBudget; // The current month's budget data (null if no budget set)
  bool _isLoading = true;      // True while fetching budget data
  bool _hasBudget = false;     // False means no budget exists for this month

  @override
  void initState() {
    super.initState();
    _loadCurrentBudget(); // Load budget when screen opens
  }

  // _loadCurrentBudget fetches the current month's budget from the backend
  Future<void> _loadCurrentBudget() async {
    setState(() => _isLoading = true);

    try {
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final result = await ApiService.getCurrentBudget(userId);

      if (result['success'] && result['budget'] != null) {
        // BudgetModel.fromJson converts the API JSON response to a typed model object
        final budget = BudgetModel.fromJson(result['budget']);

        setState(() {
          _currentBudget = budget;
          _hasBudget = true;
        });

        // Check if any categories are over 80% used and send a push notification alert
        // Wrapped in try/catch so a notification failure doesn't crash the whole screen
        try {
          await NotificationService.checkBudgetAndAlert(budget);
        } catch (e) {
          print('Error checking budget alerts: $e'); // Debug log, not shown to user
        }
      } else {
        setState(() {
          _hasBudget = false; // No budget found for this month
        });
      }
    } catch (e) {
      print('Error loading budget: $e');
      setState(() {
        _hasBudget = false;
      });
    } finally {
      // 'finally' block always runs, whether the try succeeded or the catch ran
      // Ensures loading spinner always stops even if there's an error
      setState(() => _isLoading = false);
    }
  }

  // _getProgressColor returns a color based on how much budget has been used
  // Green (<80%), orange (80-99%), red (100%+ = over budget)
  Color _getProgressColor(double percentage) {
    if (percentage >= 100) return AppColors.danger;  // Over budget: red
    if (percentage >= 80) return AppColors.warning;  // Almost over: orange
    return AppColors.success;                        // Under 80%: green
  }

  // _showDeleteConfirmation asks for confirmation then deletes the current budget
  Future<void> _showDeleteConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: const Text(
          'Are you sure you want to delete this budget? '
          'This action cannot be undone.',
        ),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Proceed only if confirmed, and budget data is loaded with a valid ID
    if (confirm == true && _currentBudget != null && _currentBudget!.budgetId != null) {
      try {
        final result = await ApiService.deleteBudget(_currentBudget!.budgetId!);

        if (!mounted) return;

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadCurrentBudget(); // Refresh to show the "no budget" state
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to delete budget'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budget Overview'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Only show menu and add button when a budget exists
          if (_hasBudget)
            PopupMenuButton<String>(
              // PopupMenuButton shows a dropdown menu with options
              icon: const Icon(Icons.more_vert), // Three-dot menu icon
              onSelected: (value) async {
                if (value == 'edit') {
                  // Navigate to edit screen, then refresh on return
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateBudgetScreen(budget: _currentBudget), // Pass current budget
                    ),
                  );
                  _loadCurrentBudget();
                } else if (value == 'delete') {
                  _showDeleteConfirmation();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text('Edit Budget'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete Budget', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          if (_hasBudget)
            // "+" button to create a new budget (replaces current)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Create New Budget',
              onPressed: () async {
                // Warn user that creating a new budget replaces the current one
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Create New Budget?'),
                    content: const Text(
                      'Creating a new budget will replace your current budget. '
                      'You can only have one active budget at a time. Continue?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Create New'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateBudgetScreen(), // No budget = create new
                    ),
                  );
                  _loadCurrentBudget();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasBudget
              ? _buildNoBudgetState() // Show "create budget" prompt
              : RefreshIndicator(
                  onRefresh: _loadCurrentBudget,
                  child: SingleChildScrollView(
                    // AlwaysScrollableScrollPhysics ensures pull-to-refresh works
                    // even when content doesn't fill the screen
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(), // Top gradient card with totals
                        const SizedBox(height: 24),
                        // Budget alert widget shows warnings for categories near/over limit
                        BudgetAlertCard(budget: _currentBudget!),
                        // Add spacing after alerts only if there are alerts to show
                        if (_currentBudget!.percentageUsed >= 80 ||
                            _currentBudget!.categories.any((cat) => cat.percentageUsed >= 90))
                          const SizedBox(height: 24),
                        Text(
                          'Category Breakdown',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Build one card per budget category
                        ..._currentBudget!.categories.map((category) {
                          return _buildCategoryCard(category);
                        }).toList(),
                      ],
                    ),
                  ),
                ),
      // FAB: only shown when budget exists - refreshes the data
      floatingActionButton: !_hasBudget
          ? null
          : FloatingActionButton(
              onPressed: _loadCurrentBudget,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.refresh),
            ),
    );
  }

  // _buildNoBudgetState shows the empty state when no budget is set for this month
  Widget _buildNoBudgetState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Budget Set',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a budget to track your spending',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Full-width "Create Budget" button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateBudgetScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadCurrentBudget(); // Refresh when returning from create screen
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Create Budget',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildSummaryCard creates the large gradient card showing total spent/remaining/progress
  Widget _buildSummaryCard() {
    final budget = _currentBudget!; // '!' asserts non-null (we know it's set when this is called)
    final percentage = budget.percentageUsed; // e.g., 65.5 for 65.5% used
    final progressColor = _getProgressColor(percentage);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4), // Shadow below
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Month name and year (e.g., "March 2024")
              Text(
                // budget.monthYear is "2024-03"; append "-01" to make a valid date, then format
                DateFormat('MMMM yyyy').format(
                  DateTime.parse('${budget.monthYear}-01'),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Days remaining pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${budget.daysLeftInMonth} days left',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Spent and Remaining amounts side by side
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Spent',
                budget.totalSpent,
                Icons.arrow_upward,
              ),
              _buildSummaryItem(
                'Remaining',
                budget.totalRemaining,
                Icons.account_balance_wallet,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Overall Progress',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar: shows percentage of total budget used
          LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0), // .clamp prevents going above 1.0
            backgroundColor: Colors.white.withOpacity(0.3), // Semi-transparent track
            valueColor: AlwaysStoppedAnimation<Color>(progressColor), // Color by usage level
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% used',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'RM ${budget.totalBudget.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // Over-budget warning banner - only shown when over 100% used
          if (budget.isOverBudget) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      // '\\'' is an escaped apostrophe in string literals
                      // -budget.totalRemaining gives positive over-amount
                      'You\'ve exceeded your budget by RM ${(-budget.totalRemaining).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
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
    );
  }

  // _buildSummaryItem creates a label+amount pair in the summary card
  Widget _buildSummaryItem(String label, double amount, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // _buildCategoryCard creates one card per expense category showing spent vs allocated
  Widget _buildCategoryCard(BudgetCategoryModel category) {
    // Get the icon and color for this category from our utility class
    final categoryInfo = TransactionCategories.getCategoryInfo(
      category.categoryName,
      'expense',
    );
    final percentage = category.percentageUsed; // How much of this category's budget is used
    final progressColor = _getProgressColor(percentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Subtle shadow
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Category icon in a colored circle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryInfo.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryInfo.icon,
                  color: categoryInfo.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              // Category name and "spent of allocated" text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.categoryName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${category.spentAmount.toStringAsFixed(2)} of RM ${category.allocatedAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Percentage on the right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: progressColor, // Color changes with usage level
                    ),
                  ),
                  Text(
                    category.isOverBudget ? 'Over' : 'Remaining',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar for this category
          LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          // Over-budget warning text - only shown when category is over limit
          if (category.isOverBudget) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.danger, size: 16),
                const SizedBox(width: 4),
                Text(
                  // -category.remaining gives the positive over-budget amount
                  'Over budget by RM ${(-category.remaining).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
