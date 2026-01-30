import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import 'add_goal_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Map<String, dynamic>> _goals = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, active, completed

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final results = await Future.wait([
      ApiService.getUserGoals(userId, status: _selectedFilter == 'all' ? null : _selectedFilter),
      ApiService.getGoalsSummary(userId),
    ]);

    setState(() {
      if (results[0]['success']) {
        _goals = List<Map<String, dynamic>>.from(results[0]['goals']);
      }
      if (results[1]['success']) {
        _summary = results[1]['summary'];
      }
      _isLoading = false;
    });
  }

  Future<void> _deleteGoal(int goalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
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

    if (confirmed == true) {
      final result = await ApiService.deleteGoal(goalId);
      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to delete goal'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showContributeDialog(Map<String, dynamic> goal) async {
    final amountController = TextEditingController();
    final remainingAmount = (goal['remainingAmount'] ?? 0).toDouble();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Contribution'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                enabled: !isLoading,
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
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }

                setDialogState(() => isLoading = true);

                final result = await ApiService.contributeToGoal(goal['goalId'], amount);

                setDialogState(() => isLoading = false);

                Navigator.pop(dialogContext);

                if (!this.mounted) return;

                if (result['success']) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Contribution added successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadData();
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
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddGoalScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary Card
                  if (_summary != null) _buildSummaryCard(),
                  const SizedBox(height: 16),

                  // Filter Chips
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

                  // Goals List
                  if (_goals.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFilter == 'completed' ? Icons.check_circle_outline : Icons.flag_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
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
                    ..._goals.map((goal) => _buildGoalCard(goal)),
                ],
              ),
            ),
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

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
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
          _selectedFilter = value;
        });
        _loadData();
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final progressPercentage = goal['progressPercentage'] ?? 0.0;
    final daysRemaining = goal['daysRemaining'] ?? 0;
    final isOverdue = goal['isOverdue'] ?? false;
    final isCompleted = goal['status'] == 'completed';

    Color priorityColor = Colors.grey;
    if (goal['priority'] == 'high') priorityColor = Colors.red;
    if (goal['priority'] == 'medium') priorityColor = Colors.orange;
    if (goal['priority'] == 'low') priorityColor = Colors.green;

    Color progressColor = AppColors.success;
    if (progressPercentage < 50) progressColor = AppColors.danger;
    else if (progressPercentage < 80) progressColor = AppColors.warning;

    return Dismissible(
      key: Key(goal['goalId'].toString()),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteGoal(goal['goalId']),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddGoalScreen(existingGoal: goal),
              ),
            ).then((_) => _loadData());
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        goal['priority'].toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (goal['description'] != null && goal['description'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    goal['description'],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),

                // Progress Bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressPercentage / 100,
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

                // Amount and Deadline
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                                    ? AppColors.success
                                    : isOverdue
                                        ? AppColors.danger
                                        : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
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

                // Contribute Button (only for active goals)
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
