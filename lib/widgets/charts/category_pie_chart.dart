// Import fl_chart — third-party Flutter charting library
// Provides PieChart, PieChartData, PieChartSectionData, PieTouchData, etc.
import 'package:fl_chart/fl_chart.dart';

// Import Flutter's core UI package — gives us StatefulWidget, setState, Column, Wrap, etc.
import 'package:flutter/material.dart';

// Import our transaction categories utility — provides category icons and colors
import '../../utils/categories.dart';

// Import our app color constants — AppColors.textSecondary
import '../../utils/colors.dart';

// CategoryPieChart — a StatefulWidget that renders an interactive donut pie chart
// Shows the breakdown of spending (or income) across different categories
// "Stateful" because the chart responds to touch: the tapped slice grows larger
// Used in the Analytics screen to show the spending distribution by category
class CategoryPieChart extends StatefulWidget {
  // categoryData — a map of category name → total amount
  // Example: {"Food": 500.0, "Transport": 200.0, "Entertainment": 150.0}
  final Map<String, double> categoryData;

  // type — either 'expense' or 'income'
  // This determines which color/icon to use for each category via TransactionCategories
  final String type;

  // const constructor with two required parameters
  const CategoryPieChart({
    super.key,
    required this.categoryData,
    required this.type,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

// _CategoryPieChartState — the mutable state for CategoryPieChart
// Holds touchedIndex to track which slice is currently selected/expanded
class _CategoryPieChartState extends State<CategoryPieChart> {
  // touchedIndex — the index of the currently tapped pie slice
  // -1 means no slice is tapped (all slices at normal size)
  // When a slice is tapped, it grows from radius 60 to radius 70
  int touchedIndex = -1;

  // build() — called by Flutter to render the widget
  @override
  Widget build(BuildContext context) {
    // Guard clause: if no data, show a placeholder message
    if (widget.categoryData.isEmpty) {
      // "widget." prefix — inside State, you access the StatefulWidget's fields via "widget."
      return const Center(
        child: Text('No data available'),
      );
    }

    // Calculate the total across all categories for percentage calculation
    // .values — gets just the amounts (doubles) from the map
    // .fold(0.0, ...) — starts with 0.0, adds each value to the running sum
    // (sum, value) => sum + value — the accumulator function
    final total = widget.categoryData.values.fold(0.0, (sum, value) => sum + value);

    return Column(
      children: [
        // ── PIE CHART ────────────────────────────────────────────────────────
        // Fixed height container for the chart (charts need explicit size constraints)
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              // ── TOUCH INTERACTION ──────────────────────────────────────────
              pieTouchData: PieTouchData(
                // touchCallback — called every time the user touches the chart area
                // FlTouchEvent describes the touch (tap, drag, etc.)
                // pieTouchResponse contains information about which section was touched
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    // Conditions when we should deselect (set touchedIndex to -1):
                    // 1. The event type isn't a meaningful interaction (e.g., just hovering)
                    // 2. No touch response was returned
                    // 3. No section was touched (tapped empty area)
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1; // Deselect — reset all slices to normal size
                      return;
                    }
                    // Record which section was tapped
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    // setState() triggers a rebuild, which will make _getSections()
                    // re-render the tapped slice at a larger radius
                  });
                },
              ),

              borderData: FlBorderData(show: false), // No border around the chart

              sectionsSpace: 2,       // 2-pixel gap between slices (visual separation)
              centerSpaceRadius: 40,  // Radius of the empty center hole (donut shape)

              // sections — the pie slices, built by the helper method below
              sections: _getSections(total),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── LEGEND ───────────────────────────────────────────────────────────
        // Fixed height so the legend does not overflow the chart container.
        // SingleChildScrollView allows scrolling when there are many categories.
        SizedBox(
          height: 130,
          child: SingleChildScrollView(
            child: _buildLegend(),
          ),
        ),
      ],
    );
  }

  // _getSections — builds the list of PieChartSectionData (one per category)
  // Receives "total" — the sum of all amounts — for percentage calculation
  List<PieChartSectionData> _getSections(double total) {
    // Sort categories from highest to lowest spending
    // .entries.toList() converts the map to a list of MapEntry (key-value pairs)
    // ..sort(...) sorts in place — "b.value.compareTo(a.value)" sorts descending
    final sortedEntries = widget.categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // .asMap().entries — converts list to Map<int, MapEntry> so we get both index + value
    // This is the way to iterate a list with both the index and the value
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;           // Position in the sorted list (0 = biggest)
      final category = entry.value.key;  // Category name (e.g., "Food")
      final amount = entry.value.value;  // Amount spent in this category

      // Calculate what percentage of total spending this category represents
      final percentage = (amount / total) * 100;

      // Get the icon and color for this category
      final categoryInfo = TransactionCategories.getCategoryInfo(
        category,
        widget.type, // 'expense' or 'income'
      );

      // Determine if this slice is currently being tapped (touched)
      final isTouched = index == touchedIndex;

      // Tapped slice gets a bigger radius (70 vs 60) — visual "pop out" effect
      final radius = isTouched ? 70.0 : 60.0;

      // Tapped slice also gets slightly larger text
      final fontSize = isTouched ? 16.0 : 12.0;

      return PieChartSectionData(
        color: categoryInfo.color, // Each category has its own color
        value: amount,             // The size of this slice (proportional to amount)
        title: '${percentage.toStringAsFixed(1)}%', // Label shown ON the slice
        radius: radius,            // How wide the ring is (larger when tapped)
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white, // White text on colored slices
        ),
      );
    }).toList();
  }

  // _buildLegend — builds the row of colored pill badges below the chart
  // Each badge shows the category color dot, name, and total amount
  Widget _buildLegend() {
    // Sort categories from highest to lowest spending (same order as the chart)
    final sortedEntries = widget.categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Wrap — like Row but wraps to the next line when items don't fit
    // spacing: horizontal gap between items; runSpacing: vertical gap between rows
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: sortedEntries.map((entry) {
        // Get icon and color for this category
        final categoryInfo = TransactionCategories.getCategoryInfo(
          entry.key,    // Category name
          widget.type,  // 'expense' or 'income'
        );

        // Each legend item is a rounded pill container
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: categoryInfo.color.withOpacity(0.1), // Very light tinted background
            borderRadius: BorderRadius.circular(16),     // Rounded pill shape
            border: Border.all(
              color: categoryInfo.color.withOpacity(0.3), // Subtle colored border
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Row only takes up as much space as its content
            children: [
              // Small colored dot matching the pie slice color
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: categoryInfo.color,
                  shape: BoxShape.circle, // Perfect circle dot
                ),
              ),
              const SizedBox(width: 6),

              // Category name in the category's color
              Text(
                entry.key, // e.g., "Food", "Transport"
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: categoryInfo.color, // Colored text matches the dot
                ),
              ),
              const SizedBox(width: 4),

              // Total amount for this category (e.g., "RM500")
              Text(
                // .toStringAsFixed(0) — no decimal places for the legend amount
                'RM${entry.value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary, // Muted grey text for the amount
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
