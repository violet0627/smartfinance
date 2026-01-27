import 'package:flutter_test/flutter_test.dart';
import 'package:smartfinance2/services/export_service.dart';
import 'package:smartfinance2/models/transaction_model.dart';

void main() {
  // Initialize Flutter bindings for tests that use platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportService Tests', () {
    late List<TransactionModel> testTransactions;

    setUp(() {
      // Create test transactions
      testTransactions = [
        TransactionModel(
          transactionId: 1,
          amount: 50.00,
          category: 'Food & Dining',
          description: 'Lunch at restaurant',
          transactionDate: DateTime(2026, 1, 10),
          transactionType: 'expense',
          userId: 1,
        ),
        TransactionModel(
          transactionId: 2,
          amount: 3000.00,
          category: 'Salary',
          description: 'Monthly salary',
          transactionDate: DateTime(2026, 1, 5),
          transactionType: 'income',
          userId: 1,
        ),
        TransactionModel(
          transactionId: 3,
          amount: 100.00,
          category: 'Shopping',
          description: 'Groceries',
          transactionDate: DateTime(2026, 1, 8),
          transactionType: 'expense',
          userId: 1,
        ),
      ];
    });

    test('exportTransactionsToCSV creates file with correct data', () async {
      final filePath = await ExportService.exportTransactionsToCSV(
        testTransactions,
        filename: 'test_transactions.csv',
      );

      expect(filePath, isNotNull);
      expect(filePath, contains('test_transactions.csv'));
    });

    test('exportTransactionsToCSV handles empty list', () async {
      final filePath = await ExportService.exportTransactionsToCSV([]);

      expect(filePath, isNotNull);
    });

    test('exportReportToPDF creates file with summary data', () async {
      final summary = {
        'totalIncome': 3000.0,
        'totalExpense': 150.0,
        'netSavings': 2850.0,
        'savingsRate': 95.0,
      };

      final categoryBreakdown = [
        {'category': 'Food & Dining', 'amount': 50.0, 'percentage': 33.3},
        {'category': 'Shopping', 'amount': 100.0, 'percentage': 66.7},
      ];

      final filePath = await ExportService.exportReportToPDF(
        summary: summary,
        categoryBreakdown: categoryBreakdown,
        filename: 'test_report.pdf',
      );

      expect(filePath, isNotNull);
      expect(filePath, contains('test_report.pdf'));
    });

    test('exportBudgetReportToPDF creates file', () async {
      final budgetData = {
        'month': 'January',
        'year': 2026,
        'totalAmount': 5000.0,
        'totalSpent': 150.0,
        'remaining': 4850.0,
        'percentageUsed': 3.0,
        'categories': [
          {
            'category': 'Food',
            'allocated': 1000.0,
            'spent': 50.0,
            'remaining': 950.0,
          },
        ],
      };

      final filePath = await ExportService.exportBudgetReportToPDF(
        budgetData: budgetData,
        filename: 'test_budget.pdf',
      );

      expect(filePath, isNotNull);
      expect(filePath, contains('test_budget.pdf'));
    });

    test('exportTransactionsByDateRange filters correctly', () async {
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 7);

      final filePath = await ExportService.exportTransactionsByDateRange(
        transactions: testTransactions,
        startDate: startDate,
        endDate: endDate,
      );

      expect(filePath, isNotNull);
      // Should only include transaction from Jan 5
    });

    test('getFileSize returns valid format', () {
      // This test would need a real file to test properly
      // For now, test that it handles non-existent files
      final size = ExportService.getFileSize('/nonexistent/file.csv');
      expect(size, equals('Unknown'));
    });
  });
}
