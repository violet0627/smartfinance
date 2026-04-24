import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/gamification_model.dart';
import '../../utils/colors.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {

  List<UserAchievement> _achievements = [];
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  bool _leaderboardLoading = true;
  String _error = '';
  String _selectedDifficulty = 'all';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAchievements();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _loadLeaderboard() async {
    setState(() => _leaderboardLoading = true);
    try {
      final result = await ApiService.getLeaderboard();
      if (result['success']) {
        setState(() {
          _leaderboard = List<Map<String, dynamic>>.from(result['leaderboard'] ?? []);
          _leaderboardLoading = false;
        });
      } else {
        setState(() => _leaderboardLoading = false);
      }
    } catch (e) {
      setState(() => _leaderboardLoading = false);
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

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnlocked ? Colors.grey.shade700 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),

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

  Widget _buildLeaderboard() {
    if (_leaderboardLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_leaderboard.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No leaderboard data yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboard.length,
        itemBuilder: (context, index) {
          final entry = _leaderboard[index];
          final rank = (entry['rank'] ?? index + 1) as int;
          final name = entry['fullName'] ?? entry['name'] ?? 'Unknown';
          final xp = entry['totalXp'] ?? entry['xp'] ?? 0;
          final level = entry['level'] ?? 1;

          Color rankColor = Colors.grey.shade600;
          if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
          if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
          if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: rank <= 3 ? 3 : 1,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: rankColor.withOpacity(0.15),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                    fontSize: 13,
                  ),
                ),
              ),
              title: Text(
                name,
                style: TextStyle(
                  fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text('Level $level'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$xp XP',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoading
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

                      _buildDifficultyFilter(),

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

          _buildLeaderboard(),
        ],
      ),
    );
  }
}
