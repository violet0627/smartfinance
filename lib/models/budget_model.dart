// ==============================================================================
// budget_model.dart - Budget Data Models (Budget + Budget Category)
// ==============================================================================
// This file defines TWO related models:
// 1. BudgetModel - A monthly budget (e.g., "January 2025 - RM2000 total")
// 2. BudgetCategoryModel - A category within a budget (e.g., "Food - RM500")
//
// Relationship: One BudgetModel has MANY BudgetCategoryModel entries.
// Example:
//   Budget (January 2025, RM2000 total)
//   ├── Food:          RM500 allocated, RM350 spent
//   ├── Transport:     RM300 allocated, RM280 spent
//   ├── Entertainment: RM200 allocated, RM50 spent
//   └── Bills:         RM1000 allocated, RM950 spent
// ==============================================================================

// ==============================================================================
// BudgetModel - Represents a Monthly Budget
// ==============================================================================
class BudgetModel {
  final int? budgetId;                         // Unique ID (null for new budgets)
  final String monthYear;                      // Which month: "YYYY-MM" format (e.g., "2025-01")
  final String budgetPeriod;                   // Budget period type (e.g., "Monthly")
  final double totalBudget;                    // Total budget amount (e.g., 2000.00)
  final DateTime? createdAt;                   // When the budget was created
  final DateTime? updatedAt;                   // When the budget was last updated
  final int userId;                            // Which user owns this budget
  final List<BudgetCategoryModel> categories;  // List of category allocations

  // --- Constructor ---
  BudgetModel({
    this.budgetId,
    required this.monthYear,
    required this.budgetPeriod,
    required this.totalBudget,
    this.createdAt,
    this.updatedAt,
    required this.userId,
    required this.categories,
  });

  // ==============================================================================
  // fromJson - Create BudgetModel from JSON (API Response)
  // ==============================================================================
  // The categories field is a List of JSON objects, so we need to:
  // 1. Cast it to List (json['categories'] as List?)
  // 2. Map each item to a BudgetCategoryModel using .map()
  // 3. Convert back to List with .toList()
  // 4. Use ?? [] as fallback if categories is null (empty list)
  // ==============================================================================
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      budgetId: json['budgetId'],
      monthYear: json['monthYear'],
      budgetPeriod: json['budgetPeriod'],
      totalBudget: (json['totalBudget'] as num).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      userId: json['userId'],
      categories: (json['categories'] as List?)                    // Cast JSON array to Dart List
              ?.map((cat) => BudgetCategoryModel.fromJson(cat))    // Convert each item to BudgetCategoryModel
              .toList() ??                                          // Convert Iterable back to List
          [],                                                       // Default to empty list if null
    );
  }

  // ==============================================================================
  // toJson - Convert BudgetModel to JSON (For Sending to API)
  // ==============================================================================
  Map<String, dynamic> toJson() {
    return {
      if (budgetId != null) 'budgetId': budgetId,
      'monthYear': monthYear,
      'budgetPeriod': budgetPeriod,
      'totalBudget': totalBudget,
      'userId': userId,
      'categories': categories.map((cat) => cat.toJson()).toList(),  // Convert each category to JSON
    };
  }

  // --- Computed Properties (Getters) ---
  // These calculate values on-the-fly from the categories list.

  // Total amount spent across ALL categories
  // .fold() is like Python's reduce() - it accumulates a value across a list
  // Starting from 0.0, it adds each category's spentAmount
  double get totalSpent {
    return categories.fold(0.0, (sum, cat) => sum + cat.spentAmount);
  }

  // How much budget is remaining (total - spent)
  double get totalRemaining {
    return totalBudget - totalSpent;
  }

  // What percentage of the budget has been used (0-100)
  double get percentageUsed {
    if (totalBudget == 0) return 0.0;    // Avoid division by zero
    return (totalSpent / totalBudget) * 100;
  }

  // Is the total spending over the budget?
  bool get isOverBudget {
    return totalSpent > totalBudget;
  }

  // How many days are left in this budget's month
  int get daysLeftInMonth {
    final now = DateTime.now();
    final parts = monthYear.split('-');           // Split "2025-01" into ["2025", "01"]
    final year = int.parse(parts[0]);             // Parse year: 2025
    final month = int.parse(parts[1]);            // Parse month: 1
    final lastDay = DateTime(year, month + 1, 0); // Day 0 of next month = last day of this month
    return lastDay.difference(now).inDays;         // Days between now and end of month
  }
}

// ==============================================================================
// BudgetCategoryModel - Represents a Category Within a Budget
// ==============================================================================
// Each budget category tracks how much was allocated (planned) vs actually spent.
// Example: Food category - RM500 allocated, RM350 spent (70% used)
// ==============================================================================
class BudgetCategoryModel {
  final int? budgetCategoryId;   // Unique ID for this category entry
  final String categoryName;     // Category name (e.g., "Food", "Transport")
  final double allocatedAmount;  // How much budget was set aside for this category
  final double spentAmount;      // How much has actually been spent in this category
  final int? budgetId;           // Which budget this category belongs to

  // --- Constructor ---
  BudgetCategoryModel({
    this.budgetCategoryId,
    required this.categoryName,
    required this.allocatedAmount,
    required this.spentAmount,
    this.budgetId,
  });

  // --- fromJson ---
  factory BudgetCategoryModel.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryModel(
      budgetCategoryId: json['budgetCategoryId'],
      categoryName: json['categoryName'],
      allocatedAmount: (json['allocatedAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num).toDouble(),
      budgetId: json['budgetId'],
    );
  }

  // --- toJson ---
  Map<String, dynamic> toJson() {
    return {
      if (budgetCategoryId != null) 'budgetCategoryId': budgetCategoryId,
      'categoryName': categoryName,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      if (budgetId != null) 'budgetId': budgetId,
    };
  }

  // --- Computed Properties ---

  // How much budget remains in this category
  double get remaining {
    return allocatedAmount - spentAmount;
  }

  // What percentage of the allocation has been used (0-100)
  double get percentageUsed {
    if (allocatedAmount == 0) return 0.0;
    return (spentAmount / allocatedAmount) * 100;
  }

  // Is spending over the allocated amount for this category?
  bool get isOverBudget {
    return spentAmount > allocatedAmount;
  }
}
