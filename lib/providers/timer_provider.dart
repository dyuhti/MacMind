import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/timer_data.dart';
import '../services/native_timer_bridge.dart';

class TimerProvider extends ChangeNotifier {
  Map<String, TimerData> _timers = {};
  Timer? _ticker;

  Map<String, TimerData> get timers => Map.unmodifiable(_timers);
  List<TimerData> get activeTimers =>
      _timers.values.where((t) => t.isRunning || t.isPaused).toList();
  bool get hasActiveTimers => activeTimers.isNotEmpty;

  TimerData? getTimerForRow(int rowIndex) {
    try {
      return _timers.values.firstWhere((t) => t.activeRowIndex == rowIndex);
    } catch (_) {
      return null;
    }
  }

  TimerProvider() {
    _loadTimersFromNative();
  }

  Future<void> _loadTimersFromNative() async {
    try {
      final nativeTimers = await NativeTimerBridge.getAllTimers();
      final now = DateTime.now();
      final map = <String, TimerData>{};

      for (final nt in nativeTimers) {
        if (!nt.isActive) continue;

        final startTime = DateTime.fromMillisecondsSinceEpoch(nt.startTimestamp);
        final endTime = DateTime.fromMillisecondsSinceEpoch(nt.finishTimestamp);

        if (nt.isRunning && endTime.isBefore(now)) continue;

        map[nt.timerId] = TimerData(
          timerId: nt.timerId,
          cylinderType: nt.cylinderType,
          pressurePsi: 0,
          totalOxygenContent: 0,
          flowRate: nt.flowRate,
          durationSeconds: nt.durationSeconds,
          activeRowIndex: nt.activeRowIndex,
          startedAt: startTime,
          durationText: _formatDuration(nt.durationSeconds),
          endTime: nt.isRunning ? endTime : null,
          pausedRemainingSeconds: nt.isPaused ? nt.remainingSeconds : null,
          status: nt.isRunning ? TimerStatus.running : TimerStatus.paused,
        );
      }

      _timers = map;
    } catch (e) {
      debugPrint('TimerProvider: failed to load timers from native: $e');
    }

    _startTickerIfNeeded();
    notifyListeners();
  }

  void addTimer(TimerData timer) {
    _timers[timer.timerId] = timer;
    _startTickerIfNeeded();
    notifyListeners();
  }

  void updateTimer(TimerData timer) {
    if (_timers.containsKey(timer.timerId)) {
      _timers[timer.timerId] = timer;
      _startTickerIfNeeded();
      notifyListeners();
    }
  }

  void removeTimer(String timerId) {
    _timers.remove(timerId);
    if (_timers.isEmpty) _stopTicker();
    notifyListeners();
  }

  void clearCompleted() {
    _timers.removeWhere((_, t) => t.status == TimerStatus.completed);
    notifyListeners();
  }

  String generateTimerId() =>
      'timer_${DateTime.now().millisecondsSinceEpoch}_${_timers.length}';

  void _startTickerIfNeeded() {
    if (_ticker != null) return;
    final hasRunning = _timers.values.any((t) => t.isRunning);
    if (!hasRunning) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTick();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onTick() {
    final hasRunning = _timers.values.any((t) => t.isRunning);
    if (!hasRunning) {
      _stopTicker();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      final parts = <String>['${hours}h', '${minutes}m'];
      if (seconds > 0) parts.add('${seconds}s');
      return parts.join(' ');
    }
    if (seconds > 0) return '${minutes}m ${seconds}s';
    return '${minutes}m';
  }
}
