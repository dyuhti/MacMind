import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class AIService {
  static const String _baseUrl = 'https://med-calci-backend-new.onrender.com';
  static const Duration _timeout = Duration(seconds: 15);
  static const String _fallbackMessage =
      'AI clinical insights are temporarily unavailable.';

  static Future<Map<String, dynamic>> fetchEconomyInsights({
    required String agent,
    required double freshGasFlow,
    required double concentration,
    required double duration,
    required double consumption,
  }) {
    return _fetchClinicalInsights(
      type: 'economy',
      data: {
        'agent': agent,
        'fresh_gas_flow': freshGasFlow,
        'concentration': concentration,
        'duration': duration,
        'consumption': consumption,
      },
    );
  }

  static Future<Map<String, dynamic>> fetchOxygenInsights({
    required String cylinderType,
    required double pressure,
    required double oxygenContent,
    required double factor,
  }) {
    return _fetchClinicalInsights(
      type: 'oxygen',
      data: {
        'cylinder_type': cylinderType,
        'pressure': pressure,
        'oxygen_content': oxygenContent,
        'factor': factor,
      },
    );
  }

  static Future<Map<String, dynamic>> fetchVolatileInsights({
    required String agent,
    required double freshGasFlow,
    required double concentration,
    required double duration,
    required double biroFormula,
    required double dionFormula,
    required double weightBased,
  }) {
    return _fetchClinicalInsights(
      type: 'volatile',
      data: {
        'agent': agent,
        'fresh_gas_flow': freshGasFlow,
        'concentration': concentration,
        'duration': duration,
        'biro_formula': biroFormula,
        'dion_formula': dionFormula,
        'weight_based': weightBased,
      },
    );
  }

  static Future<Map<String, dynamic>> _fetchClinicalInsights({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      print('AIService: Missing auth token for $type insights');
      return _failure(_fallbackMessage);
    }

    final uri = Uri.parse('$_baseUrl/api/ai/clinical-insight');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'type': type, 'data': data}),
          )
          .timeout(_timeout, onTimeout: () {
        print('AIService timeout: $type request exceeded ${_timeout.inSeconds}s');
        throw TimeoutException('Timeout while fetching AI insights');
      });

      if (response.statusCode < 200 || response.statusCode >= 300) {
        print(
          'AIService API failure: status=${response.statusCode}, type=$type, body=${response.body}',
        );
        return _failure(_fallbackMessage);
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (e) {
        print('AIService invalid JSON for $type: $e | body=${response.body}');
        return _failure(_fallbackMessage);
      }

      if (decoded is! Map<String, dynamic>) {
        print('AIService invalid response shape for $type: ${decoded.runtimeType}');
        return _failure(_fallbackMessage);
      }

      final success = decoded['success'] == true;
      final rawInsights = decoded['insights'];

      final insights = rawInsights is List
          ? rawInsights
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .take(5)
              .toList()
          : <String>[];

      if (!success || insights.isEmpty) {
        print('AIService empty/unsuccessful insights for $type: $decoded');
        return _failure(_fallbackMessage);
      }

      return {'success': true, 'insights': insights};
    } on TimeoutException catch (e) {
      print('AIService timeout failure for $type: $e');
      return _failure(_fallbackMessage);
    } catch (e) {
      print('AIService unexpected failure for $type: $e');
      return _failure(_fallbackMessage);
    }
  }

  static Map<String, dynamic> _failure(String message) {
    return {
      'success': false,
      'insights': <String>[],
      'message': message,
    };
  }
}
