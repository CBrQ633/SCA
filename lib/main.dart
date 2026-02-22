import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/calls/presentation/calls_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/subscription_badge_provider.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    await NotificationService().showNotification(
      id: message.hashCode, // Added required id
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseConfig.initialize();
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionBadgeProvider()),
        ChangeNotifierProvider(create: (_) => CallsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
