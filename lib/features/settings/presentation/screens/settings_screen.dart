import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/core/providers/settings_provider.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isArabic = settingsProvider.locale.languageCode == 'ar';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'الإعدادات' : 'Settings', 
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: AppLogo(size: 70, showText: true)),
          const SizedBox(height: 32),
          
          _buildSectionLabel(isArabic ? 'التفضيلات' : 'Preferences', theme),
          _buildMenuCard(theme, [
            _buildToggleRow(
              theme: theme,
              icon: Icons.language_rounded,
              title: isArabic ? 'اللغة العربية' : 'Arabic Language',
              value: isArabic,
              onChanged: (v) => settingsProvider.setLocale(v ? const Locale('ar') : const Locale('en')),
            ),
            const Divider(height: 1, indent: 50),
            _buildToggleRow(
              theme: theme,
              icon: settingsProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: isArabic ? 'الوضع الداكن' : 'Dark Mode',
              value: settingsProvider.isDarkMode,
              onChanged: (v) => settingsProvider.toggleTheme(),
            ),
            const Divider(height: 1, indent: 50),
            _buildNavRow(
              theme: theme,
              icon: Icons.chat_bubble_outline_rounded,
              title: isArabic ? 'قوالب الواتساب' : 'WhatsApp Templates',
              onTap: () => context.push('/settings/templates'),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionLabel(isArabic ? 'الدعم والمساعدة' : 'Support & Help', theme),
          _buildMenuCard(theme, [
            _buildNavRow(
              theme: theme,
              icon: Icons.help_outline_rounded,
              title: isArabic ? 'دليل الاستخدام' : 'How to Use',
              onTap: () => context.push('/settings/how-to-use'),
            ),
            const Divider(height: 1, indent: 50),
            _buildNavRow(
              theme: theme,
              icon: Icons.info_outline_rounded,
              title: isArabic ? 'عن التطبيق' : 'About SCA',
              onTap: () => context.push('/settings/about'),
            ),
          ]),

          const SizedBox(height: 48),
          
          // Logout Button
          ElevatedButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              elevation: 0,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(isArabic ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          
          const SizedBox(height: 20),
          Center(child: Text('App Version 1.1.0', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, letterSpacing: 0.5)),
    );
  }

  Widget _buildMenuCard(ThemeData theme, List<Widget> children) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleRow({required ThemeData theme, required IconData icon, required String title, required bool value, required Function(bool) onChanged}) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeColor: theme.colorScheme.secondary),
    );
  }

  Widget _buildNavRow({required ThemeData theme, required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
      trailing: Icon(Icons.chevron_right_rounded, color: theme.textTheme.bodySmall?.color, size: 20),
    );
  }
}
