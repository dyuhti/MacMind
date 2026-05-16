import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/app_header.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ResetPasswordScreen({super.key, this.onBack});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validate password strength
  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  /// Get password strength message
  String _getPasswordStrengthMessage(String password) {
    if (password.isEmpty) return '';
    if (password.length < 8) return 'Minimum 8 characters';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'One uppercase letter';
    if (!password.contains(RegExp(r'[0-9]'))) return 'One number';
    return 'Password is strong ✓';
  }

  /// Validate current password field
  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate new password field
  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    if (!_isPasswordStrong(value)) {
      return 'Password must be at least 8 characters with 1 uppercase and 1 number';
    }
    return null;
  }

  /// Validate confirm password field
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Submit password reset request
  Future<void> _submitPasswordReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get auth token
      print('🔍 DEBUG: Getting auth token...');
      final token = await AuthService.getToken();
      
      print('🔍 DEBUG: Token retrieved: ${token != null ? 'YES (${token.substring(0, 10)}...)' : 'NO (NULL)'}');
      
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication required. Please login again.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }

      // Prepare request body
      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;
      
      final requestBody = {
        'current_password': currentPassword,
        'new_password': newPassword,
      };

      print('🔍 DEBUG: Password Reset Request');
      print('   - Current Password: ${currentPassword.length} chars');
      print('   - New Password: ${newPassword.length} chars');
      print('   - Token: ${token.substring(0, 20)}...');

      final apiUrl = '${ApiConfig.baseUrl}/api/auth/change_password';
      print('🔍 DEBUG: API URL: $apiUrl');
      print('🔍 DEBUG: Request Body: $requestBody');

      // Make POST request to backend
      print('📤 Sending HTTP POST request...');
      Future<http.Response> sendRequest() {
        return http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        );
      }

      http.Response response;
      try {
        response = await sendRequest().timeout(const Duration(seconds: 25));
      } on TimeoutException {
        // Render can be slow on cold starts; retry once before failing.
        print('⏳ First request timed out. Retrying once...');
        response = await sendRequest().timeout(const Duration(seconds: 25));
      }

      print('✅ HTTP Response received!');
      print('📨 Response status: ${response.statusCode}');
      print('📨 Response headers: ${response.headers}');
      print('📨 Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Success
        print('✅ SUCCESS: Password changed successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _showCurrentPassword = false;
          _showNewPassword = false;
          _showConfirmPassword = false;
        });

        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else if (response.statusCode == 401) {
        // Unauthorized
        print('❌ ERROR 401: Unauthorized');
        print('   - Token may be expired or invalid');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      } else if (response.statusCode == 404) {
        // Route not found
        print('❌ ERROR 404: Route not found');
        print('   - Backend endpoint may not exist');
        print('   - Check API URL: ${ApiConfig.baseUrl}/api/auth/change_password');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backend endpoint not found (404)'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      } else if (response.statusCode == 400) {
        // Bad request
        print('❌ ERROR 400: Bad Request');
        try {
          final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage = responseBody['message'] ?? 'Invalid request';
          print('   - Error message: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        } catch (e) {
          print('   - Could not parse error body: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid current password or weak new password'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      } else {
        // Other errors
        print('❌ ERROR ${response.statusCode}: Unexpected error');
        try {
          final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage = responseBody['message'] ?? 'Failed to update password';
          print('   - Error message: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        } catch (e) {
          print('   - Could not parse error body: $e');
          print('   - Raw response: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update password'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    } on TimeoutException {
      print('❌ EXCEPTION: Request timeout after retry');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server is waking up. Please try again in a few seconds.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      print('❌ EXCEPTION: $e');
      print('   - Type: ${e.runtimeType}');
      print('   - Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Build password input field with visibility toggle
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isPasswordVisible,
    required VoidCallback onVisibilityToggle,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isPasswordVisible,
          validator: validator,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: 'Enter ${label.toLowerCase()}',
            hintStyle: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E5F9A), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            suffixIcon: GestureDetector(
              onTap: onVisibilityToggle,
              child: Icon(
                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        if (helperText != null && helperText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 12,
              color: helperText.contains('✓')
                  ? Colors.green
                  : const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid = _formKey.currentState?.validate() ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          SafeArea(
            top: false,
            child: AppHeader(
              title: 'Reset Password',
              subtitle: 'Update your account credentials',
              showBack: true,
              onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Password input card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF000000).withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Current password field
                            _buildPasswordField(
                              label: 'Current Password',
                              controller: _currentPasswordController,
                              isPasswordVisible: _showCurrentPassword,
                              onVisibilityToggle: () {
                                setState(() => _showCurrentPassword = !_showCurrentPassword);
                              },
                              validator: _validateCurrentPassword,
                            ),
                            const SizedBox(height: 20),

                            // New password field
                            _buildPasswordField(
                              label: 'New Password',
                              controller: _newPasswordController,
                              isPasswordVisible: _showNewPassword,
                              onVisibilityToggle: () {
                                setState(() => _showNewPassword = !_showNewPassword);
                              },
                              validator: _validateNewPassword,
                              helperText: _getPasswordStrengthMessage(_newPasswordController.text),
                            ),
                            const SizedBox(height: 20),

                            // Confirm password field
                            _buildPasswordField(
                              label: 'Confirm New Password',
                              controller: _confirmPasswordController,
                              isPasswordVisible: _showConfirmPassword,
                              onVisibilityToggle: () {
                                setState(() => _showConfirmPassword = !_showConfirmPassword);
                              },
                              validator: _validateConfirmPassword,
                            ),
                            const SizedBox(height: 24),

                            // Password requirements section
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCF3E1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEDE7DA)),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Password Requirements',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF78450F),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...[
                                    '• Minimum 8 characters',
                                    '• One uppercase letter',
                                    '• One number',
                                  ].map((requirement) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      requirement,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF78450F),
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Update Password Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isLoading || !isFormValid) ? null : _submitPasswordReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E5F9A),
                            disabledBackgroundColor: const Color(0xFFD1D5DB),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xFF9CA3AF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Update Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
