import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_data.dart';
import '../services/notification_service.dart';

class TimerProvider extends ChangeNotifier {
  static const String _activeTimersKey = 'active_timers';

  Map<String, TimerData> _timers = {};
  Timer? _ticker;

  Map<String, TimerData> get timers => Map.unmodifiable(_timers);
  List<TimerData> get activeTimers =>
      _timers.values.where((t) => t.isRunning || t.isPaused).toList();
  bool get hasActiveTimers => activeTimers.isNotEmpty;

  TimerProvider() {
    _loadTimers();
  }

  Future<void> _loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeTimersKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        final map = <String, TimerData>{};
        for (final item in decoded) {
          final timer = TimerData.fromJson(item as Map<String, dynamic>);
          if (timer.isRunning || timer.isPaused) {
            map[timer.timerId] = timer;
          }
        }
        _timers = map;
      } catch (e) {
        debugPrint('TimerProvider: failed to decode timers: $e');
      }
    }

    _migrateLegacyTimer();

    _startTickerIfNeeded();
    notifyListeners();
  }

  Future<void> _migrateLegacyTimer() async {
    if (_timers.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final state = prefs.getString(NotificationService.oxygenTimerStateKey);
    if (state == null) return;

    final endTimeMillis = prefs.getInt(NotificationService.oxygenTimerEndKey);
    final remainingSeconds = prefs.getInt(NotificationService.oxygenTimerRemainingKey);
    final durationSeconds = prefs.getInt(NotificationService.oxygenTimerDurationKey);
    final activeRowIndex = prefs.getInt(NotificationService.oxygenTimerRowIndexKey);
    final flowRate = prefs.getInt(NotificationService.oxygenTimerFlowRateKey);
    final historyId = prefs.getInt(NotificationService.oxygenTimerHistoryIdKey);
    final cylinderType = prefs.getString(NotificationService.oxygenTimerCylinderTypeKey);
    final pressurePsi = prefs.getDouble(NotificationService.oxygenTimerPressurePsiKey);
    final totalContent = prefs.getDouble(NotificationService.oxygenTimerTotalContentKey);

    if (cylinderType == null || durationSeconds == null) return;

    final now = DateTime.now();
    final timerId = _generateId();

    if (state == NotificationService.timerStateRunning && endTimeMillis != null) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      final remaining = endTime.difference(now).inSeconds;
      if (remaining <= 0) return;

      _timers[timerId] = TimerData(
        timerId: timerId,
        cylinderType: cylinderType,
        pressurePsi: pressurePsi ?? 0,
        totalOxygenContent: totalContent ?? 0,
        flowRate: flowRate ?? (activeRowIndex ?? 0) + 1,
        durationSeconds: durationSeconds,
        historyId: historyId,
        activeRowIndex: activeRowIndex ?? 0,
        startedAt: endTime.subtract(Duration(seconds: durationSeconds)),
        durationText: '',
        endTime: endTime,
        status: TimerStatus.running,
      );
      await _persist();
    } else if (state == NotificationService.timerStatePaused && remainingSeconds != null) {
      _timers[timerId] = TimerData(
        timerId: timerId,
        cylinderType: cylinderType,
        pressurePsi: pressurePsi ?? 0,
        totalOxygenContent: totalContent ?? 0,
        flowRate: flowRate ?? (activeRowIndex ?? 0) + 1,
        durationSeconds: durationSeconds,
        historyId: historyId,
        activeRowIndex: activeRowIndex ?? 0,
        startedAt: now,
        durationText: '',
        pausedRemainingSeconds: remainingSeconds,
        status: TimerStatus.paused,
      );
      await _persist();
    }
  }

  void addTimer(TimerData timer) {
    _timers[timer.timerId] = timer;
    _persist();
    _startTickerIfNeeded();
    notifyListeners();
  }

  void updateTimer(TimerData timer) {
    if (_timers.containsKey(timer.timerId)) {
      _timers[timer.timerId] = timer;
      _persist();
      _startTickerIfNeeded();
      notifyListeners();
    }
  }

  void removeTimer(String timerId) {
    _timers.remove(timerId);
    _persist();
    if (_timers.isEmpty) {
      _stopTicker();
    }
    notifyListeners();
  }

  void clearCompleted() {
    _timers.removeWhere((_, t) => t.status == TimerStatus.completed);
    _persist();
    notifyListeners();
  }

  String _generateId() => 'timer_${DateTime.now().millisecondsSinceEpoch}_${_timers.length}';

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _timers.values
        .where((t) => t.isRunning || t.isPaused)
        .map((t) => t.toJson())
        .toList();
    await prefs.setString(_activeTimersKey, jsonEncode(list));
  }

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

    final completedIds = <String>[];
    for (final entry in _timers.entries) {
      if (entry.value.isRunning && entry.value.remainingSeconds <= 0) {
        completedIds.add(entry.key);
      }
    }

    if (completedIds.isNotEmpty) {
      for (final id in completedIds) {
        _timers.remove(id);
      }
      _persist();
      if (_timers.isEmpty) _stopTicker();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
