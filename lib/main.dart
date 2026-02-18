import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/presentation/auth_provider.dart';
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
  // Show local notification even if background
  if (message.notification != null) {
    await NotificationService().showNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    try {
      await Firebase.initializeApp();
      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      // Application can still run with Supabase even if notifications fail
    }
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
    // Consider showing a friendly error screen here or relying on the splash screen to handle it.
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionBadgeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
