import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Offline Mode / وضع الأوفلاين',
      'desc': 'Work anywhere, even without internet. Your calls and notes will sync later.\nاشتغل في أي مكان حتى بدون إنترنت، مكالماتك وملاحظاتك هتترفع لما النت يرجع.',
      'icon': '🌐',
    },
    {
      'title': 'Smart Excel Import / استيراد ذكي',
      'desc': 'Upload your call lists from Excel in seconds and select columns easily.\nارفع قوائم مكالماتك من ملفات الإكسيل في ثواني واختار الأعمدة اللي تهمك بسهولة.',
      'icon': '📊',
    },
    {
      'title': 'AI OCR / سحب الأرقام بالذكاء الاصطناعي',
      'desc': 'Extract phone numbers directly from any image or flyer using AI.\nاسحب أرقام الموبايلات مباشرة من أي صورة أو إعلان باستخدام الذكاء الاصطناعي.',
      'icon': '📸',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) => setState(() => _currentPage = page),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index], theme),
              ),
            ),
            _buildBottomBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, String> data, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(
            child: Text(data['icon']!, style: const TextStyle(fontSize: 100)),
          ),
          const SizedBox(height: 40),
          FadeInUp(
            child: Text(
              data['title']!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              data['desc']!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _pages.length,
              (index) => Container(
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? theme.colorScheme.primary : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentPage < _pages.length - 1) {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
              } else {
                context.go(AppConstants.routeSubscription);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(_currentPage == _pages.length - 1 ? 'GET STARTED' : 'NEXT'),
          ),
        ],
      ),
    );
  }
}
