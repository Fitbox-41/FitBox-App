import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FitBox typography system — athletic, condensed, inspired by Adidas Running.
///
/// Two type families, one source of truth:
/// - **Oswald** (a free, condensed grotesque) for everything expressive and
///   branded: display metrics, screen/section titles, numbers, caps labels AND
///   buttons. Bold, uppercase, tracked = the athletic sport feel. Used on BOTH
///   platforms (uniform brand voice). Oswald's heaviest weight is w700.
/// - **Platform body font** for reading paragraphs: Inter on Android, San
///   Francisco (SF Pro) on iOS — resolved by [platformFont].
///
/// This is the ONLY place `GoogleFonts.oswald(...)` is called. Never call
/// GoogleFonts directly in a screen — consume `AppTypography.*` (or the theme
/// `TextTheme`, or the `AppText` shim). Titles/labels/buttons are UPPERCASE by
/// convention (callers `.toUpperCase()` the text).
class AppTypography {
  const AppTypography._();

  // ── Low-level builders ─────────────────────────────────────────────────────

  /// The athletic brand grotesque (Oswald, condensed) — the expressive family.
  static TextStyle brand({
    double? size,
    FontWeight weight = FontWeight.w700,
    double? letterSpacing,
    double? height,
    Color? color,
  }) =>
      GoogleFonts.oswald(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );

  /// Platform body font — Inter (Android) / SF Pro (iOS).
  static TextStyle platform({
    double? size,
    FontWeight? weight,
    double? letterSpacing,
    double? height,
    Color? color,
  }) =>
      platformFont(
        size: size,
        weight: weight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );

  // ── Brand (Oswald) roles — both platforms ─────────────────────────────────

  /// Huge numeric hero — run timer / countdown.
  static TextStyle displayXL({Color? color}) =>
      brand(size: 64, weight: FontWeight.w700, height: 1.0, letterSpacing: 0, color: color);

  /// Big statistic — steps ring, points balance.
  static TextStyle displayLarge({Color? color}) =>
      brand(size: 44, weight: FontWeight.w700, height: 1.0, letterSpacing: 0, color: color);

  /// Metric value inside a tile (calories/distance/pace/steps). Size-tunable.
  static TextStyle metric({double size = 30, Color? color}) =>
      brand(size: size, weight: FontWeight.w700, height: 1.0, letterSpacing: 0, color: color);

  /// Large in-screen heading (e.g. "WELCOME BACK"). Size-tunable.
  static TextStyle heading({double size = 28, Color? color}) =>
      brand(size: size, weight: FontWeight.w700, height: 1.05, letterSpacing: 0.5, color: color);

  /// Screen title (AppBar) — UPPERCASE by convention, wide tracking.
  static TextStyle screenTitle({double size = 24, Color? color}) =>
      brand(size: size, weight: FontWeight.w700, letterSpacing: 1.5, color: color);

  /// Section header ("THIS WEEK", "LEDGER"). Size-tunable.
  static TextStyle sectionTitle({double size = 20, Color? color}) =>
      brand(size: size, weight: FontWeight.w700, letterSpacing: 0.8, color: color);

  /// Card/list-row title.
  static TextStyle title({double size = 17, Color? color}) =>
      brand(size: size, weight: FontWeight.w600, letterSpacing: 0.2, color: color);

  /// Small uppercase technical label (DISTANCE / PACE / TIME). Caller uppercases.
  static TextStyle label({double size = 12, Color? color}) =>
      brand(size: size, weight: FontWeight.w600, letterSpacing: 2.0, color: color);

  /// Tiny uppercase overline.
  static TextStyle overline({Color? color}) =>
      brand(size: 10, weight: FontWeight.w700, letterSpacing: 1.8, color: color);

  /// Button text — Oswald bold, wide-tracked. UPPERCASE by convention.
  static TextStyle button({double size = 15, Color? color}) =>
      brand(size: size, weight: FontWeight.w700, letterSpacing: 1.0, color: color);

  // ── Platform-font roles (Inter / SF Pro) — reading text ────────────────────

  static TextStyle body({double size = 15, Color? color}) =>
      platformFont(size: size, weight: FontWeight.w400, height: 1.45, color: color);

  static TextStyle bodySmall({Color? color}) =>
      platformFont(size: 13, weight: FontWeight.w400, height: 1.4, color: color);

  /// Slightly emphasised supporting text.
  static TextStyle subtitle({double size = 14, Color? color}) =>
      platformFont(size: size, weight: FontWeight.w500, height: 1.35, color: color);

  /// Muted caption / metadata.
  static TextStyle caption({double size = 12, Color? color}) =>
      platformFont(size: size, weight: FontWeight.w400, color: color);
}

/// True on Apple platforms (iOS/macOS) — where the body font is San Francisco.
bool get isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// A text style in the platform's body font: **SF Pro on Apple, Inter elsewhere**.
/// Used for reading paragraphs; Oswald (see [AppTypography]) is used for
/// everything expressive/branded.
TextStyle platformFont({
  double? size,
  FontWeight? weight,
  FontStyle? style,
  double? letterSpacing,
  double? height,
  Color? color,
  bool display = false,
}) {
  if (isApplePlatform) {
    return TextStyle(
      fontFamily: display ? '.SF Pro Display' : '.SF Pro Text',
      fontFamilyFallback: const <String>['.SF Pro Display', '.SF Pro Text'],
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    fontStyle: style,
    letterSpacing: letterSpacing,
    height: height,
    color: color,
  );
}
