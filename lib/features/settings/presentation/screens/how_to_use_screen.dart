import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_call_assistant/core/providers/settings_provider.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<SettingsProvider>().locale.languageCode == 'ar';
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'دليل الاستخدام الشامل' : 'Full User Guide'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  AppLogo(size: 50, showText: false, color: theme.colorScheme.onPrimary),
                  const SizedBox(height: 16),
                  Text(
                    isAdmin ? (isArabic ? 'دليل الإدارة' : 'Admin Operations') : (isArabic ? 'دليلك للنجاح مع SCA' : 'Mastering SCA'),
                    style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic ? 'تعرف على كافة ميزات التطبيق الاحترافية' : 'Learn all the professional features of SCA',
                    style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Sections
            if (isAdmin) ..._buildAdminGuide(isArabic, theme) else ..._buildUserGuide(isArabic, theme),
            
            const SizedBox(height: 24),
            Center(
              child: Text(
                isArabic ? '© 2026 مساعد المكالمات الذكي' : '© 2026 Smart Call Assistant',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUserGuide(bool isArabic, ThemeData theme) {
    return [
      _buildSectionTitle(isArabic ? 'إدارة قوائم الاتصال' : 'Call List Management', theme),
      _buildStepCard(
        theme,
        isArabic ? 'استيراد الأرقام (Excel/OCR)' : 'Importing Contacts',
        isArabic ? 'اضغط (+) واختر ملف Excel أو صورة. خوارزميتنا الذكية ستستخرج الأرقام المصرية والأسماء بدقة وتزيل أي بيانات غير مهمة.' : 'Press (+) and pick Excel or an Image. Our smart engine extracts Egyptian numbers and names accurately, ignoring junk data.',
        Icons.auto_fix_high_rounded,
      ),
      _buildStepCard(
        theme,
        isArabic ? 'البحث والفلترة الذكية' : 'Smart Search & Filters',
        isArabic ? 'يمكنك الآن البحث بالاسم أو الرقم، وفلترة القائمة لرؤية "من لم يرد" فقط أو "تم التواصل". التصدير لـ Excel يتبع الفلترة المختارة.' : 'Search by name/phone and filter list to see only "Missed" or "Called". Exporting to Excel follows your active filters.',
        Icons.filter_alt_rounded,
      ),
      
      const SizedBox(height: 24),
      _buildSectionTitle(isArabic ? 'أثناء المكالمات' : 'During Calling Session', theme),
      _buildStepCard(
        theme,
        isArabic ? 'قوالب واتساب الجاهزة' : 'WhatsApp Templates',
        isArabic ? 'اضغط أيقونة الإعدادات الخضراء في شاشة الاتصال لحفظ رسالة جاهزة. استخدم {name} ليتم وضع اسم العميل تلقائياً في الرسالة.' : 'Tap the green settings icon during calls to save a message template. Use {name} to auto-insert the contact name in your message.',
        Icons.whatsapp_rounded,
      ),
      _buildStepCard(
        theme,
        isArabic ? 'التسلسل الذكي' : 'Sequential Calling',
        isArabic ? 'اضغط START لبدء الاتصال التلقائي بالترتيب. يمكنك الاتصال هاتفياً أو عبر واتساب مباشرة دون حفظ الرقم.' : 'Press START to begin calling in order. Use Dialer or WhatsApp directly without saving the contact.',
        Icons.play_circle_filled_rounded,
      ),

      const SizedBox(height: 24),
      _buildSectionTitle(isArabic ? 'التقارير والأمان' : 'Reports & Security', theme),
      _buildStepCard(
        theme,
        isArabic ? 'تصدير التقارير (Excel)' : 'Export to Excel',
        isArabic ? 'يمكنك تصدير قائمة المكالمات كاملة مع الملاحظات والحالات إلى ملف Excel ومشاركته بضغطة زر من داخل القائمة.' : 'Export your entire call list with notes and statuses to an Excel file and share it instantly from within the list.',
        Icons.download_for_offline_rounded,
      ),
      _buildStepCard(
        theme,
        isArabic ? 'متابعة طلبات الاشتراك' : 'Subscription Status',
        isArabic ? 'في حالة رفض طلب اشتراكك، سيظهر لك السبب بوضوح (مثلاً: الصورة غير واضحة) لتتمكن من إعادة الطلب بشكل صحيح.' : 'If your subscription is rejected, the reason will be clearly shown (e.g., Image not clear) so you can resubmit correctly.',
        Icons.info_outline_rounded,
      ),
    ];
  }

  List<Widget> _buildAdminGuide(bool isArabic, ThemeData theme) {
    return [
      _buildSectionTitle(isArabic ? 'مهام المدير' : 'Admin Operations', theme),
      _buildStepCard(
        theme,
        isArabic ? 'تفعيل مع ذكر سبب الرفض' : 'Approval & Rejection Reasons',
        isArabic ? 'عند رفض طلب اشتراك، يمكنك الآن اختيار سبب الرفض ليصل للمستخدم ويفهم المشكلة بوضوح.' : 'When rejecting a subscription, you can now select a reason to let the user know exactly what went wrong.',
        Icons.verified_user_rounded,
      ),
    ];
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: theme.colorScheme.secondary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStepCard(ThemeData theme, String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: theme.colorScheme.secondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
