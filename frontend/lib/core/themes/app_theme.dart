import 'package:flutter/material.dart';

class AppTheme {
  // Theme Colors
  static const Color accentGreen = Color(0xFF68BB59);
  static const Color accentPink = Color(0xFFE91E63);

  // Light Mode Colors
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Color(0xFFF8F9FA);
  static const Color lightTextPrimary = Colors.black87;
  static const Color lightTextSecondary = Color(0xFF616161);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF262626);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);

  static const Color inactiveGray = Color(0xFF757575);

  // ✅ Default theme is LIGHT MODE (Green)
  static ThemeData get defaultTheme => greenLightTheme;

  // Green Themes
  static ThemeData get greenLightTheme => _buildLightTheme(accentGreen);
  static ThemeData get greenDarkTheme => _buildDarkTheme(accentGreen);

  // Pink Themes
  static ThemeData get pinkLightTheme => _buildLightTheme(accentPink);
  static ThemeData get pinkDarkTheme => _buildDarkTheme(accentPink);

  // --- Light Theme Builder ---
  static ThemeData _buildLightTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: inactiveGray,
        surface: lightBackground,
        surfaceVariant: lightSurface,
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        outline: const Color(0xFFE0E0E0),
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: lightTextPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: lightTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: lightTextSecondary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: lightTextSecondary, height: 1.4),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: inactiveGray),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightBackground,
        selectedItemColor: primaryColor,
        unselectedItemColor: inactiveGray,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // --- Dark Theme Builder ---
  static ThemeData _buildDarkTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: inactiveGray,
        surface: darkBackground,
        surfaceVariant: darkSurface,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        outline: const Color(0xFF616161),
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: darkTextPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: darkTextSecondary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: darkTextSecondary, height: 1.4),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: inactiveGray),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkBackground,
        selectedItemColor: primaryColor,
        unselectedItemColor: inactiveGray,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}