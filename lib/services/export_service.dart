// ==============================================================================
// export_service.dart - File Export Service (CSV & PDF)
// ==============================================================================
// This service handles exporting financial data to files that users can
// save or share. It supports two formats:
//
// 1. CSV (Comma-Separated Values) - Simple spreadsheet format
//    - Opens in Excel, Google Sheets, etc.
//    - Used for raw transaction data
//
// 2. PDF (Portable Document Format) - Formatted reports
//    - Professional-looking financial reports
//    - Used for spending summaries and budget reports
//
// The export flow:
// 1. Prepare data (convert to rows/tables)
// 2. Create the file in the app's documents directory
// 3. Optionally share the file using the system share dialog
//
// Key packages used:
// - csv: Converts List<List> data to CSV format
// - pdf/widgets: Creates PDF documents with tables and headers
// - path_provider: Gets the app's documents directory path
// - share_plus: Opens the system share dialog for sharing files
// ==============================================================================

import 'dart:io';                              // For File operations (read/write/delete)
import 'package:flutter/foundation.dart';      // For debugPrint (only prints in debug mode, not release)
import 'package:csv/csv.dart';                 // For converting data to CSV format
import 'package:intl/intl.dart';               // For date formatting (DateFormat)
import 'package:path_provider/path_provider.dart'; // For getting app documents directory
import 'package:pdf/pdf.dart';                 // For PDF colors and page format constants
import 'package:pdf/widgets.dart' as pw;       // PDF widget library (aliased as "pw" to avoid conflicts with Flutter widgets)
import 'package:share_plus/share_plus.dart';   // For system share dialog
import '../models/transaction_model.dart';     // Transaction data model

class ExportService {

  // ==============================================================================
  // _toDouble - Safely Convert Any JSON Value to double
  // ==============================================================================
  // JSON numbers can come back as int, double, or even String depending on the
  // backend. Using "as num" throws TypeError if the value is a String.
  // This helper handles all cases safely.
  // ==============================================================================
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    // If it's a String (some backends serialize numbers as strings), parse it
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // ==============================================================================
  // exportTransactionsToCSV - Export Transaction List to CSV File
  // ==============================================================================
  // Creates a CSV file with columns: Date, Type, Category, Amount, Description
  //
  // How CSV works:
  // 1. Create a List of Lists (each inner list = one row)
  // 2. First row = headers: ['Date', 'Type', 'Category', ...]
  // 3. Each subsequent row = transaction data
  // 4. ListToCsvConverter().convert() turns it into a CSV string
  // 5. Write the string to a file
  //
  // Returns the file path on success, or null on failure.
  // ==============================================================================
  static Future<String?> exportTransactionsToCSV(
    List<TransactionModel> transactions, {
    String? filename,                      // Optional custom filename
  }) async {
    try {
      // Step 1: Prepare CSV data as a List of Lists
      List<List<dynamic>> csvData = [
        // Header row (first row)
        ['Date', 'Type', 'Category', 'Amount (RM)', 'Description'],
      ];

      // Step 2: Add each transaction as a row
      for (var transaction in transactions) {
        csvData.add([
          DateFormat('yyyy-MM-dd').format(transaction.transactionDate),  // Format date
          transaction.transactionType,                                    // "income" or "expense"
          transaction.category,                                           // Category name
          transaction.amount.toStringAsFixed(2),                          // Amount with 2 decimal places
          transaction.description ?? '',                                  // Description (empty if null)
        ]);
      }

      // Step 3: Convert List of Lists to CSV string
      // ListToCsvConverter handles proper CSV formatting (escaping commas, quotes, etc.)
      String csv = const ListToCsvConverter().convert(csvData);

      // Step 4: Save to the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      // getApplicationDocumentsDirectory() returns the app's private documents folder
      // On Android: /data/data/com.example.app/app_flutter/
      // On iOS: <app_sandbox>/Documents/

      final fileName = filename ?? 'transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      // millisecondsSinceEpoch creates a unique filename: transactions_1706400000000.csv
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csv);          // Write CSV string to file

      return filePath;                        // Return the path where file was saved
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      return null;
    }
  }

  // ==============================================================================
  // exportReportToPDF - Export Financial Summary to PDF
  // ==============================================================================
  // Creates a professional PDF report with:
  // - Title and generation date
  // - Financial Summary table (income, expense, savings, savings rate)
  // - Category Breakdown table (optional)
  // - Footer with branding
  //
  // The pdf package uses its own widget system (similar to Flutter but for PDF):
  // - pw.Document() = the PDF document
  // - pw.MultiPage() = a page that can span multiple pages
  // - pw.Header() = section header
  // - pw.Table.fromTextArray() = creates a table from data
  // - pw.SizedBox() = spacing
  // - pw.Divider() = horizontal line
  //
  // "pw" prefix is used because "pdf/widgets.dart" is aliased as "pw"
  // to avoid conflicts with Flutter's own Widget, Text, etc.
  // ==============================================================================
  static Future<String?> exportReportToPDF({
    required Map<String, dynamic> summary,               // Financial summary data
    List<Map<String, dynamic>>? categoryBreakdown,       // Optional category data
    String? filename,                                     // Optional custom filename
  }) async {
    try {
      // Create a new PDF document
      final pdf = pw.Document();

      // Add a page to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,                    // Standard A4 paper size
          margin: const pw.EdgeInsets.all(32),             // 32pt margins on all sides
          build: (pw.Context context) {
            // Return a list of widgets that make up the page content
            return [
              // --- Title ---
              pw.Header(
                level: 0,                                  // Level 0 = main title
                child: pw.Text(
                  'SmartFinance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),                    // 20pt vertical spacing

              // --- Report Date ---
              pw.Text(
                'Generated: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                // DateFormat('MMMM dd, yyyy') formats as "January 15, 2025"
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 2),                   // Horizontal line separator
              pw.SizedBox(height: 20),

              // --- Financial Summary Section ---
              pw.Header(
                level: 1,                                  // Level 1 = section header
                child: pw.Text(
                  'Financial Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // --- Summary Table ---
              // Table.fromTextArray creates a table from a 2D list of strings
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,                  // White text on blue background
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue,                   // Blue header row
                ),
                cellStyle: const pw.TextStyle(fontSize: 12),
                data: [
                  ['Metric', 'Amount (RM)'],               // Header row
                  [
                    'Total Income',
                    _toDouble(summary['totalIncome']).toStringAsFixed(2),
                    // _toDouble() safely converts int, double, or String to double
                    // .toStringAsFixed(2) formats as "1234.56"
                  ],
                  [
                    'Total Expense',
                    _toDouble(summary['totalExpense']).toStringAsFixed(2),
                  ],
                  [
                    'Net Savings',
                    _toDouble(summary['netSavings']).toStringAsFixed(2),
                  ],
                  [
                    'Savings Rate',
                    '${_toDouble(summary['savingsRate']).toStringAsFixed(1)}%',
                  ],
                ],
              ),
              pw.SizedBox(height: 30),

              // --- Category Breakdown Section (Optional) ---
              // Only shown if categoryBreakdown data is provided and not empty
              // The ... spread operator with if condition creates conditional content
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
                    ['Category', 'Amount (RM)', 'Percentage'],   // Header row
                    // Map each category to a table row using the spread operator (...)
                    ...categoryBreakdown.map((cat) => [
                          cat['category'] ?? '',
                          _toDouble(cat['amount']).toStringAsFixed(2),
                          '${_toDouble(cat['percentage']).toStringAsFixed(1)}%',
                        ]),
                  ],
                ),
              ],

              pw.SizedBox(height: 30),

              // --- Footer ---
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

      // Save the PDF file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = filename ?? 'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());   // pdf.save() returns the PDF as bytes

      return filePath;
    } catch (e) {
      debugPrint('Error exporting to PDF: $e');
      return null;
    }
  }

  // ==============================================================================
  // shareFile - Share a File Using the System Share Dialog
  // ==============================================================================
  // Opens the native share dialog (Android/iOS) so the user can share the
  // exported file via email, WhatsApp, Google Drive, etc.
  //
  // XFile is a cross-platform file reference from the image_picker package.
  // Share.shareXFiles() handles the platform-specific sharing logic.
  // ==============================================================================
  static Future<bool> shareFile(String filePath, {String? subject}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        return false;
      }

      final fileName = filePath.split('/').last;  // Get just the filename from the full path
      await Share.shareXFiles(
        [XFile(filePath)],                        // List of files to share
        subject: subject ?? 'SmartFinance Export - $fileName',  // Email subject line
        text: 'Exported from SmartFinance',       // Share message body
      );

      return true;
    } catch (e) {
      debugPrint('Error sharing file: $e');
      return false;
    }
  }

  // ==============================================================================
  // getFileSize - Get Human-Readable File Size
  // ==============================================================================
  // Converts file size in bytes to a readable format.
  // Examples: 500 B, 1.5 KB, 2.3 MB
  // ==============================================================================
  static String getFileSize(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return 'Unknown';    // existsSync = synchronous existence check

      final bytes = file.lengthSync();             // Get file size in bytes (synchronous)
      if (bytes < 1024) return '$bytes B';                                    // Bytes
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';  // Kilobytes
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';             // Megabytes
    } catch (e) {
      return 'Unknown';
    }
  }

  // ==============================================================================
  // deleteFile - Delete a File from Device Storage
  // ==============================================================================
  // Removes an exported file. Returns true if deleted, false if file doesn't exist.
  // ==============================================================================
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;    // File doesn't exist
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // ==============================================================================
  // exportTransactionsByDateRange - Export Filtered Transactions to CSV
  // ==============================================================================
  // Convenience method that filters transactions by date range first,
  // then exports only the filtered ones to CSV.
  //
  // The filename includes the date range for easy identification:
  // "transactions_2025-01-01_to_2025-01-31.csv"
  // ==============================================================================
  static Future<String?> exportTransactionsByDateRange({
    required List<TransactionModel> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Filter transactions within the date range
    final filtered = transactions.where((t) {
      return !t.transactionDate.isBefore(startDate) &&   // On or after start date
             !t.transactionDate.isAfter(endDate);         // On or before end date
    }).toList();

    // Build a descriptive filename with the date range
    final dateRange = '${DateFormat('yyyy-MM-dd').format(startDate)}_to_${DateFormat('yyyy-MM-dd').format(endDate)}';
    return await exportTransactionsToCSV(
      filtered,
      filename: 'transactions_$dateRange.csv',
    );
  }

  // ==============================================================================
  // exportBudgetReportToPDF - Export Budget Report to PDF
  // ==============================================================================
  // Similar to exportReportToPDF but specifically for budget data.
  // Creates a PDF with:
  // - Budget overview (total budget, spent, remaining, percentage used)
  // - Category breakdown (budgeted vs spent vs remaining per category)
  //
  // The structure is very similar to exportReportToPDF - same PDF widget
  // patterns but with budget-specific data.
  // ==============================================================================
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
              // --- Title ---
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

              // --- Report Date ---
              pw.Text(
                'Generated: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // --- Budget Overview ---
              pw.Text(
                'Budget: ${budgetData['month'] ?? 'N/A'} ${budgetData['year'] ?? ''}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              // Summary table (total budget, spent, remaining, percentage)
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
                    _toDouble(budgetData['totalAmount']).toStringAsFixed(2),
                  ],
                  [
                    'Total Spent',
                    _toDouble(budgetData['totalSpent']).toStringAsFixed(2),
                  ],
                  [
                    'Remaining',
                    _toDouble(budgetData['remaining']).toStringAsFixed(2),
                  ],
                  [
                    'Percentage Used',
                    '${_toDouble(budgetData['percentageUsed']).toStringAsFixed(1)}%',
                  ],
                ],
              ),

              pw.SizedBox(height: 20),

              // --- Category Breakdown (if available) ---
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
                    ['Category', 'Budgeted', 'Spent', 'Remaining'],   // Header row
                    // Map each category to a row
                    ...(budgetData['categories'] as List).map((cat) => [
                          cat['category'] ?? '',
                          // 'allocated' and 'budgeted' are both present (backend sends both)
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

      // Save the PDF file
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
