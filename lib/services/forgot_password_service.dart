import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ForgotPasswordService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Send OTP to user's email
  /// Returns: {success: true, message: "...", email: "..."} or {success: false, message: "..."}
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/send-otp');
      print('📧 Sending OTP to: $email');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('📩 Send OTP Response Status: ${response.statusCode}');
      print('📩 Send OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': body['message'] ?? 'OTP sent successfully',
          'email': body['email'] ?? email,
        };
      }

      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to send OTP',
        };
      } catch (_) {
        return {
          'success': false,
          'message': 'Failed to send OTP. Please try again.',
        };
      }
    } catch (e) {
      print('❌ Send OTP Error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  /// Verify OTP and reset password
  /// Returns: {success: true, message: "..."} or {success: false, message: "..."}
  static Future<Map<String, dynamic>> resetPasswordWithOtp(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/reset-password');
      print('🔐 Resetting password with OTP');
      print('📧 Email: $email');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      );

      print('📩 Reset Password Response Status: ${response.statusCode}');
      print('📩 Reset Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': body['message'] ?? 'Password reset successfully',
        };
      }

      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to reset password',
        };
      } catch (_) {
        return {
          'success': false,
          'message': 'Failed to reset password. Please try again.',
        };
      }
    } catch (e) {
      print('❌ Reset Password Error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }
}
