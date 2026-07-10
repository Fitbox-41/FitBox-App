import 'package:flutter/material.dart';

/// FitBox brand + glass palette, working in light and dark.
class FitBoxColors {
  const FitBoxColors._();

  // Brand
  static const Color red = Color(0xFFE31E24);
  static const Color redDark = Color(0xFFB3141A);
  static const Color charcoal = Color(0xFF2E2E30);

  // Gradient backdrops (glass needs depth behind it)
  static const Color bgTopDark = Color(0xFF1A1B21);
  static const Color bgBottomDark = Color(0xFF0A0B0E);
  static const Color bgTopLight = Color(0xFFF2F4F8);
  static const Color bgBottomLight = Color(0xFFE6E9F0);

  // Semantic (wallet ledger)
  static const Color credit = Color(0xFF19A463);
  static const Color debit = Color(0xFFE5484D);

  // Glass tokens per brightness
  static Color glassFill(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.55);
  static Color glassStroke(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.white.withValues(alpha: 0.7);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: FitBoxColors.red,
      primary: FitBoxColors.red,
      brightness: brightness,
    );
    final Color onSurface = scheme.onSurface;

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
      dividerColor: onSurface.withValues(alpha: 0.15),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: onSurface.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FitBoxColors.red, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.14)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FitBoxColors.red,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: onSurface.withValues(alpha: 0.18)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
