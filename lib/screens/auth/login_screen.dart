// ==============================================================================
// login_screen.dart - User Login Screen
// ==============================================================================
// This screen handles user authentication (login). It provides:
//
// - Email and password input fields with validation
// - Password visibility toggle (show/hide password)
// - "Forgot Password?" link to password recovery flow
// - Login button with loading state (AnimatedButton with gradient)
// - Two-Factor Authentication (2FA) support after successful login
// - Navigation to Register and Verify Email screens
//
// Login flow:
// 1. User enters email and password
// 2. Form validates inputs (email format, password required)
// 3. API login call → receives user data + JWT token
// 4. If user has 2FA enabled → show 2FA verification dialog
// 5. On success → navigate to DashboardScreen (replace current route)
// 6. On failure → show error SnackBar
//
// Usage: Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))
// ==============================================================================

import 'package:flutter/material.dart';                         // For widgets, Form, TextFormField, etc.
import '../../services/api_service.dart';                        // For ApiService.login()
import '../../utils/colors.dart';                                // For AppColors (background, text colors)
import '../../utils/app_gradients.dart';                         // For AppGradients.primaryGradient
import '../dashboard/dashboard_screen.dart';                     // For DashboardScreen (post-login destination)
import 'register_screen.dart';                                   // For RegisterScreen (sign up link)
import 'forgot_password_screen.dart';                            // For ForgotPasswordScreen (forgot password link)
import 'verify_email_screen.dart';                               // For VerifyEmailScreen (verify email link)
import '../../widgets/two_factor_verification_dialog.dart';      // For show2FAVerificationDialog()
import '../../widgets/animated_button.dart';                     // For AnimatedButton (gradient login button)

// ==============================================================================
// LoginScreen - StatefulWidget for Login Form
// ==============================================================================
// StatefulWidget because it manages:
// - Form state (validation, text controllers)
// - Loading state (isLoading during API call)
// - Password visibility toggle (obscurePassword)
// ==============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey<FormState> allows us to validate all form fields at once
  final _formKey = GlobalKey<FormState>();

  // TextEditingControllers manage the text in each input field
  // They hold the current text value and notify listeners of changes
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Whether an API call is in progress (shows loading spinner on button)
  bool _isLoading = false;

  // Whether the password text is hidden (true = dots, false = readable text)
  bool _obscurePassword = true;

  // ==============================================================================
  // dispose - Clean Up Controllers
  // ==============================================================================
  // TextEditingControllers allocate resources that need to be freed.
  // Always dispose controllers to prevent memory leaks.
  // ==============================================================================
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==============================================================================
  // _handleLogin - Process Login Form Submission
  // ==============================================================================
  // Validates the form, calls the login API, handles 2FA if enabled,
  // and navigates to the dashboard on success.
  //
  // "async" allows using "await" to pause for asynchronous operations.
  // "Future<void>" means this function returns a Future that completes with no value.
  // ==============================================================================
  Future<void> _handleLogin() async {
    // Validate all form fields - if any validator returns a non-null string,
    // the form is invalid and the error messages are shown
    if (!_formKey.currentState!.validate()) return;

    // Show loading state on the button
    setState(() => _isLoading = true);

    // Call the login API with email and password
    // .trim() removes whitespace from the email (but not the password)
    final result = await ApiService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // Hide loading state
    setState(() => _isLoading = false);

    // Safety check: if the widget was removed while waiting for API response,
    // don't try to update the UI (would throw an error)
    if (!mounted) return;

    if (result['success']) {
      // --- Login API succeeded ---

      // Check if the user has Two-Factor Authentication enabled
      final user = result['user'];                       // UserModel from API response
      final bool twoFactorEnabled = user.twoFactorEnabled;

      if (twoFactorEnabled) {
        // Show the 2FA verification dialog (TOTP code or backup code)
        final userId = user.userId;
        final verified = await show2FAVerificationDialog(context, userId);

        if (!verified) {
          // 2FA verification failed or was cancelled
          // Log the user out since they couldn't complete 2FA
          await ApiService.logout();
          if (!mounted) return;

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Two-factor authentication required'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;  // Don't proceed to dashboard
        }
      }

      // Login successful (with or without 2FA)
      if (!mounted) return;

      // Navigate to dashboard, replacing the current screen
      // pushReplacement means the user can't go "back" to the login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      // --- Login API failed ---
      // Show error message (e.g., "Invalid email or password")
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Login failed'),
          backgroundColor: AppColors.danger,    // Red background
        ),
      );
    }
  }

  // ==============================================================================
  // build - Render the Login Screen UI
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,     // Light grey background

      // SafeArea ensures content doesn't overlap with system UI (notch, status bar)
      body: SafeArea(
        // SingleChildScrollView allows scrolling when keyboard pushes content up
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),    // 24px padding on all sides
          // Form widget groups TextFormFields for collective validation
          child: Form(
            key: _formKey,                        // Links form to our GlobalKey
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,  // Full width children
              children: [
                const SizedBox(height: 60),       // Top spacing

                // --- Welcome Title ---
                Text(
                  'Welcome Back',
                  // Theme.of(context).textTheme gives access to app-wide text styles
                  // ?.copyWith() safely modifies the style (adds bold weight)
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // --- Subtitle ---
                Text(
                  'Sign in to continue to SmartFinance',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // --- Email Input Field ---
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,  // Shows @ key on keyboard
                  decoration: InputDecoration(
                    labelText: 'EMAIL ADDRESS',
                    hintText: 'john@gmail.com',              // Placeholder text
                    filled: true,
                    fillColor: Colors.white,                  // White background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,            // No border line
                    ),
                  ),
                  // Validator runs when form.validate() is called
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    // RegExp validates email format: name@domain.tld
                    // r'' is a raw string (backslashes are literal)
                    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;  // null = validation passed
                  },
                ),
                const SizedBox(height: 16),

                // --- Password Input Field ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,              // Hides text when true
                  decoration: InputDecoration(
                    labelText: 'PASSWORD',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    // Eye icon button to toggle password visibility
                    suffixIcon: IconButton(
                      icon: Icon(
                        // Show different icons based on visibility state
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        // Toggle the obscure state
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // --- Forgot Password Link ---
                Align(
                  alignment: Alignment.centerRight,           // Right-aligned
                  child: TextButton(
                    onPressed: () {
                      // Navigate to forgot password screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Login Button (animated with gradient) ---
                AnimatedButton(
                  text: 'Login',
                  onPressed: _handleLogin,
                  gradient: AppGradients.primaryGradient,      // Purple-blue gradient
                  isLoading: _isLoading,                       // Shows spinner when loading
                  icon: Icons.login,                           // Login icon
                ),
                const SizedBox(height: 24),

                // --- Sign Up Link ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // --- Verify Email Link ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Need to verify your email? ",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const VerifyEmailScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Verify Now',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
