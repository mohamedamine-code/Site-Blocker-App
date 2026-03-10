import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  const AppPalette._();

  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const accent = Color(0xFF00E5FF);
  static const danger = Color(0xFFFF4444);
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.accent,
    onPrimary: Color(0xFF001317),
    primaryContainer: Color(0xFF00343D),
    onPrimaryContainer: AppPalette.textPrimary,
    secondary: Color(0xFF57D8EA),
    onSecondary: Color(0xFF00262D),
    secondaryContainer: Color(0xFF073D48),
    onSecondaryContainer: AppPalette.textPrimary,
    tertiary: Color(0xFF8AA4FF),
    onTertiary: Color(0xFF00105A),
    tertiaryContainer: Color(0xFF1E2B6D),
    onTertiaryContainer: AppPalette.textPrimary,
    error: AppPalette.danger,
    onError: AppPalette.textPrimary,
    errorContainer: Color(0xFF431A1A),
    onErrorContainer: AppPalette.textPrimary,
    surface: AppPalette.surface,
    onSurface: AppPalette.textPrimary,
    onSurfaceVariant: AppPalette.textSecondary,
    outline: Color(0xFF2F363D),
    outlineVariant: Color(0xFF262C33),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppPalette.textPrimary,
    onInverseSurface: AppPalette.surface,
    inversePrimary: Color(0xFF00BCD4),
    surfaceContainerHighest: Color(0xFF1F2630),
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
    brightness: Brightness.dark,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppPalette.background,
    canvasColor: AppPalette.background,
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2F363D),
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
        side: const BorderSide(color: Color(0xFF2F363D)),
      ),
    ),
    iconTheme: const IconThemeData(color: AppPalette.textPrimary),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A212B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2F363D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2F363D)),
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
        foregroundColor: const Color(0xFF001317),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppPalette.textPrimary,
        side: const BorderSide(color: Color(0xFF2F363D)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1F2630),
      selectedColor: const Color(0xFF073D48),
      side: const BorderSide(color: Color(0xFF2F363D)),
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
      backgroundColor: const Color(0xFF1A212B),
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
