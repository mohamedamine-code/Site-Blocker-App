import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  const AppPalette._();

  static const background = Color(0xFF81A6C6);
  static const surface = Color(0xFFAACDDC);
  static const accent = Color(0xFFF3E3D0);
  static const danger = Color(0xFFD2C4B4);
  static const textPrimary = Color(0xFF1F3242);
  static const textSecondary = Color(0xFF3F596F);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.accent,
    onPrimary: Color(0xFF2B1E12),
    primaryContainer: Color(0xFFF7EBDD),
    onPrimaryContainer: Color(0xFF2B1E12),
    secondary: Color(0xFF81A6C6),
    onSecondary: Color(0xFF112332),
    secondaryContainer: Color(0xFFAACDDC),
    onSecondaryContainer: Color(0xFF1C3345),
    tertiary: Color(0xFFD2C4B4),
    onTertiary: Color(0xFF2F2720),
    tertiaryContainer: Color(0xFFE2D8CB),
    onTertiaryContainer: Color(0xFF3A3027),
    error: AppPalette.danger,
    onError: Color(0xFF2F2720),
    errorContainer: Color(0xFFE2D8CB),
    onErrorContainer: Color(0xFF3A3027),
    surface: AppPalette.surface,
    onSurface: AppPalette.textPrimary,
    onSurfaceVariant: AppPalette.textSecondary,
    outline: Color(0xFF6B859B),
    outlineVariant: Color(0xFF8DA6BC),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppPalette.textPrimary,
    onInverseSurface: AppPalette.surface,
    inversePrimary: Color(0xFFE8D8C3),
    surfaceContainerHighest: Color(0xFFBBD8E4),
  );

  final baseTextTheme = GoogleFonts.interTextTheme().apply(
    bodyColor: AppPalette.textPrimary,
    displayColor: AppPalette.textPrimary,
  );

  final textTheme = baseTextTheme.copyWith(
    headlineMedium: GoogleFonts.syne(
      fontWeight: FontWeight.w700,
      color: AppPalette.textPrimary,
      fontSize: 28,
      letterSpacing: 0.2,
    ),
    titleLarge: GoogleFonts.syne(
      fontWeight: FontWeight.w700,
      color: AppPalette.textPrimary,
      fontSize: 22,
      letterSpacing: 0.2,
    ),
    titleMedium: GoogleFonts.syne(
      fontWeight: FontWeight.w700,
      color: AppPalette.textPrimary,
      fontSize: 18,
      letterSpacing: 0.2,
    ),
    bodyMedium: GoogleFonts.inter(
      fontWeight: FontWeight.w500,
      color: AppPalette.textPrimary,
      fontSize: 15,
      height: 1.35,
    ),
    labelLarge: GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      color: AppPalette.textPrimary,
      fontSize: 14,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppPalette.background,
    canvasColor: AppPalette.background,
    dividerTheme: const DividerThemeData(
      color: Color(0xFF6B859B),
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.background,
      foregroundColor: AppPalette.textPrimary,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppPalette.surface,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF8DA6BC)),
      ),
    ),
    iconTheme: const IconThemeData(color: AppPalette.textPrimary),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFBBD8E4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6B859B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6B859B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.accent, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(
        color: AppPalette.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: GoogleFonts.inter(
        color: AppPalette.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: AppPalette.accent,
        foregroundColor: const Color(0xFF2B1E12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppPalette.textPrimary,
        side: const BorderSide(color: Color(0xFF6B859B)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFBBD8E4),
      selectedColor: const Color(0xFFE2D8CB),
      side: const BorderSide(color: Color(0xFF6B859B)),
      labelStyle: GoogleFonts.inter(
        color: AppPalette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppPalette.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFFAACDDC),
      contentTextStyle: GoogleFonts.inter(
        color: AppPalette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

TextStyle monoTextStyle(BuildContext context, {double size = 14, FontWeight weight = FontWeight.w600}) {
  return GoogleFonts.jetBrainsMono(
    color: Theme.of(context).colorScheme.onSurface,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: 0.2,
  );
}
