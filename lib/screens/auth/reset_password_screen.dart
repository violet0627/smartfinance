// ==============================================================================
// reset_password_screen.dart - Password Reset Screen (Set New Password)
// ==============================================================================
// This screen allows users to reset their password using a token received
// via email from the forgot password flow.
//
// Flow:
// 1. User enters (or auto-fills) the reset token from their email
// 2. Token is verified with the API → shows the associated email if valid
// 3. User enters a new password and confirmation
// 4. Password validation: 8+ chars, uppercase, lowercase, symbol
// 5. API resets the password using the token
// 6. Success dialog → navigates to LoginScreen
//
// Features:
// - Token verification (shows email associated with the token)
// - Password visibility toggles
// - Password requirements info box
// - Loading states for API calls
//
// Usage: ResetPasswordScreen(token: 'optional-pre-filled-token')
// ==============================================================================

import 'package:flutter/material.dart';           // For StatefulWidget, Form, etc.
import '../../services/api_service.dart';           // For ApiService.verifyResetToken(), resetPassword()
import '../../utils/colors.dart';                   // For AppColors (primary, success, danger)
import 'login_screen.dart';                         // For LoginScreen (navigation after reset)

// ==============================================================================
// ResetPasswordScreen - StatefulWidget for Setting New Password
// ==============================================================================
// StatefulWidget because it manages:
// - Three text controllers (token, password, confirm password)
// - Loading state, visibility toggles
// - Token email (fetched from API after token verification)
// ==============================================================================
class ResetPasswordScreen extends StatefulWidget {
  final String? token;  // Optional pre-filled reset token

  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();              // Form validation
  final _tokenController = TextEditingController();     // Reset token input
  final _passwordController = TextEditingController();  // New password input
  final _confirmPasswordController = TextEditingController(); // Confirm password input

  bool _isLoading = false;                // API reset call in progress
  bool _obscurePassword = true;           // Hide new password text
  bool _obscureConfirmPassword = true;    // Hide confirm password text
  String? _tokenEmail;                    // Email associated with the token (from API)

  // ==============================================================================
  // initState - Auto-fill and Verify Token if Provided
  // ==============================================================================
  @override
  void initState() {
    super.initState();
    // If a token was passed in (from ForgotPasswordScreen), auto-fill and verify it
    if (widget.token != null) {
      _tokenController.text = widget.token!;
      _verifyToken();  // Immediately verify to show associated email
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ==============================================================================
  // _verifyToken - Check if Reset Token is Valid
  // ==============================================================================
  // Calls the API to verify the reset token.
  // If valid, stores the associated email to show on screen.
  // If invalid/expired, shows an error SnackBar.
  // ==============================================================================
  Future<void> _verifyToken() async {
    final result = await ApiService.verifyResetToken(_tokenController.text.trim());

    if (result['success']) {
      setState(() {
        _tokenEmail = result['email'];         // Store the email for display
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Invalid or expired token'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ==============================================================================
  // _handleResetPassword - Submit New Password
  // ==============================================================================
  // Validates the form, checks password match, calls the API to reset,
  // and shows success dialog on completion.
  // ==============================================================================
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Extra check: ensure passwords match
    // (Also checked in confirm password validator, but double-checking here)
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Call API to reset the password
    final result = await ApiService.resetPassword(
      _tokenController.text.trim(),            // The reset token
      _passwordController.text,                // The new password
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // --- Password reset succeeded ---
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 64, color: AppColors.success),
              const SizedBox(height: 16),
              const Text(
                'Your password has been reset successfully!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);        // Close dialog
                // Navigate to login and remove all previous routes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } else {
      // --- Password reset failed ---
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to reset password'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ==============================================================================
  // build - Render the Reset Password Screen UI
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // --- Lock Open Icon ---
              Icon(
                Icons.lock_open,                   // Open lock icon
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),

              // --- Title ---
              const Text(
                'Set New Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // --- Show associated email if token was verified ---
              if (_tokenEmail != null) ...[
                Text(
                  'Resetting password for: $_tokenEmail',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 40),        // Extra spacing if no email shown

              // --- Reset Token Input ---
              TextFormField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Reset Token',
                  prefixIcon: const Icon(Icons.vpn_key),   // Key icon
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  // Verify button inside the input field
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle),
                    onPressed: _verifyToken,               // Manually verify token
                    tooltip: 'Verify Token',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the reset token';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- New Password Input ---
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                // Password validation with multiple rules
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  // RegExp checks for presence of specific character types
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'Password must contain at least one uppercase letter';
                  }
                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                    return 'Password must contain at least one lowercase letter';
                  }
                  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                    return 'Password must contain at least one symbol';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Confirm Password Input ---
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // --- Password Requirements Info Box ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password must contain:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // List of requirements with check icons
                    _buildRequirement('At least 8 characters'),
                    _buildRequirement('One uppercase letter (A-Z)'),
                    _buildRequirement('One lowercase letter (a-z)'),
                    _buildRequirement('One symbol (!@#\$%^&*)'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Reset Password Button ---
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Reset Password',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Back Button ---
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================================
  // _buildRequirement - Reusable Requirement Row with Check Icon
  // ==============================================================================
  // Creates a single password requirement line with a small blue check icon.
  // ==============================================================================
  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
