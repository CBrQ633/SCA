import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/core/providers/settings_provider.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark = settingsProvider.themeMode == ThemeMode.dark;
    final isArabic = settingsProvider.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Theme Toggle
          ListTile(
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: Text(isArabic ? 'المظهر' : 'Theme'),
            subtitle: Text(isDark
                ? (isArabic ? 'داكن' : 'Dark')
                : (isArabic ? 'فاتح' : 'Light')),
            trailing: Switch(
              value: isDark,
              onChanged: (value) {
                settingsProvider
                    .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          const Divider(),

          // Language Switcher
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(isArabic ? 'اللغة' : 'Language'),
            subtitle: Text(isArabic ? 'العربية' : 'English'),
            trailing: Switch(
              value: isArabic,
              onChanged: (value) {
                settingsProvider
                    .setLocale(value ? const Locale('ar') : const Locale('en'));
              },
            ),
          ),
          const Divider(),

          // How to Use
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(isArabic ? 'طريقة الاستخدام' : 'How to Use'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/how-to-use');
            },
          ),
          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(isArabic ? 'عن التطبيق' : 'About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/about');
            },
          ),
          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              isArabic ? 'تسجيل الخروج' : 'Logout',
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
    );
  }
}
