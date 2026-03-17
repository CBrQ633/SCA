import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color bgLight = Color(0xFFF1F5F9);
  static const Color bgDark = Color(0xFF020617); // Deeper Navy for Dark Mode
  static const Color surfaceDark = Color(0xFF0F172A);

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
      titleTextStyle: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo'),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: accentEmerald.withOpacity(0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: accentEmerald);
        }
        return const IconThemeData(color: Colors.grey);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: accentEmerald, fontWeight: FontWeight.bold, fontSize: 12);
        }
        return const TextStyle(color: Colors.grey, fontSize: 12);
      }),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      labelStyle: const TextStyle(color: Colors.blueGrey),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: primaryNavy),
      bodyMedium: TextStyle(color: primaryNavy),
      titleMedium: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
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
      surface: surfaceDark,
      onSurface: Colors.white,
      onPrimary: primaryNavy,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo'),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceDark,
      indicatorColor: accentEmerald.withOpacity(0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: accentEmerald);
        }
        return const IconThemeData(color: Colors.white70);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: accentEmerald, fontWeight: FontWeight.bold, fontSize: 12);
        }
        return const TextStyle(color: Colors.white70, fontSize: 12);
      }),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentEmerald,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
