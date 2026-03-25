import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/foundation.dart' as foundation;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ✅ Real Service Account Credentials (FCM V1)
  final _serviceAccountCredentials = {
    "type": "service_account",
    "project_id": "sca-app-73e87",
    "private_key_id": "36ed13e0a891ec5f61c313231850be8877b12e83",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDVDY6e0xjd5+4j\noVbteuGhFjaK/etxVD1PhW3Yte9vI51xO0wvS8aZ3KvYGzuD1/0Flz+yhJMYx8U5\nvsquDncjsO79e9MTHrsqY1QXcfd+pLsPAM28nGHr4gD+ckJf3PDHmVvKOjFPOIsC\nr2Yom23RfA+EDIYBKNxxRRQ8Yktmh/0QT2swXFyrPBnJraBYXSJJL3H33PYE8aC1\nSi0uT5htoGUDktMwlYsAN2FC93+9ZzZHg4jwQreRCwBQPNPOBLAxj2c22shmal67\nkcaOZ4kQfHTIx695QrZ1J/OdGiC6hBfNVgztphT3DdU9Ez+brc8/rgKzwvuM7YDT\nCCNBzZ9bAgMBAAECggEADUWPbVhkE6q3fHO3+QovFPxPwH/J02D2gsYijh3jQO6c\nh6m0eLvFLt9+uvMTVYa2ZctCtgmpKiGDqTG36XjQNiJ2+MZmYyoGacEPQ3iffL2h\nQ3F+33F0bh/BhRg0B0m5nA1zGNlgKfmxOyUW/Y+VGzgZtVWcYWUculedx5ct8ECK\nO5I0scMFdiKgQPgb8XdFn0wzgFzec2UIWt5qBryhqs144H+d+3FjHLo/NQOTclKU\nQsxbyM5IHAq6XAQDftXTm/BXncYtOIHXp+m5H2/VidRI3UT+Am38I5H3qlRQZFy9\Tag4iTAZI8GvsT4RVhgF5qcg67peB12nLo17kx4PzQKBgQD5jBTUNxnqkfbOAsXJ\n0B6P1MwIDv9/ZW5Kw7WoIL0aev3DV2aAGUb+0bjmKcwwWHK7MuqlEcwY77cfPBJ3\nM8nkrGvJMdNXdBvEu/ckDAw5fr2MzlSsQLt+W+yp42ks+cAqzFLLrKeqFDVrrjw9\noCL9K63zdH+3/cfjSeLb+zPJJQKBgQDaj+Vq3I7G7letD3dA8NNel4Pgg+pcfT6w\nByptNwr1ID7io3UQxmRdtXKaHyvYej4HzUrQq6KtKGh0BD71zek/mta0PerA0sL5\nlCnq1NGTwKlSq5rIUBMtFw/BOcVZa7oSCephLWO7IN+IYf0Ax/GI02EP6h7QsoCJ\nfPBYk5iefwKBgGGEFhefuKbrhzCV8MieZXL7SwfTJJCaCHF67R/YO01/xm5xVwKz\n3gRx2/lFWB+EUMFKclszCzirZDn2dZjTSg/sOOqUZ+wC2V8VvMv/UT+egV/muTve\nx+Xm8iKpVU5YAno3AhvJSnOyFfYQTkYer82TJhS+77HsoBH3q4kfLutpAoGARakH\nXf/eIdllaGs9fx1CwStZhP2GfOQOTtx50UVx4J7ebC3c6fPRmWxzklvNBbowexwb\ndFbACqCOaivQRVfTt8oKFHiHkd2a9yEaGxaplYYacZbwRlf/RKfNBbD8DXwgWg9+\n/GoTF1lq5XUVxmHzwcBdd00PdUTvYuLHV/Py+NECgYEAp2ohdu8TXtpwTJkx7u87\nKg2Iw5/NnKKw3XzcOgigTehycvPnIgS5DUUnjLJ2fs3YlHO56XQsvm35eH8fYkif\nHAbA/J7HDSEGBl1fLMfMkNY7o2SIM4SIKwS7NrxSvu0Y/o8ERXXIDKHQJiaAiFHy\n0mR69xD3qVKGE7p5eLfYZgw=\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-fbsvc@sca-app-73e87.iam.gserviceaccount.com",
    "client_id": "107892475264293561937",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40sca-app-73e87.iam.gserviceaccount.com"
  };

  final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: DarwinInitializationSettings()),
    );

    FirebaseMessaging.onMessage.listen((message) => _showForegroundNotification(message));
  }

  Future<String> _getAccessToken() async {
    final credentials = auth.ServiceAccountCredentials.fromJson(_serviceAccountCredentials);
    final client = await auth.clientViaServiceAccount(credentials, _scopes);
    return client.credentials.accessToken.data;
  }

  Future<void> sendNotificationToTeam({
    required String leaderId,
    required String title,
    required String body,
  }) async {
    try {
      final String accessToken = await _getAccessToken();
      final String projectId = _serviceAccountCredentials['project_id']!.toString();
      
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'topic': 'team_$leaderId',
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'sound': 'default',
              },
            },
          }
        }),
      );
      foundation.debugPrint('FCM V1 Response: ${response.body}');
    } catch (e) {
      foundation.debugPrint('FCM V1 Error: $e');
    }
  }

  Future<void> subscribeToTeam(String leaderId) async {
    await FirebaseMessaging.instance.subscribeToTopic('team_$leaderId');
  }

  Future<void> unsubscribeFromTeam(String leaderId) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic('team_$leaderId');
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails('high_importance_channel', 'High Importance', importance: Importance.max, priority: Priority.high),
        ),
      );
    }
  }
}
