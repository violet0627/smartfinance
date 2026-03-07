// add_goal_screen.dart
// This screen handles both creating a new financial goal and editing an existing one.
// If 'existingGoal' is passed in, the form is pre-filled for editing; otherwise it's blank for creating.
// Users enter a name, description, target amount, deadline, category (chips), and priority (buttons).

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:intl/intl.dart'; // Date formatting (e.g., "Mar 15, 2025")
import '../../services/api_service.dart'; // Backend API calls
import '../../utils/colors.dart'; // AppColors constants

// AddGoalScreen is a StatefulWidget because form fields and selected values change over time
class AddGoalScreen extends StatefulWidget {
  // existingGoal is optional - if provided, the screen works in "edit" mode
  // Map<String, dynamic> is a dictionary type: keys are Strings, values can be anything
  final Map<String, dynamic>? existingGoal; // '?' means this is nullable (can be null)

  const AddGoalScreen({super.key, this.existingGoal}); // existingGoal defaults to null

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  // GlobalKey<FormState> allows programmatic validation of all form fields at once
  final _formKey = GlobalKey<FormState>();

  // TextEditingControllers manage the text in each input field
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController(); // Only shown when editing

  DateTime? _selectedDeadline; // null means no deadline chosen yet
  String _selectedCategory = 'Other'; // Default category selection
  String _selectedPriority = 'medium'; // Default priority: 'low', 'medium', or 'high'
  List<Map<String, dynamic>> _categories = []; // Loaded from API - list of goal categories
  bool _isLoading = false; // True while loading categories from API
  bool _isSaving = false;  // True while saving the goal to the API

  // Maps icon name strings (from the API) to Flutter IconData objects
  // The API returns icon names as strings like 'emergency', 'home', etc.
  final Map<String, IconData> _categoryIcons = {
    'emergency': Icons.warning_amber,
    'flight': Icons.flight,
    'home': Icons.home,
    'school': Icons.school,
    'directions_car': Icons.directions_car,
    'favorite': Icons.favorite,
    'elderly': Icons.elderly,
    'business': Icons.business,
    'trending_up': Icons.trending_up,
    'savings': Icons.savings,
  };

  @override
  void initState() {
    super.initState(); // Always call super.initState() first
    _loadCategories();  // Fetch goal categories from the backend
    _initializeForm();  // Pre-fill form if we're editing an existing goal
  }

  @override
  void dispose() {
    // Dispose all TextEditingControllers to free memory when the widget is removed
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  // _initializeForm pre-populates the form fields when editing an existing goal
  void _initializeForm() {
    if (widget.existingGoal != null) {
      // widget.existingGoal accesses the existingGoal passed to the widget
      final goal = widget.existingGoal!; // '!' asserts it's not null
      _nameController.text = goal['goalName'] ?? '';
      _descriptionController.text = goal['description'] ?? '';
      // toString() converts the number to a String for the text field
      _targetAmountController.text = goal['targetAmount']?.toString() ?? '';
      _currentAmountController.text = goal['currentAmount']?.toString() ?? '0';
      _selectedCategory = goal['category'] ?? 'Other';
      _selectedPriority = goal['priority'] ?? 'medium';
      if (goal['deadline'] != null) {
        // DateTime.parse converts an ISO date string "2025-12-31" to a DateTime object
        _selectedDeadline = DateTime.parse(goal['deadline']);
      }
    }
  }

  // _loadCategories fetches the available goal categories from the backend
  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    final result = await ApiService.getGoalCategories();

    if (result['success']) {
      setState(() {
        // List.from() creates a typed List<Map<String, dynamic>> from the raw API response
        _categories = List<Map<String, dynamic>>.from(result['categories']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // _selectDeadline opens a calendar date picker dialog for the user to choose a deadline
  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      // If no deadline is set, default to 30 days from now
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(), // Can't set a past deadline
      lastDate: DateTime.now().add(const Duration(days: 3650)), // Max 10 years ahead
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked; // Update state to show the new date
      });
    }
  }

  // _saveGoal validates the form and sends the goal data to the backend
  Future<void> _saveGoal() async {
    // validate() calls all TextFormField validator functions
    // Returns false if any field has an error
    if (!_formKey.currentState!.validate()) return;

    // Extra validation: deadline is required but not in the Form
    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a deadline'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    // double.tryParse safely converts String to double - returns null if invalid
    final targetAmount = double.tryParse(_targetAmountController.text);
    // When editing, use the entered current amount; when creating, start at 0
    final currentAmount = widget.existingGoal != null
        ? double.tryParse(_currentAmountController.text) ?? 0.0
        : 0.0; // New goals always start with 0 saved

    // Validate target amount is a positive number
    if (targetAmount == null || targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid target amount'),
          backgroundColor: AppColors.danger,
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    // Current saved amount can't exceed the target
    if (currentAmount > targetAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current amount cannot exceed target amount'),
          backgroundColor: AppColors.danger,
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    // Build the data map to send to the API
    final goalData = {
      'goalName': _nameController.text,
      'description': _descriptionController.text,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      // DateFormat('yyyy-MM-dd') formats DateTime to "2025-12-31" (ISO 8601 format for backend)
      'deadline': DateFormat('yyyy-MM-dd').format(_selectedDeadline!),
      'category': _selectedCategory,
      'priority': _selectedPriority,
    };

    // Call different API methods depending on whether we're creating or editing
    final result = widget.existingGoal != null
        ? await ApiService.updateGoal(widget.existingGoal!['goalId'], goalData) // Edit mode
        : await ApiService.createGoal(userId, goalData); // Create mode

    setState(() => _isSaving = false);

    if (!mounted) return; // Check widget is still in tree after async gap

    if (result['success']) {
      Navigator.pop(context, true); // Go back and signal to refresh the goals list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Show different messages for create vs edit
          content: Text(widget.existingGoal != null ? 'Goal updated successfully' : 'Goal created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to save goal'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Dynamic title: "Edit Goal" or "Add New Goal" based on whether existingGoal is set
        title: Text(widget.existingGoal != null ? 'Edit Goal' : 'Add New Goal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      // Show spinner while categories are loading, otherwise show the form
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // Allows the form to scroll when the keyboard appears
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey, // Attach the form key for validation
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Left-align labels
                  children: [
                    // Goal Name field - required
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Goal Name *', // '*' indicates required field
                        hintText: 'e.g., Emergency Fund',
                        prefixIcon: const Icon(Icons.flag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a goal name';
                        }
                        return null; // null = valid
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field - optional, allows multiple lines
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional details about your goal',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3, // Allow up to 3 lines of text
                    ),
                    const SizedBox(height: 16),

                    // Target Amount field - required, must be a positive number
                    TextFormField(
                      controller: _targetAmountController,
                      decoration: InputDecoration(
                        labelText: 'Target Amount (RM) *',
                        hintText: 'e.g., 10000',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number, // Show numeric keyboard
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a target amount';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Current Amount field - only shown when editing an existing goal
                    // '...' is the spread operator - it inserts the list items directly into the parent list
                    if (widget.existingGoal != null) ...[
                      TextFormField(
                        controller: _currentAmountController,
                        decoration: InputDecoration(
                          labelText: 'Current Amount (RM) *',
                          hintText: 'e.g., 5000',
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter current amount';
                          }
                          // Current amount can be 0 (just started) but not negative
                          if (double.tryParse(value) == null || double.parse(value) < 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Deadline picker - shows a styled container that looks like a form field
                    InkWell(
                      // InkWell adds a tap ripple effect to any widget
                      onTap: _selectDeadline,
                      child: InputDecorator(
                        // InputDecorator makes a non-input widget look like a form field (with label, border)
                        decoration: InputDecoration(
                          labelText: 'Deadline *',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          // Show formatted date if selected, or placeholder text if not
                          _selectedDeadline != null
                              ? DateFormat('MMM dd, yyyy').format(_selectedDeadline!) // e.g., "Mar 15, 2025"
                              : 'Select deadline date',
                          style: TextStyle(
                            fontSize: 16,
                            // Grey text for placeholder, dark text when date is selected
                            color: _selectedDeadline != null ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category selection using ChoiceChips
                    const Text(
                      'Category',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      // Wrap lays out children horizontally and wraps to the next line when full
                      spacing: 8,    // Horizontal gap between chips
                      runSpacing: 8, // Vertical gap between rows of chips
                      children: _categories.map((category) {
                        // .map() transforms each category item into a ChoiceChip widget
                        final isSelected = _selectedCategory == category['name'];
                        return ChoiceChip(
                          // ChoiceChip is a selectable chip that shows one selection at a time
                          label: Row(
                            mainAxisSize: MainAxisSize.min, // Row only as wide as its children
                            children: [
                              Icon(
                                // Look up the icon by name; fall back to savings icon if not found
                                _categoryIcons[category['icon']] ?? Icons.savings,
                                size: 18,
                                // White icon on selected chip, primary color on unselected
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(category['name']), // Category name text
                            ],
                          ),
                          selected: isSelected, // True if this chip is the currently selected one
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category['name']; // Update selected category
                            });
                          },
                          selectedColor: AppColors.primary, // Background color when selected
                          backgroundColor: Colors.grey.shade200, // Background color when unselected
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        );
                      }).toList(), // .toList() converts the Iterable from .map() back to a List
                    ),
                    const SizedBox(height: 24),

                    // Priority selection using custom OutlinedButtons (Low / Medium / High)
                    const Text(
                      'Priority',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          // Expanded fills equal share of available width
                          child: _buildPriorityButton('low', 'Low', Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPriorityButton('medium', 'Medium', Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPriorityButton('high', 'High', Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save / Create button at bottom
                    SizedBox(
                      width: double.infinity, // Full-width button
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveGoal, // Disable while saving
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                // Dynamic label based on create vs edit mode
                                widget.existingGoal != null ? 'Update Goal' : 'Create Goal',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // _buildPriorityButton creates a styled OutlinedButton for a priority level
  // value: the priority string ('low', 'medium', 'high')
  // label: display text ('Low', 'Medium', 'High')
  // color: the color for this priority level
  Widget _buildPriorityButton(String value, String label, Color color) {
    final isSelected = _selectedPriority == value; // Is this the currently selected priority?
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedPriority = value; // Update the selected priority
        });
      },
      style: OutlinedButton.styleFrom(
        // Lightly tinted background when selected, white when unselected
        backgroundColor: isSelected ? color.withOpacity(0.1) : Colors.white,
        side: BorderSide(
          // Colored and thicker border when selected; grey and thinner when unselected
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? color : Colors.black87, // Colored text when selected
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
