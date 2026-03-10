import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFFFAF3E1);
  static const surface = Color(0xFFF5E7C6);
  static const primary = Color(0xFFFF6D1F);
  static const dark = Color(0xFF222222);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.dark,
    primaryContainer: AppColors.surface,
    onPrimaryContainer: AppColors.dark,
    secondary: AppColors.background,
    onSecondary: AppColors.dark,
    secondaryContainer: AppColors.surface,
    onSecondaryContainer: AppColors.dark,
    tertiary: AppColors.surface,
    onTertiary: AppColors.dark,
    tertiaryContainer: AppColors.background,
    onTertiaryContainer: AppColors.dark,
    error: AppColors.primary,
    onError: AppColors.dark,
    errorContainer: AppColors.surface,
    onErrorContainer: AppColors.dark,
    surface: AppColors.surface,
    onSurface: AppColors.dark,
    onSurfaceVariant: AppColors.dark.withValues(alpha: 0.72),
    outline: AppColors.dark.withValues(alpha: 0.35),
    outlineVariant: AppColors.dark.withValues(alpha: 0.20),
    shadow: AppColors.dark.withValues(alpha: 0.35),
    scrim: AppColors.dark.withValues(alpha: 0.45),
    inverseSurface: AppColors.dark,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppColors.primary,
    surfaceContainerHighest: AppColors.background,
  );

  final baseTextTheme = GoogleFonts.cairoTextTheme().apply(
    bodyColor: AppColors.dark,
    displayColor: AppColors.dark,
  );

  final textTheme = baseTextTheme.copyWith(
    headlineMedium: GoogleFonts.tajawal(
      fontWeight: FontWeight.w700,
      color: AppColors.dark,
      fontSize: 28,
      letterSpacing: 0.2,
    ),
    titleLarge: GoogleFonts.tajawal(
      fontWeight: FontWeight.w700,
      color: AppColors.dark,
      fontSize: 22,
      letterSpacing: 0.2,
    ),
    titleMedium: GoogleFonts.tajawal(
      fontWeight: FontWeight.w700,
      color: AppColors.dark,
      fontSize: 18,
      letterSpacing: 0.2,
    ),
    bodyMedium: GoogleFonts.cairo(
      fontWeight: FontWeight.w500,
      color: AppColors.dark,
      fontSize: 15,
      height: 1.35,
    ),
    labelLarge: GoogleFonts.cairo(
      fontWeight: FontWeight.w600,
      color: AppColors.dark,
      fontSize: 14,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    dividerTheme: DividerThemeData(
      color: AppColors.dark.withValues(alpha: 0.35),
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.dark,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.dark.withValues(alpha: 0.20)),
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.dark),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.dark.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.dark.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: GoogleFonts.cairo(
        color: AppColors.dark.withValues(alpha: 0.72),
        fontWeight: FontWeight.w500,
      ),
      labelStyle: GoogleFonts.cairo(
        color: AppColors.dark.withValues(alpha: 0.72),
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.dark,
        side: BorderSide(color: AppColors.dark.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.background,
      selectedColor: AppColors.surface,
      side: BorderSide(color: AppColors.dark.withValues(alpha: 0.35)),
      labelStyle: GoogleFonts.cairo(
        color: AppColors.dark,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: GoogleFonts.cairo(
        color: AppColors.dark,
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
