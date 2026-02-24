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
    final theme = Theme.of(context);
    final isArabic = settingsProvider.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // ✅ Bright clean background
      appBar: AppBar(
        title: Text(isArabic ? 'الإعدادات' : 'Settings', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: AppLogo(size: 70, showText: true)),
          const SizedBox(height: 32),
          
          _buildSectionHeader(isArabic ? 'التفضيلات' : 'Preferences'),
          _buildCard(children: [
            _buildToggleTile(
              icon: Icons.language,
              title: isArabic ? 'اللغة العربية' : 'Arabic Language',
              value: isArabic,
              onChanged: (v) => settingsProvider.setLocale(v ? const Locale('ar') : const Locale('en')),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader(isArabic ? 'الدعم' : 'Support'),
          _buildCard(children: [
            _buildNavTile(
              icon: Icons.help_outline,
              title: isArabic ? 'كيفية الاستخدام' : 'How to Use',
              onTap: () => context.push('/settings/how-to-use'),
            ),
            _buildNavTile(
              icon: Icons.info_outline,
              title: isArabic ? 'عن التطبيق' : 'About SCA',
              onTap: () => context.push('/settings/about'),
            ),
          ]),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(isArabic ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile({required IconData icon, required String title, required bool value, required Function(bool) onChanged}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0F172A)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeColor: const Color(0xFF10B981)),
    );
  }

  Widget _buildNavTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0F172A)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
