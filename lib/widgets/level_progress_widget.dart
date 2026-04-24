// ==============================================================================
// level_progress_widget.dart - Gamification Level Progress Display Widget
// ==============================================================================
// This widget shows the user's gamification level, XP progress, and stats.
// It has TWO display modes:
//
// 1. Compact mode: Single-row with level badge, progress bar, and total XP
//    Used in headers or small spaces (e.g., dashboard summary)
//
// 2. Full mode: Detailed view with large level badge, XP breakdown,
//    custom progress bar, and stats cards (achievements, streaks)
//    Used on the gamification/profile screen
//
// Level tiers (with colors):
// - Level 1-4:   Beginner     (Blue)
// - Level 5-9:   Intermediate (Orange)
// - Level 10-14: Advanced     (Red)
// - Level 15-19: Expert       (Deep Orange)
// - Level 20+:   Master       (Purple)
//
// Usage: LevelProgressWidget(stats: userStats, compact: true)
// ==============================================================================

import 'package:flutter/material.dart';          // For widgets, Colors, Icons, etc.
import '../models/gamification_model.dart';        // For UserStats model
import '../utils/colors.dart';                    // For AppColors (primary color)

// ==============================================================================
// LevelProgressWidget - StatelessWidget for Level Display
// ==============================================================================
// StatelessWidget because the display is determined entirely by the
// UserStats data passed in - no internal state changes needed.
// ==============================================================================
class LevelProgressWidget extends StatelessWidget {
  // UserStats holds level, totalXp, xpProgressInLevel, xpForNextLevel,
  // levelProgress, achievementsUnlocked, totalAchievements, streaks, etc.
  final UserStats stats;

  // Whether to show compact (true) or full (false) view
  // Defaults to false (full view) if not specified
  final bool compact;

  // Constructor: stats is required, compact is optional with default false
  const LevelProgressWidget({
    super.key,
    required this.stats,
    this.compact = false,
  });

  // ==============================================================================
  // _getLevelColor - Map Level Number to a Color
  // ==============================================================================
  // Returns a color based on the user's level tier.
  // Higher levels get more intense/"prestigious" colors.
  // ==============================================================================
  Color _getLevelColor(int level) {
    if (level >= 20) return Colors.purple;       // Master tier
    if (level >= 15) return Colors.deepOrange;   // Expert tier
    if (level >= 10) return Colors.red;          // Advanced tier
    if (level >= 5) return Colors.orange;        // Intermediate tier
    return Colors.blue;                          // Beginner tier (default)
  }

  // ==============================================================================
  // _getLevelTitle - Map Level Number to a Title String
  // ==============================================================================
  // Returns a human-readable title for the user's level tier.
  // ==============================================================================
  String _getLevelTitle(int level) {
    if (level >= 20) return 'Master';
    if (level >= 15) return 'Expert';
    if (level >= 10) return 'Advanced';
    if (level >= 5) return 'Intermediate';
    return 'Beginner';
  }

  // ==============================================================================
  // build - Choose Between Compact and Full View
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    // Pre-calculate level color and title since both views need them
    final levelColor = _getLevelColor(stats.level);
    final levelTitle = _getLevelTitle(stats.level);

    // Return the appropriate view based on the compact flag
    if (compact) {
      return _buildCompactView(levelColor, levelTitle);
    }

    return _buildFullView(levelColor, levelTitle);
  }

  // ==============================================================================
  // _buildCompactView - Single-Row Level Summary
  // ==============================================================================
  // Layout: [Level Badge] [Level Info + Progress Bar] [Total XP Badge]
  // Used for embedding in headers or small dashboard areas.
  // ==============================================================================
  Widget _buildCompactView(Color levelColor, String levelTitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Subtle gradient from level color (10% opacity) to white
        gradient: LinearGradient(
          colors: [
            levelColor.withOpacity(0.1),   // Tinted left side
            Colors.white,                  // White right side
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withOpacity(0.3)),  // Subtle colored border
      ),
      child: Row(
        children: [
          // --- Level Badge (Circle with number) ---
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: levelColor,                // Solid level color background
              shape: BoxShape.circle,           // Perfect circle shape
              boxShadow: [
                BoxShadow(
                  color: levelColor.withOpacity(0.3),  // Colored glow effect
                  blurRadius: 8,                        // How spread out the glow is
                  offset: const Offset(0, 2),           // Shadow slightly below
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${stats.level}',              // Display level number
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,         // White text on colored background
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),           // Space between badge and info

          // --- Level Info Section ---
          // Expanded takes all remaining horizontal space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,  // Left-align text
              mainAxisSize: MainAxisSize.min,                 // Don't expand vertically
              children: [
                // Level label: "Level 5 - Intermediate"
                Text(
                  'Level ${stats.level} - $levelTitle',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // XP progress bar
                // ClipRRect clips the progress bar to have rounded corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    // value must be 0.0 to 1.0 (divide percentage by 100)
                    value: stats.levelProgress / 100,
                    backgroundColor: Colors.grey.shade200,           // Grey track
                    // AlwaysStoppedAnimation provides a fixed color (not animated)
                    valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                    minHeight: 6,                                    // Bar thickness
                  ),
                ),
                const SizedBox(height: 2),

                // XP numbers: "150 / 500 XP"
                Text(
                  '${stats.xpProgressInLevel} / ${stats.xpForNextLevel} XP',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,      // Grey subtitle text
                  ),
                ),
              ],
            ),
          ),

          // --- Total XP Badge (right side) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),  // Light primary tint
              borderRadius: BorderRadius.circular(12),    // Pill shape
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,              // Don't expand wider than content
              children: [
                Icon(Icons.stars, size: 14, color: AppColors.primary),  // Star icon
                const SizedBox(width: 4),
                Text(
                  '${stats.totalXp}',                     // Total XP number
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // _buildFullView - Detailed Level Progress Display
  // ==============================================================================
  // Layout:
  // [Large Level Badge] [Level Title + Total XP + XP to next level]
  // [Custom Progress Bar with gradient fill]
  // [Stats Row: Achievements | Best Streak | Daily Streak]
  // ==============================================================================
  Widget _buildFullView(Color levelColor, String levelTitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            levelColor.withOpacity(0.15),   // Stronger tint than compact view
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          // --- Top Row: Level Badge + Details ---
          Row(
            children: [
              // Large Level Badge (80x80 circle)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: levelColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // "LVL" label above the number
                      const Text(
                        'LVL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,        // 70% opacity white
                        ),
                      ),
                      // Large level number
                      Text(
                        '${stats.level}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Level Details (title, total XP, XP needed)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level title (e.g., "Intermediate") in level color
                    Text(
                      levelTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Total XP with star icon
                    Row(
                      children: [
                        Icon(Icons.stars, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.totalXp} Total XP',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // XP remaining to reach next level
                    Text(
                      '${stats.xpForNextLevel - stats.xpProgressInLevel} XP to Level ${stats.level + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,     // Italic for secondary info
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- Custom Progress Bar ---
          // Using Stack to layer the background track and foreground fill
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label row: "Level Progress" on left, percentage on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level Progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    // .toStringAsFixed(1) shows one decimal: "75.3%"
                    '${stats.levelProgress.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: levelColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stack layers widgets on top of each other
              Stack(
                children: [
                  // Background track (grey, full width)
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),

                  // Foreground fill (colored, partial width based on progress)
                  // FractionallySizedBox sizes its child as a fraction of the parent
                  FractionallySizedBox(
                    widthFactor: stats.levelProgress / 100,  // 0.0 to 1.0
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        // Gradient fill for the progress bar
                        gradient: LinearGradient(
                          colors: [
                            levelColor,                          // Solid color
                            levelColor.withOpacity(0.7),         // Slightly faded
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: levelColor.withOpacity(0.3),  // Colored glow
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // XP range labels: current XP on left, target XP on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stats.xpProgressInLevel} XP',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${stats.xpForNextLevel} XP',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- Stats Row: Three Stat Cards Side by Side ---
          Row(
            children: [
              // Achievements card
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events,                   // Trophy icon
                  label: 'Achievements',
                  value: '${stats.achievementsUnlocked}/${stats.totalAchievements}',
                  color: Colors.amber,                        // Gold/yellow
                ),
              ),
              const SizedBox(width: 12),

              // Best streak card
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department,           // Fire icon
                  label: 'Best Streak',
                  value: '${stats.longestStreak} days',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),

              // Current daily streak card
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,                    // Upward trend icon
                  label: 'Daily Streak',
                  value: '${stats.currentDailyStreak} days',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // _buildStatCard - Reusable Stat Display Card
  // ==============================================================================
  // Creates a small card with an icon, value, and label.
  // Used for the stats row at the bottom of the full view.
  //
  // Named parameters with "required" keyword must be provided.
  // ==============================================================================
  Widget _buildStatCard({
    required IconData icon,    // Icon to display at top
    required String label,     // Label text at bottom (e.g., "Achievements")
    required String value,     // Value text in middle (e.g., "5/10")
    required Color color,      // Color theme for this card
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),                   // Light tinted background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),            // Colored icon
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,                              // Value in matching color
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,               // Grey label text
            ),
            textAlign: TextAlign.center,                 // Center multiline labels
          ),
        ],
      ),
    );
  }
}
