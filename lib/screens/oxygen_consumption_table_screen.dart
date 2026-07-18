import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/oxygen_timer_models.dart';
import '../models/timer_data.dart';
import '../providers/timer_provider.dart';
import '../services/oxygen_timer_service.dart';
import '../services/native_timer_bridge.dart';
import '../widgets/app_header.dart';
import '../services/notification_service.dart';
import 'settings_screen.dart';
import 'timer_history_screen.dart';

class OxygenConsumptionTableScreen extends StatefulWidget {
  final String cylinderType;
  final double pressurePsi;
  final double totalContent;
  final String? timerId;

  const OxygenConsumptionTableScreen({
    super.key,
    required this.cylinderType,
    required this.pressurePsi,
    required this.totalContent,
    this.timerId,
  });

  @override
  State<OxygenConsumptionTableScreen> createState() => _OxygenConsumptionTableScreenState();
}

class _OxygenConsumptionTableScreenState extends State<OxygenConsumptionTableScreen>
    with WidgetsBindingObserver {
  int selectedIndex = -1;
  Timer? _countdownTimer;
  int _remainingTime = 0;
  bool _isTimerRunning = false;
  bool _isTimerPaused = false;
  bool _finalShown = false;
  int? _selectedFlowRate;
  int? _activeRowIndex;
  int? _historyId;
  Future<int?>? _pendingHistoryIdFuture;

  DateTime? _timerEndTime;
  int? _timerDurationSeconds;
  String? _timerId;
  bool _timerLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.timerId != null && !_timerLoaded) {
      _timerLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadTimerFromProvider();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isTimerRunning && _timerEndTime != null) {
          _startTicker();
          _syncRemainingTimeFromEndTime();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _countdownTimer?.cancel();
        break;
    }
  }

  void _loadTimerFromProvider() {
    final provider = context.read<TimerProvider>();
    final timer = provider.timers[widget.timerId];
    if (timer == null) return;

    if (timer.isRunning && timer.endTime != null) {
      final remaining = timer.endTime!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        unawaited(_handleTimerCompletion());
        return;
      }
      setState(() {
        _timerId = timer.timerId;
        _timerEndTime = timer.endTime;
        _timerDurationSeconds = timer.durationSeconds;
        _remainingTime = remaining;
        _isTimerRunning = true;
        _isTimerPaused = false;
        _finalShown = false;
        _activeRowIndex = timer.activeRowIndex;
        _selectedFlowRate = timer.flowRate;
        selectedIndex = timer.activeRowIndex;
        _historyId = timer.historyId;
      });
      _startTicker();
    } else if (timer.isPaused) {
      setState(() {
        _timerId = timer.timerId;
        _timerDurationSeconds = timer.durationSeconds;
        _remainingTime = timer.pausedRemainingSeconds ?? 0;
        _isTimerRunning = false;
        _isTimerPaused = true;
        _finalShown = false;
        _activeRowIndex = timer.activeRowIndex;
        _selectedFlowRate = timer.flowRate;
        selectedIndex = timer.activeRowIndex;
        _historyId = timer.historyId;
      });
    }
  }

  void _selectRow(int index) {
    final provider = context.read<TimerProvider>();
    final rowTimer = provider.getTimerForRow(index);

    if (rowTimer == null) {
      _countdownTimer?.cancel();
      setState(() {
        selectedIndex = index;
        _remainingTime = 0;
        _isTimerRunning = false;
        _isTimerPaused = false;
        _finalShown = false;
        _timerEndTime = null;
        _activeRowIndex = null;
        _selectedFlowRate = null;
        _timerDurationSeconds = null;
        _timerId = null;
      });
      return;
    }

    selectedIndex = index;
    _populateFromTimer(rowTimer);
  }

  void _populateFromTimer(TimerData timer) {
    _countdownTimer?.cancel();

    if (timer.isRunning && timer.endTime != null) {
      final remaining = timer.endTime!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        unawaited(_handleTimerCompletion());
        return;
      }
      setState(() {
        _timerId = timer.timerId;
        _timerEndTime = timer.endTime;
        _timerDurationSeconds = timer.durationSeconds;
        _remainingTime = remaining;
        _isTimerRunning = true;
        _isTimerPaused = false;
        _finalShown = false;
        _activeRowIndex = timer.activeRowIndex;
        _selectedFlowRate = timer.flowRate;
        _historyId = timer.historyId;
        selectedIndex = timer.activeRowIndex;
      });
      _startTicker();
    } else if (timer.isPaused) {
      setState(() {
        _timerId = timer.timerId;
        _timerDurationSeconds = timer.durationSeconds;
        _remainingTime = timer.pausedRemainingSeconds ?? 0;
        _isTimerRunning = false;
        _isTimerPaused = true;
        _finalShown = false;
        _activeRowIndex = timer.activeRowIndex;
        _selectedFlowRate = timer.flowRate;
        _historyId = timer.historyId;
        selectedIndex = timer.activeRowIndex;
      });
    }
  }

  void _syncRemainingTimeFromEndTime() {
    if (_timerEndTime == null || _timerDurationSeconds == null) {
      return;
    }

    final newRemaining = _timerEndTime!.difference(DateTime.now()).inSeconds;

    if (!mounted) {
      return;
    }

    setState(() {
      _remainingTime = newRemaining > 0 ? newRemaining : 0;
    });

    if (_remainingTime <= 0) {
      unawaited(_handleTimerCompletion());
      return;
    }

    _checkAlertTriggers();
  }

  String _formatCountdownDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _timerStatusLabel() {
    if (_isTimerRunning) {
      return 'Running';
    }
    if (_isTimerPaused) {
      return 'Paused';
    }
    return 'Stopped';
  }

  Color _timerStatusColor() {
    if (_isTimerRunning) {
      return const Color(0xFF16A34A);
    }
    if (_isTimerPaused) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFDC2626);
  }

  Color _timerStatusBackground() {
    if (_isTimerRunning) {
      return const Color(0xFFEAF8EF);
    }
    if (_isTimerPaused) {
      return const Color(0xFFFFF7ED);
    }
    return const Color(0xFFFEE2E2);
  }

  Color _timerStatusBorder() {
    if (_isTimerRunning) {
      return const Color(0xFFCDE8D7);
    }
    if (_isTimerPaused) {
      return const Color(0xFFFED7AA);
    }
    return const Color(0xFFFCA5A5);
  }

  Widget _buildStatusChip() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey<String>(_timerStatusLabel()),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _timerStatusBackground(),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _timerStatusBorder()),
        ),
        child: Text(
          _timerStatusLabel(),
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _timerStatusColor(),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTimerActionButton({
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    bool outlined = false,
  }) {
    final button = SizedBox(
      height: 40,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: foregroundColor,
                side: BorderSide(color: backgroundColor),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                elevation: 0,
                shadowColor: backgroundColor.withValues(alpha: 0.24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
    );

    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      scale: 1,
      child: button,
    );
  }

  Widget _buildTimerControls(List<_ConsumptionRowData> rows) {
    final isActiveRow = _activeRowIndex != null && _activeRowIndex == selectedIndex;
    final hasLocalTimer = _isTimerRunning || _isTimerPaused;

    if (hasLocalTimer && isActiveRow && _isTimerRunning) {
      return Row(
        children: [
          Expanded(
            child: _buildTimerActionButton(
              label: 'Pause',
              onPressed: _pauseTimer,
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildTimerActionButton(
              label: 'Stop',
              onPressed: _stopTimer,
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    if (hasLocalTimer && isActiveRow && _isTimerPaused) {
      return Row(
        children: [
          Expanded(
            child: _buildTimerActionButton(
              label: 'Resume',
              onPressed: _resumeTimer,
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildTimerActionButton(
              label: 'Reset',
              onPressed: _resetTimer,
              backgroundColor: const Color(0xFFD1D5DB),
              foregroundColor: const Color(0xFF334155),
              outlined: true,
            ),
          ),
        ],
      );
    }

    if (selectedIndex < 0) {
      return SizedBox(
        width: double.infinity,
        child: _buildTimerActionButton(
          label: 'Start Timer',
          onPressed: null,
          backgroundColor: const Color(0xFFD1D5DB),
          foregroundColor: const Color(0xFF9CA3AF),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: _buildTimerActionButton(
        label: 'Start Timer',
        onPressed: () => _startSelectedRowTimer(rows),
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _startSelectedRowTimer(List<_ConsumptionRowData> rows) {
    if (selectedIndex < 0 || selectedIndex >= rows.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a row first')),
      );
      return;
    }

    final row = rows[selectedIndex];
    _startTimer(row: row, index: selectedIndex);
  }

  void _startTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _syncRemainingTimeFromEndTime();
      _checkAlertTriggers();
    });
  }

  void _startTimer({required _ConsumptionRowData row, required int index}) {
    final durationInSeconds = (row.durationHr * 3600).round();
    if (durationInSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration must be greater than 0 seconds')),
      );
      return;
    }

    _countdownTimer?.cancel();

    final now = DateTime.now();
    final endTime = now.add(Duration(seconds: durationInSeconds));

    setState(() {
      _remainingTime = durationInSeconds;
      _isTimerRunning = true;
      _isTimerPaused = false;
      _finalShown = false;
      _selectedFlowRate = row.flowRate;
      _activeRowIndex = index;
      _timerEndTime = endTime;
      _timerDurationSeconds = durationInSeconds;
    });

    _startTicker();
    final timerId = 'timer_${DateTime.now().millisecondsSinceEpoch}';
    _timerId = timerId;
    unawaited(_persistRunningTimerState(endTime: endTime, durationSeconds: durationInSeconds, row: row, index: index));
    unawaited(_persistCylinderMetadata(timerId));
    _notifyProviderAdd(timerId: timerId, endTime: endTime, durationSeconds: durationInSeconds, row: row, index: index);
    unawaited(NativeTimerBridge.startTimer(
      timerId: timerId,
      finishTimestamp: endTime.millisecondsSinceEpoch,
      cylinderType: widget.cylinderType,
      flowRate: row.flowRate,
      durationSeconds: durationInSeconds,
      startTimestamp: now.millisecondsSinceEpoch,
      activeRowIndex: index,
    ));
    _pendingHistoryIdFuture = _createTimerHistoryRecord(
      row: row,
      durationSeconds: durationInSeconds,
      durationText: _formatDuration(row.durationHr),
    );
    unawaited(_pendingHistoryIdFuture!);
  }

  Future<void> _pauseTimer() async {
    if (!_isTimerRunning || _timerEndTime == null || _timerDurationSeconds == null) {
      return;
    }

    _countdownTimer?.cancel();
    final remainingSeconds = _timerEndTime!.difference(DateTime.now()).inSeconds;

    setState(() {
      _remainingTime = remainingSeconds > 0 ? remainingSeconds : 0;
      _timerEndTime = null;
      _isTimerRunning = false;
      _isTimerPaused = true;
    });

    _notifyProviderPause();
    unawaited(NativeTimerBridge.pauseTimer(
      timerId: _timerId!,
      remainingSeconds: _remainingTime,
    ));
    unawaited(_persistPausedTimerState(remainingSeconds: _remainingTime));
    unawaited(_sendTimerPauseUpdate());
  }

  Future<void> _resumeTimer() async {
    if (!_isTimerPaused || _remainingTime <= 0) {
      return;
    }

    final now = DateTime.now();
    final resumedEndTime = now.add(Duration(seconds: _remainingTime));

    setState(() {
      _timerEndTime = resumedEndTime;
      _isTimerRunning = true;
      _isTimerPaused = false;
      _finalShown = false;
    });

    _startTicker();
    unawaited(_persistRunningTimerState(
      endTime: resumedEndTime,
      durationSeconds: _timerDurationSeconds ?? _remainingTime,
      row: _ConsumptionRowData(
        flowRate: _selectedFlowRate ?? 1,
        durationMin: (_timerDurationSeconds ?? _remainingTime) / 60,
        durationHr: (_timerDurationSeconds ?? _remainingTime) / 3600,
      ),
      index: _activeRowIndex ?? selectedIndex,
    ));
    unawaited(_persistCylinderMetadata(_timerId ?? ''));
    _notifyProviderResume(resumedEndTime);
    unawaited(NativeTimerBridge.resumeTimer(
      timerId: _timerId!,
      newFinishTimestamp: resumedEndTime.millisecondsSinceEpoch,
    ));
    unawaited(_sendTimerResumeUpdate());
  }

  Future<void> _stopTimer() async {
    _countdownTimer?.cancel();
    _notifyProviderRemove();
    if (_timerId != null) {
      unawaited(NativeTimerBridge.markStopped(_timerId!));
    }
    setState(() {
      _remainingTime = 0;
      _isTimerRunning = false;
      _isTimerPaused = false;
      _finalShown = false;
      _timerEndTime = null;
      _activeRowIndex = null;
      _selectedFlowRate = null;
      _timerDurationSeconds = null;
    });
    unawaited(_sendTimerStopUpdate());
    unawaited(_clearPersistedTimerState());
  }

  void _checkAlertTriggers() {
    if (_timerDurationSeconds == null) {
      return;
    }

    if (!_finalShown && _remainingTime <= 0) {
      _handleTimerCompletion();
    }
  }

  Future<void> _handleTimerCompletion() async {
    if (_finalShown) {
      return;
    }

    _finalShown = true;
    _countdownTimer?.cancel();
    _timerEndTime = null;
    _notifyProviderRemove();

    setState(() {
      _remainingTime = 0;
      _isTimerRunning = false;
      _isTimerPaused = false;
    });

    if (_timerId != null) {
      unawaited(NativeTimerBridge.markStopped(_timerId!));
    }

    await _sendTimerCompleteUpdate();
    unawaited(_clearPersistedTimerState());
    unawaited(NotificationService().showTimerCompletionNotification());
    _showFinalAlert();
  }

  void _showFinalAlert() {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Oxygen Alert'),
            content: const Text('Oxygen supply exhausted'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                    _resetTimer(updateBackend: false);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _resetTimer({bool updateBackend = true}) async {
    _countdownTimer?.cancel();
    _notifyProviderRemove();
    if (_timerId != null) {
      unawaited(NativeTimerBridge.deleteTimer(_timerId!));
    }
    setState(() {
      _remainingTime = 0;
      _isTimerRunning = false;
      _isTimerPaused = false;
      _finalShown = false;
      _timerEndTime = null;
      _activeRowIndex = null;
      _selectedFlowRate = null;
      _timerDurationSeconds = null;
    });
    if (updateBackend) {
      unawaited(_sendTimerStopUpdate());
    }
    unawaited(_clearPersistedTimerState());
  }

  Future<void> _persistCylinderMetadata(String timerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(NotificationService.oxygenTimerCylinderTypeKey, widget.cylinderType);
    await prefs.setDouble(NotificationService.oxygenTimerPressurePsiKey, widget.pressurePsi);
    await prefs.setDouble(NotificationService.oxygenTimerTotalContentKey, widget.totalContent);
  }

  void _notifyProviderAdd({
    required String timerId,
    required DateTime endTime,
    required int durationSeconds,
    required _ConsumptionRowData row,
    required int index,
  }) {
    if (!mounted) return;
    final provider = context.read<TimerProvider>();
    provider.addTimer(TimerData(
      timerId: timerId,
      cylinderType: widget.cylinderType,
      pressurePsi: widget.pressurePsi,
      totalOxygenContent: widget.totalContent,
      flowRate: row.flowRate,
      durationSeconds: durationSeconds,
      activeRowIndex: index,
      startedAt: DateTime.now(),
      durationText: _formatDuration(row.durationHr),
      endTime: endTime,
      status: TimerStatus.running,
    ));
  }

  void _notifyProviderPause() {
    if (!mounted || _timerId == null) return;
    final provider = context.read<TimerProvider>();
    final existing = provider.timers[_timerId];
    if (existing != null) {
      provider.updateTimer(existing.copyWith(
        status: TimerStatus.paused,
        endTime: null,
        pausedRemainingSeconds: _remainingTime,
      ));
    }
  }

  void _notifyProviderResume(DateTime endTime) {
    if (!mounted || _timerId == null) return;
    final provider = context.read<TimerProvider>();
    final existing = provider.timers[_timerId];
    if (existing != null) {
      provider.updateTimer(existing.copyWith(
        status: TimerStatus.running,
        endTime: endTime,
        pausedRemainingSeconds: null,
      ));
    }
  }

  void _notifyProviderRemove() {
    if (!mounted || _timerId == null) return;
    context.read<TimerProvider>().removeTimer(_timerId!);
  }

  Future<void> _persistRunningTimerState({
    required DateTime endTime,
    required int durationSeconds,
    required _ConsumptionRowData row,
    required int index,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(NotificationService.oxygenTimerStateKey, NotificationService.timerStateRunning);
    await prefs.setInt(NotificationService.oxygenTimerEndKey, endTime.millisecondsSinceEpoch);
    await prefs.setInt(NotificationService.oxygenTimerRemainingKey, endTime.difference(DateTime.now()).inSeconds > 0 ? endTime.difference(DateTime.now()).inSeconds : 0);
    await prefs.setInt(NotificationService.oxygenTimerDurationKey, durationSeconds);
    await prefs.setInt(NotificationService.oxygenTimerRowIndexKey, index);
    await prefs.setInt(NotificationService.oxygenTimerFlowRateKey, row.flowRate);
  }

  Future<void> _persistPausedTimerState({required int remainingSeconds}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(NotificationService.oxygenTimerStateKey, NotificationService.timerStatePaused);
    await prefs.setInt(NotificationService.oxygenTimerRemainingKey, remainingSeconds > 0 ? remainingSeconds : 0);
    if (_timerDurationSeconds != null) {
      await prefs.setInt(NotificationService.oxygenTimerDurationKey, _timerDurationSeconds!);
    }
    if (_activeRowIndex != null) {
      await prefs.setInt(NotificationService.oxygenTimerRowIndexKey, _activeRowIndex!);
      await prefs.setInt(NotificationService.oxygenTimerFlowRateKey, _selectedFlowRate ?? _activeRowIndex! + 1);
    }
    await prefs.remove(NotificationService.oxygenTimerEndKey);
  }

  Future<void> _clearPersistedTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(NotificationService.oxygenTimerStateKey);
    await prefs.remove(NotificationService.oxygenTimerEndKey);
    await prefs.remove(NotificationService.oxygenTimerRemainingKey);
    await prefs.remove(NotificationService.oxygenTimerDurationKey);
    await prefs.remove(NotificationService.oxygenTimerRowIndexKey);
    await prefs.remove(NotificationService.oxygenTimerFlowRateKey);
    await prefs.remove(NotificationService.oxygenTimerHistoryIdKey);
    await prefs.remove(NotificationService.oxygenTimerCylinderTypeKey);
    await prefs.remove(NotificationService.oxygenTimerPressurePsiKey);
    await prefs.remove(NotificationService.oxygenTimerTotalContentKey);
  }

  Future<void> _persistHistoryId(int historyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(NotificationService.oxygenTimerHistoryIdKey, historyId);
  }

  Future<void> _clearHistoryId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(NotificationService.oxygenTimerHistoryIdKey);
  }

  Future<int?> _resolveHistoryId() async {
    if (_historyId != null) {
      return _historyId;
    }

    if (_pendingHistoryIdFuture != null) {
      _historyId = await _pendingHistoryIdFuture;
      if (_historyId != null) {
        await _persistHistoryId(_historyId!);
      }
    }

    if (_historyId != null) {
      return _historyId;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedHistoryId = prefs.getInt(NotificationService.oxygenTimerHistoryIdKey);
    if (storedHistoryId != null && storedHistoryId > 0) {
      _historyId = storedHistoryId;
      return _historyId;
    }

    return null;
  }

  Future<void> _showTimerApiFailure(String action, String message) async {
    debugPrint('$action failure: $message');
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action failed: $message')),
    );
  }

  Future<int?> _createTimerHistoryRecord({
    required _ConsumptionRowData row,
    required int durationSeconds,
    required String durationText,
  }) async {
    debugPrint('Selected Flow Rate: ${row.flowRate}');
    debugPrint('Duration Seconds: $durationSeconds');
    debugPrint('Duration Text: $durationText');

    final response = await OxygenTimerApiService.startTimer(
      OxygenTimerStartRequest(
        cylinderType: widget.cylinderType,
        pressurePsi: widget.pressurePsi,
        totalOxygenContent: widget.totalContent,
        selectedFlowRate: row.flowRate.toDouble(),
        durationSeconds: durationSeconds,
        durationText: durationText,
      ),
    );

    debugPrint('Start Success: ${response.success}');
    debugPrint('API Response: ${response.toJson()}');

    if (response.success && response.historyId != null) {
      _historyId = response.historyId;
      await _persistHistoryId(response.historyId!);
      debugPrint('History ID: ${response.historyId}');
      return response.historyId;
    }

    await _showTimerApiFailure('Start Timer', response.message ?? 'Unknown error');
    return null;
  }

  Future<void> _sendTimerPauseUpdate() async {
    final historyId = await _resolveHistoryId();
    if (historyId == null) {
      debugPrint('Pause Success: skipped because history_id is unavailable');
      return;
    }

    final response = await OxygenTimerApiService.pauseTimer(historyId);
    debugPrint('Pause Success: ${response.success}');
    debugPrint('API Response: ${response.toJson()}');
    if (!response.success) {
      await _showTimerApiFailure('Pause Timer', response.message ?? 'Unknown error');
    }
  }

  Future<void> _sendTimerResumeUpdate() async {
    final historyId = await _resolveHistoryId();
    if (historyId == null) {
      debugPrint('Resume Success: skipped because history_id is unavailable');
      return;
    }

    final response = await OxygenTimerApiService.resumeTimer(historyId);
    debugPrint('Resume Success: ${response.success}');
    debugPrint('API Response: ${response.toJson()}');
    if (!response.success) {
      await _showTimerApiFailure('Resume Timer', response.message ?? 'Unknown error');
    }
  }

  Future<void> _sendTimerStopUpdate() async {
    final historyId = await _resolveHistoryId();
    if (historyId == null) {
      debugPrint('Stop Success: skipped because history_id is unavailable');
      await _clearHistoryId();
      return;
    }

    final response = await OxygenTimerApiService.stopTimer(historyId);
    debugPrint('Stop Success: ${response.success}');
    debugPrint('API Response: ${response.toJson()}');
    if (!response.success) {
      await _showTimerApiFailure('Stop Timer', response.message ?? 'Unknown error');
    }
    await _clearHistoryId();
    _historyId = null;
    _pendingHistoryIdFuture = null;
  }

  Future<void> _sendTimerCompleteUpdate() async {
    final historyId = await _resolveHistoryId();
    if (historyId == null) {
      debugPrint('Complete Success: skipped because history_id is unavailable');
      return;
    }

    final response = await OxygenTimerApiService.completeTimer(historyId);
    debugPrint('Complete Success: ${response.success}');
    debugPrint('API Response: ${response.toJson()}');
    if (!response.success) {
      await _showTimerApiFailure('Complete Timer', response.message ?? 'Unknown error');
    }
  }

  void _openTimerHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimerHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = List.generate(15, (index) {
      final flowRate = index + 1;
      final durationMin = widget.totalContent / flowRate;
      final durationHr = durationMin / 60;
      return _ConsumptionRowData(
        flowRate: flowRate,
        durationMin: durationMin,
        durationHr: durationHr,
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),
      body: Column(
        children: [
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: AppHeader(
              title: 'Oxygen Consumption Table',
              subtitle: 'Total content: ${widget.totalContent.toStringAsFixed(1)} L',
              breadcrumb: _isTimerRunning
                  ? 'Timer running on row ${(_activeRowIndex ?? 0) + 1}'
                  : _isTimerPaused
                      ? 'Timer paused on row ${(_activeRowIndex ?? 0) + 1}'
                      : selectedIndex >= 0
                          ? 'Row ${selectedIndex + 1} selected — tap Start'
                          : 'Tap a row to highlight',
              showBack: true,
              onBack: () => Navigator.pop(context),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppHeaderActionButton(
                    icon: Icons.history,
                    tooltip: 'Timer History',
                    onTap: _openTimerHistory,
                  ),
                  const SizedBox(width: 8),
                  AppHeaderProfileAvatar(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Oxygen Consumption Table',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: Color(0xFF888780),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Oxygen Consumption Timer',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5F5E5A),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                _buildStatusChip(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Time Remaining',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 220),
                                        transitionBuilder: (child, animation) => FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, 0.08),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        ),
                                        child: Text(
                                          _formatCountdownDuration(_remainingTime),
                                          key: ValueKey<String>('timer-$_remainingTime-$_isTimerRunning-$_isTimerPaused'),
                                          style: const TextStyle(
                                            fontFamily: 'Roboto Mono',
                                            fontSize: 32,
                                            height: 1.05,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                            fontFeatures: [FontFeature.tabularFigures()],
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Flow Rate: ${_selectedFlowRate ?? '-'} L/min',
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: const Color(0xFFE9EEF5),
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (child, animation) => FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.06),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: _buildTimerControls(rows),
                            ),
                            if (selectedIndex < 0 && !_isTimerRunning && !_isTimerPaused) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Select a row below, then start the countdown.',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildHeaderRow(),
                      const SizedBox(height: 8),
                      ...List.generate(rows.length, (index) {
                        final row = rows[index];
                        final isSelected = index == selectedIndex;
                        final hasRowTimer = context
                            .read<TimerProvider>()
                            .getTimerForRow(index) != null;
                        final isActiveTimerRow =
                            ((_isTimerRunning || _isTimerPaused) &&
                                    _activeRowIndex == index) ||
                                hasRowTimer;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: isActiveTimerRow
                                ? const Color(0xFFBDECCC)
                                : isSelected
                                    ? const Color(0xFFCCDEFD)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _selectRow(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${row.flowRate}',
                                        style: const TextStyle(fontFamily: 'DM Sans'),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        row.durationMin.toStringAsFixed(2),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontFamily: 'DM Sans'),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _formatDuration(row.durationHr),
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(fontFamily: 'DM Sans'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap a row to highlight. Duration = Total Content / Flow Rate',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF5F5E5A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    const headerStyle = TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF1A1A2E),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(child: Text('Flow Rate (L/min)', style: headerStyle)),
          Expanded(child: Text('Duration (min)', style: headerStyle, textAlign: TextAlign.center)),
          Expanded(child: Text('Duration', style: headerStyle, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  String _formatDuration(double durationHours) {
    final totalSeconds = (durationHours * 3600).round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      final parts = <String>['${hours}h', '${minutes}m'];
      if (seconds > 0) {
        parts.add('${seconds}s');
      }
      return parts.join(' ');
    }

    if (seconds > 0) {
      return '${minutes}m ${seconds}s';
    }

    return '${minutes}m';
  }
}

class _ConsumptionRowData {
  final int flowRate;
  final double durationMin;
  final double durationHr;

  const _ConsumptionRowData({
    required this.flowRate,
    required this.durationMin,
    required this.durationHr,
  });
}
