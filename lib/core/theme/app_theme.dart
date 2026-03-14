import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color bgLight = Color(0xFFF1F5F9);
  static const Color bgDark = Color(0xFF020617); // Deeper Navy for Dark Mode

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgLight,
    colorScheme: const ColorScheme.light(
      primary: primaryNavy,
      secondary: accentEmerald,
      surface: Colors.white,
      onSurface: primaryNavy,
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
    cardTheme: CardThemeData(
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

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: accentEmerald,
      surface: Color(0xFF0F172A),
      onSurface: Colors.white,
      onPrimary: primaryNavy,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF0F172A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}
