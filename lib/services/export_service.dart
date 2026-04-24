import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';

class ExportService {

  // JSON numbers can come back as int, double, or String — "as num" throws on String
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static Future<String?> exportTransactionsToCSV(
    List<TransactionModel> transactions, {
    String? filename,
  }) async {
    try {
      List<List<dynamic>> csvData = [
        ['Date', 'Type', 'Category', 'Amount (RM)', 'Description'],
      ];

      for (var transaction in transactions) {
        csvData.add([
          DateFormat('yyyy-MM-dd').format(transaction.transactionDate),
          transaction.transactionType,
          transaction.category,
          transaction.amount.toStringAsFixed(2),
          transaction.description ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);

      final directory = await getApplicationDocumentsDirectory();
      final fileName = filename ?? 'transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      return null;
    }
  }

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
              pw.Header(
                level: 0,
                child: pw.Text(
                  'SmartFinance Report',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Financial Summary',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                cellStyle: const pw.TextStyle(fontSize: 12),
                data: [
                  ['Metric', 'Amount (RM)'],
                  ['Total Income', _toDouble(summary['totalIncome']).toStringAsFixed(2)],
                  ['Total Expense', _toDouble(summary['totalExpense']).toStringAsFixed(2)],
                  ['Net Savings', _toDouble(summary['netSavings']).toStringAsFixed(2)],
                  ['Savings Rate', '${_toDouble(summary['savingsRate']).toStringAsFixed(1)}%'],
                ],
              ),
              pw.SizedBox(height: 30),
              if (categoryBreakdown != null && categoryBreakdown.isNotEmpty) ...[
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Category Breakdown',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  data: [
                    ['Category', 'Amount (RM)', 'Percentage'],
                    ...categoryBreakdown.map((cat) => [
                          cat['category'] ?? '',
                          _toDouble(cat['amount']).toStringAsFixed(2),
                          '${_toDouble(cat['percentage']).toStringAsFixed(1)}%',
                        ]),
                  ],
                ),
              ],
              pw.SizedBox(height: 30),
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

      final directory = await getApplicationDocumentsDirectory();
      final fileName = filename ?? 'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      debugPrint('Error exporting to PDF: $e');
      return null;
    }
  }

  static Future<bool> shareFile(String filePath, {String? subject}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
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
      debugPrint('Error sharing file: $e');
      return false;
    }
  }

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

  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

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
    return await exportTransactionsToCSV(filtered, filename: 'transactions_$dateRange.csv');
  }

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
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Budget Report',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              pw.Text(
                'Budget: ${budgetData['month'] ?? 'N/A'} ${budgetData['year'] ?? ''}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                data: [
                  ['Metric', 'Amount (RM)'],
                  ['Total Budget', _toDouble(budgetData['totalAmount']).toStringAsFixed(2)],
                  ['Total Spent', _toDouble(budgetData['totalSpent']).toStringAsFixed(2)],
                  ['Remaining', _toDouble(budgetData['remaining']).toStringAsFixed(2)],
                  ['Percentage Used', '${_toDouble(budgetData['percentageUsed']).toStringAsFixed(1)}%'],
                ],
              ),
              pw.SizedBox(height: 20),
              if (budgetData['categories'] != null) ...[
                pw.Text(
                  'Category Breakdown',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                  data: [
                    ['Category', 'Budgeted', 'Spent', 'Remaining'],
                    ...(budgetData['categories'] as List).map((cat) => [
                          cat['category'] ?? '',
                          // 'allocated' is the key sent by export_service.dart; 'budgeted' is the fallback
                          _toDouble(cat['allocated'] ?? cat['budgeted']).toStringAsFixed(2),
                          _toDouble(cat['spent']).toStringAsFixed(2),
                          _toDouble(cat['remaining']).toStringAsFixed(2),
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

      final directory = await getApplicationDocumentsDirectory();
      final fileName = filename ?? 'budget_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      debugPrint('Error exporting budget to PDF: $e');
      return null;
    }
  }
}
