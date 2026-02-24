import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/components/app_logo.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About SCA / عن التطبيق'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: const AppLogo(size: 120, showText: true),
              ),
              const SizedBox(height: 48),

              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Version $_version ($_buildNumber)',
                  style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 40),

              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      const Text('Developed by / المطور', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('Mahmoud Ayman Barakat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => launchUrl(Uri.parse('https://sites.google.com/view/mahmoudayman')),
                        icon: const Icon(Icons.language_rounded, size: 18),
                        label: const Text('Developer Website'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),
              FadeIn(
                delay: const Duration(seconds: 1),
                child: Text(
                  '© 2026 Mahmoud Ayman Barakat. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
