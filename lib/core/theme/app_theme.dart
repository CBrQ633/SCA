import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color bgLight = Color(0xFFF1F5F9);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgLight,
    colorScheme: const ColorScheme.light(
      primary: primaryNavy,
      secondary: accentEmerald,
      surface: Colors.white,
      onSurface: primaryNavy, // ✅ Ensures text is Navy on White
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: primaryNavy,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: primaryNavy),
      titleTextStyle: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 18),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: primaryNavy),
      bodyMedium: TextStyle(color: primaryNavy),
      titleMedium: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
    ),
  );

  // Forcing Light Theme for now to ensure consistency
  static ThemeData darkTheme = lightTheme;
}
