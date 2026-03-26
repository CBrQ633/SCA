import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/core/providers/settings_provider.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isArabic = settingsProvider.locale.languageCode == 'ar';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'الإعدادات' : 'Settings',
            style: TextStyle(
                color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              authProvider.refreshUser();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isArabic ? 'تم تحديث البيانات' : 'Profile Refreshed'))
              );
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user != null) _buildProfileCard(context, user, isArabic),

          const SizedBox(height: 24),

          // ✅ Account Management Section
          _buildSectionLabel(isArabic ? 'إدارة الحساب' : 'Account Management', theme),
          _buildMenuCard(theme, [
            _buildNavRow(
              theme: theme,
              icon: Icons.logout_rounded,
              title: isArabic ? 'تسجيل الخروج' : 'Logout',
              color: Colors.red,
              onTap: () => authProvider.logout(),
            ),
          ]),

          const SizedBox(height: 24),

          // ✅ Team Section (Only for Sales Users)
          if (user != null && user.role == 'sales_user') ...[
            _buildSectionLabel(isArabic ? 'الفريق' : 'My Team', theme),
            _buildMenuCard(theme, [
              if (user.leaderId == null)
                ListTile(
                  onTap: () => _showJoinTeamDialog(context, isArabic),
                  leading:
                      const Icon(Icons.group_add_rounded, color: Colors.orange),
                  title: Text(isArabic ? 'الانضمام لفريق' : 'Join a Team'),
                  subtitle: Text(
                      isArabic ? 'أدخل كود التيم ليدر' : 'Enter Team Leader ID',
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                )
              else
                ListTile(
                  leading: const Icon(Icons.verified_user_rounded,
                      color: Colors.green),
                  title: Text(isArabic ? 'عضو في فريق' : 'Team Member'),
                  subtitle: Text(
                      isArabic ? 'تم الربط بنجاح' : 'Connected to Leader',
                      style: const TextStyle(fontSize: 12)),
                ),
            ]),
            const SizedBox(height: 24),
          ],

          _buildSectionLabel(isArabic ? 'التفضيلات' : 'Preferences', theme),
          _buildMenuCard(theme, [
            _buildToggleRow(
              theme: theme,
              icon: Icons.language_rounded,
              title: isArabic ? 'اللغة العربية' : 'Arabic Language',
              value: isArabic,
              onChanged: (v) => settingsProvider
                  .setLocale(v ? const Locale('ar') : const Locale('en')),
            ),
            const Divider(height: 1, indent: 50),
            _buildToggleRow(
              theme: theme,
              icon: settingsProvider.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
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
          _buildSectionLabel(
              isArabic ? 'الدعم والمساعدة' : 'Support & Help', theme),
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
          Center(
              child: Text('App Version 1.1.0',
                  style: TextStyle(
                      color: theme.textTheme.bodySmall?.color, fontSize: 12))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showJoinTeamDialog(BuildContext context, bool isArabic) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isArabic ? 'الانضمام لفريق' : 'Join a Team'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'SCA-XXXXXX',
            labelText: isArabic ? 'كود التيم ليدر' : 'Team Leader ID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              final id = controller.text.trim();
              if (id.isEmpty) return;

              final provider = context.read<AuthProvider>();
              final success = await provider.joinTeam(id);

              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isArabic
                          ? 'تم الانضمام بنجاح!'
                          : 'Successfully joined the team!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(provider.errorMessage ?? 'Error')));
                }
              }
            },
            child: Text(isArabic ? 'انضمام' : 'Join'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user, bool isArabic) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(user.fullName?[0].toUpperCase() ?? 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName ?? 'User',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        user.role.toString().replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isArabic ? 'هويتك الفريدة' : 'YOUR SCA ID',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  Text(user.scaId ?? 'SCA-XXXXXX',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                ],
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: user.scaId ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isArabic
                          ? 'تم نسخ المعرف!'
                          : 'ID Copied to clipboard!')));
                },
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1)),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildMenuCard(ThemeData theme, List<Widget> children) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleRow(
      {required ThemeData theme,
      required IconData icon,
      required String title,
      required bool value,
      required Function(bool) onChanged}) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface)),
      trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged),
    );
  }

  Widget _buildNavRow(
      {required ThemeData theme,
      required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color? color}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? theme.colorScheme.primary, size: 22),
      title: Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color ?? theme.colorScheme.onSurface)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: theme.textTheme.bodySmall?.color, size: 20),
    );
  }
}
