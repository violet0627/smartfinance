// add_recurring_transaction_screen.dart
// This screen lets users set up a new recurring transaction (e.g., monthly rent, weekly salary).
// Users specify: type (income/expense), name, amount, category, frequency, start date, and optional end date.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:intl/intl.dart'; // Date formatting (e.g., "Mar 15, 2025")
import '../../services/api_service.dart'; // Backend API calls
import '../../utils/colors.dart'; // AppColors constants

// AddRecurringTransactionScreen is a StatefulWidget because many fields change as the user types
class AddRecurringTransactionScreen extends StatefulWidget {
  const AddRecurringTransactionScreen({super.key});

  @override
  State<AddRecurringTransactionScreen> createState() => _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState extends State<AddRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>(); // Enables form-wide validation
  final _nameController = TextEditingController();        // e.g., "Monthly Rent"
  final _amountController = TextEditingController();      // e.g., "1500"
  final _descriptionController = TextEditingController(); // Optional notes

  String _transactionType = 'expense';          // 'expense' or 'income'
  String _selectedCategory = 'Food & Dining';   // Currently selected category
  String _selectedFrequency = 'monthly';        // 'daily', 'weekly', 'monthly', 'yearly'
  DateTime _startDate = DateTime.now();          // When the first transaction occurs
  DateTime? _endDate;                            // Optional: when recurring stops (null = no end)
  bool _hasEndDate = false;   // Whether the user wants to set an end date
  bool _isSubmitting = false; // True while the API call is in progress

  // Expense categories: shown when transaction type is 'expense'
  final List<String> _expenseCategories = [
    'Food & Dining',
    'Transport',
    'Utilities',
    'Rent/Mortgage',
    'Shopping',
    'Entertainment',
    'Healthcare',
    'Education',
    'Insurance',
    'Subscriptions',
    'Other Expenses',
  ];

  // Income categories: shown when transaction type is 'income'
  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Rental Income',
    'Gift/Bonus',
    'Other Income',
  ];

  // Available repeat frequencies - each has a 'value' (sent to API) and 'label' (shown to user)
  final List<Map<String, String>> _frequencies = [
    {'value': 'daily', 'label': 'Daily'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'yearly', 'label': 'Yearly'},
  ];

  @override
  void dispose() {
    // Free memory for all controllers when the screen is removed
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // _categories is a computed getter that returns the right category list based on transaction type
  // 'get' keyword defines a getter - it's accessed like a property, not called like a method
  List<String> get _categories {
    return _transactionType == 'income' ? _incomeCategories : _expenseCategories;
  }

  // _selectStartDate opens a date picker for the start date
  // Start date must be today or in the future (can't set up a past recurring transaction)
  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),   // Can't pick before today
      lastDate: DateTime.now().add(const Duration(days: 365)), // Up to 1 year ahead
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }

  // _selectEndDate opens a date picker for the optional end date
  // End date must be after the start date
  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      // Default end date: 1 year after start date (if not already set)
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate,   // End must be after start
      lastDate: DateTime.now().add(const Duration(days: 3650)), // Up to 10 years
    );

    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }

  // _submitForm validates and sends the recurring transaction data to the backend
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return; // Validate all form fields

    setState(() {
      _isSubmitting = true; // Show loading state
    });

    try {
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Call the API to create the recurring transaction
      final result = await ApiService.createRecurringTransaction(
        userId: userId,
        name: _nameController.text.trim(), // .trim() removes leading/trailing whitespace
        transactionType: _transactionType,
        category: _selectedCategory,
        amount: double.parse(_amountController.text), // Convert String to double
        // If description is empty, pass null (optional field)
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        frequency: _selectedFrequency,
        // DateFormat('yyyy-MM-dd') formats the date as "2024-03-15" (backend-friendly format)
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        // Only pass end date if the switch is on AND a date was picked
        endDate: _hasEndDate && _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      );

      if (!mounted) return; // Check widget is still in the tree after the await

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring transaction created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Go back and signal the list to refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to create recurring transaction'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() {
          _isSubmitting = false; // Re-enable the button so user can try again
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Recurring Transaction'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // SingleChildScrollView allows scrolling when the keyboard appears
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey, // Attach key to enable form validation
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner reminding user to scroll down to fill all required fields
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please scroll down to fill ALL required fields (Name, Amount, etc.)',
                        style: TextStyle(color: Colors.blue, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction Type: two ChoiceChips side by side (Expense / Income)
              const Text(
                'Transaction Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      // ChoiceChip is selectable; only one can be selected at a time
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.arrow_downward, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Expense', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      selected: _transactionType == 'expense', // True when expense is selected
                      onSelected: (selected) {
                        setState(() {
                          _transactionType = 'expense';
                          // Reset category to first expense category when switching type
                          _selectedCategory = _expenseCategories[0];
                        });
                      },
                      selectedColor: AppColors.expense, // Red when selected
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.arrow_upward, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Income', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      selected: _transactionType == 'income',
                      onSelected: (selected) {
                        setState(() {
                          _transactionType = 'income';
                          // Reset category to first income category when switching type
                          _selectedCategory = _incomeCategories[0];
                        });
                      },
                      selectedColor: AppColors.income, // Green when selected
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name field - descriptive name for this recurring transaction
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name *', // '*' indicates required
                  hintText: 'e.g., Monthly Rent, Weekly Salary',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  // .trim() removes whitespace; checks if result is empty
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount field - how much each recurring transaction will be
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (RM) *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value); // Returns null if not a valid number
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown - options depend on transaction type (income vs expense)
              DropdownButtonFormField<String>(
                // DropdownButtonFormField shows a dropdown list of options
                value: _selectedCategory, // Currently selected item
                decoration: InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // .map() transforms each category string into a DropdownMenuItem widget
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,     // Value sent to onChanged when selected
                    child: Text(category), // Display text in the dropdown list
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!; // '!' asserts non-null (dropdown always has a value)
                  });
                },
              ),
              const SizedBox(height: 16),

              // Frequency dropdown - how often the transaction repeats
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: InputDecoration(
                  labelText: 'Frequency *',
                  prefixIcon: const Icon(Icons.repeat),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _frequencies.map((freq) {
                  return DropdownMenuItem(
                    value: freq['value'],    // e.g., 'monthly'
                    child: Text(freq['label']!), // e.g., 'Monthly'
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFrequency = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Start Date picker - when this recurring transaction first runs
              InkWell(
                onTap: _selectStartDate, // Tapping opens the date picker
                child: InputDecorator(
                  // InputDecorator gives a non-field widget the appearance of a form field
                  decoration: InputDecoration(
                    labelText: 'Start Date *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_startDate), // e.g., "Mar 15, 2024"
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End Date toggle switch - user can optionally set when the recurring stops
              SwitchListTile(
                // SwitchListTile is a ListTile with a Switch widget on the right
                title: const Text('Set End Date'),
                subtitle: const Text('Leave off for no end date'),
                value: _hasEndDate, // Current switch state
                onChanged: (value) {
                  setState(() {
                    _hasEndDate = value;
                    if (!value) {
                      _endDate = null; // Clear end date when switch is turned off
                    }
                  });
                },
                activeColor: AppColors.primary,
              ),

              // End Date picker - only visible when _hasEndDate is true
              // '...' spread operator inserts the items into the parent Column
              if (_hasEndDate) ...[
                InkWell(
                  onTap: _selectEndDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'End Date',
                      prefixIcon: const Icon(Icons.event),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      // Show formatted date or placeholder text if no date chosen yet
                      _endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Select end date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _endDate == null ? Colors.grey.shade600 : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Description field - optional notes about this recurring transaction
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add notes or details',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3, // Allow multi-line input
              ),
              const SizedBox(height: 24),

              // Info box explaining automatic transaction creation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1), // Light blue background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Transactions will be automatically created based on the schedule. You can also execute manually.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button - full width, shows spinner while submitting
              SizedBox(
                width: double.infinity, // Stretch to full width
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm, // Disable while loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Recurring Transaction',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
