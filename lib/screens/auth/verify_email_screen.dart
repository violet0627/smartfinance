// ==============================================================================
// verify_email_screen.dart - Email Verification Screen
// ==============================================================================
// This screen allows users to verify their email address by entering a
// verification token they received via email.
//
// Features:
// - Token input field (multi-line for long tokens)
// - Instructions section explaining the verification process
// - Verify button with loading state
// - Resend verification email button (if email is available)
// - Auto-fill token when navigating from development mode
// - Success dialog → navigates to dashboard after verification
//
// Navigation:
// - Accessed from: RegisterScreen (after registration), EmailVerificationBanner,
//   LoginScreen ("Verify Now" link)
// - Navigates to: DashboardScreen (after successful verification)
//
// Usage: VerifyEmailScreen(email: 'user@example.com', token: 'optional-dev-token')
// ==============================================================================

import 'package:flutter/material.dart';           // For StatefulWidget, Form, etc.
import '../../services/api_service.dart';           // For ApiService.verifyEmail(), resendVerification()
import '../../utils/colors.dart';                   // For AppColors (primary, success, danger)
import '../dashboard/dashboard_screen.dart';        // For DashboardScreen (post-verification destination)

// ==============================================================================
// VerifyEmailScreen - StatefulWidget for Email Verification
// ==============================================================================
// StatefulWidget because it manages:
// - Token input controller
// - Two loading states (verifying and resending)
// ==============================================================================
class VerifyEmailScreen extends StatefulWidget {
  final String? token;   // Optional pre-filled token (from development/testing)
  final String? email;   // User's email (needed for resend functionality)

  const VerifyEmailScreen({super.key, this.token, this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();       // Form validation key
  final _tokenController = TextEditingController(); // Controller for token input

  bool _isVerifying = false;    // Whether verify API call is in progress
  bool _isResending = false;    // Whether resend API call is in progress

  // ==============================================================================
  // initState - Pre-fill Token if Provided
  // ==============================================================================
  // If a token was passed (from development mode or deep link),
  // auto-fill it in the text field.
  // ==============================================================================
  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _tokenController.text = widget.token!;    // ! asserts token is not null
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  // ==============================================================================
  // _handleVerifyEmail - Submit Token for Verification
  // ==============================================================================
  // Validates the form, calls the API to verify the token, and shows
  // a success dialog on verification.
  // ==============================================================================
  Future<void> _handleVerifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);

    // Call API to verify the email using the token
    final result = await ApiService.verifyEmail(_tokenController.text.trim());

    setState(() => _isVerifying = false);

    if (!mounted) return;

    if (result['success']) {
      // --- Verification succeeded ---
      // Show success dialog with checkmark icon
      showDialog(
        context: context,
        barrierDismissible: false,             // Must tap the button
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.success,      // Green checkmark
              ),
              const SizedBox(height: 16),
              const Text(
                'Your email has been verified successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);        // Close dialog
                // Navigate to dashboard and remove all previous routes
                // This prevents the user from going "back" to the verification screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  (route) => false,            // Remove all previous routes
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      );
    } else {
      // --- Verification failed ---
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to verify email'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ==============================================================================
  // _handleResendVerification - Resend Verification Email
  // ==============================================================================
  // Calls the API to send a new verification email.
  // If in development mode, auto-fills the new token.
  // ==============================================================================
  Future<void> _handleResendVerification() async {
    // Can only resend if we know the user's email
    if (widget.email == null || widget.email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email address not available'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isResending = true);

    // Call API to resend verification email
    final result = await ApiService.resendVerification(widget.email!);

    setState(() => _isResending = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Verification email sent'),
          backgroundColor: AppColors.success,
        ),
      );

      // In development mode, the API returns the token directly
      // Auto-fill it for convenience
      if (result['verificationToken'] != null) {
        setState(() {
          _tokenController.text = result['verificationToken'];
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to resend verification'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ==============================================================================
  // build - Render the Verification Screen UI
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
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

              // --- Email Icon ---
              Icon(
                Icons.mark_email_read,             // Email with checkmark icon
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),

              // --- Title ---
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // --- Description ---
              // Shows different text depending on whether email is available
              Text(
                widget.email != null
                    ? 'We sent a verification link to:\n${widget.email}'
                    : 'Enter the verification token from your email',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- Verification Token Input ---
              TextFormField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Verification Token',
                  hintText: 'Paste token from email',
                  prefixIcon: const Icon(Icons.vpn_key),   // Key icon
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,                       // Allow multi-line for long tokens
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the verification token';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // --- Instructions Box ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,       // Light blue background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info header with icon
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'How to verify:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Step-by-step instructions
                    _buildInstruction('1. Check your email inbox'),
                    _buildInstruction('2. Open the verification email'),
                    _buildInstruction('3. Copy the verification token'),
                    _buildInstruction('4. Paste it above and click Verify'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Verify Button ---
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerifyEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Show spinner when verifying, text when idle
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
                          'Verify Email',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Resend Button (only shown if email is available) ---
              if (widget.email != null) ...[
                TextButton(
                  onPressed: _isResending ? null : _handleResendVerification,
                  child: _isResending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Didn\'t receive the email? Resend'),
                ),
              ],

              const SizedBox(height: 16),

              // --- Back to Login Button ---
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================================
  // _buildInstruction - Reusable Instruction Text Row
  // ==============================================================================
  // Creates an indented instruction text (used in the "How to verify" section).
  // ==============================================================================
  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 28),   // Indented from the header
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
