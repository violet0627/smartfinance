// Import Flutter's core UI package — gives us Scaffold, AppBar, ListTile, Switch, etc.
import 'package:flutter/material.dart';

// Import provider package — used to access ThemeProvider (the app-wide theme state)
// Provider is a state management approach: widgets can "consume" shared state without passing it down manually
import 'package:provider/provider.dart';

// Import shared_preferences — persistent key-value storage on the device (used indirectly via ApiService)
import 'package:shared_preferences/shared_preferences.dart';

// Import our custom API service — handles all HTTP calls to the backend
import '../../services/api_service.dart';

// Import our color constants — AppColors.primary, .success, .danger, .warning
import '../../utils/colors.dart';

// Import our theme provider — manages light/dark/system theme switching
import '../../providers/theme_provider.dart';

// Import the login screen — needed for navigation after logout
import '../auth/login_screen.dart';

// Import email verification screen — so user can go verify their email from settings
import '../auth/verify_email_screen.dart';

// Import the profile edit screen — for the edit button in the profile header
import 'profile_edit_screen.dart';

// Import the security settings screen — a sub-screen accessible from this screen
import 'security_settings_screen.dart';

// SettingsScreen is a StatefulWidget — it has data that changes (settings loaded from API, loading state)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// The State class — holds all the data and logic for SettingsScreen
class _SettingsScreenState extends State<SettingsScreen> {
  // _settings — stores the user's settings from the API (notification prefs, currency, language, etc.)
  // Nullable (?) — null until data is loaded
  Map<String, dynamic>? _settings;

  // _profile — stores the user's profile (name, email) for the profile header
  Map<String, dynamic>? _profile;

  // _isLoading — true while API calls are in progress
  bool _isLoading = true;

  // _error — error message if loading fails; empty string means no error
  String _error = '';

  // _emailVerified — whether the user's email has been verified
  // Used to show a "Verified" badge or a "Verify" button on the email tile
  bool _emailVerified = false;

  // initState() — called once when this widget is first created
  @override
  void initState() {
    super.initState(); // Required: call parent initState first
    _loadData();       // Load settings + profile data from API immediately
  }

  // _loadData — fetches settings, profile, and email verification status in parallel
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // Show loading spinner
      _error = '';       // Clear any previous error
    });

    try {
      // Get the logged-in user's ID
      final userId = await ApiService.getCurrentUserId();

      if (userId == null) {
        // User not logged in — show error
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Future.wait — run all 3 API calls simultaneously (parallel, not sequential)
      // results is a List with 3 items in the same order as the futures
      final results = await Future.wait([
        ApiService.getUserSettings(userId),           // results[0]: notification prefs, currency, etc.
        ApiService.getUserProfile(userId),            // results[1]: name, email
        ApiService.checkVerificationStatus(userId),  // results[2]: is email verified?
      ]);

      // Update state with all 3 results at once
      setState(() {
        if (results[0]['success']) {
          _settings = results[0]['settings']; // Extract the 'settings' map from API response
        }
        if (results[1]['success']) {
          _profile = results[1]['profile'];   // Extract the 'profile' map from API response
        }
        if (results[2]['success']) {
          // The ?? false means: use the value if not null, otherwise default to false
          _emailVerified = results[2]['emailVerified'] ?? false;
        }
        _isLoading = false; // Hide loading spinner
      });
    } catch (e) {
      // If any exception occurred (network error, JSON error, etc.), show error message
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // _updateSetting — sends a single setting change to the API and updates local state
  // key: the setting name (e.g., 'enableNotifications')
  // value: the new value (could be bool, String, or any type)
  Future<void> _updateSetting(String key, dynamic value) async {
    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    // Send just the changed setting as a map — API merges it into existing settings
    final result = await ApiService.updateUserSettings(userId, {key: value});

    if (result['success']) {
      // Optimistically update local state so the UI reflects the change immediately
      setState(() {
        _settings![key] = value; // Update the in-memory settings map
      });

      if (!mounted) return; // Widget might be gone if user navigated away
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings updated successfully'),
          backgroundColor: AppColors.success, // Green
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // ?? — fallback message if 'error' key is null in the response
          content: Text(result['error'] ?? 'Failed to update settings'),
          backgroundColor: AppColors.danger, // Red
        ),
      );
    }
  }

  // _handleLogout — shows a confirmation dialog then logs the user out
  Future<void> _handleLogout() async {
    // showDialog returns the value passed to Navigator.pop()
    // <bool> means we expect the dialog to return a boolean
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          // Cancel button — returns false (don't logout)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),

          // Logout button — returns true (do logout)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger, // Red button for destructive action
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    // Only proceed if user confirmed by tapping the Logout button
    // confirmed == true (not just 'confirmed' because it could be null if dismissed)
    if (confirmed == true) {
      await ApiService.logout(); // Clear stored token + user data from SharedPreferences

      if (!mounted) return;

      // Navigate to LoginScreen and remove ALL routes from the stack
      // pushAndRemoveUntil removes everything behind so pressing "back" doesn't return to settings
      // (route) => false — never keep any old routes (remove all of them)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // Remove ALL routes
      );
    }
  }

  // _buildSettingTile — reusable widget for a settings row with icon, title, subtitle, and optional tap
  // Named parameters with "required" keyword mean they must be provided when calling this method
  Widget _buildSettingTile({
    required IconData icon,     // The icon to show on the left
    required String title,       // The main label text
    String? subtitle,            // Optional secondary text below the title
    Widget? trailing,            // Optional widget on the right (defaults to chevron arrow)
    VoidCallback? onTap,         // Optional function called when the tile is tapped
  }) {
    return ListTile(
      // Leading widget — the colored icon box on the left
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1), // Light blue background
          borderRadius: BorderRadius.circular(8),    // Rounded corners
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),

      // Title — the main setting name
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),

      // Subtitle — optional description, only shown if subtitle parameter is not null
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
          : null,

      // Trailing — right side widget; defaults to a right-pointing arrow chevron
      // ?? — if trailing is null, use the default chevron icon
      trailing: trailing ?? const Icon(Icons.chevron_right),

      onTap: onTap, // The tap handler (null means tile is non-interactive)
    );
  }

  // _buildSwitchTile — reusable widget for a settings row with a toggle switch on the right
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,               // Current on/off state of the switch
    required Function(bool) onChanged, // Called when user toggles the switch; receives new bool value
  }) {
    return ListTile(
      // Same icon box as _buildSettingTile
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

      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
          : null,

      // Switch widget — the toggle button on the right
      trailing: Switch(
        value: value,           // Current state: true = on, false = off
        onChanged: onChanged,  // Callback when user flips the switch
        activeColor: AppColors.primary, // Color when switch is ON
      ),
    );
  }

  // build() — called by Flutter to draw the UI; called again whenever setState() is called
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── APP BAR ──────────────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary, // Blue app bar
        foregroundColor: Colors.white,       // White title and icons
        elevation: 0,                        // No shadow
      ),

      // ── BODY ─────────────────────────────────────────────────────────────
      // Ternary chain to handle three states: loading, error, or loaded
      body: _isLoading
          // State 1: Loading — show centered spinner
          ? const Center(child: CircularProgressIndicator())

          // State 2: Error — show error icon, message, and retry button
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
                        onPressed: _loadData, // Retry button re-runs the data loading
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )

              // State 3: Data loaded — show the settings list with pull-to-refresh
              : RefreshIndicator(
                  onRefresh: _loadData, // Pull down to reload settings from API
                  child: ListView(
                    children: [
                      // ── PROFILE HEADER ───────────────────────────────────
                      // Blue banner at top showing user's avatar, name, email, and edit button
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary, // Solid blue background
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1), // Slight shadow below
                              blurRadius: 4,
                              offset: const Offset(0, 2), // Shadow goes 2 pixels down
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Circular avatar with person icon (no photo — just initials placeholder)
                            CircleAvatar(
                              radius: 35,                    // Circle diameter = 70 pixels
                              backgroundColor: Colors.white, // White circle
                              child: Icon(Icons.person, size: 40, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),

                            // Expanded — user name and email take all remaining horizontal space
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User's full name
                                  // _profile?['fullName'] — if _profile is null, returns null; ?? 'User' provides fallback
                                  Text(
                                    _profile?['fullName'] ?? 'User',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // User's email address
                                  Text(
                                    _profile?['email'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70, // Slightly transparent white
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Edit (pencil) icon button — navigates to ProfileEditScreen
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () {
                                // Navigate to the profile edit screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileEditScreen(),
                                  ),
                                // .then() — runs after coming back from the edit screen
                                // Refreshes settings data in case the name/email changed
                                ).then((_) => _loadData());
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── NOTIFICATIONS SECTION ─────────────────────────────
                      _buildSectionHeader('Notifications'),

                      // Master notification toggle — enables/disables ALL notifications
                      _buildSwitchTile(
                        icon: Icons.notifications,
                        title: 'Enable Notifications',
                        subtitle: 'Receive push notifications',
                        // ?? true — if _settings is null or key is missing, default to true
                        value: _settings?['enableNotifications'] ?? true,
                        onChanged: (value) => _updateSetting('enableNotifications', value),
                      ),

                      // Budget alerts — notify when close to or over budget
                      _buildSwitchTile(
                        icon: Icons.account_balance_wallet,
                        title: 'Budget Alerts',
                        subtitle: 'Get notified about budget status',
                        value: _settings?['enableBudgetAlerts'] ?? true,
                        onChanged: (value) => _updateSetting('enableBudgetAlerts', value),
                      ),

                      // Achievement alerts — notify when unlocking a new achievement
                      _buildSwitchTile(
                        icon: Icons.emoji_events,
                        title: 'Achievement Alerts',
                        subtitle: 'Get notified when you unlock achievements',
                        value: _settings?['enableAchievementAlerts'] ?? true,
                        onChanged: (value) => _updateSetting('enableAchievementAlerts', value),
                      ),

                      // Streak alerts — notify about daily streak milestones
                      _buildSwitchTile(
                        icon: Icons.local_fire_department,
                        title: 'Streak Alerts',
                        subtitle: 'Get notified about streak milestones',
                        value: _settings?['enableStreakAlerts'] ?? true,
                        onChanged: (value) => _updateSetting('enableStreakAlerts', value),
                      ),

                      // Divider — horizontal line separating sections
                      const Divider(height: 32),

                      // ── DISPLAY SECTION ───────────────────────────────────
                      _buildSectionHeader('Display'),

                      // Currency setting — shows current currency, opens picker on tap
                      _buildSettingTile(
                        icon: Icons.attach_money,
                        title: 'Currency',
                        subtitle: _settings?['currency'] ?? 'RM', // Show current currency code
                        onTap: () => _showCurrencyPicker(),        // Open currency selection dialog
                      ),

                      // Theme setting — wrapped in Consumer to access ThemeProvider
                      // Consumer<ThemeProvider> — rebuilds this tile whenever ThemeProvider changes
                      // This is necessary because theme state lives in ThemeProvider, not in _settings
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          // themeProvider is the current ThemeProvider instance
                          return _buildSettingTile(
                            icon: Icons.dark_mode,
                            title: 'Theme',
                            // Convert the ThemeMode enum to a display string (e.g., "Light")
                            subtitle: _getThemeLabelFromMode(themeProvider.themeMode),
                            onTap: () => _showThemePicker(themeProvider),
                          );
                        },
                      ),

                      // Language setting — shows current language, opens picker on tap
                      _buildSettingTile(
                        icon: Icons.language,
                        title: 'Language',
                        // _getLanguageLabel converts code 'en' to full name 'English'
                        subtitle: _getLanguageLabel(_settings?['language'] ?? 'en'),
                        onTap: () => _showLanguagePicker(),
                      ),

                      const Divider(height: 32),

                      // ── PRIVACY SECTION ───────────────────────────────────
                      _buildSectionHeader('Privacy'),

                      // Leaderboard visibility — whether username appears in global rankings
                      _buildSwitchTile(
                        icon: Icons.leaderboard,
                        title: 'Show in Leaderboard',
                        subtitle: 'Display your rank in global leaderboard',
                        value: _settings?['showInLeaderboard'] ?? true,
                        onChanged: (value) => _updateSetting('showInLeaderboard', value),
                      ),

                      const Divider(height: 32),

                      // ── SECURITY SECTION ──────────────────────────────────
                      _buildSectionHeader('Security'),

                      // Navigate to full SecuritySettingsScreen for advanced security options
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
                          ).then((_) => _loadData()); // Reload when returning (e.g., 2FA might have changed)
                        },
                      ),

                      // Email verification status tile — different appearance for verified vs unverified
                      _buildSettingTile(
                        icon: Icons.verified_user,
                        title: 'Email Verification',
                        // Ternary: show different subtitle based on verification status
                        subtitle: _emailVerified
                            ? 'Your email is verified'
                            : 'Email not verified - Click to verify',

                        // Custom trailing widget — badge showing "Verified" or "Verify"
                        trailing: _emailVerified
                            // "Verified" green badge for verified users
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1), // Light green background
                                  borderRadius: BorderRadius.circular(20),   // Pill shape
                                  border: Border.all(color: AppColors.success), // Green border
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min, // Row only as wide as content
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
                            // "Verify" orange badge for unverified users
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

                        // onTap: null if already verified (makes tile non-interactive)
                        // Otherwise: navigate to email verification screen
                        onTap: _emailVerified
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VerifyEmailScreen(
                                      email: _profile?['email'], // Pass email for the verification UI
                                    ),
                                  ),
                                ).then((_) => _loadData()); // Reload after verifying
                              },
                      ),

                      // Change password tile — opens a dialog with current+new password fields
                      _buildSettingTile(
                        icon: Icons.lock,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: () => _showChangePasswordDialog(),
                      ),

                      const Divider(height: 32),

                      // ── ABOUT SECTION ─────────────────────────────────────
                      _buildSectionHeader('About'),

                      // App version display — no tap handler, no chevron (non-interactive)
                      _buildSettingTile(
                        icon: Icons.info,
                        title: 'Version',
                        subtitle: '1.0.0',
                        // SizedBox.shrink() — invisible zero-size widget
                        // Used to replace the default chevron icon (nothing on the right)
                        trailing: const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 32),

                      // ── LOGOUT BUTTON ─────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity, // Button spans full width
                          child: ElevatedButton.icon(
                            onPressed: _handleLogout,           // Shows confirmation dialog
                            icon: const Icon(Icons.logout),     // Logout icon
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger, // Red button
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16), // Taller button
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

  // _buildSectionHeader — a section label shown above each group of settings
  // E.g., "Notifications", "Display", "Security", "About"
  Widget _buildSectionHeader(String title) {
    return Padding(
      // fromLTRB — sets left=16, top=8, right=16, bottom=8 individually
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary, // Blue section header
        ),
      ),
    );
  }

  // _getThemeLabel — converts a theme mode string to a display label
  // Note: this method is defined but _getThemeLabelFromMode (using ThemeMode enum) is actually used
  String _getThemeLabel(String themeMode) {
    // switch statement — cleaner than multiple if/else when checking one variable against many values
    switch (themeMode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
      default: // "default" matches if no other case matched
        return 'System Default';
    }
  }

  // _getThemeLabelFromMode — converts a ThemeMode enum value to a display label
  // ThemeMode is Flutter's built-in enum: ThemeMode.light, ThemeMode.dark, ThemeMode.system
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

  // _getLanguageLabel — converts a language code to a full display name
  String _getLanguageLabel(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ms':
        return 'Bahasa Melayu'; // Malay language
      case 'zh':
        return '中文 (Chinese)'; // Chinese characters + English label
      case 'ta':
        return 'தமிழ் (Tamil)'; // Tamil script + English label
      default:
        return 'English'; // Default if code is unrecognized
    }
  }

  // _showCurrencyPicker — fetches available currencies from API and shows a radio-button dialog
  Future<void> _showCurrencyPicker() async {
    // Fetch the list of available currencies (e.g., [{"code": "MYR", "name": "Malaysian Ringgit", "symbol": "RM"}, ...])
    final result = await ApiService.getAvailableCurrencies();
    if (!result['success']) return; // If the API call failed, do nothing

    final currencies = result['currencies'] as List;

    if (!mounted) return; // Widget might have been unmounted during the await

    // Show a dialog with a scrollable list of currency options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SingleChildScrollView(
          // Map each currency to a RadioListTile for single-selection behavior
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((currency) {
              // RadioListTile — a ListTile with a radio button
              // Only one radio can be selected at a time within the same groupValue
              return RadioListTile<String>(
                title: Text(currency['name']),    // e.g., "Malaysian Ringgit"
                subtitle: Text(currency['symbol']), // e.g., "RM"
                value: currency['code'],            // The value this radio represents (e.g., "MYR")
                groupValue: _settings?['currency'] ?? 'RM', // Currently selected value
                onChanged: (value) {
                  Navigator.pop(context); // Close the dialog
                  if (value != null) {
                    _updateSetting('currency', value); // Save the new currency to API
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // _showThemePicker — currently forces light mode and shows an info message
  // Dark mode has been temporarily disabled due to visibility issues
  Future<void> _showThemePicker(ThemeProvider themeProvider) async {
    // If not already in light mode, force it back to light
    if (themeProvider.themeMode != ThemeMode.light) {
      themeProvider.setThemeMode(ThemeMode.light);
    }

    // Show an informational dialog explaining that dark mode is disabled
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

  // _showLanguagePicker — fetches available languages from API and shows a radio-button dialog
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
              title: Text(lang['name']),  // e.g., "English" or "Bahasa Melayu"
              value: lang['code'],        // The value this radio represents (e.g., "en" or "ms")
              groupValue: _settings?['language'] ?? 'en', // Currently selected language
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  _updateSetting('language', value); // Save the new language code to API
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // _showChangePasswordDialog — shows a form dialog for changing the account password
  Future<void> _showChangePasswordDialog() async {
    // GlobalKey<FormState> — a key that lets us call validate() on the Form widget
    // Think of it as a "handle" to the form that we can use from outside
    final formKey = GlobalKey<FormState>();

    // TextEditingControllers — manage the text content in each password field
    // Must be created here (not as state variables) since this is a dialog-local concern
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // isLoading — tracks whether the API call is in progress
    // This is a local variable (not setState), so we use StatefulBuilder below to update it
    bool isLoading = false;

    // validatePassword — a reusable validator function for the new password field
    // Returns an error message string if invalid, or null if valid
    String? validatePassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Password is required';
      }
      if (value.length < 8) {
        return 'Password must be at least 8 characters';
      }
      // RegExp (Regular Expression) — a pattern to match specific characters
      // r'[A-Z]' — any uppercase letter A through Z
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'Must contain at least one uppercase letter';
      }
      // r'[a-z]' — any lowercase letter a through z
      if (!value.contains(RegExp(r'[a-z]'))) {
        return 'Must contain at least one lowercase letter';
      }
      // r'[!@#$%^&*(),.?":{}|<>]' — any of these special symbol characters
      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        return 'Must contain at least one symbol';
      }
      return null; // null means the password is valid
    }

    showDialog(
      context: context,
      // StatefulBuilder — allows the dialog to have its own local setState
      // Without this, we couldn't update isLoading inside the dialog
      // "dialogContext" is the BuildContext of the dialog (different from screen's context)
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey, // Attach the form key so we can call formKey.currentState!.validate()
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current password field — just checks it's not empty
                  TextFormField(
                    controller: currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true, // Hide password characters with bullets
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null; // Valid
                    },
                  ),
                  const SizedBox(height: 16),

                  // New password field — uses the validatePassword function with all rules
                  TextFormField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock),
                      helperText: 'Min 8 chars, uppercase, lowercase, symbol',
                      helperMaxLines: 2, // Allow helper text to wrap to 2 lines
                    ),
                    obscureText: true,
                    validator: validatePassword, // Use our reusable validator
                  ),
                  const SizedBox(height: 16),

                  // Confirm password field — checks it matches the new password
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      // value != newPasswordController.text — compare against what's in the new password field
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null; // Valid
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // Cancel button — disabled if loading (can't cancel mid-request)
            TextButton(
              // isLoading ? null : callback — null disables the button
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),

            // Change button — triggers validation and API call
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                // Validate all form fields — returns false if any validator returned an error string
                if (!formKey.currentState!.validate()) return;

                // Show loading spinner inside the button
                setDialogState(() => isLoading = true);

                final userId = await ApiService.getCurrentUserId();
                if (userId == null) {
                  setDialogState(() => isLoading = false);
                  return;
                }

                // Send the password change request to the backend
                final result = await ApiService.changePassword(
                  userId,
                  currentPasswordController.text, // Old password for verification
                  newPasswordController.text,      // New password to set
                );

                // Hide loading spinner
                setDialogState(() => isLoading = false);

                // Close the dialog (dialogContext refers to the dialog's context)
                Navigator.pop(dialogContext);

                // "this.mounted" and "this.context" — explicitly use the outer widget's mounted/context
                // (not the dialog's context, which is now gone after Navigator.pop)
                if (!this.mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    // Ternary inside ternary: success → "Password changed successfully", failure → error message
                    content: Text(result['success']
                        ? 'Password changed successfully'
                        : (result['error'] ?? 'Failed to change password')),
                    backgroundColor: result['success'] ? AppColors.success : AppColors.danger,
                  ),
                );
              },

              // While loading: show a small circular spinner inside the button
              // Otherwise: show "Change" text
              child: isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2), // Thin spinner
                  )
                : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }
}
