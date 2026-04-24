// ==============================================================================
// transaction_model.dart - Transaction Data Model
// ==============================================================================
// This file defines the TransactionModel class which represents a single
// financial transaction (either income or expense) in the Flutter app.
//
// This is the client-side model that corresponds to the backend's Transaction model.
// It converts JSON data from the API into Dart objects for easy use in the UI.
//
// Example: A lunch expense of RM15 at KFC on January 15, 2025
// ==============================================================================

class TransactionModel {
  // --- Properties ---
  final int? transactionId;          // Unique ID (nullable because new transactions don't have one yet)
  final double amount;               // Transaction amount (e.g., 15.00)
  final String category;             // Category (e.g., "Food", "Transport", "Salary")
  final String? description;         // Optional description (e.g., "Lunch at KFC")
  final DateTime transactionDate;    // When the transaction occurred
  final String transactionType;      // "income" or "expense"
  final DateTime? createdAt;         // When the record was created in the database
  final int userId;                  // Which user this transaction belongs to

  // --- Constructor ---
  TransactionModel({
    this.transactionId,              // Optional (null for new transactions not yet saved)
    required this.amount,            // Required - must provide an amount
    required this.category,          // Required - must specify a category
    this.description,                // Optional description
    required this.transactionDate,   // Required - when did this happen?
    required this.transactionType,   // Required - income or expense?
    this.createdAt,                  // Optional - set by the database
    required this.userId,            // Required - who owns this transaction?
  });

  // ==============================================================================
  // fromJson - Create TransactionModel from JSON (API Response)
  // ==============================================================================
  // Called when receiving transaction data from the backend API.
  //
  // (json['amount'] as num).toDouble() explanation:
  // The JSON parser might give us an int (45) or a double (45.0).
  // "as num" accepts both types, then .toDouble() converts to double.
  // ==============================================================================
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transactionId'],
      amount: (json['amount'] as num).toDouble(),   // Handle both int and double from JSON
      category: json['category'],
      description: json['description'],
      transactionDate: DateTime.parse(json['transactionDate']),  // Parse date string to DateTime
      transactionType: json['transactionType'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      userId: json['userId'],
    );
  }

  // ==============================================================================
  // toJson - Convert TransactionModel to JSON (For Sending to API)
  // ==============================================================================
  // Called when sending transaction data to the backend API (e.g., creating/updating).
  //
  // "if (transactionId != null)" is a collection-if:
  // The key-value pair is only included in the map if the condition is true.
  // New transactions don't have an ID, so we skip it.
  //
  // .split('T')[0] explanation:
  // DateTime.toIso8601String() produces "2025-01-15T00:00:00.000"
  // .split('T') splits it into ["2025-01-15", "00:00:00.000"]
  // [0] takes the first part: "2025-01-15" (just the date, no time)
  // ==============================================================================
  Map<String, dynamic> toJson() {
    return {
      if (transactionId != null) 'transactionId': transactionId,  // Only include if not null
      'amount': amount,
      'category': category,
      'description': description ?? '',                             // Use empty string if null
      'transactionDate': transactionDate.toIso8601String().split('T')[0],  // "YYYY-MM-DD" format
      'transactionType': transactionType,
      'userId': userId,
    };
  }

  // --- Computed Properties (Getters) ---
  // These are convenient shortcuts that calculate a value from existing data.
  // "get" keyword creates a property that's computed on-the-fly.

  bool get isIncome => transactionType == 'income';    // True if this is an income transaction
  bool get isExpense => transactionType == 'expense';  // True if this is an expense transaction
}
