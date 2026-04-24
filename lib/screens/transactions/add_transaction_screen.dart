import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../../models/gamification_model.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/categories.dart';
import '../../utils/colors.dart';
import '../../utils/app_gradients.dart';
import '../../widgets/animated_button.dart';
import '../../services/receipt_scanner_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

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
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description ?? '';
      _transactionType = widget.transaction!.transactionType;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.transactionDate;
    }
  }

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
      transactionId: widget.transaction?.transactionId,
      amount: double.parse(_amountController.text),
      category: _selectedCategory!,
      description: _descriptionController.text,
      transactionDate: _selectedDate,
      transactionType: _transactionType,
      userId: userId,
    );

    final result = widget.transaction != null
        ? await ApiService.updateTransaction(widget.transaction!.transactionId!, transaction.toJson())
        : await ApiService.createTransaction(transaction.toJson());

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      if (_transactionType == 'expense') {
        final budgetResult = await ApiService.getCurrentBudget(userId);
        if (budgetResult['success'] && budgetResult['budget'] != null) {
          final budget = BudgetModel.fromJson(budgetResult['budget']);

          // Only check category budget if there are categories in the budget
          // budget.categories.first crashes with RangeError if the list is empty
          if (budget.categories.isNotEmpty) {
            final categoryBudget = budget.categories.firstWhere(
              (cat) => cat.categoryName == _selectedCategory,
              orElse: () => budget.categories.first, // Safe — we checked isNotEmpty above
            );

            if (categoryBudget.percentageUsed >= 90 || budget.percentageUsed >= 80) {
              await NotificationService.checkBudgetAndAlert(budget);
            }
          } else if (budget.percentageUsed >= 80) {
            await NotificationService.checkBudgetAndAlert(budget);
          }
        }
      }

      try {
        await ApiService.updateStreak(userId);

        final achievementResult = await ApiService.checkAchievements(userId);
        if (achievementResult['success']) {
          final newlyUnlocked = (achievementResult['newlyUnlocked'] as List)
              .map((json) => NewAchievement.fromJson(json))
              .toList();

          if (newlyUnlocked.isNotEmpty) {
            await NotificationService.checkAndNotifyAchievements(newlyUnlocked);
          }
        }
      } catch (e) {
        // Silently fail gamification updates — don't block the user flow
        debugPrint('Gamification update error: $e');
      }

      if (!mounted) return;
      // Show snackbar BEFORE popping — context becomes invalid after Navigator.pop
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.transaction != null
              ? 'Transaction updated successfully!'
              : 'Transaction added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? (widget.transaction != null
              ? 'Failed to update transaction'
              : 'Failed to add transaction')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  bool get _hasUnsavedChanges {
    if (widget.transaction != null) {
      final original = widget.transaction!;
      final originalAmountStr = original.amount.toString();
      final originalDescription = original.description ?? '';
      return _amountController.text != originalAmountStr ||
          _descriptionController.text != originalDescription ||
          _transactionType != original.transactionType ||
          _selectedCategory != original.category ||
          _selectedDate != original.transactionDate;
    }
    return _amountController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _selectedCategory != null ||
        _selectedDate.day != DateTime.now().day;
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. If you go back now, your data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _scanReceipt() async {
    final useCamera = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Receipt'),
        content: const Text('Choose how to capture your receipt:'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Gallery'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (useCamera == null || !mounted) return;

    final image = useCamera
        ? await ReceiptScannerService.captureReceipt()
        : await ReceiptScannerService.pickReceiptFromGallery();

    if (image == null || !mounted) return;

    setState(() => _isLoading = true);
    final receiptData = await ReceiptScannerService.scanReceipt(image);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (receiptData == null || receiptData.rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read the receipt. Try a clearer photo.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    _showReceiptReviewDialog(receiptData);
  }

  void _showReceiptReviewDialog(ReceiptData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.document_scanner_outlined, size: 20),
            SizedBox(width: 8),
            Text('Receipt Scanned'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following details were found. Tap Apply to fill the form.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (data.amount != null)
              _receiptDetailRow(Icons.attach_money, 'Amount', 'RM ${data.amount!.toStringAsFixed(2)}'),
            if (data.date != null)
              _receiptDetailRow(Icons.calendar_today, 'Date', DateFormat('MMM dd, yyyy').format(data.date!)),
            if (data.merchantName != null)
              _receiptDetailRow(Icons.store_outlined, 'Merchant', data.merchantName!),
            if (data.category != null)
              _receiptDetailRow(Icons.category_outlined, 'Category', data.category!),
            if (data.amount == null && data.date == null && data.merchantName == null)
              const Text(
                'No structured data could be extracted. The form was not changed.',
                style: TextStyle(color: AppColors.warning),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyReceiptData(data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _receiptDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _applyReceiptData(ReceiptData data) {
    setState(() {
      if (data.amount != null) {
        _amountController.text = data.amount!.toStringAsFixed(2);
      }
      if (data.date != null) {
        _selectedDate = data.date!;
      }
      if (data.merchantName != null) {
        _descriptionController.text = data.merchantName!;
      }
      if (data.category != null) {
        final expenseCategories = TransactionCategories.getCategories('expense');
        final match = expenseCategories.firstWhere(
          (c) => c.toLowerCase().contains(data.category!.toLowerCase()) ||
                 data.category!.toLowerCase().contains(c.toLowerCase()),
          orElse: () => '',
        );
        if (match.isNotEmpty) {
          _transactionType = 'expense';
          _selectedCategory = match;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt data applied to form'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = TransactionCategories.getCategories(_transactionType);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (!_hasUnsavedChanges) {
          Navigator.of(context).pop();
          return;
        }
        final shouldDiscard = await _confirmDiscard();
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: widget.transaction == null
            ? [
                IconButton(
                  icon: const Icon(Icons.document_scanner_outlined),
                  onPressed: _isLoading ? null : _scanReceipt,
                  tooltip: 'Scan Receipt',
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.transaction != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Editing transaction from ${DateFormat('MMM dd, yyyy').format(widget.transaction!.transactionDate)}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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

                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Amount (RM)',
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

                Text(
                  'Category',
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
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
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
                              category,
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

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
                          'Date',
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

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
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

                AnimatedButton(
                  text: '${widget.transaction != null ? "Update" : "Add"} ${_transactionType == "expense" ? "Expense" : "Income"}',
                  onPressed: _handleSubmit,
                  gradient: _transactionType == 'expense'
                      ? AppGradients.expenseGradient
                      : AppGradients.incomeGradient,
                  isLoading: _isLoading,
                  icon: _transactionType == 'expense' ? Icons.remove_circle : Icons.add_circle,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
