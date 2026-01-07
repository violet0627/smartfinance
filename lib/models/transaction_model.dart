class TransactionModel {
  final int? transactionId;
  final double amount;
  final String category;
  final String? description;
  final DateTime transactionDate;
  final String transactionType; // 'income' or 'expense'
  final DateTime? createdAt;
  final int userId;

  TransactionModel({
    this.transactionId,
    required this.amount,
    required this.category,
    this.description,
    required this.transactionDate,
    required this.transactionType,
    this.createdAt,
    required this.userId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transactionId'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      description: json['description'],
      transactionDate: DateTime.parse(json['transactionDate']),
      transactionType: json['transactionType'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (transactionId != null) 'transactionId': transactionId,
      'amount': amount,
      'category': category,
      'description': description ?? '',
      'transactionDate': transactionDate.toIso8601String().split('T')[0],
      'transactionType': transactionType,
      'userId': userId,
    };
  }

  bool get isIncome => transactionType == 'income';
  bool get isExpense => transactionType == 'expense';
}
