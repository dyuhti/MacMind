import 'package:flutter/services.dart';

class NativeTimerInfo {
  final String timerId;
  final int startTimestamp;
  final int finishTimestamp;
  final int durationSeconds;
  final int remainingSeconds;
  final String cylinderType;
  final int flowRate;
  final String status;
  final int notificationId;
  final int requestCode;
  final int activeRowIndex;

  const NativeTimerInfo({
    required this.timerId,
    required this.startTimestamp,
    required this.finishTimestamp,
    required this.durationSeconds,
    required this.remainingSeconds,
    required this.cylinderType,
    required this.flowRate,
    required this.status,
    required this.notificationId,
    required this.requestCode,
    this.activeRowIndex = 0,
  });

  bool get isRunning => status == 'running';
  bool get isPaused => status == 'paused';
  bool get isActive => isRunning || isPaused;

  factory NativeTimerInfo.fromMap(Map<String, dynamic> map) {
    return NativeTimerInfo(
      timerId: map['timerId'] as String,
      startTimestamp: (map['startTimestamp'] as num).toInt(),
      finishTimestamp: (map['finishTimestamp'] as num).toInt(),
      durationSeconds: (map['durationSeconds'] as num).toInt(),
      remainingSeconds: (map['remainingSeconds'] as num).toInt(),
      cylinderType: map['cylinderType'] as String,
      flowRate: (map['flowRate'] as num).toInt(),
      status: map['status'] as String,
      notificationId: (map['notificationId'] as num).toInt(),
      requestCode: (map['requestCode'] as num).toInt(),
      activeRowIndex: (map['activeRowIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class NativeTimerBridge {
  static const _channel = MethodChannel('com.example.med_calci_app/timer_bridge');

  static Future<void> startTimer({
    required String timerId,
    required int finishTimestamp,
    required String cylinderType,
    required int flowRate,
    required int durationSeconds,
    required int startTimestamp,
    int activeRowIndex = 0,
  }) async {
    await _channel.invokeMethod('startTimer', {
      'timerId': timerId,
      'finishTimestamp': finishTimestamp,
      'cylinderType': cylinderType,
      'flowRate': flowRate,
      'durationSeconds': durationSeconds,
      'startTimestamp': startTimestamp,
      'activeRowIndex': activeRowIndex,
    });
  }

  static Future<void> cancelTimer(String timerId) async {
    await _channel.invokeMethod('cancelTimer', {'timerId': timerId});
  }

  static Future<void> pauseTimer({
    required String timerId,
    required int remainingSeconds,
  }) async {
    await _channel.invokeMethod('pauseTimer', {
      'timerId': timerId,
      'remainingSeconds': remainingSeconds,
    });
  }

  static Future<void> resumeTimer({
    required String timerId,
    required int newFinishTimestamp,
  }) async {
    await _channel.invokeMethod('resumeTimer', {
      'timerId': timerId,
      'newFinishTimestamp': newFinishTimestamp,
    });
  }

  static Future<List<NativeTimerInfo>> getAllTimers() async {
    final result = await _channel.invokeMethod('getAllTimers');
    if (result == null) return [];
    final list = result as List<dynamic>;
    return list
        .map((e) => NativeTimerInfo.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deleteTimer(String timerId) async {
    await _channel.invokeMethod('deleteTimer', {'timerId': timerId});
  }

  static Future<void> markStopped(String timerId) async {
    await _channel.invokeMethod('markStopped', {'timerId': timerId});
  }
}
