// ==============================================================================
// goal_progress_card.dart - Financial Goals Progress Summary Card
// ==============================================================================
// This widget displays a summary card for the user's financial goals.
// It shows on the dashboard and provides a quick overview of:
//
// - Overall progress (circular progress indicator with percentage)
// - Active goals count and completed goals count
// - Total amount saved across all goals
// - Amount progress bar (saved vs target)
// - Closest upcoming deadline warning
//
// If there are no active goals, it shows an empty state with a prompt
// to create the first goal.
//
// The entire card is tappable (InkWell) to navigate to the goals screen.
//
// Usage: GoalProgressCard(summary: goalSummaryMap, onTap: () => navigateToGoals())
// ==============================================================================

import 'package:flutter/material.dart';   // For widgets, Colors, Icons, etc.
import 'package:intl/intl.dart';          // For NumberFormat (formatting currency with commas)
import '../utils/colors.dart';            // For AppColors (primary, success, warning, danger)

// ==============================================================================
// GoalProgressCard - StatelessWidget for Goal Summary Display
// ==============================================================================
// StatelessWidget because the display depends entirely on the summary data
// passed in - no internal state changes needed.
// ==============================================================================
class GoalProgressCard extends StatelessWidget {
  // Map containing goal summary data from the API:
  // - 'activeGoals': int - number of in-progress goals
  // - 'completedGoals': int - number of finished goals
  // - 'overallProgress': double - average progress percentage (0-100)
  // - 'totalSavedAmount': double - sum of all saved amounts
  // - 'totalTargetAmount': double - sum of all target amounts
  // - 'closestDeadline': Map with 'goalName', 'daysRemaining', 'isOverdue'
  final Map<String, dynamic> summary;

  // Callback function when the card is tapped (navigate to goals screen)
  // VoidCallback is a function type that takes no arguments and returns nothing
  final VoidCallback onTap;

  const GoalProgressCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- Extract data from the summary map ---
    // ?? provides default values if keys are missing (null safety)
    final activeGoals = summary['activeGoals'] ?? 0;           // Default: 0
    final completedGoals = summary['completedGoals'] ?? 0;
    final overallProgress = summary['overallProgress'] ?? 0.0; // Default: 0.0
    final totalSaved = summary['totalSavedAmount'] ?? 0.0;
    final totalTarget = summary['totalTargetAmount'] ?? 0.0;
    final closestDeadline = summary['closestDeadline'];        // May be null

    // --- Determine progress bar color based on progress percentage ---
    Color progressColor = AppColors.success;    // Default: green (>=80%)
    if (overallProgress < 50) {
      progressColor = AppColors.danger;         // Red for low progress (<50%)
    } else if (overallProgress < 80) {
      progressColor = AppColors.warning;        // Orange for moderate progress (50-79%)
    }

    // --- Card wrapper with tap handling ---
    return Card(
      elevation: 3,                                           // Shadow depth
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,                                         // Handle tap to navigate
        borderRadius: BorderRadius.circular(16),              // Ripple clips to card shape
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // Subtle gradient from primary tint to white
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,     // Left-align children
            children: [
              // --- Header Row: Icon + Title + Arrow ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Flag icon in colored container
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Financial Goals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Forward arrow indicating the card is tappable
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Conditional Content: Goals exist vs. No goals ---
              // "if (condition) ...[widgets]" is Dart's collection-if with spread
              // It conditionally inserts widgets into the children list
              if (activeGoals > 0) ...[
                // ========== ACTIVE GOALS VIEW ==========
                Row(
                  children: [
                    // --- Circular Progress Indicator ---
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,          // Center children in stack
                        children: [
                          // The circular progress ring
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: overallProgress / 100,   // 0.0 to 1.0
                              strokeWidth: 8,                 // Ring thickness
                              backgroundColor: Colors.grey.shade200,  // Grey unfilled portion
                              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                            ),
                          ),
                          // Percentage text centered inside the ring
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${overallProgress.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // --- Stats Column (right of progress circle) ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active goals count
                          _buildStatRow(
                            'Active Goals',
                            activeGoals.toString(),
                            Icons.flag,                       // Flag icon
                            AppColors.primary,                // Blue
                          ),
                          const SizedBox(height: 8),

                          // Completed goals count
                          _buildStatRow(
                            'Completed',
                            completedGoals.toString(),
                            Icons.check_circle,               // Checkmark icon
                            AppColors.success,                // Green
                          ),
                          const SizedBox(height: 8),

                          // Total saved amount
                          _buildStatRow(
                            'Total Saved',
                            // NumberFormat('#,##0') formats with commas: 1000 -> "1,000"
                            'RM ${NumberFormat('#,##0').format(totalSaved)}',
                            Icons.savings,                    // Piggy bank icon
                            AppColors.warning,                // Orange
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Amount Progress Bar (saved vs target) ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,               // Light grey background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Saved amount (left) vs Target amount (right)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            // '#,##0.00' formats with commas and 2 decimals
                            'RM ${NumberFormat('#,##0.00').format(totalSaved)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'RM ${NumberFormat('#,##0.00').format(totalTarget)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Linear progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: overallProgress / 100,        // 0.0 to 1.0
                          minHeight: 8,                        // Bar thickness
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Closest Deadline Warning (if exists) ---
                // Only shows if closestDeadline is not null
                if (closestDeadline != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),   // Light orange background
                      border: Border.all(color: AppColors.warning, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Timer icon
                        Icon(
                          Icons.timer,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 8),

                        // Goal name and "Next Deadline" label
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next Deadline',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                closestDeadline['goalName'],   // Name of the goal
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,                   // Prevent text wrapping
                                overflow: TextOverflow.ellipsis, // Show "..." if too long
                              ),
                            ],
                          ),
                        ),

                        // Days remaining (red if overdue, orange otherwise)
                        Text(
                          '${closestDeadline['daysRemaining']} days',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            // Ternary: red if overdue, orange if not
                            color: closestDeadline['isOverdue'] ? AppColors.danger : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // ========== NO ACTIVE GOALS - EMPTY STATE ==========
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        // Large grey outlined flag icon
                        Icon(
                          Icons.flag_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No active goals',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to create your first goal',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================================
  // _buildStatRow - Reusable Row with Icon, Label, and Value
  // ==============================================================================
  // Creates a single stat row: [Icon] [Label ............... Value]
  // Used for Active Goals, Completed, and Total Saved stats.
  // ==============================================================================
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),       // Colored stat icon
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,                                // Stat name (takes remaining space)
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,                                  // Stat value (right-aligned)
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
