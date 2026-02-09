import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_call_assistant/core/providers/settings_provider.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<SettingsProvider>().locale.languageCode == 'ar';
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'طريقة الاستخدام' : 'How to Use'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  isAdmin
                      ? (isArabic ? 'دليل المشرف' : 'Admin Guide')
                      : (isArabic ? 'دليل المستخدم' : 'User Guide'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAdmin
                      ? (isArabic
                          ? 'كيفية إدارة التطبيق'
                          : 'How to manage the application')
                      : (isArabic
                          ? 'كيفية استخدام التطبيق'
                          : 'How to use the application'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Steps
          if (isAdmin)
            ..._buildAdminGuide(isArabic)
          else
            ..._buildUserGuide(isArabic),
        ],
      ),
    );
  }

  List<Widget> _buildUserGuide(bool isArabic) {
    return [
      _buildStepCard(
        stepNumber: '1',
        title: isArabic ? 'استيراد الأرقام' : 'Import Numbers',
        description: isArabic
            ? 'انتقل إلى شاشة "المكالمات" ← اضغط "+" ← اختر "استيراد من Excel" أو "استيراد من صورة"'
            : 'Go to "Calls" screen ← Press "+" ← Choose "Import from Excel" or "Import from Image"',
        icon: Icons.upload_file,
        color: Colors.blue,
      ),
      _buildStepCard(
        stepNumber: '2',
        title: isArabic ? 'إنشاء قائمة مكالمات' : 'Create Call List',
        description: isArabic
            ? 'بعد استيراد الأرقام، اكتب اسم القائمة ← اضغط "حفظ"'
            : 'After importing numbers, enter list name ← Press "Save"',
        icon: Icons.list,
        color: Colors.green,
      ),
      _buildStepCard(
        stepNumber: '3',
        title: isArabic ? 'بدء المكالمات' : 'Start Calling',
        description: isArabic
            ? 'اضغط على القائمة ← "بدء المكالمات" ← سجل نتيجة كل مكالمة (رد/مش رد/مهتم/إلخ)'
            : 'Tap on list ← "Start Calling" ← Record result for each call (Answered/No Answer/Interested/etc)',
        icon: Icons.phone,
        color: Colors.orange,
      ),
      _buildStepCard(
        stepNumber: '4',
        title: isArabic ? 'عرض التقارير' : 'View Reports',
        description: isArabic
            ? 'انتقل إلى تبويب "التقارير" لعرض إحصائيات المكالمات والنتائج'
            : 'Go to "Reports" tab to view call statistics and results',
        icon: Icons.analytics,
        color: Colors.purple,
      ),
      _buildStepCard(
        stepNumber: '5',
        title: isArabic ? 'تجديد الاشتراك' : 'Renew Subscription',
        description: isArabic
            ? 'انتقل إلى "الاشتراك" ← اختر الباقة ← ادفع عبر فودافون كاش أو إنستاباي ← ارفع صورة الإيصال ← انتظر الموافقة'
            : 'Go to "Subscription" ← Choose plan ← Pay via Vodafone Cash or Instapay ← Upload receipt ← Wait for approval',
        icon: Icons.star,
        color: Colors.amber,
      ),
    ];
  }

  List<Widget> _buildAdminGuide(bool isArabic) {
    return [
      _buildStepCard(
        stepNumber: '1',
        title:
            isArabic ? 'مراجعة طلبات الاشتراك' : 'Review Subscription Requests',
        description: isArabic
            ? 'انتقل إلى "Sub Requests" ← اضغط على الطلب ← شاهد صورة الدفع ← اضغط "موافقة" أو "رفض"'
            : 'Go to "Sub Requests" ← Tap on request ← View payment screenshot ← Press "Approve" or "Reject"',
        icon: Icons.subscriptions,
        color: Colors.blue,
      ),
      _buildStepCard(
        stepNumber: '2',
        title: isArabic ? 'إضافة الأخبار' : 'Add News',
        description: isArabic
            ? 'انتقل إلى "News" ← اضغط "+" ← اكتب العنوان والمحتوى ← اضغط "نشر"'
            : 'Go to "News" ← Press "+" ← Write title and content ← Press "Publish"',
        icon: Icons.newspaper,
        color: Colors.green,
      ),
      _buildStepCard(
        stepNumber: '3',
        title: isArabic ? 'إدارة الصلاحيات' : 'Manage Permissions',
        description: isArabic
            ? 'في Supabase Dashboard، يمكنك تغيير صلاحيات المستخدمين (admin/user)'
            : 'In Supabase Dashboard, you can change user roles (admin/user)',
        icon: Icons.admin_panel_settings,
        color: Colors.purple,
      ),
    ];
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with step number and icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      stepNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 28),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
