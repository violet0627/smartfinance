// Import fl_chart — third-party Flutter charting library
// Provides BarChart, BarChartData, BarChartGroupData, BarChartRodData, etc.
import 'package:fl_chart/fl_chart.dart';

// Import Flutter's core UI package — gives us StatelessWidget, Padding, Text, etc.
import 'package:flutter/material.dart';

// Import intl package — provides DateFormat for formatting dates (e.g., "Jan 2024")
import 'package:intl/intl.dart';

// Import our app color constants — AppColors.income, .expense, .primary
import '../../utils/colors.dart';

// IncomeExpenseBarChart — a StatelessWidget that renders a grouped bar chart
// Each month shows two side-by-side bars: one green (income) and one red (expense)
// Used in the Analytics screen to compare income vs. expense across months
class IncomeExpenseBarChart extends StatelessWidget {
  // data — a nested map: outer key is "YYYY-MM", inner map has 'income' and 'expense'
  // Example: {
  //   "2024-01": {"income": 5000.0, "expense": 3000.0},
  //   "2024-02": {"income": 4500.0, "expense": 3500.0},
  // }
  final Map<String, Map<String, double>> data;

  // maxY — the maximum Y axis value, pre-calculated by the parent
  // Set 20% higher than the tallest bar to give visual breathing room
  final double maxY;

  // const constructor with two required parameters
  const IncomeExpenseBarChart({
    super.key,
    required this.data,
    required this.maxY,
  });

  // build() — Flutter calls this to render the widget
  @override
  Widget build(BuildContext context) {
    // Guard clause: if no data, show a placeholder message
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Sort the month keys alphabetically (which is also chronological for "YYYY-MM" format)
    // "2024-01" < "2024-02" < "2024-03" etc.
    final sortedKeys = data.keys.toList()..sort();

    // Padding — add margin around the chart so axis labels aren't cut off
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      child: BarChart(
        // BarChartData — all configuration for the bar chart
        BarChartData(
          alignment: BarChartAlignment.spaceAround, // Distribute groups evenly with equal spacing

          maxY: maxY, // Maximum height of the Y axis

          // ── TOUCH/TAP INTERACTION ─────────────────────────────────────────
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.primary.withOpacity(0.9), // Dark blue tooltip background

              // getTooltipItem — returns the text shown in tooltip when a bar is tapped
              // group: the bar group (one per month)
              // groupIndex: the group's index in the list
              // rod: the specific bar rod that was tapped
              // rodIndex: 0 = income bar, 1 = expense bar
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                // Convert the x position index back to the "YYYY-MM" key
                final monthKey = sortedKeys[group.x.toInt()];
                final parts = monthKey.split('-'); // ["2024", "01"]
                final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                // DateFormat('MMM yyyy') → "Jan 2024"
                final monthYear = DateFormat('MMM yyyy').format(date);

                // rodIndex 0 = first rod (income), rodIndex 1 = second rod (expense)
                final type = rodIndex == 0 ? 'Income' : 'Expense';

                // BarTooltipItem — the tooltip content
                return BarTooltipItem(
                  // Three lines: month name, type (Income/Expense), and amount
                  '$monthYear\n$type\nRM ${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),

          // ── AXIS LABELS ───────────────────────────────────────────────────
          titlesData: FlTitlesData(
            show: true,
            // Hide right and top axis labels
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            // Bottom axis — shows month abbreviations (Jan, Feb, Mar...)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30, // Reserve 30px height for labels

                // getTitlesWidget — returns the Widget for each x-axis tick
                getTitlesWidget: (value, meta) {
                  // Don't render a label if the index is out of range
                  if (value.toInt() >= sortedKeys.length) {
                    return const Text('');
                  }

                  // Convert index to month abbreviation
                  final monthKey = sortedKeys[value.toInt()];
                  final parts = monthKey.split('-');
                  final month = DateFormat('MMM').format(
                    DateTime(int.parse(parts[0]), int.parse(parts[1])),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      month,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Left axis — shows RM amount labels (e.g., "RM2k", "RM4k")
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,       // Reserve 40px width for labels
                interval: maxY / 5,    // Show 5 evenly-spaced labels along Y axis
                getTitlesWidget: (value, meta) {
                  return Text(
                    'RM${(value / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ),

          // ── CHART BORDER ──────────────────────────────────────────────────
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!), // Bottom axis line
              left: BorderSide(color: Colors.grey[300]!),   // Left axis line
            ),
          ),

          // ── GRID LINES ────────────────────────────────────────────────────
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,        // Only horizontal grid lines
            horizontalInterval: maxY / 5,  // 5 equally-spaced horizontal lines
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),

          // ── BAR GROUPS ────────────────────────────────────────────────────
          // barGroups — the actual bar data, one group per month
          // Delegated to the helper method _getBarGroups below
          barGroups: _getBarGroups(sortedKeys),
        ),
      ),
    );
  }

  // _getBarGroups — builds the list of BarChartGroupData, one per month
  // Each group has two rods: income (green) and expense (red)
  List<BarChartGroupData> _getBarGroups(List<String> sortedKeys) {
    // .asMap() converts the list to a Map<int, String> (index → value)
    // .entries gives us Iterable<MapEntry<int, String>> so we can access both index and value
    return sortedKeys.asMap().entries.map((entry) {
      final index = entry.key;       // The x-position of this group (0, 1, 2...)
      final monthKey = entry.value;  // The "YYYY-MM" key (e.g., "2024-03")
      final monthData = data[monthKey]!; // The income/expense data for this month

      return BarChartGroupData(
        x: index, // x position in the chart
        barRods: [
          // First rod: income (green)
          BarChartRodData(
            toY: monthData['income'] ?? 0.0, // Height of the bar (the Y value it reaches)
            color: AppColors.income,          // Green color for income
            width: 12,                        // Bar width in pixels
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),   // Rounded top-left corner
              topRight: Radius.circular(4),  // Rounded top-right corner
              // Bottom corners are square (0 radius) to sit flush on the axis
            ),
          ),
          // Second rod: expense (red)
          BarChartRodData(
            toY: monthData['expense'] ?? 0.0, // ?? 0.0 — if key missing, default to 0
            color: AppColors.expense,          // Red color for expense
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList(); // Convert the Iterable to a List (required by barGroups parameter)
  }
}
