import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/categories.dart';
import '../../utils/colors.dart';

class BudgetComparisonChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final double maxY;

  const BudgetComparisonChart({
    super.key,
    required this.data,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No budget data available'),
      );
    }

    final categories = data.keys.toList();

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.primary.withOpacity(0.9),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final category = categories[group.x.toInt()];
                final type = rodIndex == 0 ? 'Budgeted' : 'Actual';
                return BarTooltipItem(
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
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= categories.length) {
                    return const Text('');
                  }
                  final category = categories[value.toInt()];
                  // Get first word or first 3 letters
                  final shortName = category.contains(' ')
                      ? category.split(' ')[0]
                      : (category.length > 5 ? category.substring(0, 5) : category);

                  final categoryInfo = TransactionCategories.getCategoryInfo(
                    category,
                    'expense',
                  );

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: [
                        Icon(
                          categoryInfo.icon,
                          size: 16,
                          color: categoryInfo.color,
                        ),
                        const SizedBox(height: 2),
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
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY / 5,
                getTitlesWidget: (value, meta) {
                  if (value >= 1000) {
                    return Text(
                      'RM${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
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
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
              left: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          barGroups: _getBarGroups(categories),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(List<String> categories) {
    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final categoryData = data[category]!;
      final budgeted = categoryData['budgeted'] ?? 0.0;
      final actual = categoryData['actual'] ?? 0.0;

      // Color based on whether over or under budget
      final actualColor = actual > budgeted ? AppColors.danger : AppColors.success;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: budgeted,
            color: AppColors.primary.withOpacity(0.5),
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: actual,
            color: actualColor,
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }
}
