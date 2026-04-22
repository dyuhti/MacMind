import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const String _isLoggedInKey = "isLoggedIn";
  static const String _loggedInEmailKey = "loggedInEmail";
  static const String _rememberMeKey = "rememberMe";

  static Future<Map<String, dynamic>> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/send-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      return {"success": true};
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {"success": false, "error": body["error"] ?? "Failed to send OTP"};
    } catch (_) {
      return {"success": false, "error": "Failed to send OTP"};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp": otp,
      }),
    );

    if (response.statusCode == 200) {
      return {"success": true};
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {"success": false, "error": body["error"] ?? "Invalid OTP"};
    } catch (_) {
      return {"success": false, "error": "Invalid OTP"};
    }
  }

  static Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final url = Uri.parse("$baseUrl/api/auth/login");
      print('🔐 Login Request: $url');
      print('📧 Email: $email');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );
      
      print('📩 Login Response Status: ${response.statusCode}');
      print('📩 Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Save login status and email to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_loggedInEmailKey, email);
        await prefs.setBool(_rememberMeKey, rememberMe);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Login Error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> register(
      String fullName, String email, String password, {String? confirmPassword}) async {
    try {
      final url = Uri.parse("$baseUrl/api/auth/register");
      print('📝 Register Request: $url');
      print('👤 Full Name: $fullName');
      print('📧 Email: $email');
      
      final requestBody = {
        "full_name": fullName,
        "email": email,
        "password": password,
      };
      
      // Add confirm_password if provided
      if (confirmPassword != null) {
        requestBody["confirm_password"] = confirmPassword;
      } else {
        requestBody["confirm_password"] = password;
      }
      
      print('📤 Request Body: $requestBody');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('📩 Register Response Status: ${response.statusCode}');
      print('📩 Register Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return {"success": true};
      }

      String? error;
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          error = (body["message"] ?? body["error"])?.toString();
        }
      } catch (_) {
        // ignore JSON parsing issues
      }

      error ??= response.statusCode == 400
          ? "Invalid input. Please check your details."
          : "Failed to create account";

      return {"success": false, "error": error};
    } catch (e) {
      print('❌ Register Error: $e');
      return {
        "success": false,
        "error": "Network error. Please check your connection and try again.",
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
      String email, String newPassword) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "newPassword": newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return {"success": true};
    } else if (response.statusCode == 404) {
      return {"success": false, "error": "Email not found"};
    } else if (response.statusCode == 403) {
      return {"success": false, "error": "OTP verification required"};
    } else if (response.statusCode == 400) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return {"success": false, "error": body["error"] ?? "Failed to reset password"};
      } catch (_) {
        return {"success": false, "error": "Failed to reset password"};
      }
    } else {
      return {"success": false, "error": "Failed to reset password"};
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get logged in email
  static Future<String?> getLoggedInEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loggedInEmailKey);
  }

  // Get remember me flag
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  // Check if should auto-login on app launch
  static Future<bool> shouldAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    return isLoggedIn && rememberMe;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    // Always clear login status
    await prefs.setBool(_isLoggedInKey, false);

    // If rememberMe is false, clear email too
    if (!rememberMe) {
      await prefs.remove(_loggedInEmailKey);
    }
    // Otherwise keep loggedInEmail for case history sync

    // Always clear rememberMe flag on logout
    await prefs.remove(_rememberMeKey);
  }
}
