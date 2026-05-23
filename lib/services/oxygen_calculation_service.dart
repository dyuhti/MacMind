import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class OxygenCalculationService {
  static Future<Map<String, dynamic>> saveCalculation({
    required String cylinderType,
    required double pressurePsi,
    required double totalOxygenContent,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/oxygen/save');

    final payload = <String, dynamic>{
      'cylinder_type': cylinderType,
      'pressure_psi': pressurePsi,
      'total_oxygen_content': totalOxygenContent,
    };

    try {
      debugPrint('🧪 Oxygen save request: $uri');
      debugPrint('🧪 Oxygen save payload: ${jsonEncode(payload)}');

      final token = await AuthService.getToken();
      debugPrint(
        '🧪 Oxygen save token: ${token == null ? 'NULL' : '${token.substring(0, 16)}...'}',
      );
      if (token == null || token.isEmpty) {
        debugPrint('🧪 Oxygen save skipped: missing auth token');
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12), onTimeout: () {
        throw TimeoutException('Timeout while saving oxygen calculation');
      });

      debugPrint('🧪 Oxygen save response status: ${response.statusCode}');
      debugPrint('🧪 Oxygen save response body: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (error) {
        return {
          'success': false,
          'message': 'Invalid server response',
          'error': error.toString(),
        };
      }

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'success': false,
        'message': 'Unexpected response shape',
      };
    } on TimeoutException catch (error) {
      debugPrint('🧪 Oxygen save timeout: $error');
      return {
        'success': false,
        'message': 'Request timed out',
        'error': error.toString(),
      };
    } catch (error) {
      debugPrint('🧪 Oxygen save error: $error');
      return {
        'success': false,
        'message': 'Failed to save calculation',
        'error': error.toString(),
      };
    }
  }
}