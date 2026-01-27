import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../auth/verify_email_screen.dart';
import 'two_factor_setup_screen.dart';
import 'backup_codes_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isLoading = true;
  bool _emailVerified = false;
  bool _twoFactorEnabled = false;
  String _userEmail = '';
  List<Map<String, dynamic>> _activeSessions = [];
  List<Map<String, dynamic>> _securityLog = [];

  @override
  void initState() {
    super.initState();
    _loadSecurityData();
  }

  Future<void> _loadSecurityData() async {
    setState(() => _isLoading = true);

    try {
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        ApiService.getUserProfile(userId),
        ApiService.checkVerificationStatus(userId),
        ApiService.get2FAStatus(userId),
        ApiService.getActiveSessions(userId),
        ApiService.getSecurityActivityLog(userId, limit: 10),
      ]);

      setState(() {
        if (results[0]['success']) {
          _userEmail = results[0]['profile']['email'] ?? '';
        }
        if (results[1]['success']) {
          _emailVerified = results[1]['emailVerified'] ?? false;
        }
        if (results[2]['success']) {
          _twoFactorEnabled = results[2]['twoFactorEnabled'] ?? false;
        }
        if (results[3]['success']) {
          _activeSessions = List<Map<String, dynamic>>.from(results[3]['sessions'] ?? []);
        } else {
          _activeSessions = [];
        }
        if (results[4]['success']) {
          _securityLog = List<Map<String, dynamic>>.from(results[4]['logs'] ?? []);
        } else {
          _securityLog = [];
        }

        _isLoading = false;
      });
    } catch (e) {
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

  Future<void> _revokeSession(int sessionId) async {
    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    final result = await ApiService.revokeSession(sessionId, userId);

    if (!mounted) return;
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session revoked'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadSecurityData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to revoke session'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _revokeAllSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke All Sessions'),
        content: const Text('This will log you out of all other devices. Continue?'),
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
            child: const Text('Revoke All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    final result = await ApiService.revokeAllSessions(userId, null);

    if (!mounted) return;
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['revokedCount']} sessions revoked'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadSecurityData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to revoke sessions'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is PERMANENT and cannot be undone!',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
            ),
            const SizedBox(height: 12),
            const Text('All your data will be deleted:'),
            const SizedBox(height: 8),
            const Text('• Transactions and budgets'),
            const Text('• Investments and goals'),
            const Text('• Achievements and progress'),
            const Text('• All personal information'),
            const SizedBox(height: 16),
            const Text('Enter your password to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your password'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
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

    if (confirmed != true || passwordController.text.isEmpty) return;

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    final result = await ApiService.deleteAccount(userId, passwordController.text);

    if (!mounted) return;
    if (result['success']) {
      // Navigate to login screen after account deletion
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: AppColors.success,
        ),
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

  Future<void> _handleChangePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
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
                    return 'Please enter current password';
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
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter new password';
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final userId = await ApiService.getCurrentUserId();
              if (userId == null) return;

              final result = await ApiService.changePassword(
                userId,
                currentPasswordController.text,
                newPasswordController.text,
              );

              if (!context.mounted) return;
              Navigator.pop(context, result['success']);

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

    if (result == true) {
      _loadSecurityData();
    }
  }

  Future<void> _handleToggle2FA() async {
    if (_twoFactorEnabled) {
      // Disable 2FA - Requires password confirmation
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

      if (confirmed == true && passwordController.text.isNotEmpty) {
        // Call API to disable 2FA
        final userId = await ApiService.getCurrentUserId();
        if (userId == null) return;

        final result = await ApiService.disable2FA(userId, passwordController.text);

        if (!mounted) return;

        if (result['success']) {
          setState(() => _twoFactorEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Two-factor authentication disabled'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadSecurityData(); // Reload to update UI
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
      // Enable 2FA - Navigate to setup screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TwoFactorSetupScreen(),
        ),
      );

      // Reload security data after returning from setup
      if (result == true || !mounted) {
        _loadSecurityData();
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? '
          'This action cannot be undone and all your data will be permanently deleted.',
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
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show password confirmation dialog
      final passwordController = TextEditingController();
      final passwordConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your password to confirm account deletion:'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
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
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (passwordConfirmed == true) {
        // TODO: API call to delete account
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deletion will be available in next update'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSecurityData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Security Overview Card
                  _buildSecurityOverviewCard(),
                  const SizedBox(height: 24),

                  // Email Verification Section
                  _buildSectionHeader('Email Verification'),
                  _buildEmailVerificationCard(),
                  const SizedBox(height: 24),

                  // Two-Factor Authentication Section
                  _buildSectionHeader('Two-Factor Authentication'),
                  _build2FACard(),
                  const SizedBox(height: 24),

                  // Password Section
                  _buildSectionHeader('Password'),
                  _buildPasswordCard(),
                  const SizedBox(height: 24),

                  // Active Sessions Section
                  _buildSectionHeader('Active Sessions'),
                  _buildActiveSessionsCard(),
                  const SizedBox(height: 24),

                  // Security Activity Log
                  _buildSectionHeader('Security Activity'),
                  _buildSecurityLogCard(),
                  const SizedBox(height: 24),

                  // Danger Zone
                  _buildSectionHeader('Danger Zone'),
                  _buildDangerZoneCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSecurityOverviewCard() {
    final securityScore = _emailVerified && _twoFactorEnabled ? 100 : _emailVerified ? 60 : 30;
    final scoreColor = securityScore >= 80 ? AppColors.success : securityScore >= 50 ? Colors.orange : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Security Score',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor),
                ),
                child: Text(
                  '$securityScore%',
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
          LinearProgressIndicator(
            value: securityScore / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
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

  Widget _buildEmailVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _emailVerified ? AppColors.success.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _emailVerified ? Icons.verified_user : Icons.warning_amber,
                color: _emailVerified ? AppColors.success : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),
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
          if (!_emailVerified) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerifyEmailScreen(email: _userEmail),
                    ),
                  ).then((_) => _loadSecurityData());
                },
                icon: const Icon(Icons.verified_user, size: 18),
                label: const Text('Verify Email Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
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

  Widget _build2FACard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _twoFactorEnabled ? AppColors.success.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: _twoFactorEnabled ? AppColors.success : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 12),
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
              Switch(
                value: _twoFactorEnabled,
                onChanged: (_) => _handleToggle2FA(),
                activeColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
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

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleChangePassword,
              icon: const Icon(Icons.lock_reset, size: 18),
              label: const Text('Change Password'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
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
                '${_activeSessions.length} active',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_activeSessions.length > 1)
            OutlinedButton.icon(
              onPressed: _revokeAllSessions,
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Revoke All Other Sessions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          const SizedBox(height: 16),
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
            ..._activeSessions.map((session) => _buildSessionTile(session)).toList(),
        ],
      ),
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> session) {
    final isActive = session['IsActive'] == true || session['IsActive'] == 1;
    final deviceName = session['DeviceName'] ?? 'Unknown Device';
    final deviceType = session['DeviceType'] ?? 'mobile';
    final ipAddress = session['IpAddress'] ?? 'Unknown IP';
    final lastActive = session['LastActiveAt'] ?? session['LoginAt'];

    DateTime? lastActiveDate;
    try {
      if (lastActive != null) {
        lastActiveDate = lastActive is DateTime ? lastActive : DateTime.parse(lastActive);
      }
    } catch (e) {
      // Handle parse error
    }

    IconData deviceIcon;
    switch (deviceType.toLowerCase()) {
      case 'desktop':
        deviceIcon = Icons.computer;
        break;
      case 'tablet':
        deviceIcon = Icons.tablet;
        break;
      default:
        deviceIcon = Icons.phone_android;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.grey.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            deviceIcon,
            color: isActive ? AppColors.primary : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ipAddress,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (lastActiveDate != null)
                  Text(
                    'Last active: ${DateFormat('MMM d, HH:mm').format(lastActiveDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          if (session['SessionId'] != null)
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: () => _revokeSession(session['SessionId']),
              color: AppColors.danger,
              tooltip: 'Revoke Session',
            ),
        ],
      ),
    );
  }

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
            ..._securityLog.map((log) => _buildLogTile(log)).toList(),
        ],
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log) {
    final eventType = log['EventType'] ?? 'unknown';
    final description = log['EventDescription'] ?? log['EventType'] ?? 'Unknown event';
    final ipAddress = log['IpAddress'] ?? 'Unknown IP';
    final deviceInfo = log['DeviceInfo'] ?? 'Unknown Device';
    final success = log['Success'] == true || log['Success'] == 1;
    final createdAt = log['CreatedAt'];

    DateTime? timestamp;
    try {
      if (createdAt != null) {
        timestamp = createdAt is DateTime ? createdAt : DateTime.parse(createdAt);
      }
    } catch (e) {
      // Handle parse error
    }

    IconData icon;
    Color iconColor;

    switch (eventType.toLowerCase()) {
      case 'login':
        icon = success ? Icons.login : Icons.block;
        iconColor = success ? AppColors.success : AppColors.danger;
        break;
      case 'logout':
        icon = Icons.logout;
        iconColor = Colors.blue;
        break;
      case 'password_change':
        icon = Icons.lock_reset;
        iconColor = Colors.orange;
        break;
      case '2fa_enable':
      case '2fa_disable':
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
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    Icon(
                      success ? Icons.check_circle : Icons.error,
                      size: 14,
                      color: success ? AppColors.success : AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$deviceInfo • $ipAddress',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (timestamp != null)
                  Text(
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

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning, color: AppColors.danger, size: 24),
              SizedBox(width: 8),
              Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Permanently delete your account and all associated data. This action cannot be undone.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Delete My Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
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
