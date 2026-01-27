import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';

class ExportService {
  /// Export transactions to CSV file
  static Future<String?> exportTransactionsToCSV(
    List<TransactionModel> transactions, {
    String? filename,
  }) async {
    try {
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        // Header row
        ['Date', 'Type', 'Category', 'Amount (RM)', 'Description'],
      ];

      // Add transaction rows
      for (var transaction in transactions) {
        csvData.add([
          DateFormat('yyyy-MM-dd').format(transaction.transactionDate),
          transaction.transactionType,
          transaction.category,
          transaction.amount.toStringAsFixed(2),
          transaction.description ?? '',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = filename ?? 'transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      print('Error exporting to CSV: $e');
      return null;
    }
  }

  /// Export financial report to PDF
  static Future<String?> exportReportToPDF({
    required Map<String, dynamic> summary,
    List<Map<String, dynamic>>? categoryBreakdown,
    String? filename,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Title
              pw.Header(
                level: 0,
                child: pw.Text(
                  'SmartFinance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Report Date
              pw.Text(
                'Generated: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Financial Summary Section
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Financial Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // Summary Table
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue,
                ),
                cellStyle: const pw.TextStyle(fontSize: 12),
                data: [
                  ['Metric', 'Amount (RM)'],
                  [
                    'Total Income',
                    ((summary['totalIncome'] ?? 0) as num).toDouble().toStringAsFixed(2),
                  ],
                  [
                    'Total Expense',
                    ((summary['totalExpense'] ?? 0) as num).toDouble().toStringAsFixed(2),
                  ],
                  [
                    'Net Savings',
                    ((summary['netSavings'] ?? 0) as num).toDouble().toStringAsFixed(2),
                  ],
                  [
                    'Savings Rate',
                    '${((summary['savingsRate'] ?? 0) as num).toDouble().toStringAsFixed(1)}%',
                  ],
                ],
              ),
              pw.SizedBox(height: 30),

              // Category Breakdown Section
              if (categoryBreakdown != null && categoryBreakdown.isNotEmpty) ...[
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Category Breakdown',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  data: [
                    ['Category', 'Amount (RM)', 'Percentage'],
                    ...categoryBreakdown.map((cat) => [
                          cat['category'] ?? '',
                          ((cat['amount'] ?? 0) as num).toDouble().toStringAsFixed(2),
                          '${((cat['percentage'] ?? 0) as num).toDouble().toStringAsFixed(1)}%',
                        ]),
                  ],
                ),
              ],

              pw.SizedBox(height: 30),

              // Footer
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated by SmartFinance © 2026',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ];
          },
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = filename ?? 'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      print('Error exporting to PDF: $e');
      return null;
    }
  }

  /// Share a file (CSV or PDF)
  static Future<bool> shareFile(String filePath, {String? subject}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('File does not exist: $filePath');
        return false;
      }

      final fileName = filePath.split('/').last;
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'SmartFinance Export - $fileName',
        text: 'Exported from SmartFinance',
      );

      return true;
    } catch (e) {
      print('Error sharing file: $e');
      return false;
    }
  }

  /// Get file size in a human-readable format
  static String getFileSize(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return 'Unknown';

      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Delete a file
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Export transactions with custom date range
  static Future<String?> exportTransactionsByDateRange({
    required List<TransactionModel> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final filtered = transactions.where((t) {
      return !t.transactionDate.isBefore(startDate) &&
             !t.transactionDate.isAfter(endDate);
    }).toList();

    final dateRange = '${DateFormat('yyyy-MM-dd').format(startDate)}_to_${DateFormat('yyyy-MM-dd').format(endDate)}';
    return await exportTransactionsToCSV(
      filtered,
      filename: 'transactions_$dateRange.csv',
    );
  }

  /// Export budget report to PDF
  static Future<String?> exportBudgetReportToPDF({
    required Map<String, dynamic> budgetData,
    String? filename,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Title
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Budget Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Report Date
              pw.Text(
                'Generated: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Budget Overview
              pw.Text(
                'Budget: ${budgetData['month'] ?? 'N/A'} ${budgetData['year'] ?? ''}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue,
                ),
                data: [
                  ['Metric', 'Amount (RM)'],
                  [
                    'Total Budget',
                    ((budgetData['totalAmount'] ?? 0) as num).toDouble().toStringAsFixed(2),
                  ],
                  [
                    'Total Spent',
                    ((budgetData['totalSpent'] ?? 0) as num).toDouble().toStringAsFixed(2),
                  ],
                  [
                    'Remaining',
                    ((budgetData['remaining'] ?? 0) as num).toDouble().toStringAsFixed(2),
                  ],
                  [
                    'Percentage Used',
                    '${((budgetData['percentageUsed'] ?? 0) as num).toDouble().toStringAsFixed(1)}%',
                  ],
                ],
              ),

              pw.SizedBox(height: 20),

              // Category Breakdown
              if (budgetData['categories'] != null) ...[
                pw.Text(
                  'Category Breakdown',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),

                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue,
                  ),
                  data: [
                    ['Category', 'Budgeted', 'Spent', 'Remaining'],
                    ...(budgetData['categories'] as List).map((cat) => [
                          cat['category'] ?? '',
                          ((cat['allocated'] ?? 0) as num).toDouble().toStringAsFixed(2),
                          ((cat['spent'] ?? 0) as num).toDouble().toStringAsFixed(2),
                          ((cat['remaining'] ?? 0) as num).toDouble().toStringAsFixed(2),
                        ]),
                  ],
                ),
              ],

              pw.SizedBox(height: 30),
              pw.Divider(thickness: 1),
              pw.Text(
                'Generated by SmartFinance © 2026',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ];
          },
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = filename ?? 'budget_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      print('Error exporting budget to PDF: $e');
      return null;
    }
  }
}
