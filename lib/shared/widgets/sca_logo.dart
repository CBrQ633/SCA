import 'package:flutter/material.dart';
import 'dart:ui';

class ScaLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const ScaLogo({
    super.key,
    this.size = 100,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00C6FF),
                Color(0xFF0072FF)
              ], // Vibrant Blue to Teal
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glassmorphism effect overlay
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              // Communication Icon (Stylized Phone/Waves)
              Icon(
                Icons.phone_in_talk_rounded,
                size: size * 0.5,
                color: Colors.white,
              ),
              // Signal Waves (Custom decoration)
              Positioned(
                top: size * 0.2,
                right: size * 0.2,
                child: Icon(
                  Icons.wifi,
                  size: size * 0.2,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'SCA',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
            ),
          ),
          Text(
            'Smart Call Assistant',
            style: TextStyle(
              fontSize: size * 0.12,
              fontWeight: FontWeight.w300,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
