import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      backgroundColor: const Color(0xFFF8FAFC), // Bright background for clarity
      appBar: AppBar(
        title: Text(isArabic ? 'دليل الاستخدام' : 'User Guide', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Deep Navy
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const AppLogo(size: 50, showText: false, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    isAdmin ? (isArabic ? 'إدارة النظام' : 'Management') : (isArabic ? 'ابدأ مع SCA' : 'Get Started'),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (isAdmin) ..._buildAdminGuide(isArabic) else ..._buildUserGuide(isArabic),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUserGuide(bool isArabic) {
    return [
      _buildStepCard(
        isArabic ? '1. استيراد الأرقام' : '1. Import Contacts',
        isArabic ? 'اضغط (+) في شاشة المكالمات واختر ملف Excel أو صورة.' : 'Press (+) in Calls screen and pick Excel or an Image.',
        Icons.upload_file_rounded,
      ),
      _buildStepCard(
        isArabic ? '2. بدء الجلسة' : '2. Start Session',
        isArabic ? 'اختر القائمة واضغط "START" للبدء بالاتصال بالترتيب.' : 'Select a list and press "START" to begin sequential calling.',
        Icons.play_circle_fill_rounded,
      ),
      _buildStepCard(
        isArabic ? '3. التواصل السريع' : '3. Quick Connect',
        isArabic ? 'استخدم زر الاتصال أو الواتساب دون حفظ الرقم.' : 'Use Call or WhatsApp buttons without saving numbers.',
        Icons.bolt_rounded,
      ),
    ];
  }

  List<Widget> _buildAdminGuide(bool isArabic) {
    return [
      _buildStepCard(
        isArabic ? 'إدارة الطلبات' : 'Subscription Requests',
        isArabic ? 'راجع صور التحويل وقم بتفعيل حسابات المستخدمين.' : 'Review payment receipts and activate user accounts.',
        Icons.verified_user_rounded,
      ),
      _buildStepCard(
        isArabic ? 'مراقبة الإحصائيات' : 'Monitor Stats',
        isArabic ? 'تابع إجمالي المستخدمين والمكالمات اليومية من اللوحة.' : 'Track total users and daily calls from your dashboard.',
        Icons.analytics_rounded,
      ),
    ];
  }

  Widget _buildStepCard(String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 13, color: Colors.blueGrey[600], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
