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

    // ✅ High Contrast Colors
    const textPrimary = Color(0xFF0F172A); // Deep Navy
    const textSecondary = Color(0xFF64748B); // Slate Gray

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Clean Light Gray background
      appBar: AppBar(
        title: Text(isArabic ? 'الإعدادات' : 'Settings', style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: AppLogo(size: 70, showText: true)),
          const SizedBox(height: 32),
          
          _buildSectionLabel(isArabic ? 'التفضيلات' : 'Preferences', textSecondary),
          _buildMenuCard([
            _buildToggleRow(
              icon: Icons.language_rounded,
              title: isArabic ? 'اللغة العربية' : 'Arabic Language',
              value: isArabic,
              onChanged: (v) => settingsProvider.setLocale(v ? const Locale('ar') : const Locale('en')),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionLabel(isArabic ? 'الدعم والمساعدة' : 'Support & Help', textSecondary),
          _buildMenuCard([
            _buildNavRow(
              icon: Icons.help_outline_rounded,
              title: isArabic ? 'دليل الاستخدام' : 'How to Use',
              onTap: () => context.push('/settings/how-to-use'),
            ),
            const Divider(height: 1, indent: 50),
            _buildNavRow(
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
              backgroundColor: const Color(0xFFFEE2E2), // Light Red
              foregroundColor: const Color(0xFFDC2626), // Red 600
              elevation: 0,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(isArabic ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          
          const SizedBox(height: 20),
          Center(child: Text('App Version 1.1.0', style: TextStyle(color: textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleRow({required IconData icon, required String title, required bool value, required Function(bool) onChanged}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0F172A), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeColor: const Color(0xFF10B981)),
    );
  }

  Widget _buildNavRow({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF0F172A), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
    );
  }
}
