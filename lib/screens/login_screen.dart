import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_header.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Login screen for healthcare app
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _userIdController;
  late TextEditingController _passwordController;

  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userIdController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void resetLoginForm() {
    _userIdController.clear();
    _passwordController.clear();
    _rememberMe = false;
    _isLoading = false;
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  void _handleLogin() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    final success = await AuthService.login(
      _userIdController.text.trim(),
      _passwordController.text.trim(),
      rememberMe: _rememberMe,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showErrorSnackBar("Invalid email or password");
    }
  }

  bool _validateForm() {
    if (_userIdController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please fill in email and password');
      return false;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppHeader(
                        title: 'Welcome Back',
                        subtitle: 'Login to continue',
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CompactInputField(
                                label: 'Email / User ID',
                                hint: 'Enter your email or user ID',
                                prefixIcon: Icons.person_outline,
                                controller: _userIdController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              _CompactInputField(
                                label: 'Password',
                                hint: 'Enter your password',
                                prefixIcon: Icons.lock_outline,
                                controller: _passwordController,
                                obscureText: true,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: 8,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _rememberMe = !_rememberMe);
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: AppColors.primary,
                                              width: 1.5,
                                            ),
                                            color: _rememberMe
                                                ? AppColors.primary
                                                : Colors.white,
                                          ),
                                          child: _rememberMe
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Remember me',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1F2937),
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    disabledBackgroundColor: AppColors.disabled,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  runSpacing: 6,
                                  children: [
                                    const Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF6B7280),
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const RegisterScreen(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                          decoration: TextDecoration.underline,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Compact input field widget
class _CompactInputField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;

  const _CompactInputField({
    Key? key,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  }) : super(key: key);

  @override
  State<_CompactInputField> createState() => _CompactInputFieldState();
}

class _CompactInputFieldState extends State<_CompactInputField> {
  late bool _obscuredText;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _obscuredText = widget.obscureText;
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: _obscuredText,
            focusNode: _focusNode,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 18,
                      color: _focusNode.hasFocus
                          ? AppColors.primary
                          : const Color(0xFF9CA3AF),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIcon: widget.obscureText
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscuredText = !_obscuredText;
                        });
                      },
                      child: Icon(
                        _obscuredText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: const Color(0xFF9CA3AF),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE6F2), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// STEP 1: Forgot Password modal (send OTP)
void _showForgotPasswordModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      final emailController = TextEditingController();
      bool isLoading = false;

      return StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> handleSendOtp() async {
            final email = emailController.text.trim();
            if (email.isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('Please enter your email'),
                  backgroundColor: Color(0xFFDC2626),
                ),
              );
              return;
            }

            setState(() => isLoading = true);
            final result = await AuthService.sendOtp(email);
            setState(() => isLoading = false);

            if (!dialogContext.mounted) return;

            if (result['success'] == true) {
              Navigator.pop(dialogContext);

              final verified = await _showOtpVerificationModal(context, email);
              if (verified == true && context.mounted) {
                _showResetPasswordModal(context, email);
              }

              return;
            }

            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'Failed to send OTP'),
                backgroundColor: const Color(0xFFDC2626),
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
            ),
            title: const Text('Forgot Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your registered email to receive OTP',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'your@email.com',
                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : handleSendOtp,
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send OTP'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// STEP 2: OTP Verification modal
Future<bool?> _showOtpVerificationModal(BuildContext context, String email) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _OtpVerificationDialog(email: email),
  );
}

class _OtpVerificationDialog extends StatefulWidget {
  final String email;

  const _OtpVerificationDialog({required this.email});

  @override
  State<_OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<_OtpVerificationDialog> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        t.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  String _otpValue() {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _handleVerify() async {
    final otp = _otpValue().trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP must be 6 digits'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final result = await AuthService.verifyOtp(widget.email.trim(), otp);
    setState(() => _isVerifying = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verified'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['error'] ?? 'Invalid OTP'),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0) return;
    setState(() => _isResending = true);
    final result = await AuthService.sendOtp(widget.email.trim());
    setState(() => _isResending = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent'),
          backgroundColor: Colors.green,
        ),
      );
      _startCountdown();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['error'] ?? 'Failed to resend OTP'),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
      ),
      title: const Text('Verify OTP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OTP sent only if email exists',
            style: TextStyle(
              color: AppColors.textMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 40,
                height: 48,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      if (index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else {
                        _focusNodes[index].unfocus();
                      }
                    } else {
                      if (index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: (_secondsRemaining > 0 || _isResending) ? null : _handleResend,
                child: Text(
                  _secondsRemaining > 0
                      ? 'Resend OTP in ${_secondsRemaining}s'
                      : (_isResending ? 'Resending...' : 'Resend OTP'),
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _handleVerify,
          child: _isVerifying
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}

void _showResetPasswordModal(BuildContext parentContext, String email) {
  showDialog(
    context: parentContext,
    builder: (dialogContext) {
        final newPasswordController = TextEditingController();
        final confirmPasswordController = TextEditingController();
        bool showPassword = false;
        bool showConfirmPassword = false;

        return StatefulBuilder(
          builder: (dialogContext, setState) {
            String? _validatePasswords() {
              final password = newPasswordController.text;
              final confirmPassword = confirmPasswordController.text;

              if (password.isEmpty) {
                return 'New Password cannot be empty';
              }
              if (password.length < 8) {
                return 'Password must be at least 8 characters';
              }
              if (!password.contains(RegExp(r'[A-Z]'))) {
                return 'Password must contain 1 uppercase letter';
              }
              if (!password.contains(RegExp(r'[a-z]'))) {
                return 'Password must contain 1 lowercase letter';
              }
              if (!password.contains(RegExp(r'[0-9]'))) {
                return 'Password must contain 1 number';
              }
              if (confirmPassword.isEmpty) {
                return 'Re-enter Password cannot be empty';
              }
              if (password != confirmPassword) {
                return 'Passwords do not match';
              }

              return null;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
              ),
              title: const Text('Set New Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: TextFormField(
                        controller: newPasswordController,
                        obscureText: !showPassword,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() => showPassword = !showPassword);
                            },
                            child: Icon(
                              showPassword ? Icons.visibility : Icons.visibility_off,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !showConfirmPassword,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Re-enter New Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() => showConfirmPassword = !showConfirmPassword);
                            },
                            child: Icon(
                              showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Password rules: 8+ chars, uppercase, lowercase, number',
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final validationError = _validatePasswords();

                    if (validationError != null) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(validationError),
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                      );
                      return;
                    }

                    final result = await AuthService.resetPassword(
                      email,
                      newPasswordController.text.trim(),
                    );

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    if (result['success']) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset successful'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(result['error'] ?? 'Failed to reset password'),
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                      );
                    }
                  },
                  child: const Text('Reset Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Show create account modal
  void _showCreateAccountModal(
    BuildContext parentContext,
    TextEditingController loginEmailController,
  ) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        final nameController = TextEditingController();
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        final confirmPasswordController = TextEditingController();
        bool isLoading = false;

        String? _validateForm() {
          final name = nameController.text.trim();
          final email = emailController.text.trim();
          final password = passwordController.text;
          final confirmPassword = confirmPasswordController.text;

          // Name validation
          if (name.isEmpty) {
            return 'Full name cannot be empty';
          }

          // Email validation
          if (email.isEmpty) {
            return 'Email cannot be empty';
          }
          if (!email.contains('@') || !email.contains('.')) {
            return 'Email must contain @ and .';
          }

          // Password validation
          if (password.isEmpty) {
            return 'Password cannot be empty';
          }
          if (password.length < 6) {
            return 'Password must be at least 6 characters';
          }

          // Confirm password validation
          if (confirmPassword.isEmpty) {
            return 'Re-enter Password cannot be empty';
          }
          if (password != confirmPassword) {
            return 'Passwords do not match';
          }

          return null;
        }

        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
              ),
              title: const Text('Create Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: TextFormField(
                        controller: nameController,
                        enabled: !isLoading,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Full name',
                          prefixIcon: const Icon(Icons.person_outline, size: 18),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: TextFormField(
                        controller: emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: TextFormField(
                        controller: passwordController,
                        enabled: !isLoading,
                        obscureText: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: TextFormField(
                        controller: confirmPasswordController,
                        enabled: !isLoading,
                        obscureText: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Re-enter Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    final validationError = _validateForm();

                    if (validationError != null) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(validationError),
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isLoading = true);

                    final email = emailController.text.trim();
                    final result = await AuthService.register(
                      nameController.text.trim(),
                      email,
                      passwordController.text.trim(),
                      confirmPassword: confirmPasswordController.text.trim(),
                    );

                    if (!dialogContext.mounted) return;

                    setDialogState(() => isLoading = false);

                    if (result["success"] == true) {
                      // Success: auto-fill login email, close modal, show success message
                      loginEmailController.text = email;

                      nameController.clear();
                      emailController.clear();
                      passwordController.clear();
                      confirmPasswordController.clear();
                      
                      if (!dialogContext.mounted) return;
                      
                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text("Account created successfully. Please login."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      // Error: keep modal open and show error message
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            (result["error"] ?? "Registration failed").toString(),
                          ),
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                      );
                    }
                  },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
