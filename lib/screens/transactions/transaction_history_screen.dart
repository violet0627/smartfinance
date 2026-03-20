// ==============================================================================
// transaction_history_screen.dart - Transaction History with Search & Filters
// ==============================================================================
// This screen displays the user's full transaction history with powerful
// search, filter, and sort capabilities.
//
// Features:
// - Search bar (searches by category name and description)
// - Filter chips (All / Income / Expenses)
// - Advanced filters (date range, amount range, specific categories)
// - Sort options (by date or amount, ascending or descending)
// - Swipe-to-delete (Dismissible widget)
// - Tap to edit (navigates to AddTransactionScreen in edit mode)
// - CSV export functionality
// - Pull-to-refresh (RefreshIndicator)
// - Floating action button to add new transactions
// - Empty state with contextual messages
// - Shimmer loading skeletons while loading
//
// Navigation:
// - Accessed from: DashboardScreen (quick action or "View All" link)
// - Navigates to: AddTransactionScreen (edit/add), RecurringTransactionsScreen
//
// Usage: TransactionHistoryScreen() — shows all transactions for current user
// ==============================================================================

import 'package:flutter/material.dart';                    // For StatefulWidget, ListView, etc.
import 'package:intl/intl.dart';                            // For DateFormat (date formatting)
import '../../models/transaction_model.dart';               // For TransactionModel
import '../../services/api_service.dart';                    // For API calls (get, delete transactions)
import '../../services/export_service.dart';                 // For CSV export functionality
import '../../utils/categories.dart';                        // For TransactionCategories (icons/colors)
import '../../utils/colors.dart';                            // For AppColors
import '../../widgets/shimmer_loading.dart';                  // For TransactionListSkeleton
import 'add_transaction_screen.dart';                        // For AddTransactionScreen (edit/add)
import 'recurring_transactions_screen.dart';                 // For RecurringTransactionsScreen

// ==============================================================================
// TransactionHistoryScreen - StatefulWidget for Transaction List
// ==============================================================================
// StatefulWidget because it manages:
// - Two lists: all transactions and filtered transactions
// - Search query, filter type, sort order
// - Advanced filter state (dates, amounts, categories)
// - Loading state
// ==============================================================================
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<TransactionModel> _transactions = [];           // All transactions from API
  List<TransactionModel> _filteredTransactions = [];   // Transactions after filters applied
  bool _isLoading = true;                              // Whether initial data is loading
  String _filterType = 'all';                          // Current filter: 'all', 'income', 'expense'

  // --- Search and Filter State ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';                            // Current search text (lowercased)
  String _sortBy = 'date_desc';                        // Sort order key
  DateTime? _startDate;                                // Start of date range filter (null = no filter)
  DateTime? _endDate;                                  // End of date range filter
  double _minAmount = 0;                               // Minimum amount filter
  double _maxAmount = 10000;                           // Maximum amount filter
  List<String> _selectedCategories = [];               // Category filter list (empty = all)
  bool _hasActiveFilters = false;                      // Whether any non-default filters are active

  // ==============================================================================
  // initState - Set Up Search Listener and Load Data
  // ==============================================================================
  @override
  void initState() {
    super.initState();
    // addListener calls _onSearchChanged every time the search text changes
    _searchController.addListener(_onSearchChanged);
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==============================================================================
  // _onSearchChanged - Handle Search Text Changes
  // ==============================================================================
  // Called automatically when the user types in the search bar.
  // Updates the search query and re-applies all filters.
  // ==============================================================================
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFiltersAndSort();
    });
  }

  // ==============================================================================
  // _loadTransactions - Fetch Transactions from API
  // ==============================================================================
  // Loads transactions from the server. If a filter type is active (income/expense),
  // only that type is requested from the API. After loading, applies local filters.
  // ==============================================================================
  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    // API call with optional type filter
    final result = await ApiService.getUserTransactions(
      userId,
      type: _filterType == 'all' ? null : _filterType,
    );

    if (result['success']) {
      final transactionsList = result['transactions'] as List;
      setState(() {
        // Convert JSON list to TransactionModel list
        _transactions = transactionsList
            .map((json) => TransactionModel.fromJson(json))
            .toList();
        _applyFiltersAndSort();                    // Apply local filters and sorting
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // ==============================================================================
  // _applyFiltersAndSort - Apply All Local Filters and Sorting
  // ==============================================================================
  // Filters the master _transactions list based on:
  // 1. Search query (category name or description)
  // 2. Date range (start date to end date)
  // 3. Amount range (min to max)
  // 4. Selected categories
  // Then sorts the result based on the current sort order.
  // Also updates _hasActiveFilters flag for the UI clear button.
  // ==============================================================================
  void _applyFiltersAndSort() {
    // Start with a copy of all transactions
    List<TransactionModel> filtered = List.from(_transactions);

    // Filter 1: Search query (case-insensitive)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.category.toLowerCase().contains(_searchQuery) ||
            (t.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Filter 2: Date range
    if (_startDate != null) {
      filtered = filtered.where((t) =>
        !t.transactionDate.isBefore(_startDate!)   // On or after start date
      ).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((t) =>
        !t.transactionDate.isAfter(_endDate!)      // On or before end date
      ).toList();
    }

    // Filter 3: Amount range
    filtered = filtered.where((t) =>
      t.amount >= _minAmount && t.amount <= _maxAmount
    ).toList();

    // Filter 4: Specific categories
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((t) =>
        _selectedCategories.contains(t.category)
      ).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'date_desc':
        // Newest first (default)
        filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
        break;
      case 'date_asc':
        // Oldest first
        filtered.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
        break;
      case 'amount_desc':
        // Highest amount first
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        // Lowest amount first
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    // Check if any filters are active (for showing "Clear" button)
    _hasActiveFilters = _searchQuery.isNotEmpty ||
        _startDate != null ||
        _endDate != null ||
        _minAmount > 0 ||
        _maxAmount < 10000 ||
        _selectedCategories.isNotEmpty ||
        _sortBy != 'date_desc';

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  // ==============================================================================
  // _clearFilters - Reset All Filters to Defaults
  // ==============================================================================
  void _clearFilters() {
    setState(() {
      _searchController.clear();                   // Clear search text
      _searchQuery = '';
      _startDate = null;                           // Remove date range
      _endDate = null;
      _minAmount = 0;                              // Reset amount range
      _maxAmount = 10000;
      _selectedCategories.clear();                 // Clear category selections
      _sortBy = 'date_desc';                       // Reset to default sort
      _applyFiltersAndSort();
    });
  }

  // ==============================================================================
  // _showFilterDialog - Show Advanced Filters Bottom Sheet
  // ==============================================================================
  // Opens a modal bottom sheet with date range pickers, amount range slider,
  // and category filter chips.
  // ==============================================================================
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,                    // Allow sheet to be tall
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  // ==============================================================================
  // _showSortDialog - Show Sort Options Dialog
  // ==============================================================================
  // Shows an AlertDialog with radio buttons for the four sort options.
  // ==============================================================================
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('Date (Newest First)', 'date_desc'),
            _buildSortOption('Date (Oldest First)', 'date_asc'),
            _buildSortOption('Amount (Highest First)', 'amount_desc'),
            _buildSortOption('Amount (Lowest First)', 'amount_asc'),
          ],
        ),
      ),
    );
  }

  // ==============================================================================
  // _buildSortOption - Reusable Radio Button for Sort Dialog
  // ==============================================================================
  // Creates a RadioListTile that updates the sort order when tapped.
  // ==============================================================================
  Widget _buildSortOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,                                // This option's sort key
      groupValue: _sortBy,                         // Currently selected sort key
      onChanged: (v) {
        setState(() => _sortBy = v!);              // Update sort order
        _applyFiltersAndSort();                    // Re-sort the list
        Navigator.pop(context);                    // Close the dialog
      },
      activeColor: AppColors.primary,
    );
  }

  // ==============================================================================
  // _deleteTransaction - Delete a Transaction via API
  // ==============================================================================
  // Calls the delete API and shows a success or error SnackBar.
  // On success, reloads the full transaction list.
  // ==============================================================================
  Future<void> _deleteTransaction(int transactionId) async {
    final result = await ApiService.deleteTransaction(transactionId);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadTransactions();                         // Refresh the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to delete'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ==============================================================================
  // _showDeleteDialog - Confirm Delete Dialog
  // ==============================================================================
  // Shows an AlertDialog asking the user to confirm deletion.
  // This is triggered when the user swipes a transaction card to the left.
  // ==============================================================================
  void _showDeleteDialog(TransactionModel transaction) {
    // Build a human-readable label for the transaction being deleted
    final label =
        '${transaction.category} (${transaction.isExpense ? "-" : "+"}RM ${transaction.amount.toStringAsFixed(2)})';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        // Name the specific transaction so the user knows exactly what will be removed
        content: Text('Delete $label? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // ElevatedButton with danger color for destructive confirm (consistent with other screens)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);              // Close dialog
              if (transaction.transactionId != null) {
                _deleteTransaction(transaction.transactionId!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // build - Render the Transaction History Screen UI
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // CSV export button
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to CSV',
            onPressed: _exportToCSV,
          ),
          // Sort button
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: _showSortDialog,
          ),
          // Recurring transactions button
          IconButton(
            icon: const Icon(Icons.repeat),
            tooltip: 'Recurring Transactions',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecurringTransactionsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                // Show clear (X) button only when there's text
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // --- Filter Chips and Actions Bar ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                // Horizontally scrollable filter chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Income', 'income'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Expenses', 'expense'),
                      ],
                    ),
                  ),
                ),
                // "Clear" button (only shown when filters are active)
                if (_hasActiveFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                // Advanced filter funnel icon
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    // Highlighted when filters are active
                    color: _hasActiveFilters ? AppColors.primary : Colors.grey,
                  ),
                  tooltip: 'Filter',
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Transaction List ---
          Expanded(
            child: _isLoading
                // Show shimmer skeleton loading during data fetch
                ? const TransactionListSkeleton(itemCount: 8)
                : _filteredTransactions.isEmpty
                    // Show empty state when no transactions match
                    ? _buildEmptyState()
                    // Show the scrollable transaction list
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _filteredTransactions[index];
                            return _buildTransactionCard(transaction);
                          },
                        ),
                      ),
          ),
        ],
      ),

      // --- Floating Action Button (Add Transaction) ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to add transaction screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
          // Reload if a transaction was added
          if (result == true) {
            _loadTransactions();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  // ==============================================================================
  // _buildFilterChip - Reusable Type Filter Chip (All/Income/Expenses)
  // ==============================================================================
  // Creates a tappable chip that filters transactions by type.
  // Tapping reloads transactions from the API with the selected type filter.
  // ==============================================================================
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = value);
        _loadTransactions();                       // Reload from API with new filter
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Selected chip is colored, unselected is grey
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),   // Pill shape
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==============================================================================
  // _buildTransactionCard - Single Transaction Card with Swipe-to-Delete
  // ==============================================================================
  // Creates a card for one transaction showing:
  // - Category icon with colored background
  // - Category name
  // - Date
  // - Description (if available)
  // - Amount (red/-/green/+ based on type)
  //
  // Wrapped in Dismissible for swipe-to-delete functionality.
  // Tapping navigates to edit mode.
  // ==============================================================================
  Widget _buildTransactionCard(TransactionModel transaction) {
    // Get the icon and color for this transaction's category
    final categoryInfo = TransactionCategories.getCategoryInfo(
      transaction.category,
      transaction.transactionType,
    );

    return Dismissible(
      // Unique key for each item (required by Dismissible)
      key: Key(transaction.transactionId.toString()),
      // Red background shown behind the card when swiping
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,          // Delete icon on the right
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,       // Swipe left only
      // confirmDismiss shows the delete dialog instead of immediately deleting
      confirmDismiss: (direction) async {
        _showDeleteDialog(transaction);
        return false;                              // Don't actually dismiss (dialog handles it)
      },
      child: GestureDetector(
        onTap: () async {
          // Navigate to AddTransactionScreen in edit mode
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(transaction: transaction),
            ),
          );
          // Reload if the transaction was edited
          if (result == true) {
            _loadTransactions();
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: Row(
          children: [
            // Category Icon with colored background
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

            // Transaction Details (category, date, description)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(transaction.transactionDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Show description if it exists and is not empty
                  if (transaction.description != null &&
                      transaction.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      transaction.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,   // Truncate long descriptions
                    ),
                  ],
                ],
              ),
            ),

            // Amount (colored by type: red for expense, green for income)
            Text(
              '${transaction.isExpense ? "-" : "+"}RM ${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: transaction.isExpense
                    ? AppColors.expense
                    : AppColors.income,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // ==============================================================================
  // _buildEmptyState - Empty State When No Transactions Found
  // ==============================================================================
  // Shows a message and icon when there are no transactions to display.
  // The message changes based on whether filters are active.
  // ==============================================================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _hasActiveFilters
                ? 'No matching transactions'       // Filters are hiding results
                : 'No transactions yet',           // User has no transactions at all
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters
                ? 'Try adjusting your filters'
                : 'Start by recording your first transaction',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          // Show CTA button only when there are no transactions at all (not a filter result)
          if (!_hasActiveFilters) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
                if (result == true) _loadTransactions();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
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
    );
  }

  // ==============================================================================
  // _buildFilterSheet - Advanced Filters Bottom Sheet Content
  // ==============================================================================
  // Creates a draggable scrollable sheet with:
  // - Date range picker (start date and end date buttons)
  // - Amount range slider (RM 0 to RM 10,000)
  // - Category filter chips (from existing transaction categories)
  // - Reset and Apply buttons
  //
  // Uses StatefulBuilder so the bottom sheet can update its own state
  // (e.g., when the user picks a date) without needing to rebuild the main screen.
  // ==============================================================================
  Widget _buildFilterSheet() {
    return StatefulBuilder(
      // StatefulBuilder provides its own setState (setModalState) for the sheet
      builder: (context, setModalState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,                   // Start at 90% of screen height
          minChildSize: 0.5,                       // Can shrink to 50%
          maxChildSize: 0.95,                      // Can expand to 95%
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: title + close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Advanced Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Scrollable filter content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // --- Date Range Section ---
                        const Text(
                          'Date Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Start Date button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setModalState(() => _startDate = date);
                                  }
                                },
                                icon: const Icon(Icons.calendar_today, size: 18),
                                label: Text(
                                  _startDate != null
                                      ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                      : 'Start Date',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // End Date button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: _startDate ?? DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setModalState(() => _endDate = date);
                                  }
                                },
                                icon: const Icon(Icons.calendar_today, size: 18),
                                label: Text(
                                  _endDate != null
                                      ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                      : 'End Date',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- Amount Range Section ---
                        const Text(
                          'Amount Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Display current range values
                        Text(
                          'RM ${_minAmount.toStringAsFixed(0)} - RM ${_maxAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // RangeSlider for selecting min and max amount
                        RangeSlider(
                          values: RangeValues(_minAmount, _maxAmount),
                          min: 0,
                          max: 10000,
                          divisions: 100,              // 100-unit increments
                          labels: RangeLabels(
                            'RM ${_minAmount.toStringAsFixed(0)}',
                            'RM ${_maxAmount.toStringAsFixed(0)}',
                          ),
                          onChanged: (values) {
                            setModalState(() {
                              _minAmount = values.start;
                              _maxAmount = values.end;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(height: 24),

                        // --- Categories Section ---
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Wrap creates a flow layout that wraps chips to the next line
                        Wrap(
                          spacing: 8,                  // Horizontal space between chips
                          runSpacing: 8,               // Vertical space between rows
                          children: _getAllCategories().map((category) {
                            final isSelected = _selectedCategories.contains(category);
                            return FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    _selectedCategories.add(category);
                                  } else {
                                    _selectedCategories.remove(category);
                                  }
                                });
                              },
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Bottom Action Buttons (Reset / Apply) ---
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Reset filters within the sheet
                            setModalState(() {
                              _startDate = null;
                              _endDate = null;
                              _minAmount = 0;
                              _maxAmount = 10000;
                              _selectedCategories.clear();
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});           // Trigger parent rebuild
                            _applyFiltersAndSort();    // Apply filters to the list
                            Navigator.pop(context);    // Close the bottom sheet
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==============================================================================
  // _getAllCategories - Get Unique Categories from Current Transactions
  // ==============================================================================
  // Collects all unique category names from the loaded transactions and returns
  // them sorted alphabetically. Used by the category filter chips.
  // ==============================================================================
  List<String> _getAllCategories() {
    final Set<String> categories = {};             // Set ensures uniqueness
    for (var transaction in _transactions) {
      categories.add(transaction.category);
    }
    return categories.toList()..sort();            // ..sort() sorts in place and returns list
  }

  // ==============================================================================
  // _exportToCSV - Export Filtered Transactions to CSV File
  // ==============================================================================
  // Creates a CSV file from the currently filtered transactions, then shows
  // a success dialog with options to share the file.
  // ==============================================================================
  Future<void> _exportToCSV() async {
    // Check if there are transactions to export
    if (_filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions to export'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      // Show loading dialog with a descriptive message so the user knows what is happening
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Only as tall as content
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Exporting transactions...',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Generate the CSV file
      final filePath = await ExportService.exportTransactionsToCSV(
        _filteredTransactions,
        filename: 'transactions_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (filePath != null) {
        // Show success dialog with share option
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exported ${_filteredTransactions.length} transactions to CSV'),
                const SizedBox(height: 8),
                Text(
                  // Show just the filename (last part of the path)
                  'File: ${filePath.split('/').last}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${ExportService.getFileSize(filePath)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              // Share button to send the file via system share sheet
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await ExportService.shareFile(
                    filePath,
                    subject: 'SmartFinance Transactions Export',
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
            content: Text('Failed to export transactions'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);                      // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}
