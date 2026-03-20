// ==============================================================================
// register_screen.dart - User Registration Screen
// ==============================================================================
// This screen handles new user account creation. It provides:
//
// - Full name, email, phone number input fields
// - Password field with real-time strength indicators
// - Confirm password field with match validation
// - Terms & Conditions checkbox (required to proceed)
// - Registration button with loading state
// - Navigation back to login screen
//
// Registration flow:
// 1. User fills in all required fields
// 2. Form validates: name required, email format, phone format, password rules
// 3. Password strength is checked in real-time (8+ chars, uppercase, lowercase, symbol)
// 4. User must agree to Terms & Conditions
// 5. API register call → creates account
// 6. On success → shows dialog with options to verify email or go to login
//
// Password validation rules:
// - Minimum 8 characters
// - At least one uppercase letter (A-Z)
// - At least one lowercase letter (a-z)
// - At least one symbol (!@#$%^&*(),.?":{}|<>)
//
// Usage: Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()))
// ==============================================================================

import 'package:flutter/material.dart';              // For widgets, Form, TextFormField, etc.
import '../../services/api_service.dart';              // For ApiService.register()
import '../../utils/colors.dart';                      // For AppColors (colors for UI)
import '../../utils/app_gradients.dart';               // For AppGradients.successGradient
import 'login_screen.dart';                            // For LoginScreen (navigation after registration)
import 'verify_email_screen.dart';                     // For VerifyEmailScreen (email verification)
import '../../widgets/animated_button.dart';           // For AnimatedButton (gradient button)

// ==============================================================================
// RegisterScreen - StatefulWidget for Registration Form
// ==============================================================================
// StatefulWidget because it manages:
// - Multiple form field controllers (name, email, phone, password, confirm)
// - Loading state during API call
// - Password visibility toggles
// - Terms agreement checkbox
// - Real-time password strength indicators
// ==============================================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Form key for collective validation of all fields
  final _formKey = GlobalKey<FormState>();

  // Text controllers for each input field
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // UI state variables
  bool _isLoading = false;                // API call in progress
  bool _obscurePassword = true;           // Hide password text
  bool _obscureConfirmPassword = true;    // Hide confirm password text
  bool _agreeToTerms = false;             // Terms & Conditions checkbox

  // Password strength indicators (updated in real-time as user types)
  bool _hasMinLength = false;             // Password >= 8 characters
  bool _hasUppercase = false;             // Contains uppercase letter
  bool _hasLowercase = false;             // Contains lowercase letter
  bool _hasSymbol = false;                // Contains special symbol

  // ==============================================================================
  // initState - Set Up Password Strength Listener
  // ==============================================================================
  // addListener registers a callback that fires every time the password text changes.
  // This enables real-time password strength feedback.
  // ==============================================================================
  @override
  void initState() {
    super.initState();
    // Listen to password changes to update strength indicators
    _passwordController.addListener(_checkPasswordStrength);
  }

  // ==============================================================================
  // dispose - Clean Up All Controllers
  // ==============================================================================
  // Must remove the listener before disposing to prevent calling setState
  // on a disposed widget.
  // ==============================================================================
  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordStrength);  // Remove listener first
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ==============================================================================
  // _checkPasswordStrength - Real-Time Password Validation
  // ==============================================================================
  // Called every time the password field changes.
  // Updates the boolean indicators that drive the visual password requirements.
  //
  // RegExp patterns:
  // r'[A-Z]' = matches any uppercase letter
  // r'[a-z]' = matches any lowercase letter
  // r'[!@#$%^&*(),.?":{}|<>]' = matches any of these symbols
  // ==============================================================================
  void _checkPasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  // ==============================================================================
  // _validatePassword - Password Form Validator
  // ==============================================================================
  // Called when the form is submitted. Returns null if valid, or an error
  // message string if invalid. This is used by the TextFormField's validator.
  // ==============================================================================
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
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
    return null;  // All checks passed
  }

  // ==============================================================================
  // _handleRegister - Process Registration Form Submission
  // ==============================================================================
  // Validates the form, checks terms agreement, calls the registration API,
  // and shows success dialog with next steps.
  // ==============================================================================
  Future<void> _handleRegister() async {
    // Validate all form fields
    if (!_formKey.currentState!.validate()) return;

    // Check terms agreement (not part of form validation)
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Conditions'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Call the registration API
    // Phone number is optional: send null if empty
    final result = await ApiService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      // Ternary: if phone is not empty send it, otherwise send null
      phoneNumber: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // --- Registration succeeded ---
      // Show success dialog with verification options
      showDialog(
        context: context,
        barrierDismissible: false,              // Must choose an option
        builder: (context) => AlertDialog(
          title: const Text('Registration Successful!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,      // Dialog shrinks to fit content
            children: [
              // Success checkmark icon
              const Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your account has been created successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please verify your email address to access all features.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              // Display the registered email in primary color
              Text(
                _emailController.text.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          actions: [
            // Option 1: Go to email verification screen
            TextButton(
              onPressed: () {
                Navigator.pop(context);          // Close dialog
                // pushReplacement replaces current screen with verification screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VerifyEmailScreen(
                      email: _emailController.text.trim(),
                    ),
                  ),
                );
              },
              child: const Text('Verify Email'),
            ),
            // Option 2: Go to login screen
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);          // Close dialog
                // pushAndRemoveUntil navigates and removes ALL previous routes
                // (route) => false means remove everything (clean navigation stack)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
                // Show success SnackBar after a small delay (to let navigation finish)
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Registration successful! Please login to continue.'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Login Now'),
            ),
          ],
        ),
      );
    } else {
      // --- Registration failed ---
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Registration failed'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ==============================================================================
  // build - Render the Registration Screen UI
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // App bar with back button (transparent, no elevation)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,                                  // No shadow
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),     // Go back to login
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Title ---
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // --- Subtitle ---
                Text(
                  'Join SmartFinance to start your financial journey',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // --- Full Name Field ---
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'FULL NAME',
                    hintText: 'John Tan Ah Meng',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Email Field ---
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'EMAIL ADDRESS',
                    hintText: 'john@gmail.com',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    // Email format validation using regex
                    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Phone Number Field ---
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,           // Shows phone keyboard
                  decoration: InputDecoration(
                    labelText: 'PHONE NUMBER',
                    hintText: '012-345-6789',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    // Phone is optional — only validate format if the user typed something
                    if (value == null || value.isEmpty) return null;
                    // Malaysian phone format: 01X-XXXXXXX or 01XXXXXXXX
                    final phoneRegex = RegExp(r'^01[0-9]-?[0-9]{7,8}$');
                    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
                      return 'Please enter a valid Malaysian phone number (e.g., 012-3456789)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Password Field ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'PASSWORD',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    // Toggle visibility button
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: _validatePassword,        // Uses the password validator method
                ),
                const SizedBox(height: 8),

                // --- Password Strength Indicators ---
                // Only shown when the password field has text
                if (_passwordController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password must contain:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Each requirement shows green check or red X based on status
                        _buildPasswordRequirement('At least 8 characters', _hasMinLength),
                        _buildPasswordRequirement('One uppercase letter', _hasUppercase),
                        _buildPasswordRequirement('One lowercase letter', _hasLowercase),
                        _buildPasswordRequirement('One symbol', _hasSymbol),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // --- Confirm Password Field ---
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'CONFIRM PASSWORD',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    // Check that passwords match
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Terms & Conditions Checkbox ---
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        // value ?? false handles null (converts to false)
                        setState(() => _agreeToTerms = value ?? false);
                      },
                      activeColor: AppColors.primary,    // Checked color
                    ),
                    // Expanded prevents text overflow
                    Expanded(
                      // GestureDetector makes the text tappable too (not just checkbox)
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _agreeToTerms = !_agreeToTerms);
                        },
                        // RichText allows different styles in one text widget
                        child: RichText(
                          text: TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(color: AppColors.textSecondary),
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Create Account Button ---
                AnimatedButton(
                  text: 'Create Account',
                  onPressed: _handleRegister,
                  gradient: AppGradients.successGradient,   // Blue gradient
                  isLoading: _isLoading,
                  icon: Icons.person_add,                   // Add person icon
                ),
                const SizedBox(height: 16),

                // --- Already Have Account Link ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),  // Go back to login
                      child: const Text('Login'),
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

  // ==============================================================================
  // _buildPasswordRequirement - Visual Password Requirement Row
  // ==============================================================================
  // Shows a check (green) or cancel (red) icon next to a requirement text.
  // Used in the password strength indicators section.
  //
  // Parameters:
  //   text: The requirement description (e.g., "At least 8 characters")
  //   isMet: Whether this requirement is currently satisfied
  // ==============================================================================
  Widget _buildPasswordRequirement(String text, bool isMet) {
    // Green for met requirements, red for unmet
    final color = isMet ? AppColors.success : AppColors.danger;
    // Checkmark for met, X for unmet
    final icon = isMet ? Icons.check_circle : Icons.cancel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
