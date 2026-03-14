import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'استيراد ذكي للأرقام',
      desc: 'بكل بساطة، ارفع ملف إكسيل أو صورة سكرين شوت، والتطبيق سيقوم باستخراج الأرقام المصرية والأسماء بدقة متناهية.',
      icon: Icons.auto_fix_high_rounded,
    ),
    OnboardingItem(
      title: 'نظام الاتصال المتسلسل',
      desc: 'بدلاً من البحث عن كل رقم يدوياً، ابدأ جلسة اتصال ذكية تتنقل بك بين العملاء بضغطة زر واحدة (اتصال أو واتساب).',
      icon: Icons.play_circle_filled_rounded,
    ),
    OnboardingItem(
      title: 'تقارير احترافية ومفصلة',
      desc: 'تابع معدل نجاحك وصدر تقارير إكسيل مفصلة للعملاء الذين ردوا أو لم يردوا، مع إمكانية كتابة ملاحظاتك الخاصة.',
      icon: Icons.insights_rounded,
    ),
    OnboardingItem(
      title: 'ابدأ نجاحك الآن',
      desc: 'فعل اشتراكك الآن لتفتح الباب أمام نظام مبيعات منظم، سريع، واحترافي يضاعف إنتاجيتك.',
      icon: Icons.star_rounded,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      context.go(AppConstants.routeSubscription);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F172A);
    const emerald = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const AppLogo(size: 60, showText: true),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _items.length,
                itemBuilder: (context, idx) => _buildPage(_items[idx]),
              ),
            ),
            
            // Indicators & Button
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (idx) => _buildIndicator(idx == _currentPage, emerald)),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _items.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _items.length - 1 ? 'ابدأ الآن / GET STARTED' : 'التالي / NEXT',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('تخطي / Skip', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: Icon(item.icon, size: 80, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 48),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          Text(
            item.desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.blueGrey[600], height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(color: isActive ? color : Colors.grey[300], borderRadius: BorderRadius.circular(4)),
    );
  }
}

class OnboardingItem {
  final String title;
  final String desc;
  final IconData icon;
  OnboardingItem({required this.title, required this.desc, required this.icon});
}
