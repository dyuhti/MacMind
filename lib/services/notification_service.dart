import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';

/// Service for managing local notifications and vibration alerts
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const int warningNotificationId = 1;
  static const int finalNotificationId = 2;

  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize notifications plugin and request permissions
  Future<void> initialize() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Request notification permissions for Android 13+
    await _requestNotificationPermission();
  }

  /// Request notification permissions for Android 13+
  Future<void> _requestNotificationPermission() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final result = await android.requestNotificationsPermission();
      if (result != null) {
        print('Notification permission requested: $result');
      }
    }
  }

  /// Show 5-minute warning notification with vibration
  Future<void> showWarningNotification() async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'oxygen_timer_channel',
      'Oxygen Timer',
      channelDescription: 'Notifications for oxygen cylinder timer',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      warningNotificationId,
      'Oxygen Warning',
      '⚠️ Oxygen will run out in 5 minutes',
      platformChannelSpecifics,
    );

    print('📢 Warning notification shown');
  }

  /// Show final depletion notification with strong alert
  Future<void> showFinalNotification() async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'oxygen_timer_channel',
      'Oxygen Timer',
      channelDescription: 'Notifications for oxygen cylinder timer',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]),
      sound: RawResourceAndroidNotificationSound('notification'),
      fullScreenIntent: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      finalNotificationId,
      'Oxygen Depleted',
      '🚨 Oxygen supply exhausted',
      platformChannelSpecifics,
    );

    print('🚨 Final depletion notification shown');
  }

  /// Cancel all scheduled and active notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('All notifications cancelled');
  }

  /// Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    print('Notification $id cancelled');
  }
}
