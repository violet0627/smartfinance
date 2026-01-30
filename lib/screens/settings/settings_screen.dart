import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../auth/verify_email_screen.dart';
import 'profile_edit_screen.dart';
import 'security_settings_screen.dart';

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
  bool _emailVerified = false;

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
        ApiService.checkVerificationStatus(userId),
      ]);

      setState(() {
        if (results[0]['success']) {
          _settings = results[0]['settings'];
        }
        if (results[1]['success']) {
          _profile = results[1]['profile'];
        }
        if (results[2]['success']) {
          _emailVerified = results[2]['emailVerified'] ?? false;
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
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return _buildSettingTile(
                            icon: Icons.dark_mode,
                            title: 'Theme',
                            subtitle: _getThemeLabelFromMode(themeProvider.themeMode),
                            onTap: () => _showThemePicker(themeProvider),
                          );
                        },
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
                        icon: Icons.security,
                        title: 'Security Settings',
                        subtitle: 'Manage your account security',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SecuritySettingsScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                      ),
                      _buildSettingTile(
                        icon: Icons.verified_user,
                        title: 'Email Verification',
                        subtitle: _emailVerified
                            ? 'Your email is verified'
                            : 'Email not verified - Click to verify',
                        trailing: _emailVerified
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.success),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verify',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        onTap: _emailVerified
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VerifyEmailScreen(
                                      email: _profile?['email'],
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                      ),
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

  String _getThemeLabelFromMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
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

  Future<void> _showThemePicker(ThemeProvider themeProvider) async {
    // Ensure app is in light mode
    if (themeProvider.themeMode != ThemeMode.light) {
      themeProvider.setThemeMode(ThemeMode.light);
    }

    // Show info dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: const Text(
          'The app is currently set to Light mode only. '
          'Dark mode has been temporarily disabled due to visibility issues '
          'and will be improved in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    String? validatePassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Password is required';
      }
      if (value.length < 8) {
        return 'Password must be at least 8 characters';
      }
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'Must contain at least one uppercase letter';
      }
      if (!value.contains(RegExp(r'[a-z]'))) {
        return 'Must contain at least one lowercase letter';
      }
      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        return 'Must contain at least one symbol';
      }
      return null;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock),
                      helperText: 'Min 8 chars, uppercase, lowercase, symbol',
                      helperMaxLines: 2,
                    ),
                    obscureText: true,
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;

                setDialogState(() => isLoading = true);

                final userId = await ApiService.getCurrentUserId();
                if (userId == null) {
                  setDialogState(() => isLoading = false);
                  return;
                }

                final result = await ApiService.changePassword(
                  userId,
                  currentPasswordController.text,
                  newPasswordController.text,
                );

                setDialogState(() => isLoading = false);

                Navigator.pop(dialogContext);

                if (!this.mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(result['success'] ? 'Password changed successfully' : (result['error'] ?? 'Failed to change password')),
                    backgroundColor: result['success'] ? AppColors.success : AppColors.danger,
                  ),
                );
              },
              child: isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }
}
