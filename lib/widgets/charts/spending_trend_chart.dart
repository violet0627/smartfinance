import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';

class SpendingTrendChart extends StatelessWidget {
  final Map<String, double> trendData;
  final double maxY;

  const SpendingTrendChart({
    super.key,
    required this.trendData,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final sortedKeys = trendData.keys.toList()..sort();
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), trendData[sortedKeys[i]]!));
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      child: LineChart(
        LineChartData(
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
                interval: 1,
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
          minX: 0,
          maxX: (sortedKeys.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.expense,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: AppColors.expense,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.expense.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.primary.withOpacity(0.9),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final monthKey = sortedKeys[barSpot.x.toInt()];
                  final parts = monthKey.split('-');
                  final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                  final monthYear = DateFormat('MMM yyyy').format(date);
                  return LineTooltipItem(
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
