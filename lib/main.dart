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
  // Handle background message - you can store it locally or process it
  debugPrint('Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    try {
      await Firebase.initializeApp(
          // options: DefaultFirebaseOptions.currentPlatform, // Uncomment if generated
          );
      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Failed to init Firebase: $e');
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
