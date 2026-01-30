import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../dashboard/dashboard_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? token;
  final String? email;

  const VerifyEmailScreen({super.key, this.token, this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _tokenController.text = widget.token!;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);

    final result = await ApiService.verifyEmail(_tokenController.text.trim());

    setState(() => _isVerifying = false);

    if (!mounted) return;

    if (result['success']) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.success,
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
                Navigator.pop(context); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  (route) => false,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to verify email'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleResendVerification() async {
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

      // If development token is available, auto-fill it
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
              Icon(
                Icons.mark_email_read,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
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

              // Verification Token Input
              TextFormField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Verification Token',
                  hintText: 'Paste token from email',
                  prefixIcon: const Icon(Icons.vpn_key),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the verification token';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    _buildInstruction('1. Check your email inbox'),
                    _buildInstruction('2. Open the verification email'),
                    _buildInstruction('3. Copy the verification token'),
                    _buildInstruction('4. Paste it above and click Verify'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Verify Button
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

              // Resend Button
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

              // Back to Login
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

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 28),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
