import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';

class FinancialInsightsScreen extends StatefulWidget {
  const FinancialInsightsScreen({super.key});

  @override
  State<FinancialInsightsScreen> createState() => _FinancialInsightsScreenState();
}

class _FinancialInsightsScreenState extends State<FinancialInsightsScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) {
      setState(() {
        _error = 'Not logged in';
        _isLoading = false;
      });
      return;
    }

    final result = await ApiService.getFinancialInsights(userId);

    if (!mounted) return; // Guard — widget may have been disposed while awaiting

    if (result['success']) {
      setState(() {
        _data = result['data'] as Map<String, dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? 'Failed to load insights';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Insights'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInsights,
            tooltip: 'Refresh insights',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _loadInsights,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInsights,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // _data is guaranteed non-null here (checked in build)
    final score = _data!['score'] as int;
    final scoreLabel = _data!['scoreLabel'] as String;
    final scoreColor = _scoreColor(scoreLabel);
    final pillars = _data!['pillars'] as Map<String, dynamic>;
    final summary = _data!['summary'] as Map<String, dynamic>;
    final insights = (_data!['insights'] as List).cast<Map<String, dynamic>>();

    return ListView(
      // AlwaysScrollableScrollPhysics makes pull-to-refresh work even when
      // the content is shorter than the screen
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildScoreCard(score, scoreLabel, scoreColor),
        const SizedBox(height: 16),
        _buildPillarCard(pillars),
        const SizedBox(height: 16),
        _buildSummaryCard(summary),
        const SizedBox(height: 16),
        const Text(
          'Personalised Insights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // If no insights returned, the user has no transactions yet this month.
        // Show an encouraging empty state instead of a blank section.
        if (insights.isEmpty)
          _buildEmptyInsights()
        else
          ...insights.map((insight) => _buildInsightCard(insight)),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Based on your transactions this calendar month',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildScoreCard(int score, String label, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, color: color, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Financial Health Score',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 14,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _scoreCaption(label),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarCard(Map<String, dynamic> pillars) {
    final items = [
      {'label': 'Savings Rate',   'icon': Icons.savings,                'value': (pillars['savingsRate'] as num).toDouble()},
      {'label': 'Budget',         'icon': Icons.account_balance_wallet,  'value': (pillars['budgetAdherence'] as num).toDouble()},
      {'label': 'Consistency',    'icon': Icons.show_chart,              'value': (pillars['spendingConsistency'] as num).toDouble()},
      {'label': 'Goal Progress',  'icon': Icons.flag,                    'value': (pillars['goalProgress'] as num).toDouble()},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Score Breakdown',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildPillarRow(
              label: item['label'] as String,
              icon: item['icon'] as IconData,
              value: item['value'] as double,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarRow({required String label, required IconData icon, required double value}) {
    final fraction = value / 25.0; // Each pillar is scored 0–25 by the backend

    final Color barColor;
    if (fraction >= 0.75) {
      barColor = Colors.green;
    } else if (fraction >= 0.50) {
      barColor = Colors.teal;
    } else if (fraction >= 0.25) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: barColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 13)),
                    Text(
                      '${value.toStringAsFixed(1)}/25',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    final income = (summary['currentMonthIncome'] as num).toDouble();
    final expense = (summary['currentMonthExpense'] as num).toDouble();
    final savings = (summary['savingsAmount'] as num).toDouble();
    final rate = (summary['savingsRate'] as num).toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Month',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryBox(
                    label: 'Income',
                    value: 'RM ${income.toStringAsFixed(0)}',
                    color: Colors.green,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryBox(
                    label: 'Expenses',
                    value: 'RM ${expense.toStringAsFixed(0)}',
                    color: Colors.red,
                    icon: Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryBox(
                    label: 'Saved (${rate.toStringAsFixed(0)}%)',
                    value: 'RM ${savings.abs().toStringAsFixed(0)}',
                    color: savings >= 0 ? Colors.teal : Colors.orange,
                    icon: savings >= 0 ? Icons.savings : Icons.warning_amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    final type = insight['type'] as String;     // 'positive' | 'info' | 'warning' | 'danger'
    final title = insight['title'] as String;
    final message = insight['message'] as String;
    final iconName = insight['icon'] as String; // backend sends icon name as plain string

    final Color typeColor;
    switch (type) {
      case 'positive':
        typeColor = Colors.green;
        break;
      case 'warning':
        typeColor = Colors.orange;
        break;
      case 'danger':
        typeColor = Colors.red;
        break;
      default:
        typeColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: typeColor, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _iconFromName(iconName),
                    color: typeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInsights() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No insights yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start adding your income and expenses this month — '
              'your personalised financial insights will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(String label) {
    switch (label) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.teal;
      case 'Fair':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _scoreCaption(String label) {
    switch (label) {
      case 'Excellent':
        return 'You\'re in great financial shape. Keep it up!';
      case 'Good':
        return 'Solid habits — a few tweaks could push you to Excellent.';
      case 'Fair':
        return 'You\'re on the right track. Focus on the insights below.';
      default:
        return 'Your finances need attention. Read the insights for guidance.';
    }
  }

  // The backend sends icon names as plain strings (e.g., 'savings', 'flag').
  // Flutter's Icon widget needs an IconData object, not a string.
  // This function does the translation.
  IconData _iconFromName(String name) {
    switch (name) {
      case 'savings':                return Icons.savings;
      case 'warning_amber':          return Icons.warning_amber;
      case 'trending_up':            return Icons.trending_up;
      case 'trending_down':          return Icons.trending_down;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'money_off':              return Icons.money_off;
      case 'pie_chart':              return Icons.pie_chart;
      case 'flag':                   return Icons.flag;
      case 'emoji_events':           return Icons.emoji_events;
      case 'notification_important': return Icons.notification_important;
      case 'show_chart':             return Icons.show_chart;
      default:                       return Icons.lightbulb_outline;
    }
  }
}
