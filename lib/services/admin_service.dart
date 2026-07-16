import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class AdminService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$path'),
        headers: await _headers(),
      );

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...body};
      }

      return {
        'success': false,
        'status': response.statusCode,
        'message': body['message'] ?? body['error'] ?? 'Request failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDashboard() {
    return _get('/api/admin/dashboard');
  }

  static Future<Map<String, dynamic>> getUsers() {
    return _get('/api/admin/users');
  }

  static Future<Map<String, dynamic>> getCalculators() {
    return _get('/api/admin/calculators');
  }

  static Future<Map<String, dynamic>> getFeedback() {
    return _get('/api/admin/feedback');
  }

  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/admin/users/$userId'),
        headers: await _headers(),
      );

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...body};
      }

      return {
        'success': false,
        'status': response.statusCode,
        'message': body['message'] ?? body['error'] ?? 'Delete failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
