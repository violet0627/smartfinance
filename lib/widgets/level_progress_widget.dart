import 'package:flutter/material.dart';
import '../models/gamification_model.dart';
import '../utils/colors.dart';

class LevelProgressWidget extends StatelessWidget {
  final UserStats stats;
  final bool compact;

  const LevelProgressWidget({
    super.key,
    required this.stats,
    this.compact = false,
  });

  Color _getLevelColor(int level) {
    if (level >= 20) return Colors.purple;
    if (level >= 15) return Colors.deepOrange;
    if (level >= 10) return Colors.red;
    if (level >= 5) return Colors.orange;
    return Colors.blue;
  }

  String _getLevelTitle(int level) {
    if (level >= 20) return 'Master';
    if (level >= 15) return 'Expert';
    if (level >= 10) return 'Advanced';
    if (level >= 5) return 'Intermediate';
    return 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(stats.level);
    final levelTitle = _getLevelTitle(stats.level);

    if (compact) {
      return _buildCompactView(levelColor, levelTitle);
    }

    return _buildFullView(levelColor, levelTitle);
  }

  Widget _buildCompactView(Color levelColor, String levelTitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            levelColor.withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Level Badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: levelColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: levelColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${stats.level}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Level Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Level ${stats.level} - $levelTitle',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.levelProgress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stats.xpProgressInLevel} / ${stats.xpForNextLevel} XP',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Total XP Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${stats.totalXp}',
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

  Widget _buildFullView(Color levelColor, String levelTitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            levelColor.withOpacity(0.15),
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
          Row(
            children: [
              // Level Badge
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
                      const Text(
                        'LVL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
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

              // Level Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                    Text(
                      '${stats.xpForNextLevel - stats.xpProgressInLevel} XP to Level ${stats.level + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: stats.levelProgress / 100,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            levelColor,
                            levelColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: levelColor.withOpacity(0.3),
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

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events,
                  label: 'Achievements',
                  value: '${stats.achievementsUnlocked}/${stats.totalAchievements}',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department,
                  label: 'Best Streak',
                  value: '${stats.longestStreak} days',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
