enum TimerStatus { running, paused, stopped, completed }

class TimerData {
  final String timerId;
  final String cylinderType;
  final double pressurePsi;
  final double totalOxygenContent;
  final int flowRate;
  final int durationSeconds;
  final int? historyId;
  final int activeRowIndex;
  final DateTime startedAt;
  final String durationText;

  final DateTime? endTime;
  final int? pausedRemainingSeconds;
  final TimerStatus status;

  const TimerData({
    required this.timerId,
    required this.cylinderType,
    required this.pressurePsi,
    required this.totalOxygenContent,
    required this.flowRate,
    required this.durationSeconds,
    this.historyId,
    required this.activeRowIndex,
    required this.startedAt,
    required this.durationText,
    this.endTime,
    this.pausedRemainingSeconds,
    this.status = TimerStatus.running,
  });

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;

  int get remainingSeconds {
    if (status == TimerStatus.running && endTime != null) {
      final remaining = endTime!.difference(DateTime.now()).inSeconds;
      return remaining > 0 ? remaining : 0;
    }
    if (status == TimerStatus.paused) {
      return pausedRemainingSeconds ?? 0;
    }
    return 0;
  }

  TimerData copyWith({
    DateTime? endTime,
    int? pausedRemainingSeconds,
    TimerStatus? status,
    int? historyId,
  }) {
    return TimerData(
      timerId: timerId,
      cylinderType: cylinderType,
      pressurePsi: pressurePsi,
      totalOxygenContent: totalOxygenContent,
      flowRate: flowRate,
      durationSeconds: durationSeconds,
      historyId: historyId ?? this.historyId,
      activeRowIndex: activeRowIndex,
      startedAt: startedAt,
      durationText: durationText,
      endTime: endTime ?? this.endTime,
      pausedRemainingSeconds: pausedRemainingSeconds ?? this.pausedRemainingSeconds,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'timerId': timerId,
        'cylinderType': cylinderType,
        'pressurePsi': pressurePsi,
        'totalOxygenContent': totalOxygenContent,
        'flowRate': flowRate,
        'durationSeconds': durationSeconds,
        'historyId': historyId,
        'activeRowIndex': activeRowIndex,
        'startedAt': startedAt.toIso8601String(),
        'durationText': durationText,
        'endTime': endTime?.toIso8601String(),
        'pausedRemainingSeconds': pausedRemainingSeconds,
        'status': status.name,
      };

  factory TimerData.fromJson(Map<String, dynamic> json) => TimerData(
        timerId: json['timerId'] as String,
        cylinderType: json['cylinderType'] as String,
        pressurePsi: (json['pressurePsi'] as num).toDouble(),
        totalOxygenContent: (json['totalOxygenContent'] as num).toDouble(),
        flowRate: json['flowRate'] as int,
        durationSeconds: json['durationSeconds'] as int,
        historyId: json['historyId'] as int?,
        activeRowIndex: json['activeRowIndex'] as int,
        startedAt: DateTime.parse(json['startedAt'] as String),
        durationText: json['durationText'] as String? ?? '',
        endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
        pausedRemainingSeconds: json['pausedRemainingSeconds'] as int?,
        status: TimerStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TimerStatus.running,
        ),
      );
}
