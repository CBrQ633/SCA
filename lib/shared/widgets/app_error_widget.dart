import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData? icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              child: Icon(
                icon ?? Icons.cloud_off_rounded,
                size: 80,
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            FadeIn(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              child: SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('RETRY / إعادة محاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
