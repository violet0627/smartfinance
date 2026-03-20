// Import Flutter's core UI package — gives us widgets like Scaffold, AppBar, ListView, Card, etc.
import 'package:flutter/material.dart';

// Import the intl package — provides DateFormat for formatting dates (e.g., "March 2024")
import 'package:intl/intl.dart';

// Import dart:io — provides File class for reading/writing files on disk
import 'dart:io';

// Import http — lets the app make HTTP GET requests to download CSV bytes from the backend
import 'package:http/http.dart' as http;

// Import path_provider — gives us getApplicationDocumentsDirectory() to find a writable folder
import 'package:path_provider/path_provider.dart';

// Import fl_chart — a third-party Flutter charting library that provides PieChart widget
import 'package:fl_chart/fl_chart.dart';

// Import our custom API service — handles all HTTP calls to the Flask backend
import '../../services/api_service.dart';

// Import our export service — handles PDF creation and file sharing
import '../../services/export_service.dart';

// Import our app color constants — AppColors.primary, .expense, .income, .success, .danger, .warning
import '../../utils/colors.dart';

// ReportsScreen is a StatefulWidget — it has data that changes (loading state, selected period, report data)
class ReportsScreen extends StatefulWidget {
  // const constructor — Flutter can optimize this widget if created with constant values
  const ReportsScreen({super.key});

  // createState() returns the mutable state object for this widget
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

// The State class — holds all the data and logic for ReportsScreen
// "with SingleTickerProviderStateMixin" — this mixin provides animation ticking for TabController
// A "ticker" fires every animation frame (60 times/second) to animate the tab indicator
class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  // _selectedPeriod tracks which time period is currently selected for the report
  // 'this_month' is the default — shows data from the current month
  String _selectedPeriod = 'this_month';

  // These three variables store the API response data for each report type
  // They are nullable (?) — null means the data hasn't loaded yet
  Map<String, dynamic>? _spendingReport;   // Data for the Spending tab
  Map<String, dynamic>? _budgetReport;    // Data for the Budget tab
  Map<String, dynamic>? _categoryAnalysis; // Data for the Categories tab

  // _isLoading — true while API calls are in progress, controls showing spinner
  bool _isLoading = false;

  // _error — stores error message if loading fails; empty string means no error
  String _error = '';

  // _tabController.index is the source of truth for the active tab index;
  // a separate _selectedTab field is not needed.

  // _tabController — manages the TabBar + TabBarView synchronization
  // "late" means we will assign it before first use (in initState), not at declaration time
  late TabController _tabController;

  // Helper method: safely converts any dynamic value to a double (decimal number)
  // "dynamic" means the variable can be any type — we don't know if it's int, double, or String
  // This is needed because API responses can return numbers as different types
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;            // If null, return 0
    if (value is num) return value.toDouble(); // If it's already a number (int or double), convert to double
    if (value is String) return double.tryParse(value) ?? 0.0; // If it's a string like "123.45", parse it
    return 0.0;                               // Fallback for any other unexpected type
  }

  // _periods — the list of time period options shown as FilterChips at the top
  // Each entry has:
  //   'label' — the display text shown to the user (e.g., "This Month")
  //   'value' — the string sent to the API (e.g., "this_month")
  final List<Map<String, String>> _periods = [
    {'label': 'This Month', 'value': 'this_month'},
    {'label': 'Last Month', 'value': 'last_month'},
    {'label': 'Last 3 Months', 'value': 'last_3_months'},
    {'label': 'Last 6 Months', 'value': 'last_6_months'},
    {'label': 'This Year', 'value': 'this_year'},
    {'label': 'Last Year', 'value': 'last_year'},
  ];

  // initState() is called once when this widget is inserted into the widget tree
  // Use it for one-time initialization: setting up controllers, loading initial data
  @override
  void initState() {
    super.initState(); // Always call super.initState() first — required by Flutter

    // Create a TabController with 3 tabs (Spending, Budget, Categories)
    // vsync: this — "this" refers to our State object which is a TickerProvider (from the mixin)
    // vsync prevents animations from running when the screen is off-screen (saves battery)
    _tabController = TabController(length: 3, vsync: this);

    // addListener — triggers a rebuild when the tab changes so the UI stays in sync
    _tabController.addListener(() {
      setState(() {}); // Rebuild to reflect _tabController.index change
    });

    // Load all report data from the API when the screen first opens
    _loadReports();
  }

  // dispose() is called when the widget is permanently removed from the tree
  // Always dispose controllers here to free memory and prevent memory leaks
  @override
  void dispose() {
    _tabController.dispose(); // Release the TabController's animation resources
    super.dispose();          // Always call super.dispose() last
  }

  // _loadReports() — async method that fetches all 3 report types from the backend
  // "async" allows us to use "await" to pause execution until a Future completes
  Future<void> _loadReports() async {
    // Show loading spinner and clear any previous error
    setState(() {
      _isLoading = true;
      _error = '';
    });

    // try/catch — "try" the risky code; if anything throws an exception, "catch" handles it
    try {
      // Get the current logged-in user's ID from SharedPreferences
      final userId = await ApiService.getCurrentUserId();

      // If userId is null, the user isn't logged in — show error and stop
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return; // Stop the function here — nothing more to do without a valid user
      }

      // Future.wait — runs all 3 API calls SIMULTANEOUSLY (in parallel) and waits for ALL to finish
      // This is faster than calling them one by one sequentially
      // results is a List with 3 items in the same order as the futures
      final results = await Future.wait([
        ApiService.getSpendingReport(userId, period: _selectedPeriod),  // results[0]
        ApiService.getBudgetReport(userId, period: _selectedPeriod),     // results[1]
        ApiService.getCategoryAnalysis(userId, period: _selectedPeriod), // results[2]
      ]);

      // Update state with all results at once
      setState(() {
        // Only store the data if the API call was successful
        if (results[0]['success']) {
          _spendingReport = results[0]['report']; // Extract the 'report' from the API response
        }
        if (results[1]['success']) {
          _budgetReport = results[1]['report'];
        }
        if (results[2]['success']) {
          _categoryAnalysis = results[2]['report'];
        }
        _isLoading = false; // Hide the loading spinner
      });
    } catch (e) {
      // If any error occurred (network failure, JSON parse error, etc.), show the error
      setState(() {
        _error = 'Error: $e'; // $e embeds the error message into the string
        _isLoading = false;
      });
    }
  }

  // _downloadCSV — downloads the CSV from the backend and saves it locally,
  // then shows a share dialog — same flow as PDF export.
  // "type" is either 'transactions' or 'spending_report'
  Future<void> _downloadCSV(String type) async {
    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return; // Can't download without a user ID

    // Build the backend CSV endpoint URL (same URL as before, just fetched in-app now)
    final String url = type == 'transactions'
        ? ApiService.getExportTransactionsUrl(userId, period: _selectedPeriod)
        : ApiService.getExportSpendingReportUrl(userId, period: _selectedPeriod);

    // Choose a filename based on the type and today's date
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final filename = type == 'transactions'
        ? 'transactions_${_selectedPeriod}_$dateStr.csv'
        : 'spending_report_${_selectedPeriod}_$dateStr.csv';

    // Show a loading dialog while the file downloads (same pattern as PDF export)
    // barrierDismissible: false — user cannot tap outside to cancel
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // http.get() — sends an HTTP GET request to the backend CSV endpoint
      // The backend returns the CSV as raw bytes (binary response body)
      final response = await http.get(Uri.parse(url));

      // Close the loading dialog now that the download is complete
      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode != 200) {
        // Backend returned an error (e.g. 500) — show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed (server error ${response.statusCode})'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      // getApplicationDocumentsDirectory() — returns the app's private documents folder.
      // On Android: /data/data/com.example.app/app_flutter/
      // On iOS: <app_sandbox>/Documents/
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';

      // Write the raw CSV bytes from the HTTP response to the file
      // response.bodyBytes is a Uint8List (list of bytes from the HTTP response body)
      await File(filePath).writeAsBytes(response.bodyBytes);

      if (!mounted) return;

      // Show the same success dialog as PDF export — with OK and Share buttons
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Only as tall as the content needs
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Exported ${type == "transactions" ? "transactions" : "spending report"} to CSV'),
              const SizedBox(height: 8),
              // Show just the filename (not the full path)
              Text(
                'File: $filename',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              // Show the file size in a human-readable format (e.g., "12 KB")
              Text(
                'Size: ${ExportService.getFileSize(filePath)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            // OK button — just closes the dialog
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            // Share button — opens the OS share sheet so user can save/send the CSV file
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context); // Close this dialog first
                final success = await ExportService.shareFile(
                  filePath,
                  subject: 'SmartFinance CSV Export',
                );
                if (!mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File shared successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting CSV: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // _exportToPDF — generates a PDF file and offers to share it
  // "type" is either 'spending' or 'budget'
  Future<void> _exportToPDF(String type) async {
    // Guard clause: if there's no data loaded, show a warning and return early
    if (_spendingReport == null && _budgetReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: AppColors.warning, // Orange/yellow warning color
        ),
      );
      return;
    }

    try {
      // Show a loading dialog while the PDF is being generated
      // barrierDismissible: false — user cannot tap outside to dismiss it (forces wait)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(), // Spinning loading circle
        ),
      );

      // filePath will hold the path to the generated PDF file, or null if it failed
      String? filePath;

      if (type == 'spending') {
        // Generate a spending report PDF if spending data is available
        if (_spendingReport != null) {
          // Backend returns 'categoryBreakdown' (not 'categories') for the spending report
          final rawCategories = _spendingReport!['categoryBreakdown'];
          filePath = await ExportService.exportReportToPDF(
            // The ?? {} means: use _spendingReport!['summary'] if not null, else use an empty map {}
            summary: _spendingReport!['summary'] ?? {},

            // Convert the category list to a typed List<Map<String, dynamic>>
            // List.from() creates a new list from any iterable
            categoryBreakdown: rawCategories != null
                ? List<Map<String, dynamic>>.from(rawCategories)
                : null,

            // Create a filename with the period and today's date
            // DateFormat('yyyy-MM-dd').format(DateTime.now()) → "2024-03-15"
            filename: 'spending_report_${_selectedPeriod}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
          );
        }
      } else if (type == 'budget') {
        // Generate a budget report PDF if budget data is available
        if (_budgetReport != null) {
          // The budget API returns a nested structure: {summary: {...}, budgets: [...], period: {...}}
          // Build a flat map that exportBudgetReportToPDF expects
          final summary = (_budgetReport!['summary'] as Map<String, dynamic>?) ?? {};
          final budgets = _budgetReport!['budgets'] as List? ?? [];
          final period = (_budgetReport!['period'] as Map<String, dynamic>?) ?? {};
          final startDate = (period['startDate'] as String?) ?? '';

          // Collect all category performance entries across all budgets
          final allCategories = <Map<String, dynamic>>[];
          for (final b in budgets) {
            final catPerf = b['categoryPerformance'] as List? ?? [];
            allCategories.addAll(catPerf.cast<Map<String, dynamic>>());
          }

          // Build the flat budgetData map that the export service expects
          final budgetDataFlat = <String, dynamic>{
            'month': startDate.length >= 7 ? startDate.substring(0, 7) : 'N/A',
            'year': startDate.length >= 4 ? startDate.substring(0, 4) : '',
            'totalAmount': summary['totalBudgeted'] ?? 0,
            'totalSpent': summary['totalSpent'] ?? 0,
            'remaining': _toDouble(summary['totalBudgeted']) - _toDouble(summary['totalSpent']),
            'percentageUsed': _toDouble(summary['totalBudgeted']) > 0
                ? (_toDouble(summary['totalSpent']) / _toDouble(summary['totalBudgeted']) * 100)
                : 0.0,
            'categories': allCategories.isNotEmpty ? allCategories : null,
          };

          filePath = await ExportService.exportBudgetReportToPDF(
            budgetData: budgetDataFlat,
            filename: 'budget_report_${_selectedPeriod}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
          );
        }
      }

      // Close the loading dialog now that PDF generation is complete
      if (!mounted) return;
      Navigator.pop(context); // Pop the loading dialog off the navigation stack

      if (filePath != null) {
        // PDF was created successfully — show a success dialog with a Share button
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min, // Make the dialog only as tall as needed
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tell the user what was exported
                Text('Exported ${type == "spending" ? "spending report" : "budget report"} to PDF'),
                const SizedBox(height: 8),

                // Show just the filename (not the full path)
                // filePath!.split('/').last — splits by '/' and takes the final segment (filename)
                Text(
                  // filePath is non-null here (inside `if (filePath != null)`).
                  // The `!` is required because Dart cannot narrow nullable types
                  // inside builder closures — flow analysis doesn't cross closure boundaries.
                  'File: ${filePath!.split('/').last}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),

                // Show the file size in a human-readable format (e.g., "45 KB")
                Text(
                  'Size: ${ExportService.getFileSize(filePath!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              // OK button — just closes the dialog
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),

              // Share button — opens the system share sheet to send the file
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context); // Close the success dialog first

                  // ExportService.shareFile — opens OS share sheet with the file
                  // Returns true if sharing succeeded, false if it failed
                  final success = await ExportService.shareFile(
                    filePath!, // `!` needed — Dart can't narrow nullables inside closures
                    subject: 'SmartFinance Report Export',
                  );

                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File shared successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      } else {
        // filePath is null — the export failed for some reason
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export report'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close the loading dialog even if an error occurred
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // _buildPeriodSelector — builds the horizontal row of FilterChip buttons at the top
  // User taps a chip to change the time period for all reports
  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Allow scrolling left/right (for small screens)
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        // Map each period object to a FilterChip widget, then convert to List
        children: _periods.map((period) {
          // Check if this chip is the currently selected period
          final isSelected = _selectedPeriod == period['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8), // Space between chips
            child: FilterChip(
              label: Text(period['label']!), // The display text, ! means we're sure it's not null
              selected: isSelected,          // Chip appears highlighted when selected

              // onSelected — called when user taps the chip
              // "selected" parameter is true when tapping an unselected chip, false when tapping selected
              onSelected: (selected) {
                if (selected) {
                  // Only react when selecting (not deselecting)
                  setState(() {
                    _selectedPeriod = period['value']!; // Update the selected period
                  });
                  _loadReports(); // Reload all reports for the new time period
                }
              },

              // Highlight color when chip is selected — primary color at 20% opacity
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary, // Color of the checkmark icon
            ),
          );
        }).toList(), // .toList() converts the Iterable returned by .map() into a List
      ),
    );
  }

  // _buildEmptyState — reusable widget shown when a tab has no data to display
  // Parameters: title (big text), subtitle (description), icon (visual indicator)
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32), // Space on all sides
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            // Large grey icon — gives visual context for the empty state
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),

            // Main message (e.g., "No Spending Data")
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),

            // Secondary message explaining what to do
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center, // Center multi-line text
            ),
          ],
        ),
      ),
    );
  }

  // _buildSpendingReportTab — builds the content for the "Spending" tab
  // Shows: financial summary card, pie chart of categories, category breakdown list
  Widget _buildSpendingReportTab() {
    // If no data loaded yet, show the empty state placeholder
    if (_spendingReport == null) {
      return _buildEmptyState(
        'No Spending Data',
        'Add some transactions to see your spending report',
        Icons.receipt_long_outlined,
      );
    }

    // Extract the two main sections from the spending report data
    final summary = _spendingReport!['summary'];             // Overall totals (income, expense, savings)
    final categoryBreakdown = _spendingReport!['categoryBreakdown'] as List; // List of categories with amounts

    // ListView — scrollable vertical list of widgets
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── FINANCIAL SUMMARY CARD ──────────────────────────────────────────
        Card(
          elevation: 2, // Shadow depth
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Reusable row: label on left, amount in color on right
                _buildSummaryRow('Total Income', _toDouble(summary['totalIncome']), AppColors.income),
                const SizedBox(height: 12),
                _buildSummaryRow('Total Expense', _toDouble(summary['totalExpense']), AppColors.expense),

                // Divider — horizontal line to visually separate sections
                const Divider(height: 24),

                // Net savings: green if positive (saved money), red if negative (overspent)
                _buildSummaryRow('Net Savings', _toDouble(summary['netSavings']),
                    _toDouble(summary['netSavings']) >= 0 ? AppColors.success : AppColors.danger),
                const SizedBox(height: 12),

                // Savings rate row — percentage of income that was saved
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Savings Rate'),
                    Text(
                      // .toStringAsFixed(1) formats to 1 decimal place: "23.5%"
                      '${_toDouble(summary['savingsRate']).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        // Green if savings rate >= 0%, red if negative (spending more than earning)
                        color: _toDouble(summary['savingsRate']) >= 0 ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Average daily expense — helps user understand daily spending pattern
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Avg. Daily Expense', style: TextStyle(color: Colors.grey.shade700)),
                    Text(
                      'RM ${_toDouble(summary['avgDailyExpense']).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Total number of transactions in this period
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transaction Count', style: TextStyle(color: Colors.grey.shade700)),
                    Text(
                      '${summary['transactionCount']}', // String interpolation to convert int to string
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── SPENDING PIE CHART ──────────────────────────────────────────────
        // Only show the pie chart section if there are categories to display
        // "..." spread operator — expands the list items directly into the parent list
        // This allows conditional lists inside other lists without using if()
        if (categoryBreakdown.isNotEmpty) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spending Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // SizedBox with fixed height — PieChart needs a constrained size to render correctly
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,      // Gap (in pixels) between pie slices
                        centerSpaceRadius: 60, // Size of the empty circle in the center (donut hole)

                        // sections — one PieChartSectionData per category
                        sections: categoryBreakdown.map<PieChartSectionData>((category) {
                          final percentage = _toDouble(category['percentage']);

                          // Color palette — cycles through 8 colors using modulo (%)
                          // If there are more than 8 categories, colors repeat
                          final colors = [
                            AppColors.primary,
                            AppColors.expense,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                            Colors.amber,
                            Colors.pink,
                            Colors.indigo,
                          ];

                          // .indexOf(category) finds this item's position in the list (0-based)
                          // % colors.length — modulo keeps index within 0-7 range
                          final colorIndex = categoryBreakdown.indexOf(category) % colors.length;

                          return PieChartSectionData(
                            color: colors[colorIndex],
                            value: percentage,        // The proportion of the pie this slice takes
                            title: '${percentage.toStringAsFixed(1)}%', // Label shown on the slice
                            radius: 80,               // Width of the donut ring
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,    // White text on colored slices
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── PIE CHART LEGEND ──────────────────────────────────────
                  // Wrap — like Row but wraps to next line when items overflow
                  Wrap(
                    spacing: 16,    // Horizontal space between legend items
                    runSpacing: 8,  // Vertical space between lines when wrapped
                    children: categoryBreakdown.map<Widget>((category) {
                      // Same color list — used to match legend colors to pie slices
                      final colors = [
                        AppColors.primary,
                        AppColors.expense,
                        Colors.orange,
                        Colors.purple,
                        Colors.teal,
                        Colors.amber,
                        Colors.pink,
                        Colors.indigo,
                      ];
                      final colorIndex = categoryBreakdown.indexOf(category) % colors.length;

                      return Row(
                        mainAxisSize: MainAxisSize.min, // Row takes only as much space as its children need
                        children: [
                          // Colored dot matching the pie slice color
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colors[colorIndex],
                              shape: BoxShape.circle, // Make it a circle (dot)
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Category name label next to the dot
                          Text(
                            category['category'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── CATEGORY BREAKDOWN LIST ─────────────────────────────────────────
        const Text(
          'Category Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // If no categories, show a placeholder card
        if (categoryBreakdown.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No expense data for this period',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // Spread operator (...) expands the list of category cards into the parent list
          // .map((category) {...}) transforms each category data into a Card widget
          ...categoryBreakdown.map((category) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12), // Space below each card
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category name on left, total amount in red on right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category['category'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'RM ${_toDouble(category['amount']).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.expense, // Red — indicates spending
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress bar showing what % of total spending this category represents
                    LinearProgressIndicator(
                      // percentage is 0-100, but LinearProgressIndicator needs 0.0-1.0, so divide by 100
                      value: _toDouble(category['percentage']) / 100,
                      backgroundColor: Colors.grey.shade200, // Track (unfilled part) color
                      // AlwaysStoppedAnimation — makes the color static (not animated changing)
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.expense),
                      minHeight: 8,                          // Make the bar thicker (default is 4)
                      borderRadius: BorderRadius.circular(4), // Rounded ends
                    ),
                    const SizedBox(height: 8),

                    // Transaction count and percentage, shown below the progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${category['count']} transactions',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${_toDouble(category['percentage']).toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  // _buildBudgetReportTab — builds the content for the "Budget" tab
  // Shows: overall budget adherence, budget distribution pie chart, per-month budget cards
  Widget _buildBudgetReportTab() {
    // Show empty state if no budget data OR if the budgets list is empty
    // The "as List" cast — tells Dart that we know this value is a List
    if (_budgetReport == null || (_budgetReport!['budgets'] as List).isEmpty) {
      return _buildEmptyState(
        'No Budget Data',
        'Create a budget to track your spending against your goals',
        Icons.account_balance_wallet_outlined,
      );
    }

    // Extract the summary and budgets list from the report
    final summary = _budgetReport!['summary'];
    final budgets = _budgetReport!['budgets'] as List; // Could be multiple months of budgets

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── BUDGET OVERVIEW SUMMARY CARD ────────────────────────────────────
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Total Budgeted', _toDouble(summary['totalBudgeted']), AppColors.primary),
                const SizedBox(height: 12),
                _buildSummaryRow('Total Spent', _toDouble(summary['totalSpent']), AppColors.expense),
                const Divider(height: 24),

                // Adherence rate — what percentage of budget was actually spent
                // 100% means exactly on budget, <100% means under budget, >100% means over budget
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Adherence Rate'),
                    Text(
                      '${_toDouble(summary['adherenceRate']).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _toDouble(summary['adherenceRate']) >= 0 ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── BUDGET DISTRIBUTION PIE CHART ───────────────────────────────────
        // Only show if there are budgets AND the first budget has category data
        // budgets.first — accesses the first element of the list (same as budgets[0])
        if (budgets.isNotEmpty && budgets.first['categories'] != null) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Budget Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        // Build pie sections from the first budget's category list
                        sections: (budgets.first['categories'] as List).map<PieChartSectionData>((category) {
                          final totalBudget = _toDouble(summary['totalBudgeted']);
                          final categoryBudget = _toDouble(category['budget']);

                          // Calculate what percentage of total budget this category represents
                          // Ternary: if totalBudget > 0, do the division; otherwise 0 (avoids division by zero)
                          final percentage = totalBudget > 0 ? (categoryBudget / totalBudget * 100) : 0.0;

                          final colors = [
                            AppColors.primary,
                            AppColors.success,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                            Colors.amber,
                            Colors.pink,
                            Colors.indigo,
                          ];
                          final colorIndex = (budgets.first['categories'] as List).indexOf(category) % colors.length;

                          return PieChartSectionData(
                            color: colors[colorIndex],
                            value: percentage.toDouble(), // Convert to double just to be safe
                            title: '${percentage.toStringAsFixed(1)}%',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Legend for the budget pie chart
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: (budgets.first['categories'] as List).map<Widget>((category) {
                      final colors = [
                        AppColors.primary,
                        AppColors.success,
                        Colors.orange,
                        Colors.purple,
                        Colors.teal,
                        Colors.amber,
                        Colors.pink,
                        Colors.indigo,
                      ];
                      final colorIndex = (budgets.first['categories'] as List).indexOf(category) % colors.length;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colors[colorIndex],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Note: budget categories use 'categoryName' (not 'category' like spending)
                          Text(
                            category['categoryName'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── MONTHLY BUDGET CARDS ─────────────────────────────────────────────
        const Text(
          'Monthly Budgets',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Build one card per budget (could be multiple months if period spans months)
        ...budgets.map((budget) {
          // Determine the progress bar color based on percentage used.
          // Use _toDouble() because the API may return this as a String ("40.0")
          // and Dart's >= operator on String throws NoSuchMethodError.
          final percentage = _toDouble(budget['percentageUsed']);
          Color progressColor;
          if (percentage >= 100) {
            progressColor = AppColors.danger;  // Red: over budget
          } else if (percentage >= 80) {
            progressColor = AppColors.warning; // Orange: warning zone (80-99%)
          } else {
            progressColor = AppColors.success; // Green: on track (below 80%)
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Budget month name on left, "Over Budget" / "On Track" badge on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // _formatMonthYear converts "2024-03" to "March 2024"
                      Text(
                        _formatMonthYear(budget['monthYear']),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                      // Status badge — colored pill showing budget status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          // Red background if over budget, green if on track — at 10% opacity
                          color: budget['isOverBudget']
                              ? AppColors.danger.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12), // Rounded pill shape
                        ),
                        child: Text(
                          budget['isOverBudget'] ? 'Over Budget' : 'On Track',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: budget['isOverBudget'] ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress bar showing budget usage percentage
                  LinearProgressIndicator(
                    // .clamp(0.0, 1.0) — ensures the value stays between 0 and 1
                    // Without clamp, a 120% budget would try to render as 1.2, which breaks the widget
                    value: (_toDouble(percentage) / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),

                  // "RM 450.00 / RM 1000.00" on left, "45%" on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RM ${_toDouble(budget['totalSpent']).toStringAsFixed(2)} / RM ${_toDouble(budget['totalBudget']).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        // .toStringAsFixed(0) rounds to no decimal places: "45%"
                        '${_toDouble(percentage).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: progressColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // _buildCategoryAnalysisTab — builds the content for the "Categories" tab
  // Shows: total expense summary card, detailed stats for each spending category
  Widget _buildCategoryAnalysisTab() {
    // Show empty state if no category data loaded
    if (_categoryAnalysis == null) {
      return _buildEmptyState(
        'No Category Data',
        'Add expense transactions to see category analysis',
        Icons.pie_chart_outline,
      );
    }

    // Extract the categories list from the analysis data
    final categories = _categoryAnalysis!['categories'] as List;

    // Also show empty state if there are no categories (no expenses in this period)
    if (categories.isEmpty) {
      return _buildEmptyState(
        'No Expenses This Period',
        'No expense transactions found for the selected time period',
        Icons.category_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── TOTAL EXPENSE SUMMARY CARD ───────────────────────────────────────
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Expense',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),

                // Large number showing total spending — visually prominent
                Text(
                  'RM ${_toDouble(_categoryAnalysis!['totalExpense']).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,                  // Large font size for emphasis
                    fontWeight: FontWeight.bold,
                    color: AppColors.expense,      // Red — indicates spending
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Category Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Build one detailed card per spending category
        ...categories.map((category) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category name as the card header
                  Text(
                    category['name'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // ── TOP ROW: Total | Average | Count ──────────────────────
                  Row(
                    children: [
                      // Expanded makes each column take equal width (1/3 of row each)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              'RM ${_toDouble(category['total']).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Average', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              'RM ${_toDouble(category['average']).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Count', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            // How many transactions in this category
                            Text(
                              '${category['count']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── BOTTOM ROW: Max | Min | % of Total ───────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Max', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            // The largest single transaction in this category
                            Text(
                              'RM ${_toDouble(category['max']).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Min', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            // The smallest single transaction in this category
                            Text(
                              'RM ${_toDouble(category['min']).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('% of Total', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            // What portion of all expenses this category represents
                            Text(
                              '${_toDouble(category['percentage']).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // _buildSummaryRow — reusable widget: label on left, colored RM amount on right
  // Used in the summary cards to show income/expense/savings rows
  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Push children to opposite ends
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          'RM ${_toDouble(amount).toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color, // Passed in — green for income, red for expense, etc.
          ),
        ),
      ],
    );
  }

  // _formatMonthYear — converts "2024-03" format into "March 2024" for display
  String _formatMonthYear(String monthYear) {
    try {
      // Append "-01" to make a full date string that DateTime.parse can understand
      // "2024-03" + "-01" = "2024-03-01" — the first day of that month
      final date = DateTime.parse('$monthYear-01');

      // DateFormat('MMMM yyyy') formats as "March 2024" (MMMM = full month name, yyyy = 4-digit year)
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      // If parsing fails for any reason, just return the original string unchanged
      return monthYear;
    }
  }

  // build() — called by Flutter to draw the UI
  // Returns the complete widget tree for this screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── APP BAR ──────────────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.primary, // Blue app bar
        foregroundColor: Colors.white,       // White title and icons
        elevation: 0,                        // No shadow under app bar

        // actions — widgets shown on the right side of the AppBar
        actions: [
          // Download button — opens a popup menu with export options
          PopupMenuButton<Map<String, String>>(
            icon: const Icon(Icons.download), // Download icon in the app bar

            // onSelected — called when user picks an option from the menu
            // "value" is the Map<String, String> associated with the selected item
            onSelected: (value) {
              final type = value['type']!;     // 'transactions', 'spending_report', 'spending', or 'budget'
              final format = value['format']!; // 'csv' or 'pdf'
              if (format == 'csv') {
                _downloadCSV(type);   // Download CSV in-app and show share dialog
              } else {
                _exportToPDF(type);   // Generate PDF file
              }
            },

            // itemBuilder — builds the list of menu options
            itemBuilder: (context) => [
              // Option 1: Download all transactions as CSV
              const PopupMenuItem(
                value: {'type': 'transactions', 'format': 'csv'},
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 18, color: Colors.green), // Green spreadsheet icon
                    SizedBox(width: 8),
                    Text('Transactions (CSV)'),
                  ],
                ),
              ),

              // Option 2: Download spending summary as CSV
              const PopupMenuItem(
                value: {'type': 'spending_report', 'format': 'csv'},
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Spending Report (CSV)'),
                  ],
                ),
              ),

              // PopupMenuDivider — horizontal divider line between menu sections
              const PopupMenuDivider(),

              // Option 3: Export spending report as PDF
              const PopupMenuItem(
                value: {'type': 'spending', 'format': 'pdf'},
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 18, color: Colors.red), // Red PDF icon
                    SizedBox(width: 8),
                    Text('Spending Report (PDF)'),
                  ],
                ),
              ),

              // Option 4: Export budget report as PDF
              const PopupMenuItem(
                value: {'type': 'budget', 'format': 'pdf'},
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Budget Report (PDF)'),
                  ],
                ),
              ),
            ],
          ),
        ],

        // bottom — widget shown below the app bar title (here: the tab row)
        // TabBar — the visual row of tabs (Spending | Budget | Categories)
        bottom: TabBar(
          controller: _tabController, // Links this TabBar to our TabController
          indicatorColor: Colors.white,        // White underline on the selected tab
          labelColor: Colors.white,            // Selected tab text is white
          unselectedLabelColor: Colors.white70, // Unselected tabs are slightly transparent
          tabs: const [
            Tab(text: 'Spending'),    // Tab index 0
            Tab(text: 'Budget'),     // Tab index 1
            Tab(text: 'Categories'), // Tab index 2
          ],
        ),
      ),

      // ── BODY ─────────────────────────────────────────────────────────────
      // Ternary chain to decide what to show based on current state:
      body: _isLoading
          // State 1: Still loading — show a centered spinning circle
          ? const Center(child: CircularProgressIndicator())

          // State 2: Error occurred — show error message with retry button
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReports, // Retry button re-runs the load function
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )

              // State 3: Data loaded successfully — show the period selector + tab content
              : Column(
                  children: [
                    // Period selector (FilterChips row) at the top
                    _buildPeriodSelector(),

                    // Expanded — takes remaining vertical space after the period selector
                    Expanded(
                      // TabBarView — displays different content for each tab
                      // Automatically synced with _tabController (swipe left/right to change tabs)
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSpendingReportTab(),  // Tab 0: Spending report
                          _buildBudgetReportTab(),    // Tab 1: Budget report
                          _buildCategoryAnalysisTab(), // Tab 2: Category analysis
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
