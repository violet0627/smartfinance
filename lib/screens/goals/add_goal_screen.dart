import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';

class AddGoalScreen extends StatefulWidget {
  final Map<String, dynamic>? existingGoal;

  const AddGoalScreen({super.key, this.existingGoal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();

  DateTime? _selectedDeadline;
  String _selectedCategory = 'Other';
  String _selectedPriority = 'medium';
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  bool _isSaving = false;

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
    super.initState();
    _loadCategories();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.existingGoal != null) {
      final goal = widget.existingGoal!;
      _nameController.text = goal['goalName'] ?? '';
      _descriptionController.text = goal['description'] ?? '';
      _targetAmountController.text = goal['targetAmount']?.toString() ?? '';
      _currentAmountController.text = goal['currentAmount']?.toString() ?? '0';
      _selectedCategory = goal['category'] ?? 'Other';
      _selectedPriority = goal['priority'] ?? 'medium';
      if (goal['deadline'] != null) {
        _selectedDeadline = DateTime.parse(goal['deadline']);
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    final result = await ApiService.getGoalCategories();

    if (result['success']) {
      setState(() {
        _categories = List<Map<String, dynamic>>.from(result['categories']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

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

    // Safe parsing with error handling
    final targetAmount = double.tryParse(_targetAmountController.text);
    final currentAmount = widget.existingGoal != null
        ? double.tryParse(_currentAmountController.text) ?? 0.0
        : 0.0;

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

    // Validate current amount doesn't exceed target
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

    final goalData = {
      'goalName': _nameController.text,
      'description': _descriptionController.text,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': DateFormat('yyyy-MM-dd').format(_selectedDeadline!),
      'category': _selectedCategory,
      'priority': _selectedPriority,
    };

    final result = widget.existingGoal != null
        ? await ApiService.updateGoal(widget.existingGoal!['goalId'], goalData)
        : await ApiService.createGoal(userId, goalData);

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result['success']) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
        title: Text(widget.existingGoal != null ? 'Edit Goal' : 'Add New Goal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Goal Name *',
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
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
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Target Amount
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
                      keyboardType: TextInputType.number,
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

                    // Current Amount (only for editing)
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
                          if (double.tryParse(value) == null || double.parse(value) < 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Deadline
                    InkWell(
                      onTap: _selectDeadline,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Deadline *',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selectedDeadline != null
                              ? DateFormat('MMM dd, yyyy').format(_selectedDeadline!)
                              : 'Select deadline date',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDeadline != null ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category
                    const Text(
                      'Category',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category['name'];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _categoryIcons[category['icon']] ?? Icons.savings,
                                size: 18,
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(category['name']),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category['name'];
                            });
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Priority
                    const Text(
                      'Priority',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
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

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveGoal,
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

  Widget _buildPriorityButton(String value, String label, Color color) {
    final isSelected = _selectedPriority == value;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedPriority = value;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color.withOpacity(0.1) : Colors.white,
        side: BorderSide(
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
          color: isSelected ? color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
