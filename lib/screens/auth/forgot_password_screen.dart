// ==============================================================================
// forgot_password_screen.dart - Forgot Password / Request Reset Screen
// ==============================================================================
// This screen allows users who forgot their password to request a reset link.
//
// Flow:
// 1. User enters their email address
// 2. Form validates email format
// 3. API call sends a password reset email with a token
// 4. Success dialog shows with options:
//    - "Enter Token" (dev mode): navigates to ResetPasswordScreen with token
//    - "Back to Login": returns to login screen
// 5. User checks email and follows the reset instructions
//
// The development token is shown in the success dialog for testing purposes
// (in production, the token would only be in the email).
//
// Usage: Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()))
// ==============================================================================

import 'package:flutter/material.dart';           // For StatefulWidget, Form, etc.
import '../../services/api_service.dart';           // For ApiService.forgotPassword()
import '../../utils/colors.dart';                   // For AppColors (primary, success, danger)
import 'reset_password_screen.dart';                // For ResetPasswordScreen (next step)

// ==============================================================================
// ForgotPasswordScreen - StatefulWidget for Password Reset Request
// ==============================================================================
// StatefulWidget because it manages:
// - Email text controller
// - Loading state during API call
// ==============================================================================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();          // For form validation
  final _emailController = TextEditingController(); // Email input controller
  bool _isLoading = false;                          // API call in progress

  @override
  void dispose() {
    _emailController.dispose();                     // Clean up controller
    super.dispose();
  }

  // ==============================================================================
  // _handleForgotPassword - Request Password Reset Email
  // ==============================================================================
  // Validates the email, calls the API to send a reset link, and shows
  // a success or error dialog.
  // ==============================================================================
  Future<void> _handleForgotPassword() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Call API to send password reset email
    final result = await ApiService.forgotPassword(_emailController.text.trim());

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // --- Reset email sent successfully ---
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Email Sent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              const Icon(Icons.mark_email_read, size: 64, color: AppColors.success),
              const SizedBox(height: 16),

              // Success message from API
              Text(
                result['message'],
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Check your email for the reset link.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),

              // --- Development Token Display ---
              // In development mode, the API returns the token directly
              // This section shows it for testing convenience
              if (result['resetToken'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Development Token:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result['resetToken'],          // The actual reset token
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            // "Enter Token" button (only in development when token is available)
            if (result['resetToken'] != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);              // Close dialog
                  // Navigate to reset password screen with the token pre-filled
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResetPasswordScreen(
                        token: result['resetToken'],
                      ),
                    ),
                  );
                },
                child: const Text('Enter Token'),
              ),

            // "Back to Login" button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);                // Close dialog
                Navigator.pop(context);                // Go back to login screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      );
    } else {
      // --- Failed to send reset email ---
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to send reset email'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ==============================================================================
  // build - Render the Forgot Password Screen UI
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
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
              const SizedBox(height: 40),

              // --- Lock Reset Icon ---
              Icon(
                Icons.lock_reset,                  // Lock with circular arrow icon
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),

              // --- Title ---
              const Text(
                'Reset Your Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // --- Description ---
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- Email Input Field ---
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email),     // Email icon
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  // Email format validation
                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Send Reset Link Button ---
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Show spinner during loading, text otherwise
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
                          'Send Reset Link',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Back to Login Link ---
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
}
