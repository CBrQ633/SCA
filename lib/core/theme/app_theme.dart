import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - High Contrast for Clarity
  static const Color primaryColor = Color(0xFF0F172A); // Deep Navy
  static const Color accentColor = Color(0xFF10B981);  // Emerald Green
  static const Color scaffoldBg = Color(0xFFF1F5F9);   // Light Grayish Blue
  static const Color cardColor = Colors.white;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    brightness: Brightness.light,
    scaffoldBackgroundColor: scaffoldBg,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: cardColor,
      onSurface: primaryColor, // 👈 Ensures text is always Deep Navy on white surfaces
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: primaryColor),
      bodyMedium: TextStyle(color: primaryColor),
      titleMedium: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
    ),
  );
}
