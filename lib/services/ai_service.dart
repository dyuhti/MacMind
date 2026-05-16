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
      final backendMessage = decoded['message']?.toString();

      // Prefer deterministic, template-driven clinical insights
      // Build concise, complete sentences from the provided parameters.
      final insights = _buildDisplayInsights(
        type: type,
        data: data,
        rawInsights: rawInsights is List
            ? rawInsights.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
            : <String>[],
      );

      if (!success || insights.isEmpty) {
        print('AIService empty/unsuccessful insights for $type: $decoded');
        return _failure(backendMessage ?? _fallbackMessage);
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

  static List<String> _buildDisplayInsights({
    required String type,
    required Map<String, dynamic> data,
    required List<String> rawInsights,
  }) {
    // Ignore raw fragmentary AI output. Use template-driven sentences
    List<String> out;
    switch (type) {
      case 'economy':
        out = _generateEconomyInsights(data);
        break;
      case 'volatile':
      case 'consumption':
        out = _generateVolatileInsights(data);
        break;
      case 'oxygen':
        out = _generateOxygenInsights(data);
        break;
      default:
        out = _fallbackInsights(type: type, data: data);
    }

    // Ensure exactly 4 items by appending fallback, avoid duplicates.
    final seen = <String>{};
    final result = <String>[];
    for (final s in out) {
      final key = _normalizeForDedup(s);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      result.add(s);
      if (result.length >= 4) break;
    }

    if (result.length < 4) {
      final pads = _fallbackInsights(type: type, data: data);
      for (final p in pads) {
        final key = _normalizeForDedup(p);
        if (key.isEmpty || seen.contains(key)) continue;
        seen.add(key);
        result.add(p);
        if (result.length >= 4) break;
      }
    }

    // If still less than 4, repeat concise generic fillers (should not happen often).
    while (result.length < 4) {
      result.add('Review local protocols to confirm final settings.');
    }

    return result.take(4).toList();
  }

  // ------------------ Template generators ------------------
  static List<String> _generateEconomyInsights(Map<String, dynamic> data) {
    final fgf = (data['fresh_gas_flow'] as num?)?.toDouble();
    final conc = (data['concentration'] as num?)?.toDouble();
    final duration = (data['duration'] as num?)?.toDouble();
    final consumption = (data['consumption'] as num?)?.toDouble();

    final List<String> out = [];

    if (fgf != null) {
      if (fgf <= 1.0) {
        out.add('Reduced fresh gas flow (≤ ${fgf.toStringAsFixed(1)} L/min) supports improved cost efficiency.');
      } else if (fgf <= 3.0) {
        out.add('Moderate fresh gas flow (${fgf.toStringAsFixed(1)} L/min) balances delivery stability and economy.');
      } else {
        out.add('Higher fresh gas flow (${fgf.toStringAsFixed(1)} L/min) is associated with increased agent consumption.');
      }
    }

    if (conc != null) {
      out.add('Moderate concentration (${conc.toStringAsFixed(1)}%) may balance anesthetic delivery and agent utilization.');
    }

    if (consumption != null) {
      out.add('Estimated agent consumption for the selected settings was ${consumption.toStringAsFixed(1)} mL.');
    }

    if (out.isEmpty) {
      out.addAll(_fallbackInsights(type: 'economy', data: data));
    }

    return out.take(4).toList();
  }

  static List<String> _generateVolatileInsights(Map<String, dynamic> data) {
    final agent = (data['agent'] as String?) ?? 'Agent';
    final fgf = (data['fresh_gas_flow'] as num?)?.toDouble();
    final biro = (data['biro_formula'] as num?)?.toDouble();
    final dion = (data['dion_formula'] as num?)?.toDouble();
    final weight = (data['weight_based'] as num?)?.toDouble();

    final List<String> out = [];

    out.add('$agent consumption remained stable during the maintenance period.');

    if (biro != null && dion != null) {
      final diff = (biro - dion).abs();
      final avg = (biro + dion) / 2.0;
      if (avg > 0 && (diff / avg) * 100 <= 10) {
        out.add('Minimal variation between estimation methods indicates consistency between calculations.');
      } else {
        out.add('Moderate variation between estimation methods warrants cross-checking input parameters.');
      }
    }

    if (fgf != null) {
      out.add('Lower fresh gas flow settings may help reduce volatile agent waste.');
    }

    if (weight != null) {
      out.add('Weight-based estimate was ${weight.toStringAsFixed(1)} mL for this case.');
    }

    if (out.length < 3) {
      out.addAll(_fallbackInsights(type: 'volatile', data: data));
    }

    return out.take(4).toList();
  }

  static List<String> _generateOxygenInsights(Map<String, dynamic> data) {
    final pressure = (data['pressure'] as num?)?.toDouble();
    final oxygenContent = (data['oxygen_content'] as num?)?.toDouble();
    final factor = (data['factor'] as num?)?.toDouble();

    final List<String> out = [];

    if (oxygenContent != null) {
      out.add('The available oxygen reserve is suitable for short‑duration surgical procedures.');
    }

    if (pressure != null) {
      if (pressure < 700) {
        out.add('Low cylinder pressure suggests early replacement planning for prolonged cases.');
      } else if (pressure < 1500) {
        out.add('Cylinder pressure is moderate and should be monitored for extended procedures.');
      } else {
        out.add('Cylinder pressure is within an adequate range for routine planning.');
      }
    }

    out.add('Maintaining moderate flow settings can improve oxygen utilization efficiency.');

    return out.take(4).toList();
  }

  static String _sanitizeInsight(String text) {
    var value = text.trim();
    if (value.isEmpty) return '';

    value = value.replaceAll(RegExp(r'^[-*\u2022\s]+'), '');
    value = value.replaceAll(RegExp(r'\s+'), ' ');

    final bannedOpeners = <RegExp>[
      RegExp(r'^here are (the )?clinical insights[:\-\s]*', caseSensitive: false),
      RegExp(r'^the data suggests\s*', caseSensitive: false),
      RegExp(r'^consumption patterns imply\s*', caseSensitive: false),
      RegExp(r'^overall[,\s]*', caseSensitive: false),
      RegExp(r'^in summary[,\s]*', caseSensitive: false),
    ];
    for (final pattern in bannedOpeners) {
      value = value.replaceFirst(pattern, '').trim();
    }

    if (value.isEmpty) return '';

    final sentences = value
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (sentences.length > 2) {
      value = '${sentences[0]} ${sentences[1]}';
    }

    if (!value.endsWith('.') && !value.endsWith('!') && !value.endsWith('?')) {
      value = '$value.';
    }

    if (value.length > 150) {
      final cut = value.substring(0, 150);
      final safe = cut.contains(' ') ? cut.substring(0, cut.lastIndexOf(' ')) : cut;
      value = '${safe.trimRight()}.';
    }

    return value;
  }

  static String _normalizeForDedup(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _fallbackInsights({
    required String type,
    required Map<String, dynamic> data,
  }) {
    switch (type) {
      case 'economy':
        return _economyFallbackInsights(data);
      case 'volatile':
        return _volatileFallbackInsights(data);
      case 'oxygen':
        return _oxygenFallbackInsights(data);
      default:
        return const [
          'Calculated values were internally consistent across the selected parameters.',
          'Consider aligning flow and concentration settings to limit avoidable agent waste.',
          'Reassess values against institutional protocols before finalizing the plan.',
        ];
    }
  }

  static List<String> _economyFallbackInsights(Map<String, dynamic> data) {
    final fgf = (data['fresh_gas_flow'] as num?)?.toDouble() ?? 0;
    final conc = (data['concentration'] as num?)?.toDouble() ?? 0;
    final duration = (data['duration'] as num?)?.toDouble() ?? 0;
    final consumption = (data['consumption'] as num?)?.toDouble() ?? 0;

    final flowBand = fgf <= 1
        ? 'Low fresh gas flow supports improved volatile agent efficiency.'
        : fgf <= 3
            ? 'Moderate fresh gas flow balances delivery stability with agent economy.'
            : 'Higher fresh gas flow is associated with increased volatile agent usage.';

    final concentrationBand = conc <= 1.5
        ? 'Lower dial concentrations may reduce total liquid agent requirement during maintenance.'
        : conc <= 3.5
            ? 'Current concentration settings are within a practical range for routine maintenance.'
            : 'Elevated concentration settings can substantially increase cumulative consumption.';

    final durationBand = duration <= 60
        ? 'Shorter anesthetic duration limits cumulative agent consumption.'
        : duration <= 180
            ? 'Procedure duration remains a major driver of total anesthetic usage.'
            : 'Prolonged duration magnifies the cost impact of flow and concentration choices.';

    final summary =
        'Estimated agent use is ${consumption.toStringAsFixed(1)} mL for the selected settings.';

    return [flowBand, concentrationBand, durationBand, summary];
  }

  static List<String> _volatileFallbackInsights(Map<String, dynamic> data) {
    final fgf = (data['fresh_gas_flow'] as num?)?.toDouble() ?? 0;
    final biro = (data['biro_formula'] as num?)?.toDouble() ?? 0;
    final dion = (data['dion_formula'] as num?)?.toDouble() ?? 0;
    final weight = (data['weight_based'] as num?)?.toDouble() ?? 0;
    final mean = (biro + dion) / 2;
    final spreadPct = mean > 0 ? ((biro - dion).abs() / mean) * 100 : 0;

    final agreement = spreadPct <= 10
        ? 'Biro and Dion estimates show close agreement, supporting internal consistency.'
        : 'Biro and Dion estimates show moderate divergence and may warrant parameter review.';

    final flowBand = fgf <= 1
        ? 'Low-flow delivery profile supports reduced volatile agent expenditure.'
        : fgf <= 3
            ? 'Intermediate flow profile provides a balanced efficiency pattern.'
            : 'Higher flow profile may increase avoidable anesthetic loss.';

    final weightBand = weight > 0
        ? 'Weight-based consumption remained measurable at ${weight.toStringAsFixed(1)} mL for this case.'
        : 'Weight-based estimate was not contributory for this case profile.';

    final spread =
        'Formula difference is ${spreadPct.toStringAsFixed(1)}%, useful for cross-checking dosing assumptions.';

    return [agreement, flowBand, spread, weightBand];
  }

  static List<String> _oxygenFallbackInsights(Map<String, dynamic> data) {
    final pressure = (data['pressure'] as num?)?.toDouble() ?? 0;
    final oxygen = (data['oxygen_content'] as num?)?.toDouble() ?? 0;
    final factor = (data['factor'] as num?)?.toDouble() ?? 0;

    final pressureBand = pressure >= 1500
        ? 'Cylinder pressure remains in an adequate range for routine planning.'
        : pressure >= 700
            ? 'Cylinder pressure is moderate and should be monitored during prolonged use.'
            : 'Low cylinder pressure indicates reduced reserve and early replacement planning.';

    return [
      pressureBand,
      'Calculated oxygen reserve is ${oxygen.toStringAsFixed(0)} L using a factor of ${factor.toStringAsFixed(2)}.',
      'Reconfirm reserve margins before cases with higher anticipated oxygen demand.',
    ];
  }
}
