import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/forgot_password_service.dart';
import 'login_screen.dart';

/// Forgot Password Screen - Two-step OTP based password reset
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late TextEditingController _emailController;
  late TextEditingController _otpController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  String? _successMessage;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _otpController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    _clearMessages();

    final email = _emailController.text.trim();

    // Validate email
    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailPattern.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ForgotPasswordService.sendOtp(email);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        setState(() {
          _otpSent = true;
          _userEmail = email;
          _successMessage = result['message'] ??
              'OTP has been sent to your email. Check your inbox.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        _showError(result['message'] ?? 'Failed to send OTP');
      }
    }
  }

  Future<void> _resetPassword() async {
    _clearMessages();

    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate inputs
    if (otp.isEmpty) {
      _showError('Please enter the OTP');
      return;
    }

    if (newPassword.isEmpty) {
      _showError('Please enter your new password');
      return;
    }

    if (newPassword.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ForgotPasswordService.resetPasswordWithOtp(
      _userEmail,
      otp,
      newPassword,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Password reset successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to login after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        });
      } else {
        _showError(result['message'] ?? 'Failed to reset password');
      }
    }
  }

  void _clearMessages() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: !_otpSent ? _buildEmailStep() : _buildOtpStep(),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Enter Your Email',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We\'ll send you an OTP to reset your password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 32),

        // Email input
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email Address',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: const TextStyle(
                  color: Color(0xFFB5BFC7),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCE6F2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCE6F2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Send OTP Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Send OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Back to login
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text.rich(
              TextSpan(
                text: 'Remember your password? ',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
                children: [
                  TextSpan(
                    text: 'Login',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Enter OTP & New Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent an OTP to $_userEmail',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 32),

        // OTP Input
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OTP Code',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              enabled: !_isLoading,
              maxLength: 6,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: 'Enter 6-digit OTP',
                hintStyle: const TextStyle(
                  color: Color(0xFFB5BFC7),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCE6F2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCE6F2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                fillColor: Colors.white,
                filled: true,
                counterText: '',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // New Password Input
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Password',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              enabled: !_isLoading,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: 'Enter new password',
                hintStyle: const TextStyle(
                  color: Color(0xFFB5BFC7),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outlined,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCE6F2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCE6F2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Confirm Password Input
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Password',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              enabled: !_isLoading,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: 'Confirm your password',
                hintStyle: const TextStyle(
                  color: Color(0xFFB5BFC7),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outlined,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCE6F2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCE6F2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Reset Password Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Back button
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _otpSent = false;
                _emailController.clear();
                _otpController.clear();
                _newPasswordController.clear();
                _confirmPasswordController.clear();
              });
            },
            child: Text.rich(
              TextSpan(
                text: 'Didn\'t receive OTP? ',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
                children: [
                  TextSpan(
                    text: 'Try another email',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
