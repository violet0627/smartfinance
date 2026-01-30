import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/budget_model.dart';
import '../../services/api_service.dart';
import '../../utils/categories.dart';
import '../../utils/colors.dart';

class CreateBudgetScreen extends StatefulWidget {
  final BudgetModel? budget;

  const CreateBudgetScreen({super.key, this.budget});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalBudgetController = TextEditingController();

  DateTime _selectedMonth = DateTime.now();
  final Map<String, double> _categoryAllocations = {};
  bool _isLoading = false;

  final List<String> _expenseCategories = TransactionCategories.expenseCategories.keys.toList();

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing && widget.budget != null) {
      // Load existing budget data
      _totalBudgetController.text = widget.budget!.totalBudget.toString();

      // Parse monthYear string (YYYY-MM) to DateTime
      final parts = widget.budget!.monthYear.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        _selectedMonth = DateTime(year, month);
      }

      // Load category allocations
      for (var category in widget.budget!.categories) {
        _categoryAllocations[category.categoryName] = category.allocatedAmount;
      }

      // Initialize missing categories with 0
      for (var category in _expenseCategories) {
        if (!_categoryAllocations.containsKey(category)) {
          _categoryAllocations[category] = 0.0;
        }
      }
    } else {
      // Initialize all categories with 0
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

  double get _totalAllocated {
    return _categoryAllocations.values.fold(0.0, (sum, amount) => sum + amount);
  }

  double get _totalBudget {
    return double.tryParse(_totalBudgetController.text) ?? 0.0;
  }

  double get _remaining {
    return _totalBudget - _totalAllocated;
  }

  bool get _isValid {
    // Allow small remainders up to RM 1 for flexibility
    return _totalBudget > 0 && _remaining >= 0 && _remaining <= 1.0;
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

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
      final perCategory = _totalBudget / _expenseCategories.length;
      for (var category in _expenseCategories) {
        _categoryAllocations[category] = perCategory;
      }
    });
  }

  void _clearAllocations() {
    setState(() {
      for (var category in _expenseCategories) {
        _categoryAllocations[category] = 0.0;
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_remaining > 0
              ? 'You have RM ${_remaining.toStringAsFixed(2)} unallocated'
              : 'Total allocations exceed budget by RM ${(-_remaining).toStringAsFixed(2)}'),
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

    // Prepare categories list (only non-zero allocations)
    final categories = _categoryAllocations.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
              'categoryName': entry.key,
              'allocatedAmount': entry.value,
            })
        .toList();

    final budgetData = {
      'monthYear': DateFormat('yyyy-MM').format(_selectedMonth),
      'budgetPeriod': 'Monthly',
      'totalBudget': _totalBudget,
      'userId': userId,
      'categories': categories,
    };

    final result = _isEditing && widget.budget?.budgetId != null
        ? await ApiService.updateBudget(widget.budget!.budgetId!, budgetData)
        : await ApiService.createBudget(budgetData);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      Navigator.pop(context, true);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Budget' : 'Create Budget'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Distribute evenly',
            onPressed: _distributeEvenly,
          ),
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
            // Summary Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  // Month Selector
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
                  // Total Budget
                  TextFormField(
                    controller: _totalBudgetController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'TOTAL BUDGET (RM)',
                      prefixText: 'RM ',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
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
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  // Progress Indicator
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
                          color: _remaining < 0 ? AppColors.danger : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _totalBudget > 0 ? (_totalAllocated / _totalBudget).clamp(0.0, 1.0) : 0.0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remaining < 0 ? AppColors.danger : AppColors.primary,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Category List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _expenseCategories.length,
                itemBuilder: (context, index) {
                  final category = _expenseCategories[index];
                  final categoryInfo = TransactionCategories.getCategoryInfo(category, 'expense');
                  final allocation = _categoryAllocations[category] ?? 0.0;

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
                                    category,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
                            SizedBox(
                              width: 120,
                              child: TextFormField(
                                initialValue: allocation == 0 ? '' : allocation.toStringAsFixed(2),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  prefixText: 'RM ',
                                  isDense: true,
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
                                    _categoryAllocations[category] =
                                        double.tryParse(value) ?? 0.0;
                                  });
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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
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
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
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
    );
  }
}
