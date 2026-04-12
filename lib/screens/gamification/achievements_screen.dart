// ==============================================================================
// achievements_screen.dart - Achievements & Leaderboard Screen
// ==============================================================================
// This screen has two tabs:
//   Tab 1 — Achievements: shows all badges the user can earn, locked or unlocked.
//            Each card shows a badge icon, description, XP reward, difficulty level,
//            and a progress bar for locked achievements.
//   Tab 2 — Leaderboard: shows top users ranked by total XP earned.
//
// Features:
// - Difficulty filter chips (All / Easy / Medium / Hard / Expert)
// - Pull-to-refresh on both tabs
// - Gold / silver / bronze rank colours for top 3 leaderboard entries
//
// Usage: Navigated to from the dashboard Quick Actions grid.
// ==============================================================================

import 'package:flutter/material.dart';          // For StatefulWidget, TabBar, LinearProgressIndicator, etc.
import '../../services/api_service.dart';          // For getUserAchievements() and getLeaderboard() API calls
import '../../models/gamification_model.dart';     // For UserAchievement and Achievement data classes
import '../../utils/colors.dart';                  // For AppColors constants

// ==============================================================================
// AchievementsScreen - StatefulWidget
// ==============================================================================
// StatefulWidget because it manages:
// - Achievement list loaded from the API (_achievements)
// - Leaderboard data (_leaderboard)
// - Loading and error states for both tabs
// - The selected difficulty filter chip (_selectedDifficulty)
// - A TabController for switching between the two tabs
// ==============================================================================
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

// ==============================================================================
// "with SingleTickerProviderStateMixin" — What This Means
// ==============================================================================
// A "mixin" in Dart adds functionality to a class without inheritance.
// SingleTickerProviderStateMixin adds a "ticker" — a signal that fires every
// animation frame (60 times per second on most devices).
//
// TabController needs a ticker to animate the sliding tab indicator.
// By using this mixin, the State class itself becomes the TickerProvider,
// which is why we can pass `vsync: this` when creating the TabController.
// (If this mixin were missing, creating TabController(vsync: this) would crash.)
// ==============================================================================
class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {

  List<UserAchievement> _achievements = [];        // All achievements fetched from the API
  List<Map<String, dynamic>> _leaderboard = [];    // Leaderboard entries from the API
  bool _isLoading = true;                          // True while fetching achievements
  bool _leaderboardLoading = true;                 // True while fetching leaderboard
  String _error = '';                              // Holds error message; empty string = no error
  String _selectedDifficulty = 'all';              // Current difficulty filter ('all', 'easy', etc.)

  // ==============================================================================
  // TabController — Controls Which Tab Is Active
  // ==============================================================================
  // TabController.index = 0 means Tab 1 (Achievements) is active.
  // TabController.index = 1 means Tab 2 (Leaderboard) is active.
  // 'late' means this variable is guaranteed to be assigned before it's used —
  // it's set in initState(), so Flutter knows it will never be null when read.
  // ==============================================================================
  late TabController _tabController;

  // ==============================================================================
  // initState - Runs Once When the Widget Is Inserted Into the Widget Tree
  // ==============================================================================
  // This is where we set up the TabController and start fetching data.
  // We must call super.initState() first — this initialises the parent State class.
  // ==============================================================================
  @override
  void initState() {
    super.initState();                                      // Always call super first
    // TabController(length: 2) means we have exactly 2 tabs.
    // vsync: this passes the ticker from SingleTickerProviderStateMixin to the controller.
    _tabController = TabController(length: 2, vsync: this);
    _loadAchievements();   // Start loading Tab 1 data
    _loadLeaderboard();    // Start loading Tab 2 data (both run concurrently)
  }

  // ==============================================================================
  // dispose - Clean Up Resources When the Widget Is Removed From the Tree
  // ==============================================================================
  // dispose() is called when the user navigates away from this screen.
  // We MUST dispose the TabController here to stop its animation ticker.
  // If we forget, the ticker keeps firing 60 times/second after the screen is gone,
  // which wastes battery and can cause "setState called on a disposed widget" errors.
  // ==============================================================================
  @override
  void dispose() {
    _tabController.dispose();  // Stop the tab animation ticker and free memory
    super.dispose();           // Always call super.dispose() last
  }

  // ==============================================================================
  // _loadAchievements - Fetch All Achievements for the Current User
  // ==============================================================================
  // Calls GET /api/gamification/user/<id>/achievements
  // The response merges the master achievement list with the user's progress,
  // so we get locked/unlocked status and progress percentage for every achievement.
  // ==============================================================================
  Future<void> _loadAchievements() async {
    // Reset to loading state and clear any previous error message
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // --- Step 1: Get the current user's ID from SharedPreferences ---
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // --- Step 2: Call the API ---
      final result = await ApiService.getUserAchievements(userId);

      if (result['success']) {
        // --- Step 3: Parse the response ---
        // result['userAchievements'] is a raw JSON List (List<dynamic>).
        // We cast it to List, then call .map() to convert each item (a JSON Map)
        // into a typed UserAchievement object using its fromJson factory constructor.
        // .toList() converts the lazy Iterable returned by .map() into an actual List.
        final achievementsList = (result['userAchievements'] as List)
            .map((json) => UserAchievement.fromJson(json))
            .toList();
        setState(() {
          _achievements = achievementsList;   // Store achievements and trigger rebuild
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to load achievements'; // '??' returns right side if left is null
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

  // ==============================================================================
  // _loadLeaderboard - Fetch the Global XP Leaderboard
  // ==============================================================================
  // Calls GET /api/gamification/leaderboard
  // Returns the top 10 users ranked by total XP, with their level and display name.
  // Uses List<Map<String, dynamic>> because the leaderboard JSON doesn't have its
  // own typed model — a Map is sufficient for the simple list display.
  // ==============================================================================
  Future<void> _loadLeaderboard() async {
    setState(() => _leaderboardLoading = true);
    try {
      final result = await ApiService.getLeaderboard();
      if (result['success']) {
        setState(() {
          // List<Map<String, dynamic>>.from() converts the raw List<dynamic> from JSON
          // into a typed List<Map<String, dynamic>> so we can safely access keys like
          // entry['rank'], entry['totalXp'], etc. without runtime type errors.
          // '?? []' returns an empty list if 'leaderboard' key is null (safe fallback).
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

  // ==============================================================================
  // _filteredAchievements — Computed Getter
  // ==============================================================================
  // A Dart "getter" is a property that runs code to produce its value.
  // Instead of storing a pre-filtered list, this is computed fresh every time
  // the widget rebuilds — so it always reflects the current _selectedDifficulty.
  //
  // Syntax: `List<UserAchievement> get _filteredAchievements { ... }`
  // Usage:  `_filteredAchievements.length`  (no parentheses — reads like a field)
  // ==============================================================================
  List<UserAchievement> get _filteredAchievements {
    if (_selectedDifficulty == 'all') {
      return _achievements; // No filter: return everything
    }
    // .where() filters the list, keeping only items where the condition is true
    // ua is each UserAchievement; ua.achievement is the nested Achievement object (nullable)
    return _achievements
        .where((ua) => ua.achievement?.difficultyLevel == _selectedDifficulty)
        .toList();
  }

  // _unlockedCount counts how many achievements the user has unlocked
  int get _unlockedCount {
    // .where() filters, .length counts them
    return _achievements.where((ua) => ua.isUnlocked).length;
  }

  // _getDifficultyColor returns the appropriate color for each difficulty level
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) { // toLowerCase ensures case-insensitive comparison
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.grey; // Fallback for unknown difficulty levels
    }
  }

  // _getDifficultyIcon returns an appropriate icon for each difficulty level
  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.emoji_events_outlined; // Trophy outline (easier)
      case 'medium':
        return Icons.emoji_events; // Filled trophy
      case 'hard':
        return Icons.military_tech; // Military medal
      case 'expert':
        return Icons.workspace_premium; // Premium/star icon
      default:
        return Icons.emoji_events;
    }
  }

  // _buildDifficultyFilter creates the horizontal scrolling filter chips at the top
  Widget _buildDifficultyFilter() {
    // List of filter options - each is a Map with label (displayed text) and value (filter string)
    final difficulties = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Easy', 'value': 'easy'},
      {'label': 'Medium', 'value': 'medium'},
      {'label': 'Hard', 'value': 'hard'},
      {'label': 'Expert', 'value': 'expert'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Horizontal scrolling for the chips
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: difficulties.map((diff) {
          final isSelected = _selectedDifficulty == diff['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8), // Space between chips
            child: FilterChip(
              // FilterChip is a selectable chip widget, good for filter/tag selection
              label: Text(diff['label']!), // '!' asserts non-null (we know it's in the map)
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedDifficulty = diff['value']!; // Update filter and rebuild
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2), // Light tint when selected
              checkmarkColor: AppColors.primary, // Color of the checkmark on selected chip
            ),
          );
        }).toList(),
      ),
    );
  }

  // _buildAchievementCard creates the card UI for a single achievement
  Widget _buildAchievementCard(UserAchievement userAchievement) {
    // UserAchievement contains both user progress data and the Achievement definition
    final achievement = userAchievement.achievement; // The Achievement details (name, description, etc.)
    if (achievement == null) return const SizedBox.shrink(); // SizedBox.shrink() = invisible empty widget

    final isUnlocked = userAchievement.isUnlocked; // Has the user earned this achievement?
    final progress = userAchievement.progressPercentage; // 0-100 progress toward unlocking

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isUnlocked ? 4 : 1, // Unlocked cards have more shadow to stand out
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Unlocked achievements get a subtle gradient background; locked ones are plain
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    _getDifficultyColor(achievement.difficultyLevel).withOpacity(0.1), // Tinted start
                    Colors.white, // White end
                  ],
                  begin: Alignment.topLeft,  // Gradient flows from top-left
                  end: Alignment.bottomRight, // to bottom-right
                )
              : null, // No gradient for locked achievements
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align children to the top
            children: [
              // Left side: Badge icon in a square container
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  // Unlocked: colored background; Locked: grey background
                  color: isUnlocked
                      ? _getDifficultyColor(achievement.difficultyLevel).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    // Colored border for unlocked, grey for locked
                    color: isUnlocked
                        ? _getDifficultyColor(achievement.difficultyLevel)
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Stack(
                  // Stack overlays the lock icon on top of the badge icon for locked achievements
                  children: [
                    Center(
                      child: Icon(
                        _getDifficultyIcon(achievement.difficultyLevel),
                        size: 40,
                        // Full color for unlocked, grey for locked
                        color: isUnlocked
                            ? _getDifficultyColor(achievement.difficultyLevel)
                            : Colors.grey,
                      ),
                    ),
                    // Only show the lock overlay if the achievement is locked
                    if (!isUnlocked)
                      Center(
                        child: Icon(
                          Icons.lock, // Lock icon overlaid on the badge
                          size: 24,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16), // Space between badge and details

              // Right side: Achievement details
              Expanded( // Expanded fills remaining horizontal space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Achievement name + XP reward badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              // Bold dark text for unlocked, grey for locked
                              color: isUnlocked ? Colors.black : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        // XP reward badge (pill-shaped container)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Shrink to content
                            children: [
                              Icon(Icons.stars, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${achievement.xpReward} XP', // e.g., "100 XP"
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

                    // Achievement description
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 13,
                        // Slightly grey for unlocked, more grey for locked
                        color: isUnlocked ? Colors.grey.shade700 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Unlock criteria - italic text explaining what the user needs to do
                    Text(
                      achievement.unlockCriteria,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic, // Italic style
                        color: Colors.grey.shade600,
                      ),
                    ),

                    // Progress bar section - only shown for locked achievements
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
                                '${progress.toStringAsFixed(0)}%', // e.g., "45%"
                                // toStringAsFixed(0) formats to 0 decimal places
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
                            // ClipRRect clips the progress bar to have rounded corners
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100, // LinearProgressIndicator expects 0.0 to 1.0
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getDifficultyColor(achievement.difficultyLevel), // Color matches difficulty
                              ),
                              minHeight: 6, // Height of the progress bar
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Unlock date - only shown for achievements the user has earned
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

  // _formatDate converts a DateTime to a simple "day/month/year" string
  // e.g., DateTime(2024, 3, 15) -> "15/3/2024"
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ==============================================================================
  // _buildLeaderboard — Tab 2: Ranked Leaderboard Widget
  // ==============================================================================
  // Returns the full leaderboard list. Each row shows rank, name, level, and XP.
  // Top 3 entries use gold / silver / bronze colours defined as hex Color values.
  // ==============================================================================
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

          // Gold / silver / bronze colours for top 3
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

  // ==============================================================================
  // build — Root Widget Tree for This Screen
  // ==============================================================================
  // The Scaffold has an AppBar with a TabBar attached to its `bottom` property.
  // TabBarView in the body renders one child per tab. Both are bound to the same
  // _tabController so tapping a tab and swiping the body stay in sync.
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        // TabBar at the bottom of AppBar — this is a standard Flutter pattern for
        // tabbed screens. The AppBar's `bottom` property accepts PreferredSizeWidget,
        // and TabBar implements that interface.
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,     // White underline under active tab
          labelColor: Colors.white,         // Active tab label colour
          unselectedLabelColor: Colors.white70, // Inactive tab label colour
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: ACHIEVEMENTS ─────────────────────────────────────────────
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
              // Success state: show stats header, filter chips, and achievements list
              : RefreshIndicator(
                  // RefreshIndicator adds pull-to-refresh functionality
                  onRefresh: _loadAchievements,
                  child: Column(
                    children: [
                      // Stats header - shows overall progress at the top
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary, // Primary color background
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2), // Shadow below
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // "X / Y" unlocked count in large text
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
                                color: Colors.white70, // Slightly transparent white
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Overall progress bar showing proportion unlocked
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                // Avoid division by zero if no achievements loaded yet
                                value: _achievements.isEmpty
                                    ? 0
                                    : _unlockedCount / _achievements.length,
                                backgroundColor: Colors.white.withOpacity(0.3), // Dim white track
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), // White fill
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Horizontally scrolling difficulty filter chips
                      _buildDifficultyFilter(),

                      // Achievements list - takes all remaining screen height
                      Expanded(
                        // Expanded fills the remaining vertical space in the Column
                        child: _filteredAchievements.isEmpty
                            // Empty state when no achievements match the filter
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
                            // Scrollable list of achievement cards
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

          // ── TAB 2: LEADERBOARD ──────────────────────────────────────────────
          _buildLeaderboard(),
        ],
      ),
    );
  }
}
