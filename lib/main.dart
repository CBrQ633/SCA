import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/subscription_badge_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
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
