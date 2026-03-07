// Import fl_chart — third-party Flutter charting library
// Provides BarChart, BarChartData, BarChartGroupData, BarChartRodData, etc.
import 'package:fl_chart/fl_chart.dart';

// Import Flutter's core UI package — gives us StatelessWidget, Padding, Text, Icon, etc.
import 'package:flutter/material.dart';

// Import our transaction categories utility — provides category icons and colors
// TransactionCategories.getCategoryInfo() returns icon + color for each category name
import '../../utils/categories.dart';

// Import our app color constants — AppColors.primary, .success, .danger
import '../../utils/colors.dart';

// BudgetComparisonChart — a StatelessWidget that renders a grouped bar chart
// Each category shows two side-by-side bars: one blue (budgeted) and one green/red (actual)
// If actual > budgeted, the actual bar turns red (over budget)
// If actual <= budgeted, the actual bar is green (under budget or on track)
// Used in the Analytics screen to compare budget vs. actual spending per category
class BudgetComparisonChart extends StatelessWidget {
  // data — a nested map: outer key is category name, inner map has 'budgeted' and 'actual'
  // Example: {
  //   "Food": {"budgeted": 500.0, "actual": 620.0},
  //   "Transport": {"budgeted": 200.0, "actual": 180.0},
  // }
  final Map<String, Map<String, double>> data;

  // maxY — the maximum Y axis value, pre-calculated by the parent with 20% headroom
  final double maxY;

  // const constructor with two required parameters
  const BudgetComparisonChart({
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
        child: Text('No budget data available'),
      );
    }

    // Extract the category names as a list (order reflects insertion order in the map)
    final categories = data.keys.toList();

    // Padding — margin around the chart so labels aren't clipped at the edges
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround, // Equal spacing between bar groups

          maxY: maxY, // Maximum height of the Y axis

          // ── TOUCH/TAP INTERACTION ─────────────────────────────────────────
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.primary.withOpacity(0.9), // Dark blue tooltip

              // getTooltipItem — defines the tooltip text when a bar is tapped
              // group.x.toInt() is the index of the bar group (category index)
              // rodIndex 0 = budgeted bar, rodIndex 1 = actual bar
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final category = categories[group.x.toInt()]; // Get category name from index
                final type = rodIndex == 0 ? 'Budgeted' : 'Actual'; // Which bar was tapped
                return BarTooltipItem(
                  // Three-line tooltip: category name, type, and amount
                  '$category\n$type\nRM ${rod.toY.toStringAsFixed(2)}',
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

            // Hide right and top axis labels (not needed)
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            // Bottom axis — shows category icons and short names
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60, // Reserve 60px height (more than other charts — icons + text)

                // getTitlesWidget — returns the Widget shown below each bar group
                getTitlesWidget: (value, meta) {
                  // Don't render if index is out of range
                  if (value.toInt() >= categories.length) {
                    return const Text('');
                  }

                  final category = categories[value.toInt()]; // Category name for this group

                  // Create a short display name to avoid overflow:
                  // If the name has a space, use just the first word (e.g., "Fast Food" → "Fast")
                  // If no space and name is long, use first 5 characters (e.g., "Transport" → "Trans")
                  // If short enough, use the full name
                  final shortName = category.contains(' ')
                      ? category.split(' ')[0]
                      : (category.length > 5 ? category.substring(0, 5) : category);

                  // Get the icon and color for this category from our utility
                  // 'expense' — we're comparing expense budgets (not income)
                  final categoryInfo = TransactionCategories.getCategoryInfo(
                    category,
                    'expense',
                  );

                  // Column: icon on top, short name below
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: [
                        // Category icon in the category's color
                        Icon(
                          categoryInfo.icon,
                          size: 16,
                          color: categoryInfo.color,
                        ),
                        const SizedBox(height: 2),
                        // Short category name, very small font to fit in limited space
                        Text(
                          shortName,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Left axis — shows RM amount labels
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,       // Reserve 40px width for labels
                interval: maxY / 5,    // 5 evenly-spaced labels along the Y axis

                getTitlesWidget: (value, meta) {
                  // For values >= 1000, show as "RM1k", "RM2k" etc.
                  if (value >= 1000) {
                    return Text(
                      'RM${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  // For smaller values, show the exact amount: "RM500"
                  return Text(
                    'RM${value.toStringAsFixed(0)}',
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
          // Only show bottom and left borders (L-shape axis frame)
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
              left: BorderSide(color: Colors.grey[300]!),
            ),
          ),

          // ── GRID LINES ────────────────────────────────────────────────────
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,        // Only horizontal lines (cleaner look)
            horizontalInterval: maxY / 5,  // 5 horizontal grid lines
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),

          // ── BAR GROUPS ────────────────────────────────────────────────────
          // barGroups — the actual data, one group per category
          // Delegated to the helper method _getBarGroups below
          barGroups: _getBarGroups(categories),
        ),
      ),
    );
  }

  // _getBarGroups — builds the list of BarChartGroupData, one per spending category
  // Each group has two rods: budgeted amount (blue) and actual spending (green or red)
  List<BarChartGroupData> _getBarGroups(List<String> categories) {
    // .asMap() converts the list to Map<int, String> so we can access index + value together
    return categories.asMap().entries.map((entry) {
      final index = entry.key;     // The x-position for this group (0, 1, 2...)
      final category = entry.value; // The category name (e.g., "Food")
      final categoryData = data[category]!; // The budgeted/actual data for this category

      // Extract budgeted and actual amounts (default 0.0 if key doesn't exist)
      final budgeted = categoryData['budgeted'] ?? 0.0;
      final actual = categoryData['actual'] ?? 0.0;

      // Color the actual bar:
      // - Red if actual > budgeted (over budget)
      // - Green if actual <= budgeted (on track or under budget)
      final actualColor = actual > budgeted ? AppColors.danger : AppColors.success;

      return BarChartGroupData(
        x: index, // x position in the chart
        barRods: [
          // First rod: budgeted amount (semi-transparent blue)
          BarChartRodData(
            toY: budgeted,                           // Height = budgeted amount
            color: AppColors.primary.withOpacity(0.5), // Light blue (budget target)
            width: 14,                               // Bar width in pixels
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),   // Rounded top corners
              topRight: Radius.circular(4),
              // Bottom corners are square — they sit flush on the x-axis
            ),
          ),
          // Second rod: actual spending (green if on track, red if over budget)
          BarChartRodData(
            toY: actual,          // Height = actual amount spent
            color: actualColor,   // Green or red depending on comparison
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList(); // Convert Iterable to List
  }
}
