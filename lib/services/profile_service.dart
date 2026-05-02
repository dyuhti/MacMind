import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'user_session.dart';

class ProfileService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Fetch profile from backend: GET /api/profile
  /// Returns profile data from users table (name, email only).
  /// Role and hospital are not returned from backend - UI manages them as optional fields.
  static Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      // Get stored authentication token
      final token = await AuthService.getToken();
      print('🔑 Token retrieved: ${token != null ? token.substring(0, 20) + "..." : "NULL"}');
      
      if (token == null) {
        print('❌ No authentication token found. User may not be logged in.');
        return null;
      }

      final url = '$_baseUrl/api/profile';
      print('📡 Fetching profile from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 Fetch profile status: ${response.statusCode}');
      print('📦 Fetch profile body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Profile data received: $data');
        
        // Backend returns only name and email from users table
        // UI will leave role and hospital empty (optional fields)
        final result = {
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'role': '',  // Not persisted in database
          'hospital': '',  // Not persisted in database
        };
        print('✅ Processed profile: $result');
        return result;
      } else if (response.statusCode == 401) {
        print('⚠️  Unauthorized (401) - Token may have expired');
        // Clear token on 401
        await AuthService.logout();
      } else if (response.statusCode == 404) {
        print('⚠️  User not found (404)');
      }
      print('❌ Fetch failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Error fetching profile: $e');
      return null;
    }
  }

  /// Hydrate the global user session from the backend profile response.
  /// This is used at app startup so the UI can show the real user name after relaunch.
  static Future<void> hydrateUserSession() async {
    final data = await fetchProfile();
    if (data == null) {
      return;
    }

    final name = data['name']?.toString().trim();
    final email = data['email']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      UserSession.name = name;
    }

    if (email != null && email.isNotEmpty) {
      UserSession.email = email;
    }
  }

  /// Update profile on backend: PUT /api/profile
  /// Only name and email are persisted (stored in users table).
  /// Role and hospital are accepted but ignored by backend.
  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      // Get stored authentication token
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ No authentication token found. User may not be logged in.');
        return false;
      }

      // Send all fields to backend, but backend will only persist name and email
      final response = await http.put(
        Uri.parse('$_baseUrl/api/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      print('✏️  Update profile status: ${response.statusCode}');
      print('📦 Update profile body: ${response.body}');
      
      if (response.statusCode == 401) {
        print('⚠️  Unauthorized - Token may have expired');
        // Clear token on 401
        await AuthService.logout();
      }
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error updating profile: $e');
      return false;
    }
  }
}
