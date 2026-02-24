import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF0F172A); // Deep Navy
  static const Color accentColor = Color(0xFF10B981);  // Emerald Green
  static const Color scaffoldBg = Color(0xFFF1F5F9);   // Light Grayish Blue

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    brightness: Brightness.light,
    scaffoldBackgroundColor: scaffoldBg,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: Colors.white,
      onSurface: primaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
    ),
    cardTheme: CardThemeData( // ✅ Corrected from CardTheme to CardThemeData
      color: Colors.white,
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

  // ✅ Added missing darkTheme to fix the build error
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF020617), // Very Dark Navy
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: accentColor,
      surface: Color(0xFF0F172A),
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF020617),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF0F172A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
    ),
  );
}
