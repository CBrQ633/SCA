import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';

class EmailConfirmationSuccessScreen extends StatelessWidget {
  const EmailConfirmationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: const AppLogo(size: 80, showText: false),
              ),
              const SizedBox(height: 48),
              
              FadeIn(
                delay: const Duration(milliseconds: 500),
                child: const Icon(Icons.check_circle_outline_rounded, size: 100, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 24),
              
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: Column(
                  children: [
                    const Text(
                      'Success! / تم التفعيل بنجاح',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your email has been verified. You can now log in to the app.\nتم تفعيل بريدك الإلكتروني بنجاح. يمكنك الآن تسجيل الدخول إلى التطبيق.',
                      style: TextStyle(fontSize: 14, color: theme.hintColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 56),
              
              FadeInUp(
                delay: const Duration(milliseconds: 1000),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppConstants.routeLogin),
                    child: const Text('BACK TO LOGIN / العودة لتسجيل الدخول'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
