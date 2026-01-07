import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../../models/gamification_model.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/categories.dart';
import '../../utils/colors.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _transactionType = 'expense';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again')),
      );
      return;
    }

    final transaction = TransactionModel(
      amount: double.parse(_amountController.text),
      category: _selectedCategory!,
      description: _descriptionController.text,
      transactionDate: _selectedDate,
      transactionType: _transactionType,
      userId: userId,
    );

    final result = await ApiService.createTransaction(transaction.toJson());

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // Check budget after adding expense
      if (_transactionType == 'expense') {
        final budgetResult = await ApiService.getCurrentBudget(userId);
        if (budgetResult['success'] && budgetResult['budget'] != null) {
          final budget = BudgetModel.fromJson(budgetResult['budget']);

          // Check if category is over budget or approaching limit
          final categoryBudget = budget.categories.firstWhere(
            (cat) => cat.categoryName == _selectedCategory,
            orElse: () => budget.categories.first,
          );

          if (categoryBudget.percentageUsed >= 90 || budget.percentageUsed >= 80) {
            await NotificationService.checkBudgetAndAlert(budget);
          }
        }
      }

      // Update streak and check achievements (gamification)
      try {
        // Update daily tracking streak
        await ApiService.updateStreak(userId);

        // Check for newly unlocked achievements
        final achievementResult = await ApiService.checkAchievements(userId);
        if (achievementResult['success']) {
          final newlyUnlocked = (achievementResult['newlyUnlocked'] as List)
              .map((json) => NewAchievement.fromJson(json))
              .toList();

          // Show notifications for newly unlocked achievements
          if (newlyUnlocked.isNotEmpty) {
            await NotificationService.checkAndNotifyAchievements(newlyUnlocked);
          }
        }
      } catch (e) {
        // Silently fail gamification updates - don't block user flow
        debugPrint('Gamification update error: $e');
      }

      if (!mounted) return;
      Navigator.pop(context, true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to add transaction'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = TransactionCategories.getCategories(_transactionType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Transaction Type Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _transactionType = 'expense';
                              _selectedCategory = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _transactionType == 'expense'
                                  ? AppColors.expense
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Expense',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _transactionType == 'expense'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _transactionType = 'income';
                              _selectedCategory = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _transactionType == 'income'
                                  ? AppColors.income
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Income',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _transactionType == 'income'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'AMOUNT (RM)',
                    prefixText: 'RM ',
                    prefixStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Category Selection
                Text(
                  'CATEGORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final categoryInfo = TransactionCategories.getCategoryInfo(
                      category,
                      _transactionType,
                    );
                    final isSelected = _selectedCategory == category;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = category);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? categoryInfo.color
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? categoryInfo.color
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              categoryInfo.icon,
                              color: isSelected
                                  ? Colors.white
                                  : categoryInfo.color,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.split(' ')[0],
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Date Picker
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DATE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'DESCRIPTION (OPTIONAL)',
                    hintText: 'Add notes about this transaction...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _transactionType == 'expense'
                          ? AppColors.expense
                          : AppColors.income,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Add ${_transactionType == "expense" ? "Expense" : "Income"}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
