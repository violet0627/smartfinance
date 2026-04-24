// ==============================================================================
// email_verification_banner.dart - Email Verification Warning Banner
// ==============================================================================
// This widget displays a prominent warning banner when the user's email
// has not been verified yet. It appears on the dashboard or main screen.
//
// The banner includes:
// - Warning icon and message explaining email isn't verified
// - "Resend Email" button: Calls the API to resend the verification email,
//   then navigates to the VerifyEmailScreen
// - "Verify Now" button: Directly navigates to the VerifyEmailScreen
//
// After verification is complete, the onVerified callback is called to
// refresh the parent widget and hide the banner.
//
// Usage: EmailVerificationBanner(
//          userId: currentUser.id,
//          email: currentUser.email,
//          onVerified: () => refreshUserData(),
//        )
// ==============================================================================

import 'package:flutter/material.dart';               // For widgets, Colors, Icons, etc.
import '../utils/colors.dart';                         // For AppColors (success, danger)
import '../services/api_service.dart';                 // For ApiService.resendVerification()
import '../screens/auth/verify_email_screen.dart';     // For VerifyEmailScreen (navigation target)

// ==============================================================================
// EmailVerificationBanner - StatelessWidget for Email Verification Warning
// ==============================================================================
// StatelessWidget because it has no mutable internal state.
// The async operations (API calls, navigation) don't change widget state.
// ==============================================================================
class EmailVerificationBanner extends StatelessWidget {
  final int userId;            // Current user's ID
  final String email;          // User's email address (to resend verification to)
  final VoidCallback onVerified;  // Callback to run after verification completes

  const EmailVerificationBanner({
    super.key,
    required this.userId,
    required this.email,
    required this.onVerified,
  });

  // ==============================================================================
  // _handleResendVerification - Resend Verification Email via API
  // ==============================================================================
  // Sends a new verification email to the user and then navigates to the
  // verification screen where they can enter the code.
  //
  // "async" keyword makes this function asynchronous (can use "await").
  // "await" pauses execution until the Future completes.
  // ==============================================================================
  Future<void> _handleResendVerification(BuildContext context) async {
    // Show a temporary message that the email is being sent
    // ScaffoldMessenger manages SnackBars for the current Scaffold
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending verification email...'),
        duration: Duration(seconds: 2),              // Auto-dismiss after 2 seconds
      ),
    );

    // Call the API to resend the verification email
    // Returns a Map with 'success', 'message', 'error', 'verificationToken' keys
    final result = await ApiService.resendVerification(email);

    // Safety check: "mounted" means the widget is still in the widget tree
    // If the user navigated away while the API call was in progress,
    // we should NOT try to use the context (it would be invalid)
    if (!context.mounted) return;

    if (result['success']) {
      // API call succeeded - show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Verification email sent'),
          backgroundColor: AppColors.success,        // Green background
        ),
      );

      // Navigate to the verification screen where user enters the code
      // MaterialPageRoute creates a platform-specific page transition
      Navigator.push(
        context,
        MaterialPageRoute(
          // builder: (_) means we don't need the BuildContext parameter
          builder: (_) => VerifyEmailScreen(
            email: email,
            token: result['verificationToken'], // For development/testing
          ),
        ),
      // .then() runs AFTER the user comes back from VerifyEmailScreen
      // context.mounted check: if the parent widget was disposed while the user
      // was on VerifyEmailScreen, calling onVerified() would crash (setState on dead widget)
      ).then((_) {
        if (!context.mounted) return;
        onVerified(); // Refresh the parent widget to hide the banner
      });
    } else {
      // API call failed - show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to resend verification'),
          backgroundColor: AppColors.danger,         // Red background
        ),
      );
    }
  }

  // ==============================================================================
  // build - Render the Warning Banner
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),               // Outer spacing from screen edges
      padding: const EdgeInsets.all(16),              // Inner spacing
      decoration: BoxDecoration(
        color: Colors.orange.shade50,                 // Very light orange background
        border: Border.all(color: Colors.orange.shade300, width: 2),  // Orange border
        borderRadius: BorderRadius.circular(12),      // Rounded corners
      ),
      child: Column(
        children: [
          // --- Warning Message Row ---
          Row(
            children: [
              // Warning triangle icon
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,        // Dark orange
                size: 28,
              ),
              const SizedBox(width: 12),

              // Warning text (Expanded to take remaining width)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title: "Email Not Verified"
                    const Text(
                      'Email Not Verified',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Subtitle explaining the consequence
                    Text(
                      'Please verify your email to access all features',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Action Buttons Row ---
          Row(
            children: [
              // "Resend Email" button (outlined style - less prominent)
              Expanded(
                child: OutlinedButton.icon(
                  // Call _handleResendVerification when pressed
                  onPressed: () => _handleResendVerification(context),
                  icon: const Icon(Icons.email, size: 18),    // Email icon
                  label: const Text('Resend Email'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,   // Orange text
                    side: BorderSide(color: Colors.orange.shade700),  // Orange border
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // "Verify Now" button (filled style - more prominent)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate directly to VerifyEmailScreen (without resending)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VerifyEmailScreen(email: email),
                      ),
                    // Call onVerified when user returns from verification screen
                    ).then((_) => onVerified());
                  },
                  icon: const Icon(Icons.verified_user, size: 18),  // Verified user icon
                  label: const Text('Verify Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,  // Orange filled background
                    foregroundColor: Colors.white,             // White text on orange
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
