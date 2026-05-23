import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/oxygen_timer_models.dart';
import 'auth_service.dart';

class OxygenTimerApiService {
  static const Duration _timeout = Duration(seconds: 12);

  static Future<OxygenTimerActionResponse> startTimer(
    OxygenTimerStartRequest request,
  ) async {
    return _postAction('/api/oxygen/timer/start', request.toJson());
  }

  static Future<OxygenTimerActionResponse> pauseTimer(int historyId) async {
    return _postAction('/api/oxygen/timer/pause', {'history_id': historyId});
  }

  static Future<OxygenTimerActionResponse> resumeTimer(int historyId) async {
    return _postAction('/api/oxygen/timer/resume', {'history_id': historyId});
  }

  static Future<OxygenTimerActionResponse> stopTimer(int historyId) async {
    return _postAction('/api/oxygen/timer/stop', {'history_id': historyId});
  }

  static Future<OxygenTimerActionResponse> completeTimer(int historyId) async {
    return _postAction('/api/oxygen/timer/complete', {'history_id': historyId});
  }

  static Future<List<OxygenTimerHistoryItem>> fetchHistory() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/oxygen/timer/history');
    try {
      debugPrint('Oxygen timer history request: $uri');

      final token = await AuthService.getToken();
      debugPrint(
        'Oxygen timer history token: ${token == null ? 'NULL' : '${token.substring(0, 16)}...'}',
      );
      if (token == null || token.isEmpty) {
        debugPrint('Oxygen timer history skipped: missing auth token');
        return <OxygenTimerHistoryItem>[];
      }

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Timeout while fetching oxygen timer history');
      });

      debugPrint('Oxygen timer history response status: ${response.statusCode}');
      debugPrint('Oxygen timer history response body: ${response.body}');

      final decoded = jsonDecode(response.body);
      final entries = _extractHistoryList(decoded);
      return entries.map(OxygenTimerHistoryItem.fromJson).toList()
        ..sort((left, right) {
          final leftDate = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final rightDate = right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return rightDate.compareTo(leftDate);
        });
    } on TimeoutException catch (error) {
      debugPrint('Oxygen timer history timeout: $error');
      return <OxygenTimerHistoryItem>[];
    } catch (error) {
      debugPrint('Oxygen timer history error: $error');
      return <OxygenTimerHistoryItem>[];
    }
  }

  static Future<OxygenTimerActionResponse> _postAction(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    try {
      debugPrint('Oxygen timer request: $uri');
      debugPrint('Oxygen timer payload: ${jsonEncode(payload)}');

      final token = await AuthService.getToken();
      debugPrint(
        'Oxygen timer token: ${token == null ? 'NULL' : '${token.substring(0, 16)}...'}',
      );
      if (token == null || token.isEmpty) {
        debugPrint('Oxygen timer request skipped: missing auth token');
        return const OxygenTimerActionResponse(
          success: false,
          message: 'Authentication required',
        );
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
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Timeout while calling oxygen timer endpoint');
      });

      debugPrint('Oxygen timer response status: ${response.statusCode}');
      debugPrint('Oxygen timer response body: ${response.body}');

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return OxygenTimerActionResponse.fromJson(decoded);
        }

        return OxygenTimerActionResponse(
          success: false,
          message: decoded['message'] as String? ?? 'Request failed',
          raw: decoded,
        );
      }

      return const OxygenTimerActionResponse(
        success: false,
        message: 'Unexpected response shape',
      );
    } on TimeoutException catch (error) {
      debugPrint('Oxygen timer timeout: $error');
      return OxygenTimerActionResponse(
        success: false,
        message: 'Request timed out',
        raw: {'error': error.toString()},
      );
    } catch (error) {
      debugPrint('Oxygen timer error: $error');
      return OxygenTimerActionResponse(
        success: false,
        message: 'Failed to update oxygen timer',
        raw: {'error': error.toString()},
      );
    }
  }

  static List<Map<String, dynamic>> _extractHistoryList(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final history = decoded['history'];
      if (history is List) {
        return history
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .toList();
      }
    }

    return <Map<String, dynamic>>[];
  }
}