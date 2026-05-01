// Import Flutter's core UI package — gives us Scaffold, AppBar, Container, ListView, etc.
import 'package:flutter/material.dart';

// Import intl package — provides DateFormat for formatting DateTime values (e.g., "Mar 7, 14:30")
import 'package:intl/intl.dart';

// Import our custom API service — handles all HTTP calls to the Flask backend
import '../../services/api_service.dart';

// Import our color constants — AppColors.primary, .success, .danger, .warning, .textPrimary, .info
import '../../utils/colors.dart';

// Import the email verification screen — can navigate here to verify email
import '../auth/verify_email_screen.dart';

// Import the 2FA setup screen — navigates here when enabling Two-Factor Authentication
import 'two_factor_setup_screen.dart';

// Import the login screen — navigated to after successful account deletion
import '../auth/login_screen.dart';


// SecuritySettingsScreen — shows the full security dashboard for the user's account
// Includes: security score, email verification, 2FA toggle, active sessions, security log, danger zone
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

// The State class — holds all data and logic for SecuritySettingsScreen
class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  // _isLoading — true while the initial data fetch is in progress
  bool _isLoading = true;

  // _emailVerified — whether the user has verified their email address
  // Affects the security score and email verification card appearance
  bool _emailVerified = false;

  // _twoFactorEnabled — whether 2FA (Two-Factor Authentication) is currently active
  // Affects the security score and the 2FA toggle switch
  bool _twoFactorEnabled = false;

  // _userEmail — the user's email address, shown in the email verification card
  String _userEmail = '';

  // _activeSessions — list of all devices/sessions where the user is currently logged in
  // Each session has info like DeviceName, IpAddress, LastActiveAt, etc.
  List<Map<String, dynamic>> _activeSessions = [];

  // _securityLog — list of recent security events (login attempts, password changes, etc.)
  // Each log entry has EventType, EventDescription, IpAddress, Success, CreatedAt, etc.
  List<Map<String, dynamic>> _securityLog = [];

  // initState() — called once when widget is first inserted into the widget tree
  @override
  void initState() {
    super.initState(); // Required: call parent's initState
    _loadSecurityData(); // Load all security data immediately on screen open
  }

  // _loadSecurityData — fetches all security-related data from the backend API in parallel
  Future<void> _loadSecurityData() async {
    // Show loading spinner
    setState(() => _isLoading = true);

    try {
      final userId = await ApiService.getCurrentUserId();

      // If not logged in, just hide spinner and return (can't load without user ID)
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Future.wait — runs all 5 API calls SIMULTANEOUSLY to minimize loading time
      // Without Future.wait, these would execute one after another (5x slower)
      final results = await Future.wait([
        ApiService.getUserProfile(userId),                          // results[0]: name, email
        ApiService.checkVerificationStatus(userId),                  // results[1]: email verified?
        ApiService.get2FAStatus(userId),                             // results[2]: 2FA enabled?
        ApiService.getActiveSessions(userId),                        // results[3]: list of sessions
        ApiService.getSecurityActivityLog(userId, limit: 10),       // results[4]: last 10 security events
      ]);

      setState(() {
        // Extract email from profile data
        if (results[0]['success']) {
          _userEmail = results[0]['profile']['email'] ?? '';
        }

        // Extract email verification status
        if (results[1]['success']) {
          // ?? false — default to false if the key doesn't exist
          _emailVerified = results[1]['emailVerified'] ?? false;
        }

        // Extract 2FA status
        if (results[2]['success']) {
          _twoFactorEnabled = results[2]['twoFactorEnabled'] ?? false;
        }

        // Extract active sessions list
        if (results[3]['success']) {
          // List<Map<String, dynamic>>.from() — creates a typed list from the raw dynamic list
          // ?? [] — use empty list if 'sessions' key is null
          _activeSessions = List<Map<String, dynamic>>.from(results[3]['sessions'] ?? []);
        } else {
          _activeSessions = []; // If API failed, show no sessions
        }

        // Extract security activity log
        if (results[4]['success']) {
          _securityLog = List<Map<String, dynamic>>.from(results[4]['logs'] ?? []);
        } else {
          _securityLog = []; // If API failed, show no logs
        }

        _isLoading = false; // Hide loading spinner
      });
    } catch (e) {
      // If any exception occurs, hide spinner and show error snackbar
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading security data: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // _revokeSession — revokes (logs out) a single specific session by its ID
  // Called when user taps the logout icon next to a session in the sessions list
  Future<void> _revokeSession(int sessionId) async {
    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    // Send revoke request to the backend — this invalidates that session's token
    final result = await ApiService.revokeSession(sessionId, userId);

    if (!mounted) return; // Widget may have been removed during the async call

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session revoked'),
          backgroundColor: AppColors.success, // Green
        ),
      );
      _loadSecurityData(); // Reload to remove the revoked session from the UI
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to revoke session'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // _revokeAllSessions — logs the user out of all OTHER devices simultaneously
  // Shows a confirmation dialog first to prevent accidental mass logout
  Future<void> _revokeAllSessions() async {
    // Show confirmation dialog — returns true if user confirms, false/null if cancelled
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke All Sessions'),
        content: const Text('This will log you out of all other devices. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Return false = cancel
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Return true = confirmed
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger, // Red button for destructive action
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke All'),
          ),
        ],
      ),
    );

    // != true handles both false and null (dialog dismissed without a choice)
    if (confirmed != true) return;

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    // Pass null as the second argument — the API will revoke all sessions except the current one
    final result = await ApiService.revokeAllSessions(userId, null);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Show how many sessions were revoked (e.g., "3 sessions revoked")
          content: Text('${result['revokedCount']} sessions revoked'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadSecurityData(); // Reload sessions list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to revoke sessions'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // _deleteAccount — shows a detailed confirmation dialog then permanently deletes the account
  // This is an irreversible action — all user data is deleted from the database
  Future<void> _deleteAccount() async {
    // Controller for the password field inside the delete confirmation dialog
    final passwordController = TextEditingController();

    // Show the full deletion warning dialog
    // barrierDismissible: false — user MUST explicitly press Cancel or Delete (can't tap outside)
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        // Alert title with a warning icon
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.danger), // Red warning icon
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Don't take more space than needed
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bold red warning text
            const Text(
              'This action is PERMANENT and cannot be undone!',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
            ),
            const SizedBox(height: 12),

            // List of what will be deleted
            const Text('All your data will be deleted:'),
            const SizedBox(height: 8),
            const Text('• Transactions and budgets'),
            const Text('• Investments and goals'),
            const Text('• Achievements and progress'),
            const Text('• All personal information'),
            const SizedBox(height: 16),

            // Password confirmation field
            const Text('Enter your password to confirm:'),
            const SizedBox(height: 8),

            // TextField (not TextFormField) — used when we don't need form validation
            TextField(
              controller: passwordController,
              obscureText: true, // Hide password characters
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(), // Square border style
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          // Cancel — return false (don't delete)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),

          // Delete button — validates password is not empty before proceeding
          ElevatedButton(
            onPressed: () {
              // Guard: don't allow deletion with an empty password
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your password'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return; // Don't close dialog yet
              }
              Navigator.pop(context, true); // Return true = user confirmed with password
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete My Account'),
          ),
        ],
      ),
    );

    // If user cancelled OR somehow got through without a password, stop here
    if (confirmed != true || passwordController.text.isEmpty) return;

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    // Send the delete account request with the password for server-side verification
    final result = await ApiService.deleteAccount(userId, passwordController.text);

    if (!mounted) return;

    if (result['success']) {
      // Capture navigator before the async gap — after await, mounted may be false
      // but the navigator reference remains valid and usable
      final navigator = Navigator.of(context);

      // Clear all saved session data (tokens, userId)
      await ApiService.logout();

      // Navigate to login and remove ALL routes from the stack so user can't go back
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to delete account'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // _handleChangePassword — shows a 3-field dialog to change the account password
  // Validates all fields including password strength requirements
  Future<void> _handleChangePassword() async {
    // TextEditingControllers — one per field (current, new, confirm)
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // GlobalKey<FormState> — allows us to call validate() on all form fields at once
    final formKey = GlobalKey<FormState>();

    // showDialog returns whatever value was passed to Navigator.pop()
    // <bool> means we expect to get a boolean back (true = password changed, false = cancelled)
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey, // Attach the form key here
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current password — just checks it's not empty
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter current password';
                  }
                  return null; // Valid
                },
              ),
              const SizedBox(height: 16),

              // New password — enforces security requirements
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter new password';
                  }
                  if (value == currentPasswordController.text) {
                    return 'New password must be different from current password';
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
                },
              ),
              const SizedBox(height: 16),

              // Confirm password — must match new password exactly
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
        actions: [
          // Cancel — return false = user cancelled
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),

          // Change button — validate form then call API
          ElevatedButton(
            onPressed: () async {
              // formKey.currentState!.validate() — runs all validators
              // Returns false if any validator returned an error string
              if (!formKey.currentState!.validate()) return;

              final userId = await ApiService.getCurrentUserId();
              if (userId == null) return;

              // Call the API to change the password
              final result = await ApiService.changePassword(
                userId,
                currentPasswordController.text, // Old password for verification
                newPasswordController.text,      // New password to store
              );

              // context.mounted — check if the dialog's context is still valid
              // (the dialog context could be unmounted if user navigated away)
              if (!context.mounted) return;

              // Close the dialog, passing the success boolean back
              Navigator.pop(context, result['success']);

              // Show result snackbar using the dialog's context (still valid here)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['success']
                        ? 'Password changed successfully'
                        : result['error'] ?? 'Failed to change password',
                  ),
                  backgroundColor: result['success'] ? AppColors.success : AppColors.danger,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    // If password was successfully changed (dialog returned true), reload security data
    if (result == true) {
      _loadSecurityData();
    }
  }

  // _handleToggle2FA — either enables or disables 2FA depending on current state
  Future<void> _handleToggle2FA() async {
    if (_twoFactorEnabled) {
      // ── DISABLE 2FA ─────────────────────────────────────────────────────
      // Ask for password confirmation before disabling 2FA (security measure)
      final passwordController = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable Two-Factor Authentication'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to disable two-factor authentication? '
                'This will make your account less secure.',
              ),
              const SizedBox(height: 16),
              // Password field to verify the user's identity
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
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
              child: const Text('Disable'),
            ),
          ],
        ),
      );

      // Only proceed if user confirmed AND entered a password
      if (confirmed == true && passwordController.text.isNotEmpty) {
        final userId = await ApiService.getCurrentUserId();
        if (userId == null) return;

        // Call API to disable 2FA (server verifies password and removes TOTP secret)
        final result = await ApiService.disable2FA(userId, passwordController.text);

        if (!mounted) return;

        if (result['success']) {
          // Update local state immediately so the switch shows OFF
          setState(() => _twoFactorEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Two-factor authentication disabled'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadSecurityData(); // Reload to update security score
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to disable 2FA'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } else {
      // ── ENABLE 2FA ──────────────────────────────────────────────────────
      // Navigate to the TwoFactorSetupScreen (shows QR code + verification)
      // await Navigator.push — waits until user returns from the setup screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TwoFactorSetupScreen(),
        ),
      );

      // result == true means setup was completed successfully
      // mounted check ensures we don't update state after widget was removed
      // Must use && (AND): only reload when BOTH conditions are true
      // Using || (OR) would call _loadSecurityData() even when widget is unmounted — crash
      if (result == true && mounted) {
        _loadSecurityData(); // Reload to reflect that 2FA is now enabled
      }
    }
  }

  // build() — called by Flutter to draw the UI; rebuilds whenever setState() is called
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── APP BAR ──────────────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // ── BODY ─────────────────────────────────────────────────────────────
      // Ternary: show spinner while loading, otherwise show the security content
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())

          // RefreshIndicator — pull-down to reload all security data
          : RefreshIndicator(
              onRefresh: _loadSecurityData,
              child: ListView(
                padding: const EdgeInsets.all(16), // 16px padding on all sides
                children: [
                  // ── SECURITY OVERVIEW CARD ───────────────────────────────
                  // Shows the security score (30/60/100) and checklist of email+2FA status
                  _buildSecurityOverviewCard(),
                  const SizedBox(height: 24),

                  // ── EMAIL VERIFICATION SECTION ───────────────────────────
                  _buildSectionHeader('Email Verification'),
                  // Card showing verification status with a "Verify Email Now" button if unverified
                  _buildEmailVerificationCard(),
                  const SizedBox(height: 24),

                  // ── TWO-FACTOR AUTHENTICATION SECTION ───────────────────
                  _buildSectionHeader('Two-Factor Authentication'),
                  // Card with toggle switch to enable/disable 2FA
                  _build2FACard(),
                  const SizedBox(height: 24),

                  // ── PASSWORD SECTION ─────────────────────────────────────
                  _buildSectionHeader('Password'),
                  // Card with "Change Password" button
                  _buildPasswordCard(),
                  const SizedBox(height: 24),

                  // ── ACTIVE SESSIONS SECTION ──────────────────────────────
                  _buildSectionHeader('Active Sessions'),
                  // Card listing all active devices with "Revoke" buttons
                  _buildActiveSessionsCard(),
                  const SizedBox(height: 24),

                  // ── SECURITY ACTIVITY LOG ────────────────────────────────
                  _buildSectionHeader('Security Activity'),
                  // Card showing recent security events (logins, password changes, etc.)
                  _buildSecurityLogCard(),
                  const SizedBox(height: 24),

                  // ── DANGER ZONE ──────────────────────────────────────────
                  _buildSectionHeader('Danger Zone'),
                  // Red-bordered card with "Delete My Account" button
                  _buildDangerZoneCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // _buildSectionHeader — bold section label shown above each group of content
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Space below the header
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary, // Dark text color for section headers
        ),
      ),
    );
  }

  // _buildSecurityOverviewCard — shows a security score and status checklist
  Widget _buildSecurityOverviewCard() {
    // Calculate security score based on what security features are enabled:
    // Both email verified AND 2FA enabled = 100% (maximum security)
    // Only email verified = 60% (medium security)
    // Neither = 30% (low security)
    final securityScore = _emailVerified && _twoFactorEnabled ? 100
        : _emailVerified ? 60
        : 30;

    // Pick a color for the score badge and progress bar:
    // >= 80% = green (good), >= 50% = orange (warning), < 50% = red (poor)
    final scoreColor = securityScore >= 80 ? AppColors.success
        : securityScore >= 50 ? Colors.orange
        : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Very light shadow
            blurRadius: 10,
            offset: const Offset(0, 4),            // Shadow goes 4 pixels down
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── SCORE ROW ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Security Score',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),

              // Circular score badge showing the percentage
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1), // Light colored background
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor), // Colored border
                ),
                child: Text(
                  '$securityScore%', // String interpolation: e.g., "100%"
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── PROGRESS BAR ──────────────────────────────────────────────────
          LinearProgressIndicator(
            value: securityScore / 100, // Convert 0-100 to 0.0-1.0
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),

          // ── EMAIL STATUS ROW ──────────────────────────────────────────────
          Row(
            children: [
              // Green check or red X icon depending on verification status
              Icon(
                _emailVerified ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: _emailVerified ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 8),
              Text(
                _emailVerified ? 'Email Verified' : 'Email Not Verified',
                style: TextStyle(
                  color: _emailVerified ? AppColors.success : AppColors.danger,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── 2FA STATUS ROW ────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                _twoFactorEnabled ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: _twoFactorEnabled ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 8),
              Text(
                _twoFactorEnabled ? '2FA Enabled' : '2FA Disabled',
                style: TextStyle(
                  color: _twoFactorEnabled ? AppColors.success : AppColors.danger,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // _buildEmailVerificationCard — shows email verification status with action button
  Widget _buildEmailVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        // Border color changes: green if verified, orange if not
        border: Border.all(
          color: _emailVerified
              ? AppColors.success.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + title + email address row
          Row(
            children: [
              // Shield icon: green checkmark if verified, orange warning if not
              Icon(
                _emailVerified ? Icons.verified_user : Icons.warning_amber,
                color: _emailVerified ? AppColors.success : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),

              // Expanded column: status title and email address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _emailVerified ? 'Email Verified' : 'Email Not Verified',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Show the user's actual email address below the status
                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Only show the "Verify Email Now" button if email is NOT verified
          // The spread operator (...) expands the list conditionally
          if (!_emailVerified) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, // Button spans full width
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to the email verification screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerifyEmailScreen(email: _userEmail),
                    ),
                  // .then() — runs when user returns from verification screen
                  // Reloads data to check if email is now verified
                  ).then((_) => _loadSecurityData());
                },
                icon: const Icon(Icons.verified_user, size: 18),
                label: const Text('Verify Email Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Orange = action needed
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // _build2FACard — shows the Two-Factor Authentication status card with toggle switch
  Widget _build2FACard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Border: green if enabled, grey if disabled
        border: Border.all(
          color: _twoFactorEnabled
              ? AppColors.success.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + title + description + toggle switch
          Row(
            children: [
              // Shield icon: green if enabled, grey if disabled
              Icon(
                Icons.security,
                color: _twoFactorEnabled ? AppColors.success : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 12),

              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Two-Factor Authentication',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _twoFactorEnabled
                          ? 'Extra layer of security is active'
                          : 'Add an extra layer of security',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Toggle switch — calls _handleToggle2FA when tapped
              // The "_" in "(_)" means we don't use the bool value passed to onChanged
              // (we use the current _twoFactorEnabled state instead)
              Switch(
                value: _twoFactorEnabled,
                onChanged: (_) => _handleToggle2FA(),
                activeColor: AppColors.success, // Green when ON
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info box explaining what 2FA does
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,     // Light blue background
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '2FA adds an extra code requirement when logging in',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // _buildPasswordCard — shows a "Change Password" button card
  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // No border — simpler appearance for password section
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: lock icon + title + description
          Row(
            children: [
              Icon(
                Icons.lock,
                color: AppColors.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update your account password regularly',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // "Change Password" button — outlined style (border, no fill)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleChangePassword, // Opens the change password dialog
              icon: const Icon(Icons.lock_reset, size: 18),
              label: const Text('Change Password'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary), // Blue border
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // _buildActiveSessionsCard — shows all active login sessions with revoke options
  Widget _buildActiveSessionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Your Devices" on left, "3 active" count on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Devices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                // String interpolation: "3 active" (shows session count)
                '${_activeSessions.length} active',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Only show "Revoke All" button if there are more than 1 session
          // (1 session = current device only, nothing else to revoke)
          if (_activeSessions.length > 1)
            OutlinedButton.icon(
              onPressed: _revokeAllSessions, // Shows confirmation dialog
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Revoke All Other Sessions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger), // Red border
              ),
            ),
          const SizedBox(height: 16),

          // Show empty state or the list of session tiles
          if (_activeSessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No active sessions found',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            // Spread operator (...) — expands the list of tiles into Column children
            // .map() transforms each session data map into a _buildSessionTile widget
            ..._activeSessions.map((session) => _buildSessionTile(session)).toList(),
        ],
      ),
    );
  }

  // _buildSessionTile — builds one row in the active sessions list
  // Shows device name, IP address, last active time, and a revoke button
  Widget _buildSessionTile(Map<String, dynamic> session) {
    // Check if the session is active — API can return true (bool) or 1 (int)
    final isActive = session['IsActive'] == true || session['IsActive'] == 1;

    // Extract session data with fallback defaults using ?? operator
    final deviceName = session['DeviceName'] ?? 'Unknown Device';
    final deviceType = session['DeviceType'] ?? 'mobile'; // desktop, tablet, or mobile
    final ipAddress = session['IpAddress'] ?? 'Unknown IP';

    // LastActiveAt is preferred; fall back to LoginAt if not available
    final lastActive = session['LastActiveAt'] ?? session['LoginAt'];

    // Parse the timestamp string to DateTime for formatting
    DateTime? lastActiveDate;
    try {
      if (lastActive != null) {
        // If it's already a DateTime, use it; otherwise parse the string
        lastActiveDate = lastActive is DateTime ? lastActive : DateTime.parse(lastActive);
      }
    } catch (e) {
      // If parsing fails, lastActiveDate stays null (won't be displayed)
    }

    // Choose an icon based on the device type
    IconData deviceIcon;
    switch (deviceType.toLowerCase()) {
      case 'desktop':
        deviceIcon = Icons.computer;    // Desktop monitor icon
        break;
      case 'tablet':
        deviceIcon = Icons.tablet;      // Tablet icon
        break;
      default:
        deviceIcon = Icons.phone_android; // Default: smartphone icon
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Space between session tiles
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Slightly different shade for active vs inactive sessions
        color: isActive ? Colors.grey.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          // Device type icon — blue if active, grey if inactive
          Icon(
            deviceIcon,
            color: isActive ? AppColors.primary : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),

          // Device info column — name, IP, last active time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Device name (e.g., "iPhone 14" or "Chrome on Windows")
                Text(
                  deviceName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),

                // IP address (e.g., "192.168.1.1")
                Text(
                  ipAddress,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                // Last active time — only shown if we have a valid timestamp
                if (lastActiveDate != null)
                  Text(
                    // DateFormat('MMM d, HH:mm') → "Mar 7, 14:30"
                    // MMM = abbreviated month, d = day, HH = 24h hour, mm = minutes
                    'Last active: ${DateFormat('MMM d, HH:mm').format(lastActiveDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),

          // Revoke button — only shown if SessionId is available
          // Some sessions might not have an ID if data is incomplete
          if (session['SessionId'] != null)
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              // Pass the SessionId to _revokeSession to identify which session to revoke
              onPressed: () => _revokeSession(session['SessionId']),
              color: AppColors.danger, // Red logout icon
              tooltip: 'Revoke Session', // Shown when user long-presses the button
            ),
        ],
      ),
    );
  }

  // _buildSecurityLogCard — shows the last 10 security events
  Widget _buildSecurityLogCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Show empty state or log entries
          if (_securityLog.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No security activity yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            // Build a tile for each log entry
            ..._securityLog.map((log) => _buildLogTile(log)).toList(),
        ],
      ),
    );
  }

  // _buildLogTile — builds one row in the security activity log
  // Shows an event-type icon, description, device/IP, and timestamp
  Widget _buildLogTile(Map<String, dynamic> log) {
    // Extract fields from the log data with fallback defaults
    final eventType = log['EventType'] ?? 'unknown';

    // Prefer EventDescription; fall back to EventType; fall back to "Unknown event"
    final description = log['EventDescription'] ?? log['EventType'] ?? 'Unknown event';
    final ipAddress = log['IpAddress'] ?? 'Unknown IP';
    final deviceInfo = log['DeviceInfo'] ?? 'Unknown Device';

    // Check if the event was successful — API can return true (bool) or 1 (int)
    final success = log['Success'] == true || log['Success'] == 1;
    final createdAt = log['CreatedAt'];

    // Parse the created timestamp for formatting
    DateTime? timestamp;
    try {
      if (createdAt != null) {
        timestamp = createdAt is DateTime ? createdAt : DateTime.parse(createdAt);
      }
    } catch (e) {
      // If parsing fails, timestamp stays null
    }

    // Determine which icon and color to use based on the event type
    IconData icon;
    Color iconColor;

    // switch — checks eventType against known event names
    switch (eventType.toLowerCase()) {
      case 'login':
        // Successful login = green login icon; failed login = red block icon
        icon = success ? Icons.login : Icons.block;
        iconColor = success ? AppColors.success : AppColors.danger;
        break;
      case 'logout':
        icon = Icons.logout;
        iconColor = Colors.blue; // Blue for informational events
        break;
      case 'password_change':
        icon = Icons.lock_reset;
        iconColor = Colors.orange; // Orange for changes
        break;
      case '2fa_enable':
      case '2fa_disable':
        // Both 2FA enable and disable use the same icon
        icon = Icons.security;
        iconColor = Colors.purple;
        break;
      case 'session_revoke':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'account_delete':
        icon = Icons.delete_forever;
        iconColor = AppColors.danger;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey; // Grey for unknown events
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // Very light grey background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Circular colored icon box on the left
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1), // Very light colored background
              shape: BoxShape.circle,             // Perfect circle
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Event details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description + success/failure icon on the same row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Small check or error icon on the right
                    Icon(
                      success ? Icons.check_circle : Icons.error,
                      size: 14,
                      color: success ? AppColors.success : AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Device info and IP on the same line, separated by bullet point
                Text(
                  '$deviceInfo • $ipAddress',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                // Formatted timestamp — only shown if we have a valid DateTime
                if (timestamp != null)
                  Text(
                    // DateFormat('MMM d, yyyy at HH:mm') → "Mar 7, 2024 at 14:30"
                    DateFormat('MMM d, yyyy at HH:mm').format(timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // _buildDangerZoneCard — the red-bordered "Delete Account" section at the bottom
  // This is placed last and styled in red to warn the user about the destructive action
  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Very light red background to indicate danger
        color: AppColors.danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        // 2px red border for extra visual emphasis
        border: Border.all(color: AppColors.danger.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: warning icon + "Delete Account" text in red
          Row(
            children: const [
              Icon(Icons.warning, color: AppColors.danger, size: 24),
              SizedBox(width: 8),
              Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger, // Red text
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Warning description
          Text(
            'Permanently delete your account and all associated data. This action cannot be undone.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),

          // "Delete My Account" button — outlined red style
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteAccount, // Uses the detailed _deleteAccount flow with inline password
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Delete My Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger), // Red border
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
