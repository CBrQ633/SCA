import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_call_assistant/core/providers/settings_provider.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = context.watch<SettingsProvider>().locale.languageCode == 'ar';
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isArabic ? 'دليل الاستخدام' : 'User Guide'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    const AppLogo(size: 60, showText: false, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      isAdmin ? (isArabic ? 'لوحة تحكم المدير' : 'Admin Dashboard') : (isArabic ? 'مرحباً بك في SCA' : 'Welcome to SCA'),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isArabic ? 'دليلك السريع لإنجاز مهامك' : 'Your quick guide to success',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (isAdmin) ..._buildAdminGuide(isArabic, theme) else ..._buildUserGuide(isArabic, theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUserGuide(bool isArabic, ThemeData theme) {
    return [
      _buildStepCard(
        '1',
        isArabic ? 'استيراد البيانات' : 'Import Data',
        isArabic ? 'من شاشة المكالمات، اضغط على زر (+) واختر ملف Excel أو صورة لقراءة الأرقام تلقائياً.' : 'From Calls screen, press (+) and choose Excel or Image to extract numbers automatically.',
        Icons.cloud_download_rounded,
        theme.colorScheme.primary,
      ),
      _buildStepCard(
        '2',
        isArabic ? 'بدء جلسة الاتصال' : 'Start Calling',
        isArabic ? 'اختر القائمة واضغط "بدء". سيقوم التطبيق بعرض العملاء واحداً تلو الآخر لتوفير وقتك.' : 'Select a list and press "Start". The app will show customers one by one to save your time.',
        Icons.phone_in_talk_rounded,
        theme.colorScheme.secondary,
      ),
      _buildStepCard(
        '3',
        isArabic ? 'التواصل السريع' : 'Quick Connect',
        isArabic ? 'يمكنك الاتصال هاتفياً أو فتح واتساب بضغطة واحدة دون الحاجة لحفظ الرقم.' : 'You can call or open WhatsApp with one click without saving the contact.',
        Icons.bolt_rounded,
        Colors.orangeAccent,
      ),
      _buildStepCard(
        '4',
        isArabic ? 'متابعة الإنجاز' : 'Track Success',
        isArabic ? 'راجع شاشة التقارير لترى معدل نجاحك وإحصائيات مكالماتك اليومية.' : 'Check the Reports screen to see your success rate and daily call statistics.',
        Icons.auto_graph_rounded,
        Colors.purpleAccent,
      ),
    ];
  }

  List<Widget> _buildAdminGuide(bool isArabic, ThemeData theme) {
    return [
      _buildStepCard(
        '!',
        isArabic ? 'إدارة الاشتراكات' : 'Manage Subs',
        isArabic ? 'راجع طلبات المستخدمين الجدد وقم بتفعيل حساباتهم بعد التأكد من الدفع.' : 'Review new user requests and activate their accounts after payment verification.',
        Icons.verified_user_rounded,
        theme.colorScheme.secondary,
      ),
      _buildStepCard(
        '2',
        isArabic ? 'مراقبة النظام' : 'System Monitor',
        isArabic ? 'تابع إجمالي المكالمات والمستخدمين النشطين من لوحة التحكم الرئيسية.' : 'Monitor total calls and active users from the main admin dashboard.',
        Icons.admin_panel_settings_rounded,
        theme.colorScheme.primary,
      ),
    ];
  }

  Widget _buildStepCard(String step, String title, String desc, IconData icon, Color color) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
