import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';

class TwoFactorVerificationDialog extends StatefulWidget {
  final int userId;

  const TwoFactorVerificationDialog({
    super.key,
    required this.userId,
  });

  @override
  State<TwoFactorVerificationDialog> createState() => _TwoFactorVerificationDialogState();
}

class _TwoFactorVerificationDialogState extends State<TwoFactorVerificationDialog> {
  final _codeController = TextEditingController();
  final _backupCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isVerifying = false;
  bool _useBackupCode = false;

  @override
  void dispose() {
    _codeController.dispose();
    _backupCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);

    try {
      Map<String, dynamic> result;

      if (_useBackupCode) {
        // Verify backup code
        result = await ApiService.verify2FABackupCode(
          widget.userId,
          _backupCodeController.text.trim(),
        );
      } else {
        // Verify TOTP code
        result = await ApiService.verify2FACode(
          widget.userId,
          _codeController.text.trim(),
        );
      }

      setState(() => _isVerifying = false);

      if (!mounted) return;

      if (result['success'] && result['verified'] == true) {
        // Verification successful
        Navigator.pop(context, true);
      } else {
        // Verification failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _useBackupCode
                  ? 'Invalid or used backup code'
                  : 'Invalid verification code',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Two-Factor Authentication',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  _useBackupCode
                      ? 'Enter one of your backup codes'
                      : 'Enter the 6-digit code from your authenticator app',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Code Input
                if (!_useBackupCode) ...[
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      hintText: '000000',
                      prefixIcon: const Icon(Icons.vpn_key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLength: 6,
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the code';
                      }
                      if (value.length != 6) {
                        return 'Code must be 6 digits';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(value)) {
                        return 'Code must contain only numbers';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _backupCodeController,
                    decoration: InputDecoration(
                      labelText: 'Backup Code',
                      hintText: 'XXXX-XXXX',
                      prefixIcon: const Icon(Icons.key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter backup code';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Verify',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Toggle to Backup Code
                TextButton(
                  onPressed: () {
                    setState(() {
                      _useBackupCode = !_useBackupCode;
                      _codeController.clear();
                      _backupCodeController.clear();
                    });
                  },
                  child: Text(
                    _useBackupCode
                        ? 'Use authenticator code instead'
                        : 'Use backup code instead',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),

                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to show the 2FA verification dialog
Future<bool> show2FAVerificationDialog(BuildContext context, int userId) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => TwoFactorVerificationDialog(userId: userId),
  );
  return result ?? false;
}
