import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primary = color ?? Theme.of(context).colorScheme.primary;
    final accent = Theme.of(context).colorScheme.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer geometric shape
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(size * 0.3),
                border: Border.all(color: primary, width: size * 0.05),
              ),
            ),
            // Inner decorative element
            Positioned(
              right: size * 0.1,
              top: size * 0.1,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // The "SCA" initials
            Text(
              'SCA',
              style: TextStyle(
                color: primary,
                fontSize: size * 0.35,
                fontWeight: FontWeight.w900, // Changed from black to w900
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        if (showText) ...[
          SizedBox(height: size * 0.15),
          Text(
            'Smart Call Assistant',
            style: TextStyle(
              color: primary.withValues(alpha: 0.8),
              fontSize: size * 0.18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
