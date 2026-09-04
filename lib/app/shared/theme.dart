import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class TeamfitColors {
  static const coral500 = Color(0xFFFF4A2E);
  static const coral600 = Color(0xFFE13114);

  static const ink900 = Color(0xFF0A0F1E);
  static const ink800 = Color(0xFF111931);
  static const ink700 = Color(0xFF1B2646);
  static const ink300 = Color(0xFF9BA7C4);
  static const white = Color(0xFFFFFFFF);

  static const cyan400 = Color(0xFF00D3EE);
  static const cyan500 = Color(0xFF00B2CD);

  static const streak500 = Color(0xFFFFB020);

  static const brand = coral500;
  static const accent = cyan400;
  static const surfaceInverse = ink900;
  static const textOnInverse = white;
  static const textOnInverseMuted = ink300;
}

abstract final class TeamfitSpacing {
  static const radiusLg = 16.0;
  static const radiusPill = 999.0;
}

abstract final class TeamfitTypo {
  static TextStyle mono({
    double fontSize = 34,
    FontWeight fontWeight = FontWeight.w600,
    Color color = TeamfitColors.textOnInverse,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}

abstract final class TeamfitTheme {
  static ThemeData dark() {
    final displayFont = GoogleFonts.anton();
    final condensedFont = GoogleFonts.barlowCondensed();
    final textFont = GoogleFonts.barlow();

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: TeamfitColors.surfaceInverse,
      colorScheme: const ColorScheme.dark(
        primary: TeamfitColors.brand,
        secondary: TeamfitColors.accent,
        surface: TeamfitColors.ink800,
        onPrimary: TeamfitColors.white,
        onSecondary: TeamfitColors.ink900,
        onSurface: TeamfitColors.white,
      ),
      textTheme: TextTheme(
        displayLarge: displayFont.copyWith(
          fontSize: 88,
          height: 0.92,
          letterSpacing: -0.01 * 88,
          color: TeamfitColors.textOnInverse,
        ),
        displayMedium: displayFont.copyWith(
          fontSize: 64,
          height: 0.92,
          letterSpacing: -0.01 * 64,
          color: TeamfitColors.textOnInverse,
        ),
        displaySmall: displayFont.copyWith(
          fontSize: 44,
          height: 0.92,
          letterSpacing: -0.01 * 44,
          color: TeamfitColors.textOnInverse,
        ),
        headlineLarge: displayFont.copyWith(
          fontSize: 32,
          height: 0.92,
          color: TeamfitColors.textOnInverse,
        ),
        headlineMedium: condensedFont.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 24 * 0.06,
          color: TeamfitColors.textOnInverse,
        ),
        headlineSmall: condensedFont.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 20 * 0.06,
          color: TeamfitColors.textOnInverse,
        ),
        titleLarge: condensedFont.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 24 * 0.14,
          color: TeamfitColors.textOnInverse,
        ),
        titleMedium: condensedFont.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: TeamfitColors.textOnInverse,
        ),
        titleSmall: condensedFont.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: TeamfitColors.textOnInverse,
        ),
        bodyLarge: textFont.copyWith(
          fontSize: 18,
          height: 1.55,
          color: TeamfitColors.textOnInverse,
        ),
        bodyMedium: textFont.copyWith(
          fontSize: 16,
          height: 1.55,
          color: TeamfitColors.textOnInverse,
        ),
        bodySmall: textFont.copyWith(
          fontSize: 14,
          height: 1.55,
          color: TeamfitColors.textOnInverseMuted,
        ),
        labelLarge: condensedFont.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 14 * 0.14,
          color: TeamfitColors.textOnInverseMuted,
        ),
        labelMedium: condensedFont.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 12 * 0.14,
          color: TeamfitColors.textOnInverseMuted,
        ),
      ),
    );
  }
}
