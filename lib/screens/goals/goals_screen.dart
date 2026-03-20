// goals_screen.dart
// This screen shows all financial goals (e.g., save for a house, build emergency fund).
// It shows a summary card at the top, filter chips (All/Active/Completed), and goal cards.
// Each goal card has a progress bar, amounts, deadline, priority badge, and contribute button.
// Swiping left on a goal card deletes it.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:intl/intl.dart'; // NumberFormat for comma-separated currency, DateFormat for dates
import '../../services/api_service.dart'; // Backend API calls
import '../../utils/colors.dart'; // AppColors constants
import 'add_goal_screen.dart'; // Screen for adding/editing goals

// GoalsScreen is a StatefulWidget because filter selection, data, and loading state change
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Map<String, dynamic>> _goals = []; // Goals list loaded from API
  Map<String, dynamic>? _summary;         // Summary stats (total goals, progress, amounts)
  bool _isLoading = true;                 // True while loading data
  String _selectedFilter = 'all';         // 'all', 'active', or 'completed'

  @override
  void initState() {
    super.initState();
    _loadData(); // Load goals and summary when screen opens
  }

  // _loadData fetches goals and the summary in parallel using Future.wait
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Future.wait runs multiple async operations at the same time and waits for ALL to complete
    // This is faster than running them sequentially (one after the other)
    final results = await Future.wait([
      // Pass null for status when filter is 'all' (returns all goals regardless of status)
      ApiService.getUserGoals(userId, status: _selectedFilter == 'all' ? null : _selectedFilter),
      ApiService.getGoalsSummary(userId),
    ]);

    setState(() {
      // results[0] is from getUserGoals, results[1] is from getGoalsSummary
      if (results[0]['success']) {
        _goals = List<Map<String, dynamic>>.from(results[0]['goals']);
      }
      if (results[1]['success']) {
        _summary = results[1]['summary'];
      }
      _isLoading = false;
    });
  }

  // _deleteGoal permanently removes a goal by goalId after confirmation
  // Called by confirmDismiss inside _buildGoalCard after the user confirms the dialog
  Future<bool> _deleteGoal(int goalId, String goalName) async {
    final result = await ApiService.deleteGoal(goalId);
    if (!mounted) return false;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData(); // Refresh the list to update summary stats
      return true; // Signal Dismissible to remove the card from view
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to delete goal'),
          backgroundColor: AppColors.danger,
        ),
      );
      return false; // Keep the card — deletion failed
    }
  }

  // _showContributeDialog shows an AlertDialog for adding money to a goal
  // StatefulBuilder is used so the dialog can show its own loading state
  Future<void> _showContributeDialog(Map<String, dynamic> goal) async {
    final amountController = TextEditingController();
    final remainingAmount = (goal['remainingAmount'] ?? 0).toDouble();
    bool isLoading = false; // Local state just for this dialog

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        // StatefulBuilder provides a local setState (setDialogState) inside the dialog
        // This lets us update the dialog's UI (e.g., show a spinner) without rebuilding the whole screen
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Contribution'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Dialog only as tall as its content
            children: [
              Text(
                goal['goalName'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Remaining: RM ${remainingAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (RM)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
                enabled: !isLoading, // Disable input while API call is in progress
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  // 'this.context' refers to the GoalsScreen's context, not the dialog's context
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }

                setDialogState(() => isLoading = true); // Show spinner in dialog button

                final result = await ApiService.contributeToGoal(goal['goalId'], amount);

                setDialogState(() => isLoading = false);

                Navigator.pop(dialogContext); // Close the dialog

                if (!this.mounted) return; // 'this.mounted' checks the GoalsScreen widget

                if (result['success']) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Contribution added successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadData(); // Refresh goals to show updated amounts
                } else {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(result['error'] ?? 'Failed to add contribution'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              // Show a small spinner in the button while the API call is in progress
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Add button in app bar
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddGoalScreen()),
              ).then((_) => _loadData()); // .then() runs after the push resolves (user came back)
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData, // Pull-to-refresh
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary card - only shown when summary data is available
                  if (_summary != null) _buildSummaryCard(),
                  const SizedBox(height: 16),

                  // Filter chips row: All / Active / Completed
                  Row(
                    children: [
                      _buildFilterChip('all', 'All', Icons.list),
                      const SizedBox(width: 8),
                      _buildFilterChip('active', 'Active', Icons.flag),
                      const SizedBox(width: 8),
                      _buildFilterChip('completed', 'Completed', Icons.check_circle),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Goals list or empty state
                  if (_goals.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              // Show different icon based on which filter is active
                              _selectedFilter == 'completed' ? Icons.check_circle_outline : Icons.flag_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              // Context-aware empty message
                              _selectedFilter == 'all'
                                  ? 'No goals yet'
                                  : _selectedFilter == 'active'
                                      ? 'No active goals'
                                      : 'No completed goals',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFilter == 'all'
                                  ? 'Start by adding your first financial goal'
                                  : _selectedFilter == 'active'
                                      ? 'All your goals are completed!'
                                      : 'Complete some goals to see them here',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                              textAlign: TextAlign.center,
                            ),
                            // Only show add button in empty state when no filter is applied
                            if (_selectedFilter == 'all') ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AddGoalScreen()),
                                  ).then((_) => _loadData());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Goal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    // '...' spread operator expands the list of goal cards into the parent ListView
                    ..._goals.map((goal) => _buildGoalCard(goal)),
                ],
              ),
            ),
      // Floating action button for adding a new goal
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddGoalScreen()),
          ).then((_) => _loadData());
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // _buildSummaryCard creates the gradient overview card at the top
  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Gradient background: primary color fading slightly
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'Goals Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Three stats: Active goals count, Completed count, Overall progress %
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Active',
                  _summary!['activeGoals'].toString(),
                  Icons.flag,
                ),
                _buildSummaryItem(
                  'Completed',
                  _summary!['completedGoals'].toString(),
                  Icons.check_circle,
                ),
                _buildSummaryItem(
                  'Progress',
                  '${_summary!['overallProgress'].toStringAsFixed(0)}%',
                  Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Total saved vs target row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Semi-transparent white box
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Saved',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      Text(
                        // NumberFormat('#,##0.00') formats as "1,234.56" (with comma separators)
                        'RM ${NumberFormat('#,##0.00').format(_summary!['totalSavedAmount'])}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Target',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      Text(
                        'RM ${NumberFormat('#,##0.00').format(_summary!['totalTargetAmount'])}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildSummaryItem creates one stat item (icon + value + label) for the summary card
  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  // _buildFilterChip creates one filter option (All/Active/Completed)
  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value; // Update filter
        });
        _loadData(); // Reload with new filter applied
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  // _buildGoalCard creates the card for a single goal
  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final progressPercentage = goal['progressPercentage'] ?? 0.0; // 0-100
    final daysRemaining = goal['daysRemaining'] ?? 0;
    final isOverdue = goal['isOverdue'] ?? false;
    final isCompleted = goal['status'] == 'completed';

    // Priority color: red=high, orange=medium, green=low
    Color priorityColor = Colors.grey;
    if (goal['priority'] == 'high') priorityColor = Colors.red;
    if (goal['priority'] == 'medium') priorityColor = Colors.orange;
    if (goal['priority'] == 'low') priorityColor = Colors.green;

    // Progress bar color changes based on how much progress has been made
    Color progressColor = AppColors.success; // Green for 80%+
    if (progressPercentage < 50) progressColor = AppColors.danger;      // Red for < 50%
    else if (progressPercentage < 80) progressColor = AppColors.warning; // Orange for 50-79%

    return Dismissible(
      // Dismissible enables swipe-to-delete on the card
      key: Key(goal['goalId'].toString()), // Unique key required for Dismissible
      background: Container(
        // Red delete background visible while swiping
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,  // Delete icon on the right
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      direction: DismissDirection.endToStart, // Only allow swipe from right to left
      // confirmDismiss shows the dialog BEFORE removing the card from the UI.
      // This is the correct pattern: onDismissed fires AFTER the item is gone,
      // making cancellation impossible. confirmDismiss returns true to confirm
      // removal, or false to snap the card back into place.
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Goal'),
            // Name the specific goal so the user knows exactly what they're deleting
            content: Text('Delete "${goal['goalName']}"? This cannot be undone.'),
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
        if (confirmed != true) return false; // User cancelled — snap the card back
        // Call the API to delete, returns true on success (removes card), false on failure (keeps card)
        return _deleteGoal(goal['goalId'], goal['goalName'] as String);
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          // Tapping the card navigates to the edit screen
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddGoalScreen(existingGoal: goal), // Pass goal for pre-filling
              ),
            ).then((_) => _loadData()); // Refresh after editing
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Goal name + priority badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        goal['goalName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Priority badge (LOW/MEDIUM/HIGH)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        goal['priority'].toUpperCase(), // Convert to uppercase
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                // Optional description (capped at 2 lines)
                if (goal['description'] != null && goal['description'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    goal['description'],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // Show "..." if too long
                  ),
                ],
                const SizedBox(height: 12),

                // Progress bar with percentage
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressPercentage / 100, // Convert % to 0.0-1.0
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? AppColors.success : progressColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${progressPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom row: amounts (left) and deadline (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // "RM 500.00 / RM 10,000.00" format
                          'RM ${NumberFormat('#,##0.00').format(goal['currentAmount'])} / RM ${NumberFormat('#,##0.00').format(goal['targetAmount'])}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Remaining: RM ${NumberFormat('#,##0.00').format(goal['remainingAmount'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              // Red calendar icon if overdue
                              color: isOverdue ? AppColors.danger : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCompleted
                                  ? 'Completed'
                                  : isOverdue
                                      ? 'Overdue'
                                      : '$daysRemaining days left',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? AppColors.success  // Green for completed
                                    : isOverdue
                                        ? AppColors.danger // Red for overdue
                                        : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // Format deadline date from "2024-12-31" to "Dec 31, 2024"
                          DateFormat('MMM dd, yyyy').format(DateTime.parse(goal['deadline'])),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // "Add Contribution" button - only shown for active (not completed) goals
                if (goal['status'] == 'active') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showContributeDialog(goal),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Add Contribution'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
