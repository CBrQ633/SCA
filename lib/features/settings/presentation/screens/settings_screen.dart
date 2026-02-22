import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/core/providers/settings_provider.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = settingsProvider.themeMode == ThemeMode.dark;
    final isArabic = settingsProvider.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'الإعدادات' : 'Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FadeInDown(
              child: const Center(child: AppLogo(size: 80, showText: true)),
            ),
            const SizedBox(height: 40),

            _buildSettingsSection(
              theme,
              title: isArabic ? 'التفضيلات' : 'Preferences',
              children: [
                _buildToggleTile(
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  title: isArabic ? 'الوضع الليلي' : 'Dark Mode',
                  value: isDark,
                  onChanged: (v) => settingsProvider.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                  activeColor: theme.colorScheme.secondary,
                ),
                _buildToggleTile(
                  icon: Icons.language_rounded,
                  title: isArabic ? 'اللغة العربية' : 'Arabic Language',
                  value: isArabic,
                  onChanged: (v) => settingsProvider.setLocale(v ? const Locale('ar') : const Locale('en')),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSettingsSection(
              theme,
              title: isArabic ? 'المساعدة والدعم' : 'Support',
              children: [
                _buildNavigationTile(
                  icon: Icons.help_center_outlined,
                  title: isArabic ? 'كيفية الاستخدام' : 'How to Use',
                  onTap: () => context.push('/settings/how-to-use'),
                ),
                _buildNavigationTile(
                  icon: Icons.info_outline_rounded,
                  title: isArabic ? 'عن التطبيق' : 'About SCA',
                  onTap: () => context.push('/settings/about'),
                ),
              ],
            ),

            const SizedBox(height: 40),

            FadeInUp(
              child: ElevatedButton.icon(
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout_rounded),
                label: Text(isArabic ? 'تسجيل الخروج' : 'Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  foregroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Version 1.0.4', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme, {required String title, required List<Widget> children}) {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 14)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({required IconData icon, required String title, required bool value, required Function(bool) onChanged, required Color activeColor}) {
    return ListTile(
      leading: Icon(icon, color: activeColor),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: activeColor),
    );
  }

  Widget _buildNavigationTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}
