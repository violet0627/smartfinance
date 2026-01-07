import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../auth/login_screen.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _settings;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

      final results = await Future.wait([
        ApiService.getUserSettings(userId),
        ApiService.getUserProfile(userId),
      ]);

      setState(() {
        if (results[0]['success']) {
          _settings = results[0]['settings'];
        }
        if (results[1]['success']) {
          _profile = results[1]['profile'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    final result = await ApiService.updateUserSettings(userId, {key: value});

    if (result['success']) {
      setState(() {
        _settings![key] = value;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to update settings'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    children: [
                      // Profile Section
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, size: 40, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile?['fullName'] ?? 'User',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _profile?['email'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileEditScreen(),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notifications Section
                      _buildSectionHeader('Notifications'),
                      _buildSwitchTile(
                        icon: Icons.notifications,
                        title: 'Enable Notifications',
                        subtitle: 'Receive push notifications',
                        value: _settings?['enableNotifications'] ?? true,
                        onChanged: (value) => _updateSetting('enableNotifications', value),
                      ),
                      _buildSwitchTile(
                        icon: Icons.account_balance_wallet,
                        title: 'Budget Alerts',
                        subtitle: 'Get notified about budget status',
                        value: _settings?['enableBudgetAlerts'] ?? true,
                        onChanged: (value) => _updateSetting('enableBudgetAlerts', value),
                      ),
                      _buildSwitchTile(
                        icon: Icons.emoji_events,
                        title: 'Achievement Alerts',
                        subtitle: 'Get notified when you unlock achievements',
                        value: _settings?['enableAchievementAlerts'] ?? true,
                        onChanged: (value) => _updateSetting('enableAchievementAlerts', value),
                      ),
                      _buildSwitchTile(
                        icon: Icons.local_fire_department,
                        title: 'Streak Alerts',
                        subtitle: 'Get notified about streak milestones',
                        value: _settings?['enableStreakAlerts'] ?? true,
                        onChanged: (value) => _updateSetting('enableStreakAlerts', value),
                      ),

                      const Divider(height: 32),

                      // Display Section
                      _buildSectionHeader('Display'),
                      _buildSettingTile(
                        icon: Icons.attach_money,
                        title: 'Currency',
                        subtitle: _settings?['currency'] ?? 'RM',
                        onTap: () => _showCurrencyPicker(),
                      ),
                      _buildSettingTile(
                        icon: Icons.dark_mode,
                        title: 'Theme',
                        subtitle: _getThemeLabel(_settings?['themeMode'] ?? 'system'),
                        onTap: () => _showThemePicker(),
                      ),
                      _buildSettingTile(
                        icon: Icons.language,
                        title: 'Language',
                        subtitle: _getLanguageLabel(_settings?['language'] ?? 'en'),
                        onTap: () => _showLanguagePicker(),
                      ),

                      const Divider(height: 32),

                      // Privacy Section
                      _buildSectionHeader('Privacy'),
                      _buildSwitchTile(
                        icon: Icons.leaderboard,
                        title: 'Show in Leaderboard',
                        subtitle: 'Display your rank in global leaderboard',
                        value: _settings?['showInLeaderboard'] ?? true,
                        onChanged: (value) => _updateSetting('showInLeaderboard', value),
                      ),

                      const Divider(height: 32),

                      // Security Section
                      _buildSectionHeader('Security'),
                      _buildSettingTile(
                        icon: Icons.lock,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: () => _showChangePasswordDialog(),
                      ),

                      const Divider(height: 32),

                      // About Section
                      _buildSectionHeader('About'),
                      _buildSettingTile(
                        icon: Icons.info,
                        title: 'Version',
                        subtitle: '1.0.0',
                        trailing: const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 32),

                      // Logout Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  String _getThemeLabel(String themeMode) {
    switch (themeMode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
      default:
        return 'System Default';
    }
  }

  String _getLanguageLabel(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ms':
        return 'Bahasa Melayu';
      case 'zh':
        return '中文 (Chinese)';
      case 'ta':
        return 'தமிழ் (Tamil)';
      default:
        return 'English';
    }
  }

  Future<void> _showCurrencyPicker() async {
    final result = await ApiService.getAvailableCurrencies();
    if (!result['success']) return;

    final currencies = result['currencies'] as List;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((currency) {
              return RadioListTile<String>(
                title: Text(currency['name']),
                subtitle: Text(currency['symbol']),
                value: currency['code'],
                groupValue: _settings?['currency'] ?? 'RM',
                onChanged: (value) {
                  Navigator.pop(context);
                  if (value != null) {
                    _updateSetting('currency', value);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _showThemePicker() async {
    final themes = [
      {'label': 'Light', 'value': 'light'},
      {'label': 'Dark', 'value': 'dark'},
      {'label': 'System Default', 'value': 'system'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.map((theme) {
            return RadioListTile<String>(
              title: Text(theme['label']!),
              value: theme['value']!,
              groupValue: _settings?['themeMode'] ?? 'system',
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  _updateSetting('themeMode', value);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    final result = await ApiService.getAvailableLanguages();
    if (!result['success']) return;

    final languages = result['languages'] as List;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang['name']),
              value: lang['code'],
              groupValue: _settings?['language'] ?? 'en',
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  _updateSetting('language', value);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }

              final userId = await ApiService.getCurrentUserId();
              if (userId == null) return;

              final result = await ApiService.changePassword(
                userId,
                currentPasswordController.text,
                newPasswordController.text,
              );

              Navigator.pop(context);

              if (!this.mounted) return;
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(result['success'] ? 'Password changed successfully' : result['error']),
                  backgroundColor: result['success'] ? AppColors.success : AppColors.danger,
                ),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
