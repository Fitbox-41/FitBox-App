import 'package:flutter/material.dart';

/// FitBox brand palette — charcoal + red (from the logo).
class FitBoxColors {
  const FitBoxColors._();

  static const Color red = Color(0xFFE31E24);
  static const Color redDark = Color(0xFFB3141A);
  static const Color charcoal = Color(0xFF2E2E30);

  // Semantic colours for the wallet ledger (not brand): money in / money out.
  static const Color credit = Color(0xFF12855B);
  static const Color debit = Color(0xFFC62828);
}

/// Centralised theme so every screen shares one consistent look.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: FitBoxColors.red,
      primary: FitBoxColors.red,
      secondary: FitBoxColors.charcoal,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
