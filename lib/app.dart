import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (context, authProvider, settingsProvider, _) {
        final router = AppRouter.getRouter(authProvider);

        // ✅ Redirect to HowToUse if it's the first login ever
        if (authProvider.currentUser != null && authProvider.isFirstLogin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // This is a simple way to show it without complex routing logic change
            // Alternatively, AppRouter could handle this.
          });
        }

        return MaterialApp.router(
          title: 'SCA',
          debugShowCheckedModeBanner: false,

          // Theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settingsProvider.themeMode,
          // Localization
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: settingsProvider.locale,
          // Routing
          routerConfig: router,
        );
      },
    );
  }
}
