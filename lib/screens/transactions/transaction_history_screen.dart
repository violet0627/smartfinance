import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../services/api_service.dart';
import '../../services/export_service.dart';
import '../../utils/categories.dart';
import '../../utils/colors.dart';
import '../../widgets/shimmer_loading.dart';
import 'add_transaction_screen.dart';
import 'recurring_transactions_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;
  String _filterType = 'all'; // all, income, expense

  // Search and Filter variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  DateTime? _startDate;
  DateTime? _endDate;
  double _minAmount = 0;
  double _maxAmount = 10000;
  List<String> _selectedCategories = [];
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFiltersAndSort();
    });
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    final result = await ApiService.getUserTransactions(
      userId,
      type: _filterType == 'all' ? null : _filterType,
    );

    if (result['success']) {
      final transactionsList = result['transactions'] as List;
      setState(() {
        _transactions = transactionsList
            .map((json) => TransactionModel.fromJson(json))
            .toList();
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _applyFiltersAndSort() {
    List<TransactionModel> filtered = List.from(_transactions);

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.category.toLowerCase().contains(_searchQuery) ||
            (t.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Apply date range filter
    if (_startDate != null) {
      filtered = filtered.where((t) =>
        !t.transactionDate.isBefore(_startDate!)
      ).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((t) =>
        !t.transactionDate.isAfter(_endDate!)
      ).toList();
    }

    // Apply amount range filter
    filtered = filtered.where((t) =>
      t.amount >= _minAmount && t.amount <= _maxAmount
    ).toList();

    // Apply category filter
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((t) =>
        _selectedCategories.contains(t.category)
      ).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    // Check if any filters are active
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _startDate = null;
      _endDate = null;
      _minAmount = 0;
      _maxAmount = 10000;
      _selectedCategories.clear();
      _sortBy = 'date_desc';
      _applyFiltersAndSort();
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

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

  Widget _buildSortOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _sortBy,
      onChanged: (v) {
        setState(() => _sortBy = v!);
        _applyFiltersAndSort();
        Navigator.pop(context);
      },
      activeColor: AppColors.primary,
    );
  }

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
      _loadTransactions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to delete'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showDeleteDialog(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (transaction.transactionId != null) {
                _deleteTransaction(transaction.transactionId!);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to CSV',
            onPressed: _exportToCSV,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: _showSortDialog,
          ),
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
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
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
          // Filter Chips and Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
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
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: _hasActiveFilters ? AppColors.primary : Colors.grey,
                  ),
                  tooltip: 'Filter',
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Transaction List
          Expanded(
            child: _isLoading
                ? const TransactionListSkeleton(itemCount: 8)
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = value);
        _loadTransactions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
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

  Widget _buildTransactionCard(TransactionModel transaction) {
    final categoryInfo = TransactionCategories.getCategoryInfo(
      transaction.category,
      transaction.transactionType,
    );

    return Dismissible(
      key: Key(transaction.transactionId.toString()),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        _showDeleteDialog(transaction);
        return false;
      },
      child: GestureDetector(
        onTap: () async {
          // Navigate to edit transaction screen
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(transaction: transaction),
            ),
          );
          // Reload transactions if edited
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
            // Category Icon
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
            // Transaction Details
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Amount
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
                ? 'No matching transactions'
                : 'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters
                ? 'Try adjusting your filters'
                : 'Tap the + button to add your first transaction',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Date Range
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
                        // Amount Range
                        const Text(
                          'Amount Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'RM ${_minAmount.toStringAsFixed(0)} - RM ${_maxAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        RangeSlider(
                          values: RangeValues(_minAmount, _maxAmount),
                          min: 0,
                          max: 10000,
                          divisions: 100,
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
                        // Categories
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
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
                            setState(() {});
                            _applyFiltersAndSort();
                            Navigator.pop(context);
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

  List<String> _getAllCategories() {
    final Set<String> categories = {};
    for (var transaction in _transactions) {
      categories.add(transaction.category);
    }
    return categories.toList()..sort();
  }

  Future<void> _exportToCSV() async {
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
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Export to CSV
      final filePath = await ExportService.exportTransactionsToCSV(
        _filteredTransactions,
        filename: 'transactions_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
      );

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
                Text('Exported ${_filteredTransactions.length} transactions to CSV'),
                const SizedBox(height: 8),
                Text(
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
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}
