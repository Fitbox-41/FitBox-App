import 'package:flutter/material.dart';

/// FitBox brand + dark "glass" palette (Apple-style frosted UI).
class FitBoxColors {
  const FitBoxColors._();

  // Brand
  static const Color red = Color(0xFFE31E24);
  static const Color redDark = Color(0xFFB3141A);
  static const Color charcoal = Color(0xFF2E2E30);

  // Dark gradient backdrop (glass needs depth behind it).
  static const Color bgTop = Color(0xFF1A1B21);
  static const Color bgBottom = Color(0xFF0A0B0E);

  // Semantic (wallet ledger) — bright enough for the dark theme.
  static const Color credit = Color(0xFF32D583);
  static const Color debit = Color(0xFFFF5A5F);

  // Glass surface tokens
  static Color glassFill = Colors.white.withValues(alpha: 0.06);
  static Color glassStroke = Colors.white.withValues(alpha: 0.12);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _dark();
  static ThemeData dark() => _dark();

  static ThemeData _dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: FitBoxColors.red,
      primary: FitBoxColors.red,
      secondary: FitBoxColors.red,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerColor: Colors.white24,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIconColor: Colors.white60,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FitBoxColors.red, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FitBoxColors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
