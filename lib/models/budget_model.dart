class BudgetModel {
  final int? budgetId;
  final String monthYear; // Format: YYYY-MM
  final String budgetPeriod;
  final double totalBudget;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int userId;
  final List<BudgetCategoryModel> categories;

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

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      budgetId: json['budgetId'],
      monthYear: json['monthYear'],
      budgetPeriod: json['budgetPeriod'],
      totalBudget: (json['totalBudget'] as num).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      userId: json['userId'],
      categories: (json['categories'] as List?)
              ?.map((cat) => BudgetCategoryModel.fromJson(cat))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (budgetId != null) 'budgetId': budgetId,
      'monthYear': monthYear,
      'budgetPeriod': budgetPeriod,
      'totalBudget': totalBudget,
      'userId': userId,
      'categories': categories.map((cat) => cat.toJson()).toList(),
    };
  }

  double get totalSpent {
    return categories.fold(0.0, (sum, cat) => sum + cat.spentAmount);
  }

  double get totalRemaining {
    return totalBudget - totalSpent;
  }

  double get percentageUsed {
    if (totalBudget == 0) return 0.0;
    return (totalSpent / totalBudget) * 100;
  }

  bool get isOverBudget {
    return totalSpent > totalBudget;
  }

  int get daysLeftInMonth {
    final now = DateTime.now();
    final parts = monthYear.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final lastDay = DateTime(year, month + 1, 0);
    return lastDay.difference(now).inDays;
  }
}

class BudgetCategoryModel {
  final int? budgetCategoryId;
  final String categoryName;
  final double allocatedAmount;
  final double spentAmount;
  final int? budgetId;

  BudgetCategoryModel({
    this.budgetCategoryId,
    required this.categoryName,
    required this.allocatedAmount,
    required this.spentAmount,
    this.budgetId,
  });

  factory BudgetCategoryModel.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryModel(
      budgetCategoryId: json['budgetCategoryId'],
      categoryName: json['categoryName'],
      allocatedAmount: (json['allocatedAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num).toDouble(),
      budgetId: json['budgetId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (budgetCategoryId != null) 'budgetCategoryId': budgetCategoryId,
      'categoryName': categoryName,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      if (budgetId != null) 'budgetId': budgetId,
    };
  }

  double get remaining {
    return allocatedAmount - spentAmount;
  }

  double get percentageUsed {
    if (allocatedAmount == 0) return 0.0;
    return (spentAmount / allocatedAmount) * 100;
  }

  bool get isOverBudget {
    return spentAmount > allocatedAmount;
  }
}
