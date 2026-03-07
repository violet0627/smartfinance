// Import fl_chart — third-party Flutter charting library
// Provides LineChart, LineChartData, FlSpot, FlGridData, FlTitlesData, etc.
import 'package:fl_chart/fl_chart.dart';

// Import Flutter's core UI package — gives us StatelessWidget, Padding, Text, etc.
import 'package:flutter/material.dart';

// Import intl package — provides DateFormat for converting DateTime to "Jan", "Feb", etc.
import 'package:intl/intl.dart';

// Import our app color constants — AppColors.expense, .primary
import '../../utils/colors.dart';

// SpendingTrendChart — a StatelessWidget that renders a line chart of spending over time
// Used in the Analytics screen to show the spending trend across multiple months
// "Stateless" means this widget has no mutable state — it just renders what it's given
class SpendingTrendChart extends StatelessWidget {
  // trendData — a map of "YYYY-MM" date strings to spending amounts
  // Example: {"2024-01": 1500.0, "2024-02": 2000.0, "2024-03": 1200.0}
  // The "final" keyword means this field is set once at construction and never changes
  final Map<String, double> trendData;

  // maxY — the maximum Y axis value (top of the chart)
  // Pre-calculated by the parent with 20% headroom above the highest data point
  final double maxY;

  // const constructor — both parameters are required (must be provided when creating this widget)
  // "required" means the caller MUST pass these values — they cannot be omitted
  const SpendingTrendChart({
    super.key,
    required this.trendData,
    required this.maxY,
  });

  // build() — called by Flutter to render this widget into UI
  @override
  Widget build(BuildContext context) {
    // Guard clause: if no data, show a simple "No data available" message instead of a broken chart
    if (trendData.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Sort the month keys chronologically (e.g., "2024-01" < "2024-02")
    // .toList() converts the keys Set to a List so we can sort it
    // ..sort() is the cascade operator — calls sort() on the list and returns the same list
    final sortedKeys = trendData.keys.toList()..sort();

    // Build the list of FlSpot (data points) for the line chart
    // FlSpot(x, y) — x is the horizontal position (index 0,1,2...), y is the amount
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedKeys.length; i++) {
      // i.toDouble() — FlSpot requires doubles, so convert the int index to double
      // trendData[sortedKeys[i]]! — the ! asserts this value is NOT null (we know keys exist)
      spots.add(FlSpot(i.toDouble(), trendData[sortedKeys[i]]!));
    }

    // Padding — add space around the chart to prevent labels from being clipped
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      child: LineChart(
        // LineChartData — all configuration for the line chart
        LineChartData(
          // ── GRID LINES ────────────────────────────────────────────────────
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,         // Only show horizontal grid lines (cleaner look)
            horizontalInterval: maxY / 5,   // Show 5 evenly-spaced horizontal lines
            getDrawingHorizontalLine: (value) {
              // FlLine — defines the style of each horizontal grid line
              return FlLine(
                color: Colors.grey[300]!, // Light grey grid lines
                strokeWidth: 1,           // 1 pixel thick
              );
            },
          ),

          // ── AXIS LABELS ───────────────────────────────────────────────────
          titlesData: FlTitlesData(
            show: true,

            // Hide right and top axis labels (we only want left and bottom)
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
                reservedSize: 30, // Reserve 30 pixels height for the labels
                interval: 1,      // Show a label for every 1 unit (every month)

                // getTitlesWidget — a callback that returns a Widget for each tick value
                // "value" is the x position (0, 1, 2...), "meta" has additional info (unused here)
                getTitlesWidget: (value, meta) {
                  // Don't show label if value is out of bounds
                  if (value.toInt() >= sortedKeys.length) {
                    return const Text('');
                  }

                  // Convert the sorted key (e.g., "2024-03") to a month abbreviation ("Mar")
                  final monthKey = sortedKeys[value.toInt()];
                  final parts = monthKey.split('-'); // Split "2024-03" into ["2024", "03"]
                  // DateTime(year, month) — create a date from the year and month numbers
                  // int.parse() converts string "2024" to integer 2024
                  final month = DateFormat('MMM').format(
                    DateTime(int.parse(parts[0]), int.parse(parts[1])),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0), // Space above label
                    child: Text(
                      month, // e.g., "Jan", "Feb", "Mar"
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Left axis — shows amount labels (e.g., "RM1k", "RM2k")
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,         // Reserve 40 pixels width for labels
                interval: maxY / 5,       // Show 5 evenly-spaced labels
                getTitlesWidget: (value, meta) {
                  return Text(
                    // Format as "RM1k", "RM2k" (divide by 1000 for thousands)
                    // .toStringAsFixed(0) rounds to no decimal places
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
          // Only show bottom and left borders (forms an L-shape axis frame)
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
              left: BorderSide(color: Colors.grey[300]!),
            ),
          ),

          // ── AXIS BOUNDS ───────────────────────────────────────────────────
          minX: 0,                                     // Start at index 0 (first month)
          maxX: (sortedKeys.length - 1).toDouble(),   // End at the last month's index
          minY: 0,                                     // Start at RM 0
          maxY: maxY,                                  // End at the pre-calculated max

          // ── LINE DATA ─────────────────────────────────────────────────────
          // lineBarsData — list of lines to draw (we have only one line here)
          lineBarsData: [
            LineChartBarData(
              spots: spots,       // The data points we built above
              isCurved: true,     // Smooth curve between points (vs. straight lines)
              color: AppColors.expense, // Red/expense color for the spending line
              barWidth: 3,        // Line thickness in pixels
              isStrokeCapRound: true, // Round end caps on the line

              // dotData — configure the dots shown at each data point
              dotData: FlDotData(
                show: true,
                // getDotPainter — a callback that returns a painter for each dot
                getDotPainter: (spot, percent, barData, index) {
                  // FlDotCirclePainter — draws a circle dot
                  return FlDotCirclePainter(
                    radius: 4,                    // Dot radius in pixels
                    color: Colors.white,          // White fill (creates hollow look)
                    strokeWidth: 2,               // Border thickness
                    strokeColor: AppColors.expense, // Red border to match the line
                  );
                },
              ),

              // belowBarData — shaded area below the line (gradient effect)
              belowBarData: BarAreaData(
                show: true,
                // withOpacity(0.1) — very light transparent fill under the line
                color: AppColors.expense.withOpacity(0.1),
              ),
            ),
          ],

          // ── TOUCH/TAP INTERACTION ─────────────────────────────────────────
          // lineTouchData — defines behavior when user taps or hovers on the chart
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.primary.withOpacity(0.9), // Dark blue tooltip background

              // getTooltipItems — returns the text to show in the tooltip when tapped
              // "touchedBarSpots" is the list of data points near the tap location
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  // Convert the x index back to a human-readable month+year
                  final monthKey = sortedKeys[barSpot.x.toInt()];
                  final parts = monthKey.split('-');
                  final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                  // DateFormat('MMM yyyy') → "Mar 2024"
                  final monthYear = DateFormat('MMM yyyy').format(date);

                  // LineTooltipItem — defines the tooltip text and style
                  return LineTooltipItem(
                    // '\n' — newline character to put the amount on a second line
                    '$monthYear\nRM ${barSpot.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
