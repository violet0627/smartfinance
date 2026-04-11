// ==============================================================================
// add_transaction_screen.dart - Add or Edit a Transaction
// ==============================================================================
// This screen provides a form for creating new transactions or editing existing
// ones. It supports both income and expense transactions.
//
// Features:
// - Expense/Income toggle switch
// - Amount input field with RM prefix
// - Category selection grid (changes based on transaction type)
// - Date picker
// - Description (optional) text area
// - Budget alert checking after adding an expense
// - Gamification: updates streak and checks for new achievements
//
// The screen works in two modes:
// 1. Add Mode: No transaction passed → creates a new transaction
// 2. Edit Mode: Transaction passed via constructor → updates existing transaction
//
// Usage:
//   AddTransactionScreen()                              — add new transaction
//   AddTransactionScreen(transaction: existingTxn)     — edit existing transaction
// ==============================================================================

import 'package:flutter/material.dart';                    // For StatefulWidget, Form, etc.
import 'package:intl/intl.dart';                            // For DateFormat (date formatting)
import '../../models/budget_model.dart';                    // For BudgetModel (budget checking)
import '../../models/transaction_model.dart';               // For TransactionModel
import '../../models/gamification_model.dart';               // For NewAchievement
import '../../services/api_service.dart';                    // For API calls (create, update, budget)
import '../../services/notification_service.dart';           // For budget alerts and achievement notifications
import '../../utils/categories.dart';                        // For TransactionCategories
import '../../utils/colors.dart';                            // For AppColors
import '../../utils/app_gradients.dart';                     // For gradient button styles
import '../../widgets/animated_button.dart';                 // For AnimatedButton
import '../../services/receipt_scanner_service.dart';        // For scanning receipts with ML Kit OCR

// ==============================================================================
// AddTransactionScreen - StatefulWidget for Transaction Form
// ==============================================================================
// StatefulWidget because it manages:
// - Form fields (amount, description, category, date, type)
// - Loading state during API calls
// - Receipt scanning results
// ==============================================================================
class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;   // Null for add mode, non-null for edit mode

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();              // For form validation
  final _amountController = TextEditingController();    // Controls the amount input field
  final _descriptionController = TextEditingController(); // Controls the description input

  String _transactionType = 'expense';    // 'expense' or 'income' — which tab is selected
  String? _selectedCategory;              // Currently selected category (null = none)
  DateTime _selectedDate = DateTime.now(); // Date for the transaction (default: today)
  bool _isLoading = false;                // Whether the API call is in progress

  // ==============================================================================
  // initState - Pre-fill Form Fields When Editing
  // ==============================================================================
  @override
  void initState() {
    super.initState();
    // If editing an existing transaction, populate all fields with its data
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
    _amountController.dispose();           // Clean up controllers to prevent memory leaks
    _descriptionController.dispose();
    super.dispose();
  }

  // ==============================================================================
  // _selectDate - Show Date Picker Dialog
  // ==============================================================================
  // Opens the Material date picker and updates _selectedDate if the user
  // picks a new date.
  // ==============================================================================
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,          // Start at current selection
      firstDate: DateTime(2020),           // Earliest selectable date
      lastDate: DateTime(2100),            // Latest selectable date
    );
    // Only update if the user actually picked a date (didn't cancel)
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // ==============================================================================
  // ==============================================================================
  // _handleSubmit - Validate and Submit the Transaction
  // ==============================================================================
  // Validates all form fields, creates a TransactionModel, and either creates
  // or updates the transaction via the API. After a successful expense:
  // - Checks if the budget threshold was exceeded
  // - Updates the daily tracking streak (gamification)
  // - Checks for newly unlocked achievements
  // ==============================================================================
  Future<void> _handleSubmit() async {
    // Validate all form fields (amount, etc.)
    if (!_formKey.currentState!.validate()) return;

    // Check that a category was selected (not part of form validation)
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);     // Show loading state on button

    // Get the current user's ID
    final userId = await ApiService.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again')),
      );
      return;
    }

    // Create a TransactionModel from the form data
    final transaction = TransactionModel(
      transactionId: widget.transaction?.transactionId,  // Keep ID when editing
      amount: double.parse(_amountController.text),
      category: _selectedCategory!,
      description: _descriptionController.text,
      transactionDate: _selectedDate,
      transactionType: _transactionType,
      userId: userId,
    );

    // Call the appropriate API method: update (editing) or create (adding)
    final result = widget.transaction != null
        ? await ApiService.updateTransaction(widget.transaction!.transactionId!, transaction.toJson())
        : await ApiService.createTransaction(transaction.toJson());

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // --- Transaction saved successfully ---

      // Check budget after adding an expense
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

            // Send budget alert if category is 90%+ used or overall is 80%+ used
            if (categoryBudget.percentageUsed >= 90 || budget.percentageUsed >= 80) {
              await NotificationService.checkBudgetAndAlert(budget);
            }
          } else if (budget.percentageUsed >= 80) {
            // No categories defined, but overall budget is near limit — still alert
            await NotificationService.checkBudgetAndAlert(budget);
          }
        }
      }

      // Update gamification: streak + achievements
      try {
        // Update the daily tracking streak
        await ApiService.updateStreak(userId);

        // Check for newly unlocked achievements
        final achievementResult = await ApiService.checkAchievements(userId);
        if (achievementResult['success']) {
          // Parse the list of newly unlocked achievements
          final newlyUnlocked = (achievementResult['newlyUnlocked'] as List)
              .map((json) => NewAchievement.fromJson(json))
              .toList();

          // Show notification for each new achievement
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
      // Return true to tell the previous screen (dashboard) to reload
      Navigator.pop(context, true);
    } else {
      // --- Transaction save failed ---
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

  // ==============================================================================
  // _hasUnsavedChanges - Check Whether the User Has Made Any Changes
  // ==============================================================================
  // In ADD mode: returns true if any field has been filled in.
  // In EDIT mode: compares current field values against the original transaction
  //   to detect actual changes — avoids showing the "Discard?" dialog if nothing
  //   was actually modified.
  // ==============================================================================
  bool get _hasUnsavedChanges {
    if (widget.transaction != null) {
      // EDIT MODE — compare each field against the original value
      final original = widget.transaction!;
      // Convert original amount to string for comparison (same as what controller holds)
      final originalAmountStr = original.amount.toString();
      final originalDescription = original.description ?? '';
      return _amountController.text != originalAmountStr ||
          _descriptionController.text != originalDescription ||
          _transactionType != original.transactionType ||
          _selectedCategory != original.category ||
          _selectedDate != original.transactionDate;
    }
    // ADD MODE — warn if any field has been touched
    return _amountController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _selectedCategory != null ||
        _selectedDate.day != DateTime.now().day;
  }

  // ==============================================================================
  // _confirmDiscard - Show "Discard Changes?" Dialog
  // ==============================================================================
  // Shows an AlertDialog asking the user to confirm discarding unsaved changes.
  // Returns true if the user wants to discard, false if they want to stay.
  // ==============================================================================
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
            onPressed: () => Navigator.pop(context, false),  // Stay on screen
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),   // Confirm discard
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;  // Default to false (don't discard) if dialog dismissed
  }

  // ==============================================================================
  // _scanReceipt - Open Camera or Gallery and Run OCR on Receipt
  // ==============================================================================
  // Shows a dialog to choose camera or gallery, captures the image, runs ML Kit
  // OCR, then pre-fills the form with extracted data (amount, date, description).
  // ==============================================================================
  Future<void> _scanReceipt() async {
    // Step 1: Ask user to choose camera or gallery
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

    // Step 2: Capture the image
    final image = useCamera
        ? await ReceiptScannerService.captureReceipt()
        : await ReceiptScannerService.pickReceiptFromGallery();

    if (image == null || !mounted) return;

    // Step 3: Run OCR — show spinner while processing
    setState(() => _isLoading = true);
    final receiptData = await ReceiptScannerService.scanReceipt(image);
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Step 4: Handle failure
    if (receiptData == null || receiptData.rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read the receipt. Try a clearer photo.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Step 5: Show review dialog with extracted data
    _showReceiptReviewDialog(receiptData);
  }

  // ==============================================================================
  // _showReceiptReviewDialog - Preview Extracted Receipt Data Before Applying
  // ==============================================================================
  // Shows the user what the OCR found and lets them confirm before auto-filling
  // the form. This prevents silently overwriting data with wrong OCR results.
  // ==============================================================================
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

  // _receiptDetailRow creates one labelled row inside the receipt review dialog
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

  // _applyReceiptData fills the form fields with the confirmed receipt data
  void _applyReceiptData(ReceiptData data) {
    setState(() {
      // Fill amount if found
      if (data.amount != null) {
        _amountController.text = data.amount!.toStringAsFixed(2);
      }
      // Fill date if found
      if (data.date != null) {
        _selectedDate = data.date!;
      }
      // Fill description with merchant name if found
      if (data.merchantName != null) {
        _descriptionController.text = data.merchantName!;
      }
      // Try to match the detected category to our expense categories
      if (data.category != null) {
        final expenseCategories = TransactionCategories.getCategories('expense');
        final match = expenseCategories.firstWhere(
          (c) => c.toLowerCase().contains(data.category!.toLowerCase()) ||
                 data.category!.toLowerCase().contains(c.toLowerCase()),
          orElse: () => '',
        );
        if (match.isNotEmpty) {
          _transactionType = 'expense'; // Receipts are always expenses
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

  // ==============================================================================
  // build - Render the Add/Edit Transaction Form UI
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    // Get the list of categories for the current transaction type
    // (expense categories differ from income categories)
    final categories = TransactionCategories.getCategories(_transactionType);

    // PopScope intercepts the back gesture/button.
    // If the user has unsaved changes, show a confirmation dialog before leaving.
    return PopScope(
      canPop: false,  // Prevent default pop — we handle it ourselves in onPopInvoked
      onPopInvoked: (didPop) async {
        if (didPop) return;  // Already popped (shouldn't happen since canPop=false)
        if (!_hasUnsavedChanges) {
          // No changes — allow navigation without dialog
          Navigator.of(context).pop();
          return;
        }
        // Has unsaved changes — ask for confirmation
        final shouldDiscard = await _confirmDiscard();
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Show "Edit Transaction" or "Add Transaction" based on mode
        title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Show scan receipt button only in add mode (not when editing an existing transaction)
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
                // --- Edit Mode Indicator ---
                // Shows a banner with the original transaction date when editing
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

                // --- Transaction Type Toggle (Expense / Income) ---
                // A custom segmented control with two GestureDetector-wrapped buttons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Expense tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _transactionType = 'expense';
                              _selectedCategory = null;    // Reset category on type switch
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              // Filled red when selected, transparent when not
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
                      // Income tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _transactionType = 'income';
                              _selectedCategory = null;    // Reset category on type switch
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              // Filled green when selected, transparent when not
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

                // --- Amount Input Field ---
                TextFormField(
                  controller: _amountController,
                  // Shows numeric keyboard with decimal point
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Amount (RM)',
                    prefixText: 'RM ',                 // Currency prefix
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
                    // Check if the value is a valid number
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    // Amount must be positive
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    return null;                       // Validation passed
                  },
                ),
                const SizedBox(height: 16),

                // --- Category Selection Grid ---
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                // GridView.builder creates a grid of category buttons
                GridView.builder(
                  shrinkWrap: true,                    // Don't take infinite height
                  physics: const NeverScrollableScrollPhysics(),  // Parent scrolls
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,                 // 4 columns
                    childAspectRatio: 0.85,            // Slightly tall cells
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    // Get icon and color for this category
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
                          // Selected: filled with category color; unselected: white
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
                              // Icon color inverts when selected (white on colored bg)
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

                // --- Date Picker ---
                // Tapping this container opens the date picker dialog
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
                            // Display the selected date
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

                // --- Description Input (Optional) ---
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,                         // Multi-line input
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

                // --- Submit Button ---
                // AnimatedButton with gradient that changes based on expense/income type
                AnimatedButton(
                  // Dynamic button text: "Add Expense", "Update Income", etc.
                  text: '${widget.transaction != null ? "Update" : "Add"} ${_transactionType == "expense" ? "Expense" : "Income"}',
                  onPressed: _handleSubmit,
                  // Red gradient for expense, green gradient for income
                  gradient: _transactionType == 'expense'
                      ? AppGradients.expenseGradient
                      : AppGradients.incomeGradient,
                  isLoading: _isLoading,
                  // Different icon for expense vs income
                  icon: _transactionType == 'expense' ? Icons.remove_circle : Icons.add_circle,
                ),
              ],
            ),
          ),
        ),
      ),
    ),  // end Scaffold (child of PopScope)
    );  // end PopScope — this is the return value
  }
}
