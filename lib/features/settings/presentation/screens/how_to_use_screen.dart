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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), 
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
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const AppLogo(size: 50, showText: false, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    isAdmin ? (isArabic ? 'دليل الإدارة' : 'Admin Operations') : (isArabic ? 'دليلك للنجاح مع SCA' : 'Mastering SCA'),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic ? 'تعرف على كافة ميزات التطبيق الاحترافية' : 'Learn all the professional features of SCA',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Sections
            if (isAdmin) ..._buildAdminGuide(isArabic) else ..._buildUserGuide(isArabic),
            
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

  List<Widget> _buildUserGuide(bool isArabic) {
    return [
      _buildSectionTitle(isArabic ? 'إدارة قوائم الاتصال' : 'Call List Management'),
      _buildStepCard(
        isArabic ? 'استيراد الأرقام (Excel/OCR)' : 'Importing Contacts',
        isArabic ? 'اضغط (+) واختر ملف Excel أو صورة. خوارزميتنا الذكية ستستخرج الأرقام المصرية والأسماء بدقة وتزيل أي بيانات غير مهمة.' : 'Press (+) and pick Excel or an Image. Our smart engine extracts Egyptian numbers and names accurately, ignoring junk data.',
        Icons.auto_fix_high_rounded,
      ),
      _buildStepCard(
        isArabic ? 'الأرشفة والحذف السريع' : 'Archive & Delete',
        isArabic ? 'اسحب أي قائمة لليمين (لون برتقالي) لنقلها للأرشيف، أو لليسار (لون أحمر) لحذفها نهائياً مع التأكيد.' : 'Swipe any list Right (Orange) to Archive, or Left (Red) to Delete permanently with confirmation.',
        Icons.swipe_rounded,
      ),
      
      const SizedBox(height: 24),
      _buildSectionTitle(isArabic ? 'أثناء المكالمات' : 'During Calling Session'),
      _buildStepCard(
        isArabic ? 'التسلسل الذكي' : 'Sequential Calling',
        isArabic ? 'اضغط START لبدء الاتصال التلقائي بالترتيب. يمكنك الاتصال هاتفياً أو عبر واتساب مباشرة دون حفظ الرقم.' : 'Press START to begin calling in order. Use Dialer or WhatsApp directly without saving the contact.',
        Icons.play_circle_filled_rounded,
      ),
      _buildStepCard(
        isArabic ? 'الملاحظات السريعة' : 'Quick Notes',
        isArabic ? 'بعد كل مكالمة، يمكنك كتابة ملحوظة اختيارية (مثل: العميل مهتم، أو عاود الاتصال لاحقاً) لتظهر في تقاريرك.' : 'After each call, you can write an optional note (e.g., Interested, callback later) to show in your reports.',
        Icons.note_add_rounded,
      ),

      const SizedBox(height: 24),
      _buildSectionTitle(isArabic ? 'التقارير والأداء' : 'Performance & Reports'),
      _buildStepCard(
        isArabic ? 'تحليل الإنجاز' : 'Success Tracking',
        isArabic ? 'راقب معدل نجاحك من شاشة Insights. الأرقام التي لم ترد وتتصل بها لاحقاً وتجيب ستنتقل تلقائياً من قائمة "Missed" إلى "Answered".' : 'Monitor your success rate in Insights. Missed contacts that you call again and reach will auto-move to the Answered list.',
        Icons.insights_rounded,
      ),
      _buildStepCard(
        isArabic ? 'تصدير التقارير المفصلة' : 'Exporting Detailed Reports',
        isArabic ? 'اضغط على بطاقة "تم الرد" أو "لم يرد" لرؤية الأسماء، ثم اضغط أيقونة التحميل لتصدير ملف Excel مخصص لهذه الفئة.' : 'Tap "Answered" or "Missed" cards to view names, then press Download to export a custom Excel for that category.',
        Icons.file_download_rounded,
      ),

      const SizedBox(height: 24),
      _buildSectionTitle(isArabic ? 'الأمان والجلسات' : 'Security & Session'),
      _buildStepCard(
        isArabic ? 'حماية الجهاز الواحد' : 'Single Device Protection',
        isArabic ? 'حسابك محمي؛ لا يمكن فتحه من جهازين في نفس الوقت. إذا تم تسجيل الدخول من هاتف آخر، سيتم إخراج الجهاز الأول تلقائياً للأمان.' : 'Your account is secure; it cannot be open on two devices at once. Logging in from a new phone will auto-logout the previous one.',
        Icons.security_rounded,
      ),
    ];
  }

  List<Widget> _buildAdminGuide(bool isArabic) {
    return [
      _buildSectionTitle(isArabic ? 'مهام المدير' : 'Admin Operations'),
      _buildStepCard(
        isArabic ? 'تفعيل الاشتراكات' : 'Subscription Approval',
        isArabic ? 'راجع إيصالات الدفع المرفوعة وقم بتفعيل حسابات المناديب بنقرة واحدة.' : 'Review uploaded payment receipts and activate user accounts with a single tap.',
        Icons.verified_user_rounded,
      ),
      _buildStepCard(
        isArabic ? 'إدارة الرتب' : 'User Management',
        isArabic ? 'تحكم في صلاحيات المستخدمين، امنح فترات تجريبية، أو قم بإلغاء حسابات معينة.' : 'Control user roles, grant trial periods, or deactivate specific accounts.',
        Icons.manage_accounts_rounded,
      ),
      _buildStepCard(
        isArabic ? 'مركز الأخبار' : 'Global Announcements',
        isArabic ? 'انشر أخباراً وصوراً تصل فوراً لكافة مستخدمي النظام عبر تبويب الأخبار.' : 'Publish news and images that reach all users instantly via the News tab.',
        Icons.campaign_rounded,
      ),
    ];
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStepCard(String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey[600], height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
