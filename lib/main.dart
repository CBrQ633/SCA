import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart'; // Added
import 'core/config/supabase_config.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/calls/presentation/calls_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/subscription_badge_provider.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/calls/data/models/call_list_model.dart';
import 'features/calls/data/models/sync_task_model.dart';
import 'core/services/sync_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    await NotificationService().showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(CallListModelAdapter());
  Hive.registerAdapter(CallListItemModelAdapter());
  Hive.registerAdapter(SyncTaskModelAdapter());

  // Open Boxes
  await Hive.openBox<CallListModel>('offline_lists');
  await Hive.openBox<CallListItemModel>('offline_items');
  await Hive.openBox<SyncTaskModel>('sync_queue');
  await Hive.openBox<String>('whatsapp_templates');

  try {
    await SupabaseConfig.initialize();
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationService().initialize();
      
      // Request Notification Permission for Android 13+
      await _requestNotificationPermission();
      
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
    
    // Start Background Sync Service
    SyncService().start();
    
  } catch (e) {
    debugPrint('Failed to initialize: $e');
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

Future<void> _requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}
