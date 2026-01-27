import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/categories.dart';
import '../../utils/colors.dart';

class CategoryPieChart extends StatefulWidget {
  final Map<String, double> categoryData;
  final String type; // 'expense' or 'income'

  const CategoryPieChart({
    super.key,
    required this.categoryData,
    required this.type,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryData.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final total = widget.categoryData.values.fold(0.0, (sum, value) => sum + value);

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _getSections(total),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: _buildLegend(),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getSections(double total) {
    final sortedEntries = widget.categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      final percentage = (amount / total) * 100;

      final categoryInfo = TransactionCategories.getCategoryInfo(
        category,
        widget.type,
      );

      final isTouched = index == touchedIndex;
      final radius = isTouched ? 70.0 : 60.0;
      final fontSize = isTouched ? 16.0 : 12.0;

      return PieChartSectionData(
        color: categoryInfo.color,
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    final sortedEntries = widget.categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: sortedEntries.map((entry) {
        final categoryInfo = TransactionCategories.getCategoryInfo(
          entry.key,
          widget.type,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: categoryInfo.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: categoryInfo.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: categoryInfo.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: categoryInfo.color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'RM${entry.value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
