import 'package:flutter/foundation.dart' as foundation;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin _localNotifications =
      fln.FlutterLocalNotificationsPlugin();

  static const fln.AndroidNotificationChannel _channel = fln.AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: fln.Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    // 1. Request Permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup Android Channel
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        fln.AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channel);
    }

    // 3. Init Settings
    const androidSettings = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = fln.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // FIXED: Standard initialization call
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse details) {
        foundation.debugPrint('Notification clicked: ${details.payload}');
      },
    );

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseMessaging.instance.subscribeToTopic('all_users');
        await FirebaseMessaging.instance.subscribeToTopic('news');
      }
    } catch (e) {
      foundation.debugPrint('Topic subscription error: $e');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = fln.AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      showWhen: true,
    );

    const notificationDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: fln.DarwinNotificationDetails(),
    );

    // FIXED: Standard show call with positional arguments
    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await showNotification(
        id: notification.hashCode,
        title: notification.title ?? 'SCA Update',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  Future<String?> getToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}
