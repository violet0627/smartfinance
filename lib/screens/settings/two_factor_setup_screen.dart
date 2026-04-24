// ==============================================================================
// two_factor_setup_screen.dart - Two-Factor Authentication Setup Screen
// ==============================================================================
// Guides the user through a 2-step flow to enable 2FA on their account.
//
// Step 1 — Scan QR Code:
//   - Calls /api/auth/2fa/setup → receives a base64-encoded QR code image + plain-text secret
//   - The QR code encodes a TOTP URI that authenticator apps (Google Authenticator,
//     Authy, etc.) can scan to add this account
//   - The secret key is shown as text for manual entry if scanning doesn't work
//   - "Copy" button copies the secret to the clipboard
//
// Step 2 — Verify Code:
//   - User enters the 6-digit code shown in their authenticator app
//   - Calls /api/auth/2fa/verify-setup → if correct, 2FA is enabled on the account
//   - On success, navigates to BackupCodesScreen (shows the one-time backup codes)
//
// dart:convert is imported because the QR code from the API is a base64 string — we
// decode it with base64Decode to get raw bytes, then display it as an Image.memory widget.
// ==============================================================================

import 'package:flutter/material.dart';     // Flutter UI toolkit
import 'package:flutter/services.dart';     // Clipboard for copying the secret key
import 'dart:convert';                       // Provides base64Decode for converting QR code data to image bytes
import '../../services/api_service.dart';   // Backend API calls for 2FA setup
import '../../utils/colors.dart';           // AppColors constants
import 'backup_codes_screen.dart';          // Next screen after successful 2FA verification

// ==============================================================================
// TwoFactorSetupScreen — StatefulWidget
// ==============================================================================
// StatefulWidget because it manages a multi-step flow with several loading states:
//   - _isLoading: true while fetching the QR code from the backend
//   - _isVerifying: true while the verification API call is in progress
//   - _qrCode / _secret: data received from the setup endpoint
//   - _backupCodes: returned by the verify endpoint on success
// ==============================================================================
class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final _codeController = TextEditingController(); // Manages the 6-digit verification code input
  final _formKey = GlobalKey<FormState>(); // Enables validation of the verification code form

  bool _isLoading = true;    // True while loading the QR code from the server
  bool _isVerifying = false; // True while verifying the entered code with the server
  String _qrCode = '';       // Base64-encoded QR code image data from the API
  String _secret = '';       // The raw 2FA secret key (for manual entry in authenticator apps)
  List<dynamic> _backupCodes = []; // Backup codes returned after successful verification
  String _error = '';        // Error message if setup initialization fails; empty = no error
  int _currentStep = 0;      // 0 = Step 1 (QR scan), 1 = Step 2 (verify code)

  @override
  void initState() {
    super.initState();
    _initializeSetup(); // Fetch QR code and secret from the backend when screen opens
  }

  @override
  void dispose() {
    _codeController.dispose(); // Free memory when screen is removed
    super.dispose();
  }

  // _initializeSetup calls the backend to generate a new 2FA secret and QR code
  Future<void> _initializeSetup() async {
    setState(() {
      _isLoading = true;
      _error = ''; // Clear any previous error
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

      // setup2FA generates a new TOTP secret and returns:
      // - qrCode: base64-encoded PNG image of the QR code
      // - secret: the raw secret key text
      // - backupCodes: pre-generated backup codes
      final result = await ApiService.setup2FA(userId);

      if (result['success']) {
        setState(() {
          _qrCode = result['qrCode'];           // Store QR code image data
          _secret = result['secret'];           // Store the secret key
          _backupCodes = result['backupCodes']; // Store backup codes for later
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to initialize 2FA setup';
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

  // _verifyAndEnable sends the user's entered 6-digit code to the backend for verification
  // If correct, 2FA is enabled and we navigate to the backup codes screen
  Future<void> _verifyAndEnable() async {
    if (!_formKey.currentState!.validate()) return; // Check the code field is valid

    setState(() => _isVerifying = true);

    try {
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        setState(() => _isVerifying = false);
        return;
      }

      // .trim() removes any leading/trailing whitespace the user might have accidentally entered
      final result = await ApiService.verify2FASetup(userId, _codeController.text.trim());

      setState(() => _isVerifying = false);

      if (!mounted) return; // Widget might be gone after async gap

      if (result['success']) {
        // 2FA is now enabled - navigate to backup codes screen
        // pushReplacement replaces the current screen (can't go back to setup after success)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BackupCodesScreen(backupCodes: _backupCodes),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Invalid verification code'),
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

  // _copySecret copies the raw secret key to the clipboard for manual entry in authenticator apps
  void _copySecret() {
    Clipboard.setData(ClipboardData(text: _secret));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Secret key copied to clipboard'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Two-Factor Authentication'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Show loading spinner, error view, or the step-by-step setup flow
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildErrorView() // Shows error with a retry button
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Full-width children
                    children: [
                      // Visual progress indicator showing Step 1 and Step 2
                      _buildProgressIndicator(),
                      const SizedBox(height: 32),

                      // Show Step 1 (scan QR) when _currentStep is 0
                      if (_currentStep == 0) ...[
                        _buildStep1(),
                      ],

                      // Show Step 2 (verify code) when _currentStep is 1
                      if (_currentStep == 1) ...[
                        _buildStep2(),
                      ],
                    ],
                  ),
                ),
    );
  }

  // _buildErrorView shows an error message and a retry button
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              _error,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeSetup, // Retry the setup initialization
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // _buildProgressIndicator shows the "1 Scan QR - 2 Verify" step indicator at the top
  Widget _buildProgressIndicator() {
    return Row(
      children: [
        // Step 1 circle
        _buildProgressStep(1, 'Scan QR', _currentStep >= 0), // Step 1 is always active
        // Connecting line between steps - colored when Step 2 is active
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 1 ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        // Step 2 circle - active (colored) only when _currentStep >= 1
        _buildProgressStep(2, 'Verify', _currentStep >= 1),
      ],
    );
  }

  // _buildProgressStep creates one step circle with a number and label
  // step: the number to display (1 or 2)
  // label: text below the circle ("Scan QR" or "Verify")
  // isActive: whether this step is currently active/completed
  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Active step uses primary color; inactive uses grey
            color: isActive ? AppColors.primary : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primary : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // _buildStep1 builds the QR code scanning UI (Step 1)
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Step 1: Scan QR Code',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Use your authenticator app to scan this QR code',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // QR code image and manual secret key entry
        if (_qrCode.isNotEmpty) // Only show if QR code data was loaded
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // QR Code image - decoded from base64 string
                // The QR code is sent as a "data URL": "data:image/png;base64,iVBOR..."
                // .split(',')[1] extracts just the base64 data after the comma
                // base64Decode converts the base64 string to bytes (Uint8List)
                // Image.memory displays an image from raw bytes
                Image.memory(
                  base64Decode(_qrCode.split(',')[1]),
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                const Divider(), // Horizontal line separator
                const SizedBox(height: 16),
                const Text(
                  'Or enter this key manually:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Secret key display with copy button
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _secret, // Display the raw secret key
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace', // Monospace for code-like appearance
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: _copySecret,
                        tooltip: 'Copy',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 32),

        // Blue info box listing recommended authenticator apps
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Recommended Authenticator Apps',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Each app listed as a bullet point
              _buildAppRecommendation('Google Authenticator'),
              _buildAppRecommendation('Microsoft Authenticator'),
              _buildAppRecommendation('Authy'),
              _buildAppRecommendation('1Password'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // "Next" button to advance to Step 2
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _currentStep = 1); // Advance to step 2
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Next: Verify Code',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // _buildAppRecommendation creates a single bullet point for an authenticator app name
  Widget _buildAppRecommendation(String appName) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 4), // Indent to align with header
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            appName,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  // _buildStep2 builds the code verification UI (Step 2)
  Widget _buildStep2() {
    return Form(
      key: _formKey, // Attach form key for validation
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Step 2: Verify Code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code from your authenticator app',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Code entry card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.phone_android, size: 64, color: AppColors.primary),
                const SizedBox(height: 24),
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
                  keyboardType: TextInputType.number, // Numeric keyboard
                  textAlign: TextAlign.center,        // Center the digits
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,           // Wide spacing between digits for readability
                    fontWeight: FontWeight.bold,
                  ),
                  maxLength: 6, // TOTP codes are exactly 6 digits
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the code';
                    }
                    if (value.length != 6) {
                      return 'Code must be 6 digits';
                    }
                    // RegExp(r'^\d+$') matches strings containing only digits (0-9)
                    if (!RegExp(r'^\d+$').hasMatch(value)) {
                      return 'Code must contain only numbers';
                    }
                    return null; // Valid
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Orange info box warning about the 30-second code expiry
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The code refreshes every 30 seconds. Make sure to enter it before it expires.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // "Verify & Enable 2FA" button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyAndEnable, // Disable while verifying
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, // Green for the final action
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
                      'Verify & Enable 2FA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // "Back to QR Code" button to return to Step 1
          TextButton(
            onPressed: () {
              setState(() => _currentStep = 0); // Go back to step 1
            },
            child: const Text('Back to QR Code'),
          ),
        ],
      ),
    );
  }
}
