// ==============================================================================
// create_budget_screen.dart - Create / Edit Monthly Budget Screen
// ==============================================================================
// Dual-purpose form: creating a new budget OR editing the current month's budget.
//
// Create mode (budget == null):
//   - Month defaults to the current month
//   - Category allocations all start at 0
//   - Save calls ApiService.createBudget()
//
// Edit mode (budget != null):
//   - Total and per-category amounts are pre-filled from the existing BudgetModel
//   - Save calls ApiService.updateBudget()
//
// How allocation works:
//   - User enters a Total Budget amount (e.g., RM 3000)
//   - User types a RM amount for each expense category
//   - A progress bar and "Allocated / Total" text update in real time
//   - If total exceeds the budget, an over-allocation warning turns red
//   - "Distribute Evenly" button divides the total equally across all categories
//
// On save success, Navigator.pop(context, true) signals BudgetOverviewScreen to refresh.
// ==============================================================================

import 'package:flutter/material.dart';     // Flutter UI toolkit
import 'package:intl/intl.dart';            // Date formatting (e.g., "March 2024")
import '../../models/budget_model.dart';    // BudgetModel data class
import '../../services/api_service.dart';   // Backend API calls
import '../../utils/categories.dart';       // TransactionCategories utility (icons, colors per category)
import '../../utils/colors.dart';           // AppColors constants

// ==============================================================================
// CreateBudgetScreen — StatefulWidget
// ==============================================================================
// StatefulWidget because it manages:
//   - _formKey: validates the total budget field
//   - _totalBudgetController: the main budget amount input
//   - _selectedMonth: the month this budget covers (month picker)
//   - _categoryAllocations: Map<categoryName, allocatedAmount> — one entry per category
//   - _categoryControllers: Map<categoryName, TextEditingController> — one per input field
//   - _isSubmitting: disables the Save button while API call is in progress
// ==============================================================================
class CreateBudgetScreen extends StatefulWidget {
  final BudgetModel? budget; // Existing budget for editing; null = creating a new one

  const CreateBudgetScreen({super.key, this.budget});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final _formKey = GlobalKey<FormState>(); // For validating the total budget field
  final _totalBudgetController = TextEditingController(); // Total budget amount input

  DateTime _selectedMonth = DateTime.now(); // Which month this budget covers
  // Map: category name -> allocated amount (e.g., {"Food & Dining": 500.0})
  final Map<String, double> _categoryAllocations = {};
  bool _isLoading = false; // True while saving/updating budget

  // Get the list of expense category names from the TransactionCategories utility
  // .keys gives all the keys (category names); .toList() converts to a List
  final List<String> _expenseCategories = TransactionCategories.expenseCategories.keys.toList();

  // Computed getter: true if we're editing an existing budget, false if creating new
  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing && widget.budget != null) {
      // Pre-fill form with existing budget data
      _totalBudgetController.text = widget.budget!.totalBudget.toString();

      // Parse the "YYYY-MM" monthYear string back into a DateTime
      // e.g., "2024-03" -> DateTime(2024, 3)
      final parts = widget.budget!.monthYear.split('-'); // Split "2024-03" into ["2024", "03"]
      if (parts.length == 2) {
        final year = int.parse(parts[0]);  // "2024" -> 2024
        final month = int.parse(parts[1]); // "03" -> 3
        _selectedMonth = DateTime(year, month);
      }

      // Load the existing category allocations from the budget
      for (var category in widget.budget!.categories) {
        _categoryAllocations[category.categoryName] = category.allocatedAmount;
      }

      // Initialize any categories not in the budget with 0 (they weren't allocated before)
      for (var category in _expenseCategories) {
        if (!_categoryAllocations.containsKey(category)) {
          _categoryAllocations[category] = 0.0;
        }
      }
    } else {
      // Creating a new budget: all categories start at 0
      for (var category in _expenseCategories) {
        _categoryAllocations[category] = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    super.dispose();
  }

  // _totalAllocated computes the sum of all category allocations
  // .values gives all amounts; .fold accumulates them into a running sum
  double get _totalAllocated {
    return _categoryAllocations.values.fold(0.0, (sum, amount) => sum + amount);
  }

  // _totalBudget reads the current total budget value from the text field
  // double.tryParse returns null if the text isn't a valid number; ?? 0.0 defaults to 0
  double get _totalBudget {
    return double.tryParse(_totalBudgetController.text) ?? 0.0;
  }

  // _remaining computes how much of the total budget hasn't been allocated yet
  double get _remaining {
    return _totalBudget - _totalAllocated;
  }

  // _isValid checks if the budget allocations are complete enough to save
  // Allows up to RM 1.00 unallocated for rounding flexibility
  bool get _isValid {
    return _totalBudget > 0 && _remaining >= 0 && _remaining <= 1.0;
  }

  // _hasUnsavedChanges returns true if the user has entered data that hasn't been saved.
  // Used by PopScope to decide whether to warn before navigating back.
  bool get _hasUnsavedChanges {
    if (_isEditing) return true; // Always warn when editing — user may have changed values
    // For new budgets: warn if the total amount or any category has been set
    final hasAmount = _totalBudgetController.text.isNotEmpty;
    final hasCategory = _categoryAllocations.values.any((v) => v > 0);
    return hasAmount || hasCategory;
  }

  // _confirmDiscard shows a dialog asking whether to discard unsaved changes
  Future<bool> _confirmDiscard() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
                'You have unsaved changes. Are you sure you want to go back?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // Stay on screen
                child: const Text('Keep Editing'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true), // Confirm discard
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false; // If dialog is dismissed without a choice, treat as cancel
  }

  // _selectMonth opens a date picker to choose which month this budget applies to
  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      // firstDate allows past months so that editing existing past budgets doesn't crash.
      // Flutter throws an assertion if initialDate is before firstDate.
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),     // Max year 2030
      initialDatePickerMode: DatePickerMode.year, // Start in year/month view instead of day view
    );
    if (picked != null) {
      // Only store year and month (day is always 1)
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  // _distributeEvenly splits the total budget equally across all expense categories
  void _distributeEvenly() {
    if (_totalBudget == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter total budget first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      // Divide total equally; e.g., RM 1000 / 11 categories = ~RM 90.91 each
      final perCategory = _totalBudget / _expenseCategories.length;
      for (var category in _expenseCategories) {
        _categoryAllocations[category] = perCategory;
      }
    });
  }

  // _clearAllocations resets all category allocations back to 0
  void _clearAllocations() {
    setState(() {
      for (var category in _expenseCategories) {
        _categoryAllocations[category] = 0.0;
      }
    });
  }

  // _handleSubmit validates and saves the budget to the backend
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return; // Validate total budget field

    // Check allocations are valid (all budget is distributed)
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_remaining > 0
              ? 'You have RM ${_remaining.toStringAsFixed(2)} unallocated' // Under-allocated
              : 'Total allocations exceed budget by RM ${(-_remaining).toStringAsFixed(2)}'), // Over-allocated
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Build the categories list: only include categories with non-zero allocations
    // .entries gives MapEntry objects; .where filters; .map transforms to API format
    final categories = _categoryAllocations.entries
        .where((entry) => entry.value > 0) // Filter out zero-allocation categories
        .map((entry) => {
              'categoryName': entry.key,      // e.g., "Food & Dining"
              'allocatedAmount': entry.value,  // e.g., 500.0
            })
        .toList();

    final budgetData = {
      'monthYear': DateFormat('yyyy-MM').format(_selectedMonth), // e.g., "2024-03"
      'budgetPeriod': 'Monthly',   // This app only supports monthly budgets
      'totalBudget': _totalBudget,
      'userId': userId,
      'categories': categories,
    };

    // Call different API endpoints for create vs. update
    final result = _isEditing && widget.budget?.budgetId != null
        ? await ApiService.updateBudget(widget.budget!.budgetId!, budgetData)
        : await ApiService.createBudget(budgetData);

    setState(() => _isLoading = false);

    if (!mounted) return; // Safety check after async gap

    if (result['success']) {
      Navigator.pop(context, true); // Go back and signal refresh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Budget updated successfully!' : 'Budget created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? (_isEditing ? 'Failed to update budget' : 'Failed to create budget')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope intercepts the back navigation gesture/button.
    // canPop: false means the system back press does NOT automatically pop this route.
    // Instead, onPopInvoked is called so we can decide whether to allow it.
    return PopScope(
      canPop: false,
      // onPopInvokedWithResult replaces the deprecated onPopInvoked
      // The second parameter (result) is the value passed when popping — unused here
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Already popped — nothing to do
        // If no unsaved changes, allow immediate navigation back
        if (!_hasUnsavedChanges) {
          Navigator.of(context).pop();
          return;
        }
        // Otherwise ask the user to confirm discarding their work
        final shouldDiscard = await _confirmDiscard();
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Budget' : 'Create Budget'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // "Distribute Evenly" action button in the app bar
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Distribute evenly', // Tooltip shown on long press
            onPressed: _distributeEvenly,
          ),
          // "Clear All" action button in the app bar
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear all',
            onPressed: _clearAllocations,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Summary Header - sticky at the top showing month, total budget, and progress
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  // Month selector row - tapping opens the date picker
                  GestureDetector(
                    onTap: _selectMonth,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Budget Month',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Text(
                                // DateFormat('MMMM yyyy') formats as "March 2024"
                                DateFormat('MMMM yyyy').format(_selectedMonth),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total budget amount input field
                  TextFormField(
                    controller: _totalBudgetController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // Large text
                    decoration: InputDecoration(
                      labelText: 'Total Budget (RM)',
                      prefixText: 'RM ', // Shows "RM " before the entered number
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none, // Remove border to rely on fill color only
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter total budget';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Please enter valid amount';
                      }
                      return null;
                    },
                    // Rebuild every time the user types to update _totalAllocated and _remaining
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Progress indicators: allocated vs remaining
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Allocated: RM ${_totalAllocated.toStringAsFixed(2)}',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        'Remaining: RM ${_remaining.toStringAsFixed(2)}',
                        style: TextStyle(
                          // Red if over-budget, green if within budget
                          color: _remaining < 0 ? AppColors.danger : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar showing proportion of budget allocated
                  LinearProgressIndicator(
                    // .clamp(0.0, 1.0) prevents the bar from going beyond 100%
                    value: _totalBudget > 0 ? (_totalAllocated / _totalBudget).clamp(0.0, 1.0) : 0.0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      // Red bar when over-allocated, primary color when within budget
                      _remaining < 0 ? AppColors.danger : AppColors.primary,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const Divider(height: 1), // Thin line separating header from category list

            // Scrollable list of category allocation inputs
            Expanded(
              // Expanded fills remaining vertical space after the header
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _expenseCategories.length,
                itemBuilder: (context, index) {
                  final category = _expenseCategories[index]; // e.g., "Food & Dining"
                  // getCategoryInfo returns icon and color for this category
                  final categoryInfo = TransactionCategories.getCategoryInfo(category, 'expense');
                  final allocation = _categoryAllocations[category] ?? 0.0; // Current allocation

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Category icon in a colored circle
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: categoryInfo.color.withOpacity(0.1), // Tinted background
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                categoryInfo.icon,
                                color: categoryInfo.color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Category name and percentage of total budget
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  // Only show percentage if total is set and category has allocation
                                  if (_totalBudget > 0 && allocation > 0)
                                    Text(
                                      '${((allocation / _totalBudget) * 100).toStringAsFixed(1)}% of total',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Allocation amount input on the right side
                            SizedBox(
                              width: 120, // Fixed width for consistent alignment
                              child: TextFormField(
                                // initialValue pre-fills the field; empty string for 0 allocations
                                initialValue: allocation == 0 ? '' : allocation.toStringAsFixed(2),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.right, // Right-align numbers
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  prefixText: 'RM ', // Currency prefix
                                  isDense: true, // Reduces vertical padding for compact look
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    // Update allocation for this category; default 0 if invalid
                                    _categoryAllocations[category] =
                                        double.tryParse(value) ?? 0.0;
                                  });
                                  // setState triggers rebuild to update the progress bar
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar contains the Create/Update button pinned to the bottom
      bottomNavigationBar: SafeArea(
        // SafeArea adds padding to avoid the notch/home indicator on modern phones
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4), // Shadow above (negative y = upward)
              ),
            ],
          ),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Show a spinner with "Saving..." text while the API call is in progress
              child: _isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min, // Row only as wide as its children
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2, // Thinner stroke to fit alongside text
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Saving...', style: TextStyle(fontSize: 16)),
                      ],
                    )
                  : Text(
                      _isEditing ? 'Update Budget' : 'Create Budget',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
      ), // end Scaffold (child of PopScope)
    ); // end PopScope
  }
}
