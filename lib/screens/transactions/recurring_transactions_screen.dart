import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/colors.dart';
import 'add_recurring_transaction_screen.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  List<Map<String, dynamic>> _recurringList = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRecurringTransactions();
  }

  Future<void> _loadRecurringTransactions() async {
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

      final result = await ApiService.getRecurringTransactions(userId);

      if (result['success']) {
        final recurringList = List<Map<String, dynamic>>.from(result['recurring'] ?? []);
        setState(() {
          _recurringList = recurringList;
          _isLoading = false;
        });

        // Schedule notifications for all active recurring transactions
        NotificationService.scheduleAllRecurringReminders(recurringList);
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to load recurring transactions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTransaction(int recurringId, bool currentStatus) async {
    final result = await ApiService.toggleRecurringTransaction(recurringId);

    if (result['success']) {
      _loadRecurringTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['isActive'] ? 'Activated' : 'Paused'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to toggle'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _executeNow(int recurringId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Execute Now'),
        content: Text('Create transaction for "$name" now?'),
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
            child: const Text('Execute'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ApiService.executeRecurringTransaction(recurringId);

      if (!mounted) return;
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Transaction created!'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadRecurringTransactions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to execute'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteTransaction(int recurringId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction'),
        content: Text('Delete "$name"? This cannot be undone.'),
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
      final result = await ApiService.deleteRecurringTransaction(recurringId);

      if (!mounted) return;
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring transaction deleted'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadRecurringTransactions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to delete'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return frequency;
    }
  }

  Color _getTypeColor(String type) {
    return type.toLowerCase() == 'income' ? AppColors.income : AppColors.expense;
  }

  Icon _getCategoryIcon(String category) {
    final iconMap = {
      'salary': Icons.work,
      'freelance': Icons.computer,
      'business': Icons.business,
      'investment': Icons.trending_up,
      'food': Icons.restaurant,
      'transport': Icons.directions_car,
      'utilities': Icons.electric_bolt,
      'rent': Icons.home,
      'entertainment': Icons.movie,
      'shopping': Icons.shopping_bag,
      'healthcare': Icons.medical_services,
      'education': Icons.school,
    };

    final icon = iconMap[category.toLowerCase()] ?? Icons.attach_money;
    return Icon(icon, size: 24);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () async {
              await NotificationService.sendTestNotification();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test notification sent!'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Test Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecurringTransactions,
            tooltip: 'Refresh',
          ),
        ],
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
                        onPressed: _loadRecurringTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _recurringList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.repeat, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No Recurring Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Automate your regular income and expenses',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddRecurringTransactionScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadRecurringTransactions();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Recurring Transaction'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRecurringTransactions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _recurringList.length,
                        itemBuilder: (context, index) {
                          final recurring = _recurringList[index];
                          final isActive = recurring['isActive'] == true || recurring['isActive'] == 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Opacity(
                              opacity: isActive ? 1.0 : 0.6,
                              child: InkWell(
                                onTap: () {
                                  _showRecurringDetails(recurring);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: _getTypeColor(recurring['transactionType'] ?? 'expense')
                                                  .withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: _getCategoryIcon(recurring['category'] ?? ''),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  recurring['name'] ?? 'Unnamed',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getTypeColor(recurring['transactionType'] ?? '')
                                                            .withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        recurring['category'] ?? 'Other',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: _getTypeColor(recurring['transactionType'] ?? ''),
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.info.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        _getFrequencyLabel(recurring['frequency'] ?? ''),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors.info,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            'RM ${(recurring['amount'] ?? 0.0).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: _getTypeColor(recurring['transactionType'] ?? ''),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (recurring['description'] != null && recurring['description'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          recurring['description'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Next: ${_formatDate(recurring['nextExecution'])}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? AppColors.success.withOpacity(0.1)
                                                  : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isActive ? Icons.check_circle : Icons.pause_circle,
                                                  size: 14,
                                                  color: isActive ? AppColors.success : Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isActive ? 'Active' : 'Paused',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isActive ? AppColors.success : Colors.grey.shade600,
                                                  ),
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
                                            child: OutlinedButton.icon(
                                              onPressed: recurring['recurringId'] != null
                                                  ? () => _executeNow(
                                                        recurring['recurringId'] as int,
                                                        recurring['name'] ?? '',
                                                      )
                                                  : null,
                                              icon: const Icon(Icons.play_arrow, size: 16),
                                              label: const Text('Execute Now'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.primary,
                                                side: const BorderSide(color: AppColors.primary),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: recurring['recurringId'] != null
                                                  ? () => _toggleTransaction(
                                                        recurring['recurringId'] as int,
                                                        isActive,
                                                      )
                                                  : null,
                                              icon: Icon(isActive ? Icons.pause : Icons.play_circle, size: 16),
                                              label: Text(isActive ? 'Pause' : 'Resume'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: isActive ? Colors.orange : AppColors.success,
                                                side: BorderSide(
                                                  color: isActive ? Colors.orange : AppColors.success,
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: recurring['recurringId'] != null
                                                ? () => _deleteTransaction(
                                                      recurring['recurringId'] as int,
                                                      recurring['name'] ?? '',
                                                    )
                                                : null,
                                            icon: const Icon(Icons.delete_outline, size: 20),
                                            color: AppColors.danger,
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: _recurringList.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddRecurringTransactionScreen(),
                  ),
                );
                if (result == true) {
                  _loadRecurringTransactions();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Recurring'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _showRecurringDetails(Map<String, dynamic> recurring) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  recurring['name'] ?? 'Unnamed',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _detailRow('Type', recurring['transactionType'] ?? 'N/A'),
                _detailRow('Category', recurring['category'] ?? 'N/A'),
                _detailRow('Amount', 'RM ${(recurring['amount'] ?? 0.0).toStringAsFixed(2)}'),
                _detailRow('Frequency', _getFrequencyLabel(recurring['frequency'] ?? '')),
                _detailRow('Start Date', _formatDate(recurring['startDate'])),
                _detailRow('End Date', recurring['endDate'] != null ? _formatDate(recurring['endDate']) : 'No end date'),
                _detailRow('Next Execution', _formatDate(recurring['nextExecution'])),
                _detailRow('Last Executed', recurring['lastExecuted'] != null ? _formatDate(recurring['lastExecuted']) : 'Never'),
                if (recurring['description'] != null && recurring['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recurring['description'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
