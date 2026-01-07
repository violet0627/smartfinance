import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/gamification_model.dart';
import '../../utils/colors.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<UserAchievement> _achievements = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedDifficulty = 'all';

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final result = await ApiService.getUserAchievements(userId);

      if (result['success']) {
        final achievementsList = (result['userAchievements'] as List)
            .map((json) => UserAchievement.fromJson(json))
            .toList();

        setState(() {
          _achievements = achievementsList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to load achievements';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<UserAchievement> get _filteredAchievements {
    if (_selectedDifficulty == 'all') {
      return _achievements;
    }
    return _achievements
        .where((ua) => ua.achievement?.difficultyLevel == _selectedDifficulty)
        .toList();
  }

  int get _unlockedCount {
    return _achievements.where((ua) => ua.isUnlocked).length;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.emoji_events_outlined;
      case 'medium':
        return Icons.emoji_events;
      case 'hard':
        return Icons.military_tech;
      case 'expert':
        return Icons.workspace_premium;
      default:
        return Icons.emoji_events;
    }
  }

  Widget _buildDifficultyFilter() {
    final difficulties = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Easy', 'value': 'easy'},
      {'label': 'Medium', 'value': 'medium'},
      {'label': 'Hard', 'value': 'hard'},
      {'label': 'Expert', 'value': 'expert'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: difficulties.map((diff) {
          final isSelected = _selectedDifficulty == diff['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(diff['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedDifficulty = diff['value']!;
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementCard(UserAchievement userAchievement) {
    final achievement = userAchievement.achievement;
    if (achievement == null) return const SizedBox.shrink();

    final isUnlocked = userAchievement.isUnlocked;
    final progress = userAchievement.progressPercentage;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isUnlocked ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    _getDifficultyColor(achievement.difficultyLevel).withOpacity(0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? _getDifficultyColor(achievement.difficultyLevel).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked
                        ? _getDifficultyColor(achievement.difficultyLevel)
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getDifficultyIcon(achievement.difficultyLevel),
                        size: 40,
                        color: isUnlocked
                            ? _getDifficultyColor(achievement.difficultyLevel)
                            : Colors.grey,
                      ),
                    ),
                    if (!isUnlocked)
                      Center(
                        child: Icon(
                          Icons.lock,
                          size: 24,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Achievement Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and XP
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.black : Colors.grey.shade600,
                            ),
                          ),
                        ),
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
                                '${achievement.xpReward} XP',
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
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnlocked ? Colors.grey.shade700 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Unlock Criteria
                    Text(
                      achievement.unlockCriteria,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    if (!isUnlocked) ...[
                      const SizedBox(height: 12),
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${progress.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getDifficultyColor(achievement.difficultyLevel),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (isUnlocked && userAchievement.unlockedAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Unlocked on ${_formatDate(userAchievement.unlockedAt!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAchievements,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAchievements,
                  child: Column(
                    children: [
                      // Stats Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_unlockedCount / ${_achievements.length}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Achievements Unlocked',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _achievements.isEmpty
                                    ? 0
                                    : _unlockedCount / _achievements.length,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Difficulty Filter
                      _buildDifficultyFilter(),

                      // Achievements List
                      Expanded(
                        child: _filteredAchievements.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.emoji_events_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No achievements found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 8, bottom: 16),
                                itemCount: _filteredAchievements.length,
                                itemBuilder: (context, index) {
                                  return _buildAchievementCard(_filteredAchievements[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
