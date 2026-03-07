// ==============================================================================
// two_factor_verification_dialog.dart - 2FA Code Entry Dialog
// ==============================================================================
// This widget is a modal dialog for Two-Factor Authentication (2FA) verification.
// It appears when the user needs to verify their identity using:
//
// 1. TOTP Code: A 6-digit code from an authenticator app (Google Authenticator,
//    Authy, etc.) that changes every 30 seconds
// 2. Backup Code: A one-time-use recovery code (format: XXXX-XXXX) for when
//    the user doesn't have access to their authenticator app
//
// The dialog allows toggling between TOTP and backup code input modes.
//
// Returns: true if verification succeeds, false if cancelled or failed
//
// Usage: final verified = await show2FAVerificationDialog(context, userId);
// ==============================================================================

import 'package:flutter/material.dart';       // For StatefulWidget, Dialog, TextFormField, etc.
import '../services/api_service.dart';         // For ApiService.verify2FACode() and verify2FABackupCode()
import '../utils/colors.dart';                 // For AppColors (primary, danger)

// ==============================================================================
// TwoFactorVerificationDialog - StatefulWidget for 2FA Input
// ==============================================================================
// StatefulWidget because it manages:
// - Text input controllers (TOTP code and backup code)
// - Loading state (_isVerifying) during API calls
// - Toggle state (_useBackupCode) between TOTP and backup mode
// ==============================================================================
class TwoFactorVerificationDialog extends StatefulWidget {
  final int userId;  // The user's ID, needed for the verification API call

  const TwoFactorVerificationDialog({
    super.key,
    required this.userId,
  });

  // createState() creates the mutable state object for this widget
  @override
  State<TwoFactorVerificationDialog> createState() => _TwoFactorVerificationDialogState();
}

// ==============================================================================
// _TwoFactorVerificationDialogState - Mutable State for the Dialog
// ==============================================================================
// The underscore prefix (_) makes this class private to this file.
// State class holds all mutable data and handles user interactions.
// ==============================================================================
class _TwoFactorVerificationDialogState extends State<TwoFactorVerificationDialog> {
  // TextEditingController manages the text in a TextField
  // One controller for each input mode
  final _codeController = TextEditingController();        // For 6-digit TOTP code
  final _backupCodeController = TextEditingController();  // For backup code

  // GlobalKey<FormState> allows us to validate all form fields at once
  // Used with Form widget to trigger validation before submission
  final _formKey = GlobalKey<FormState>();

  // Whether an API verification call is in progress
  // When true, the verify button shows a loading spinner and is disabled
  bool _isVerifying = false;

  // Whether the user is entering a backup code (true) or TOTP code (false)
  bool _useBackupCode = false;

  // ==============================================================================
  // dispose - Clean Up Resources
  // ==============================================================================
  // Called when the widget is permanently removed from the widget tree.
  // Must dispose TextEditingControllers to prevent memory leaks.
  // Always call super.dispose() at the end.
  // ==============================================================================
  @override
  void dispose() {
    _codeController.dispose();        // Release TOTP controller resources
    _backupCodeController.dispose();  // Release backup code controller resources
    super.dispose();                  // Call parent's dispose
  }

  // ==============================================================================
  // _handleVerify - Submit Code for Verification
  // ==============================================================================
  // Validates the form, then calls the appropriate API endpoint based on
  // whether the user is using a TOTP code or backup code.
  //
  // On success: closes the dialog with result = true
  // On failure: shows an error SnackBar
  // ==============================================================================
  Future<void> _handleVerify() async {
    // Validate the form (checks all TextFormField validators)
    // _formKey.currentState! uses the ! operator to assert it's not null
    // .validate() returns true if all validators pass
    if (!_formKey.currentState!.validate()) return;

    // Show loading state
    // "setState(() => ...)" is shorthand for setState with a single expression
    setState(() => _isVerifying = true);

    try {
      // Variable to hold the API response
      Map<String, dynamic> result;

      if (_useBackupCode) {
        // Call backup code verification endpoint
        // .trim() removes leading/trailing whitespace from the input
        result = await ApiService.verify2FABackupCode(
          widget.userId,                           // Access parent widget's userId
          _backupCodeController.text.trim(),        // The backup code entered
        );
      } else {
        // Call TOTP code verification endpoint
        result = await ApiService.verify2FACode(
          widget.userId,
          _codeController.text.trim(),              // The 6-digit code entered
        );
      }

      // Stop loading spinner
      setState(() => _isVerifying = false);

      // Safety check: ensure widget is still mounted before using context
      // "mounted" is a property of State that's false if the widget was disposed
      if (!mounted) return;

      if (result['success'] && result['verified'] == true) {
        // Verification successful!
        // Navigator.pop closes the dialog and returns 'true' to the caller
        Navigator.pop(context, true);
      } else {
        // Verification failed - show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              // Different error messages for TOTP vs backup code
              _useBackupCode
                  ? 'Invalid or used backup code'
                  : 'Invalid verification code',
            ),
            backgroundColor: AppColors.danger,     // Red background
          ),
        );
      }
    } catch (e) {
      // Handle unexpected errors (network issues, etc.)
      setState(() => _isVerifying = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),              // Show error details
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ==============================================================================
  // build - Render the 2FA Dialog
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    // Dialog widget creates a floating overlay on top of the current screen
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),   // Rounded dialog corners
      ),
      // SingleChildScrollView allows scrolling if content exceeds screen height
      // (important for small screens or when keyboard is visible)
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          // Form widget groups TextFormFields for collective validation
          child: Form(
            key: _formKey,                         // Link form to our GlobalKey
            child: Column(
              mainAxisSize: MainAxisSize.min,       // Dialog shrinks to fit content
              children: [
                // --- Security Icon ---
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),  // Light primary tint
                    shape: BoxShape.circle,                     // Circle shape
                  ),
                  child: const Icon(
                    Icons.security,                // Shield icon
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),

                // --- Title ---
                const Text(
                  'Two-Factor Authentication',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // --- Description (changes based on input mode) ---
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

                // --- Code Input Field ---
                // "if (!_useBackupCode) ...[widgets]" conditionally shows TOTP input
                if (!_useBackupCode) ...[
                  // TOTP Code Input (6-digit number)
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      hintText: '000000',                      // Placeholder text
                      prefixIcon: const Icon(Icons.vpn_key),   // Key icon
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,        // Show numeric keyboard
                    textAlign: TextAlign.center,               // Center the digits
                    style: const TextStyle(
                      fontSize: 24,                            // Large digits
                      letterSpacing: 8,                        // Space between digits
                      fontWeight: FontWeight.bold,
                    ),
                    maxLength: 6,                              // Limit to 6 characters
                    autofocus: true,                           // Auto-focus on dialog open
                    // Validator runs when form.validate() is called
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the code';        // Error if empty
                      }
                      if (value.length != 6) {
                        return 'Code must be 6 digits';        // Error if not 6 chars
                      }
                      // RegExp(r'^\d+$') matches strings containing ONLY digits
                      // r'' is a raw string (backslashes aren't escape characters)
                      // ^ = start, \d = digit, + = one or more, $ = end
                      if (!RegExp(r'^\d+$').hasMatch(value)) {
                        return 'Code must contain only numbers';
                      }
                      return null;  // null = validation passed
                    },
                  ),
                ] else ...[
                  // Backup Code Input (format: XXXX-XXXX)
                  TextFormField(
                    controller: _backupCodeController,
                    decoration: InputDecoration(
                      labelText: 'Backup Code',
                      hintText: 'XXXX-XXXX',
                      prefixIcon: const Icon(Icons.key),       // Key icon
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      letterSpacing: 2,                        // Slight letter spacing
                      fontWeight: FontWeight.bold,
                    ),
                    autofocus: true,
                    // TextCapitalization.characters auto-uppercases all input
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

                // --- Verify Button ---
                SizedBox(
                  width: double.infinity,                      // Full width button
                  height: 48,
                  child: ElevatedButton(
                    // Disable button when verifying (onPressed: null disables it)
                    onPressed: _isVerifying ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Show spinner when loading, text when idle
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

                // --- Toggle TOTP / Backup Code Button ---
                TextButton(
                  onPressed: () {
                    setState(() {
                      _useBackupCode = !_useBackupCode;   // Toggle the mode
                      _codeController.clear();             // Clear both fields
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

                // --- Cancel Button ---
                TextButton(
                  // Pop the dialog and return false (verification cancelled)
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

// ==============================================================================
// show2FAVerificationDialog - Helper Function to Show the Dialog
// ==============================================================================
// Convenience function that handles showing the dialog and returning the result.
//
// showDialog<bool> returns a Future<bool?> - the value passed to Navigator.pop
// ?? false converts null (dialog dismissed by tapping outside) to false
//
// "async" + "await" simplifies working with Futures:
// - await pauses until showDialog completes
// - The function returns the result
//
// Usage: final verified = await show2FAVerificationDialog(context, userId);
//        if (verified) { /* proceed */ }
// ==============================================================================
Future<bool> show2FAVerificationDialog(BuildContext context, int userId) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,                    // Cannot dismiss by tapping outside
    builder: (context) => TwoFactorVerificationDialog(userId: userId),
  );
  return result ?? false;  // Convert null to false
}
