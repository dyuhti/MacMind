import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

/// Service layer for all /api/admin/* endpoints.
/// Every call attaches the stored JWT and propagates 403 as a typed error.
class AdminService {
  static String get _baseUrl => ApiConfig.baseUrl;

  // ── HTTP helpers ──────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parseResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, ...body};
    }

    if (response.statusCode == 403) {
      return {
        'success': false,
        'status': 403,
        'message': 'You do not have admin permission.',
      };
    }

    return {
      'success': false,
      'status': response.statusCode,
      'message': body['message'] ?? body['error'] ?? 'Request failed',
    };
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$path'),
        headers: await _headers(),
      );
      return _parseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl$path'),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      return _parseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$path'),
        headers: await _headers(),
      );
      return _parseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboard() =>
      _get('/api/admin/dashboard');

  // ── Analytics ─────────────────────────────────────────────────────────────

  /// Returns total counts + entries_per_day + top_calculators.
  /// [days] controls the time-series window (7–90).
  static Future<Map<String, dynamic>> getAnalyticsSummary({int days = 30}) =>
      _get('/api/admin/analytics/summary?days=$days');

  // ── Users ─────────────────────────────────────────────────────────────────

  /// Paginated + searchable user list.
  static Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int perPage = 20,
    String search = '',
  }) {
    final q = Uri(queryParameters: {
      'page': '$page',
      'per_page': '$perPage',
      if (search.isNotEmpty) 'search': search,
    }).query;
    return _get('/api/admin/users?$q');
  }

  /// Single user detail with case + oxygen counts.
  static Future<Map<String, dynamic>> getUserDetail(int userId) =>
      _get('/api/admin/users/$userId');

  /// Deactivate or reactivate a user.
  static Future<Map<String, dynamic>> updateUserActive(
    int userId, {
    required bool isActive,
  }) =>
      _patch('/api/admin/users/$userId', {'is_active': isActive});

  /// Delete a user permanently.
  static Future<Map<String, dynamic>> deleteUser(int userId) =>
      _delete('/api/admin/users/$userId');

  // ── Entries ───────────────────────────────────────────────────────────────

  /// Paginated entry list. [type] = 'case' | 'oxygen' | 'all'.
  static Future<Map<String, dynamic>> getEntries({
    String type = 'all',
    int page = 1,
    int perPage = 20,
    String search = '',
  }) {
    final q = Uri(queryParameters: {
      'type': type,
      'page': '$page',
      'per_page': '$perPage',
      if (search.isNotEmpty) 'search': search,
    }).query;
    return _get('/api/admin/entries?$q');
  }

  /// Edit a case entry (patient_name and/or notes).
  static Future<Map<String, dynamic>> updateEntry(
    int entryId,
    Map<String, dynamic> fields, {
    String type = 'case',
  }) =>
      _patch('/api/admin/entries/$entryId?type=$type', fields);

  /// Delete an entry. [type] = 'case' | 'oxygen'.
  static Future<Map<String, dynamic>> deleteEntry(
    int entryId, {
    required String type,
  }) =>
      _delete('/api/admin/entries/$entryId?type=$type');

  // ── Calculators (legacy) ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getCalculators() =>
      _get('/api/admin/calculators');

  // ── Feedback ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getFeedback() =>
      _get('/api/admin/feedback');
}
