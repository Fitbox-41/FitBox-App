import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FitBox brand + glass palette ("Aerostride Kinetic"), working in light and dark.
class FitBoxColors {
  const FitBoxColors._();

  // Brand
  static const Color red = Color(0xFFE31E24);
  static const Color redDark = Color(0xFFB3141A);
  static const Color charcoal = Color(0xFF2E2E30);

  // Gradient backdrops — deep "engine bay" black on dark; soft light on light.
  static const Color bgTopDark = Color(0xFF14181C);
  static const Color bgBottomDark = Color(0xFF0A0C0F);
  static const Color bgTopLight = Color(0xFFF2F4F8);
  static const Color bgBottomLight = Color(0xFFE6E9F0);

  // Semantic (wallet ledger, capture/loss)
  static const Color credit = Color(0xFF19A463);
  static const Color debit = Color(0xFFE5484D);

  // Glass tokens per brightness — iOS-style translucent material.
  static Color glassFill(Brightness b) => b == Brightness.dark
      ? charcoal.withValues(alpha: 0.55)
      : Colors.white.withValues(alpha: 0.6);
  static Color glassStroke(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.14)
      : Colors.white.withValues(alpha: 0.7);
}

/// Named text styles beyond the Material TextTheme — the "kinetic" italic
/// headers and the rounded data numerals used across the app.
class AppText {
  const AppText._();

  /// Forward-leaning italic header (Hanken Grotesk) — the brand voice.
  static TextStyle kinetic(
    BuildContext context, {
    double size = 32,
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) =>
      GoogleFonts.hankenGrotesk(
        fontSize: size,
        fontWeight: weight,
        fontStyle: FontStyle.italic,
        height: 1.05,
        letterSpacing: -0.5,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Big rounded data numerals (Plus Jakarta Sans) — steps, timers, points.
  static TextStyle data(
    BuildContext context, {
    double size = 42,
    Color? color,
    bool italic = false,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: 1.0,
        letterSpacing: -1,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Uppercase technical label with wide tracking (Plus Jakarta Sans).
  static TextStyle labelCaps(
    BuildContext context, {
    double size = 12,
    Color? color,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      );
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

    // Body = Inter; headlines = Hanken Grotesk (italic, kinetic); data = Plus
    // Jakarta Sans. Built on the Material baseline so sizes stay sensible.
    final TextTheme base = (brightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light())
        .textTheme;
    final TextTheme inter = GoogleFonts.interTextTheme(base);
    TextStyle kinetic(TextStyle? s) => GoogleFonts.hankenGrotesk(
          textStyle: s,
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          letterSpacing: -0.5,
          height: 1.05,
        );
    final TextTheme textTheme = inter.copyWith(
      displayLarge: kinetic(base.displayLarge),
      displayMedium: kinetic(base.displayMedium),
      displaySmall: kinetic(base.displaySmall),
      headlineLarge: kinetic(base.headlineLarge),
      headlineMedium: kinetic(base.headlineMedium),
      headlineSmall: kinetic(base.headlineSmall),
      titleLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Kinetic italic AppBar titles.
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          letterSpacing: -0.5,
          color: onSurface,
        ),
        foregroundColor: onSurface,
      ),
      dividerColor: onSurface.withValues(alpha: 0.12),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: onSurface.withValues(alpha: 0.05),
        // Pill inputs to contrast the structured grid.
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: FitBoxColors.red, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.14)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FitBoxColors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          // Fully rounded pill.
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: onSurface.withValues(alpha: 0.18)),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
