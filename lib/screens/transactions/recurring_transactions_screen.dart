// recurring_transactions_screen.dart
// This screen shows all recurring transactions (like monthly rent, weekly salary, etc.).
// Each recurring item shows name, category, frequency, amount, next execution date, and status.
// Users can: execute a transaction now, pause/resume it, delete it, and view full details.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:intl/intl.dart'; // Date formatting
import '../../services/api_service.dart'; // Backend API calls
import '../../services/notification_service.dart'; // Scheduling reminders for upcoming transactions
import '../../utils/colors.dart'; // AppColors constants
import 'add_recurring_transaction_screen.dart'; // Screen for adding new recurring transactions

// RecurringTransactionsScreen is a StatefulWidget because data loads and updates dynamically
class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  // List of recurring transaction maps from the API
  // Each map contains keys like 'name', 'amount', 'frequency', 'isActive', etc.
  List<Map<String, dynamic>> _recurringList = [];
  bool _isLoading = true; // True while fetching data
  String _error = '';     // Error message; empty = no error

  @override
  void initState() {
    super.initState();
    _loadRecurringTransactions(); // Load data when screen opens
  }

  // _loadRecurringTransactions fetches all recurring transactions for the current user
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
        // List.from() converts the raw API list to a typed List<Map<String, dynamic>>
        // The '?? []' means "use empty list if result['recurring'] is null"
        final recurringList = List<Map<String, dynamic>>.from(result['recurring'] ?? []);
        setState(() {
          _recurringList = recurringList;
          _isLoading = false;
        });

        // Schedule local device notifications for all active recurring transactions
        // so users get reminders when transactions are about to be executed
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

  // _toggleTransaction activates or pauses a recurring transaction
  // recurringId: the database ID of the transaction to toggle
  // currentStatus: current active state (true = active, false = paused)
  // Shows a confirmation dialog before toggling — prevents accidental pausing of critical bills
  Future<void> _toggleTransaction(int recurringId, bool currentStatus) async {
    // Show confirmation dialog before making the irreversible toggle
    // This prevents accidental pausing of critical payments like rent or salary
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // Dialog title changes based on whether we're pausing or resuming
        title: Text(currentStatus ? 'Pause Transaction?' : 'Resume Transaction?'),
        content: Text(
          currentStatus
              ? 'This transaction will stop executing on its scheduled dates until you resume it.'
              : 'This transaction will resume on its next scheduled date.',
        ),
        actions: [
          // Cancel — do nothing
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          // Confirm — orange for pause (caution), green for resume
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? Colors.orange : AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(currentStatus ? 'Pause' : 'Resume'),
          ),
        ],
      ),
    );

    // User cancelled — do nothing
    if (confirmed != true) return;

    final result = await ApiService.toggleRecurringTransaction(recurringId);

    if (result['success']) {
      if (!mounted) return; // Check before calling setState inside _loadRecurringTransactions
      _loadRecurringTransactions(); // Refresh list to show updated status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // result['isActive'] is the new state after toggling
          content: Text(result['isActive'] ? 'Transaction resumed' : 'Transaction paused'),
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

  // _executeNow manually triggers a recurring transaction immediately
  // (Creates one transaction instance now instead of waiting for the scheduled time)
  Future<void> _executeNow(int recurringId, String name) async {
    // Ask the user to confirm before executing
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Execute Now'),
        content: Text('Create transaction for "$name" now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Execute'),
          ),
        ],
      ),
    );

    // Only proceed if the user pressed 'Execute' (confirmed == true)
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
        _loadRecurringTransactions(); // Refresh to show updated nextExecution date
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

  // _deleteTransaction permanently removes a recurring transaction after confirmation
  Future<void> _deleteTransaction(int recurringId, String name) async {
    // Confirm deletion - this action cannot be undone
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
              backgroundColor: AppColors.danger, // Red button for destructive action
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
        _loadRecurringTransactions(); // Refresh the list after deletion
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

  // _formatDate converts an ISO date string to a human-readable format
  // Returns 'N/A' if the date is null; returns the original string if parsing fails
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr); // Parse "2024-03-15" into DateTime
      return DateFormat('MMM dd, yyyy').format(date); // Format as "Mar 15, 2024"
    } catch (e) {
      return dateStr; // Return original string if parsing fails
    }
  }

  // _getFrequencyLabel converts API frequency values to display-friendly labels
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
        return frequency; // Return original if unknown
    }
  }

  // _getTypeColor returns green for income transactions, red for expenses
  Color _getTypeColor(String type) {
    return type.toLowerCase() == 'income' ? AppColors.income : AppColors.expense;
  }

  // _getCategoryIcon returns an appropriate icon for a given category name
  Icon _getCategoryIcon(String category) {
    // Map of category keywords to Material icons
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

    // .toLowerCase() for case-insensitive matching; ?? provides fallback icon
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
          // Test notification button - sends a test push notification
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
          // Refresh button to manually reload the list
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
              // Error state with retry button
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRecurringTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _recurringList.isEmpty
                  // Empty state with call-to-action button
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
                              // Navigate to add screen; refresh if new item was added
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
                  // List state - show all recurring transactions
                  : RefreshIndicator(
                      // Pull-to-refresh reloads the list
                      onRefresh: _loadRecurringTransactions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _recurringList.length,
                        itemBuilder: (context, index) {
                          final recurring = _recurringList[index]; // Current item's data
                          // Check isActive - API returns bool or 1/0 integer
                          final isActive = recurring['isActive'] == true || recurring['isActive'] == 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Opacity(
                              // Paused transactions are shown at 60% opacity to indicate inactive state
                              opacity: isActive ? 1.0 : 0.6,
                              child: InkWell(
                                // Tapping the card opens the detail bottom sheet
                                onTap: () {
                                  _showRecurringDetails(recurring);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top row: icon, name/category/frequency, amount
                                      Row(
                                        children: [
                                          // Category icon in colored circle
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
                                          // Name, category badge, and frequency badge
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
                                                    // Category badge pill
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
                                                    // Frequency badge pill
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
                                          // Amount on the right - colored by type (green/red)
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
                                      // Optional description text
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
                                      // Next execution date and Active/Paused status badge
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
                                          const Spacer(), // Push status badge to the right
                                          // Active/Paused status indicator
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
                                      // Action buttons row: Execute Now, Pause/Resume, Delete
                                      Row(
                                        children: [
                                          // Execute Now button
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              // Disable button if recurringId is null (shouldn't happen)
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
                                          // Pause/Resume button - label and color change based on state
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
                                                // Orange for pause (caution), green for resume
                                                foregroundColor: isActive ? Colors.orange : AppColors.success,
                                                side: BorderSide(
                                                  color: isActive ? Colors.orange : AppColors.success,
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Delete button (icon only)
                                          IconButton(
                                            onPressed: recurring['recurringId'] != null
                                                ? () => _deleteTransaction(
                                                      recurring['recurringId'] as int,
                                                      recurring['name'] ?? '',
                                                    )
                                                : null,
                                            icon: const Icon(Icons.delete_outline, size: 20),
                                            color: AppColors.danger, // Red delete icon
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
      // FAB only shows when there are existing recurring transactions
      // (empty state has its own button; FAB would be redundant there)
      floatingActionButton: _recurringList.isNotEmpty
          ? FloatingActionButton.extended(
              // FloatingActionButton.extended has both an icon and a text label
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
          : null, // null = no FAB shown when the list is empty
    );
  }

  // _showRecurringDetails displays a bottom sheet with full details of a recurring transaction
  void _showRecurringDetails(Map<String, dynamic> recurring) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the sheet to take more than half the screen
      shape: const RoundedRectangleBorder(
        // Rounded top corners for the bottom sheet
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        // DraggableScrollableSheet allows the bottom sheet to be resized by dragging
        initialChildSize: 0.6, // Opens at 60% of screen height
        minChildSize: 0.4,     // Minimum height: 40%
        maxChildSize: 0.9,     // Maximum height: 90%
        expand: false, // Don't expand to fill parent by default
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController, // Connect scrolling to the DraggableScrollableSheet
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle - small grey pill at the top of the bottom sheet
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
                // Detail rows showing all properties
                _detailRow('Type', recurring['transactionType'] ?? 'N/A'),
                _detailRow('Category', recurring['category'] ?? 'N/A'),
                _detailRow('Amount', 'RM ${(recurring['amount'] ?? 0.0).toStringAsFixed(2)}'),
                _detailRow('Frequency', _getFrequencyLabel(recurring['frequency'] ?? '')),
                _detailRow('Start Date', _formatDate(recurring['startDate'])),
                _detailRow('End Date', recurring['endDate'] != null ? _formatDate(recurring['endDate']) : 'No end date'),
                _detailRow('Next Execution', _formatDate(recurring['nextExecution'])),
                _detailRow('Last Executed', recurring['lastExecuted'] != null ? _formatDate(recurring['lastExecuted']) : 'Never'),
                // Optional description section
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

  // _detailRow creates a label-value pair row for the details bottom sheet
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top for multi-line values
        children: [
          SizedBox(
            width: 120, // Fixed width for labels to keep values aligned
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded( // Expanded lets the value text use remaining width
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
