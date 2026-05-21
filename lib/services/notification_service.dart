import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service that owns the oxygen timer notification lifecycle.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  static const int warningNotificationId = 2000;
  static const int finishedNotificationId = 2001;
  static const int timerNotificationId = finishedNotificationId;
  static const String channelId = 'oxygen_timer_channel';
  static const String channelName = 'Oxygen Cylinder Alert';
  static const String channelDescription = 'Alerts when the oxygen timer reaches zero';

  static const String oxygenTimerEndKey = 'oxygen_timer_end';
  static const String oxygenTimerRemainingKey = 'oxygen_timer_remaining_seconds';
  static const String oxygenTimerDurationKey = 'oxygen_timer_duration_seconds';
  static const String oxygenTimerStateKey = 'oxygen_timer_state';
  static const String oxygenTimerRowIndexKey = 'oxygen_timer_active_row_index';
  static const String oxygenTimerFlowRateKey = 'oxygen_timer_flow_rate';
  static const String oxygenTimerHistoryIdKey = 'oxygen_timer_history_id';
  static const String permissionPromptedKey = 'oxygen_timer_notification_permission_prompted';

  static const String timerStateRunning = 'running';
  static const String timerStatePaused = 'paused';

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  bool _initialized = false;
  Future<void>? _initializationFuture;

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initializationFuture ??= _initializeInternal();
    await _initializationFuture;
  }

  Future<void> _initializeInternal() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted = prefs.getBool(permissionPromptedKey) ?? false;
    if (alreadyPrompted) {
      return;
    }

    final android = _notificationsPlugin?.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _notificationsPlugin?.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();

    try {
      await android?.requestNotificationsPermission();
    } catch (error) {
      debugPrint('Android notification permission request failed: $error');
    }

    try {
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (error) {
      debugPrint('iOS notification permission request failed: $error');
    }

    try {
      final enabled = await android?.areNotificationsEnabled();
      debugPrint('Notifications enabled: $enabled');
    } catch (error) {
      debugPrint('Failed to check Android notification state: $error');
    }

    await prefs.setBool(permissionPromptedKey, true);
  }

  Future<void> scheduleTimerNotification(DateTime endTime) async {
    await initialize();

    final remainingDurationSeconds = endTime.difference(DateTime.now()).inSeconds;
    final finishedScheduledDate = tz.TZDateTime.from(endTime.toLocal(), tz.local);
    final details = _buildNotificationDetails();

    await cancelTimerNotification();

    if (remainingDurationSeconds > 300) {
      final warningScheduledDate = tz.TZDateTime.from(
        endTime.subtract(const Duration(minutes: 5)).toLocal(),
        tz.local,
      );
      debugPrint('⏰ Warning notification scheduled for $warningScheduledDate');

      await _notificationsPlugin!.zonedSchedule(
        warningNotificationId,
        '⚠️ Oxygen Running Low',
        'Only 5 minutes of oxygen remain. Please prepare a replacement cylinder.',
        warningScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'oxygen_timer_warning',
      );
    } else {
      debugPrint('ℹ️ Warning notification skipped because remaining duration is ${remainingDurationSeconds}s');
    }

    debugPrint('⏰ Finish notification scheduled for $finishedScheduledDate');

    try {
    await _notificationsPlugin!.zonedSchedule(
      finishedNotificationId,
      '🚨 Oxygen Cylinder Empty',
      'The oxygen consumption timer has finished. Please check or replace the cylinder immediately.',
      finishedScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'oxygen_timer_finished',
    );

      await logPendingNotifications(reason: 'after timer schedule');
    } catch (error) {
      debugPrint('❌ Failed to schedule timer notification: $error');
      rethrow;
    }
  }

  Future<void> showTimerCompletionNotification() async {
    await initialize();

    debugPrint('📣 Showing immediate oxygen timer completion notification');

    await _notificationsPlugin!.show(
      timerNotificationId,
      'Oxygen Cylinder Alert',
      'The oxygen consumption timer has finished. Please check or replace the cylinder.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'oxygen_timer_finished_immediate',
    );

    await logPendingNotifications(reason: 'after immediate show');
  }

  Future<void> testNotification() async {
    await initialize();

    await _notificationsPlugin!.show(
      999,
      'Test Notification',
      'If you see this, notifications work.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    await logPendingNotifications(reason: 'after test show');
  }

  Future<void> debugScheduleNotification() async {
    await initialize();

    final debugTime = DateTime.now().add(const Duration(seconds: 10));
    debugPrint('🧪 Scheduling debug notification for $debugTime');

    await _notificationsPlugin!.zonedSchedule(
      9999,
      'Debug Notification',
      'If you see this, scheduled notifications are working.',
      tz.TZDateTime.from(debugTime.toLocal(), tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'debug_schedule_notification',
    );

    await logPendingNotifications(reason: 'after debug schedule');
  }

  Future<void> cancelTimerNotification() async {
    await initialize();
    debugPrint('🧹 Cancelling timer notifications');
    await _notificationsPlugin!.cancel(warningNotificationId);
    await _notificationsPlugin!.cancel(finishedNotificationId);
    await logPendingNotifications(reason: 'after timer cancel');
  }

  Future<void> cancelTimerNotifications() async {
    await cancelTimerNotification();
  }

  Future<void> cancelAllNotifications() async {
    await initialize();
    debugPrint('🧹 Cancelling all notifications');
    await _notificationsPlugin!.cancelAll();
    await logPendingNotifications(reason: 'after cancelAll');
  }

  Future<void> logPendingNotifications({String reason = ''}) async {
    await initialize();

    final pending = await _notificationsPlugin!.pendingNotificationRequests();
    debugPrint('📬 Pending notifications${reason.isNotEmpty ? ' ($reason)' : ''}: ${pending.length}');
    for (final notification in pending) {
      debugPrint('📬 Pending notification -> id: ${notification.id}, title: ${notification.title}, body: ${notification.body}');
    }
  }

  NotificationDetails _buildNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload ?? 'no payload'}');
  }
}
