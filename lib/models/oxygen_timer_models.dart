class OxygenTimerStartRequest {
  final String cylinderType;
  final double pressurePsi;
  final double totalOxygenContent;
  final double selectedFlowRate;
  final int durationSeconds;
  final String durationText;

  const OxygenTimerStartRequest({
    required this.cylinderType,
    required this.pressurePsi,
    required this.totalOxygenContent,
    required this.selectedFlowRate,
    required this.durationSeconds,
    required this.durationText,
  });

  Map<String, dynamic> toJson() {
    return {
      'cylinder_type': cylinderType,
      'pressure_psi': pressurePsi,
      'total_oxygen_content': totalOxygenContent,
      'selected_flow_rate': selectedFlowRate,
      'duration_seconds': durationSeconds,
      'duration_text': durationText,
    };
  }
}

class OxygenTimerActionResponse {
  final bool success;
  final String? message;
  final int? historyId;
  final Map<String, dynamic>? raw;

  const OxygenTimerActionResponse({
    required this.success,
    this.message,
    this.historyId,
    this.raw,
  });

  factory OxygenTimerActionResponse.fromJson(Map<String, dynamic> json) {
    return OxygenTimerActionResponse(
      success: json['success'] == true,
      message: json['message'] as String?,
      historyId: json['history_id'] is int
          ? json['history_id'] as int
          : int.tryParse('${json['history_id'] ?? ''}'),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'history_id': historyId,
      'raw': raw,
    };
  }
}

class OxygenTimerHistoryItem {
  final int id;
  final String? cylinderType;
  final double? pressurePsi;
  final double? totalOxygenContent;
  final double? selectedFlowRate;
  final int? durationSeconds;
  final String? durationText;
  final String? timerStatus;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? resumedAt;
  final DateTime? stoppedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const OxygenTimerHistoryItem({
    required this.id,
    this.cylinderType,
    this.pressurePsi,
    this.totalOxygenContent,
    this.selectedFlowRate,
    this.durationSeconds,
    this.durationText,
    this.timerStatus,
    this.startedAt,
    this.pausedAt,
    this.resumedAt,
    this.stoppedAt,
    this.completedAt,
    this.createdAt,
  });

  factory OxygenTimerHistoryItem.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse('$value');
    }

    int? parseInt(dynamic value) {
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse('$value');
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) {
        return null;
      }
      return DateTime.tryParse('$value');
    }

    return OxygenTimerHistoryItem(
      id: parseInt(json['id']) ?? 0,
      cylinderType: json['cylinder_type'] as String?,
      pressurePsi: parseDouble(json['pressure_psi']),
      totalOxygenContent: parseDouble(json['total_oxygen_content']),
      selectedFlowRate: parseDouble(json['selected_flow_rate']),
      durationSeconds: parseInt(json['duration_seconds']),
      durationText: json['duration_text'] as String?,
      timerStatus: json['timer_status'] as String?,
      startedAt: parseDateTime(json['started_at']),
      pausedAt: parseDateTime(json['paused_at']),
      resumedAt: parseDateTime(json['resumed_at']),
      stoppedAt: parseDateTime(json['stopped_at']),
      completedAt: parseDateTime(json['completed_at']),
      createdAt: parseDateTime(json['created_at']),
    );
  }
}