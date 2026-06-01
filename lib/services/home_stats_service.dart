import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class HomeStatsData {
  final int? totalCalculations;
  final int? savedRecords;
  final int? todaysCalculations;
  final String? mostUsedModuleTitle;

  const HomeStatsData({
    required this.totalCalculations,
    required this.savedRecords,
    required this.todaysCalculations,
    required this.mostUsedModuleTitle,
  });

  const HomeStatsData.unavailable()
      : totalCalculations = null,
        savedRecords = null,
        todaysCalculations = null,
        mostUsedModuleTitle = null;
}

class HomeStatsService {
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  static void notifyStatsRefresh() {
    refreshNotifier.value += 1;
  }

  static Future<HomeStatsData> fetchHomeStats() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return const HomeStatsData.unavailable();
      }

      final aggregated = await _tryFetchAggregatedStats(token);
      if (aggregated != null) {
        return aggregated;
      }

      return await _fallbackFromExistingHistoryEndpoints(token);
    } catch (error) {
      debugPrint('Home stats fetch error: $error');
      return const HomeStatsData.unavailable();
    }
  }

  static Future<HomeStatsData?> _tryFetchAggregatedStats(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/calculator/stats');

    try {
      final response = await http.get(
        uri,
        headers: _headers(token),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final stats = decoded['stats'];
      if (stats is! Map<String, dynamic>) {
        return null;
      }

      final mostUsedModule = stats['most_used_module'];
      final mostUsedModuleTitle = mostUsedModule is Map<String, dynamic>
          ? mostUsedModule['title']?.toString()
          : null;

      return HomeStatsData(
        totalCalculations: int.tryParse('${stats['total_calculations'] ?? ''}'),
        savedRecords: int.tryParse('${stats['saved_records'] ?? ''}'),
        todaysCalculations: int.tryParse('${stats['todays_calculations'] ?? ''}'),
        mostUsedModuleTitle: mostUsedModuleTitle,
      );
    } catch (error) {
      debugPrint('Aggregated stats unavailable, falling back: $error');
      return null;
    }
  }

  static Future<HomeStatsData> _fallbackFromExistingHistoryEndpoints(String token) async {
    final caseUri = Uri.parse('${ApiConfig.baseUrl}/api/calculator/cases');
    final oxygenUri = Uri.parse('${ApiConfig.baseUrl}/api/oxygen/history');

    try {
      final responses = await Future.wait([
        http.get(caseUri, headers: _headers(token)),
        http.get(oxygenUri, headers: _headers(token)),
      ]).timeout(const Duration(seconds: 15));

      final cases = _extractList(responses[0].body, 'cases');
      final oxygenHistory = _extractList(responses[1].body, 'history');

      final today = DateTime.now();
      final caseTodayCount = _countItemsCreatedToday(cases, 'created_at', today);
      final oxygenTodayCount = _countItemsCreatedToday(oxygenHistory, 'created_at', today);

      final caseCount = cases.length;
      final oxygenCount = oxygenHistory.length;
      final total = caseCount + oxygenCount;
      final mostUsedModuleTitle = total == 0
          ? null
          : (oxygenCount > caseCount
              ? 'Oxygen Cylinder Duration'
              : 'Volatile Anesthetic Consumption');

      return HomeStatsData(
        totalCalculations: total,
        savedRecords: caseCount,
        todaysCalculations: caseTodayCount + oxygenTodayCount,
        mostUsedModuleTitle: mostUsedModuleTitle,
      );
    } catch (error) {
      debugPrint('Fallback stats fetch error: $error');
      return const HomeStatsData.unavailable();
    }
  }

  static Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static List<Map<String, dynamic>> _extractList(String body, String key) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final value = decoded[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    }

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  static int _countItemsCreatedToday(
    List<Map<String, dynamic>> items,
    String dateKey,
    DateTime today,
  ) {
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return items.where((item) {
      final createdAt = DateTime.tryParse('${item[dateKey] ?? ''}');
      if (createdAt == null) {
        return false;
      }
      return !createdAt.isBefore(startOfDay) && createdAt.isBefore(endOfDay);
    }).length;
  }
}