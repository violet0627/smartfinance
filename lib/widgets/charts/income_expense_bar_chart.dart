import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final double maxY;

  const IncomeExpenseBarChart({
    super.key,
    required this.data,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final sortedKeys = data.keys.toList()..sort();

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
                final monthKey = sortedKeys[group.x.toInt()];
                final parts = monthKey.split('-');
                final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                final monthYear = DateFormat('MMM yyyy').format(date);
                final type = rodIndex == 0 ? 'Income' : 'Expense';
                return BarTooltipItem(
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
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sortedKeys.length) {
                    return const Text('');
                  }
                  final monthKey = sortedKeys[value.toInt()];
                  final parts = monthKey.split('-');
                  final month = DateFormat('MMM').format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
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
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY / 5,
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
          barGroups: _getBarGroups(sortedKeys),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(List<String> sortedKeys) {
    return sortedKeys.asMap().entries.map((entry) {
      final index = entry.key;
      final monthKey = entry.value;
      final monthData = data[monthKey]!;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: monthData['income'] ?? 0.0,
            color: AppColors.income,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: monthData['expense'] ?? 0.0,
            color: AppColors.expense,
            width: 12,
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
