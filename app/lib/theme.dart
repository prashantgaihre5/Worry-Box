import 'package:flutter/material.dart';

/// Design tokens from SPEC.md §7.
/// All colors, text styles, and shapes are defined here.
class AppColors {
  static const bg0 = Color(0xFF0B1020);
  static const bg1 = Color(0xFF151D3B);
  static const surface = Color(0x0FFFFFFF);       // 6% white
  static const surfaceStrong = Color(0x1AFFFFFF);  // 10% white
  static const border = Color(0x1FFFFFFF);         // 12% white
  static const text = Color(0xFFEAEEF7);
  static const textMuted = Color(0xFF97A3C4);
  static const accent = Color(0xFF7C9CF5);
  static const accentSoft = Color(0xFF8FD9C2);
  static const error = Color(0xFFFF6B6B);
}

/// Spacing scale (4px base).
class AppSpacing {
  static const double sp1 = 4;
  static const double sp2 = 8;
  static const double sp3 = 12;
  static const double sp4 = 16;
  static const double sp6 = 24;
  static const double sp8 = 32;
  static const double sp12 = 48;
}

/// Shape constants.
class AppShape {
  static const double radius = 16;
  static const double radiusSm = 10;
  static const double blur = 14;
}

/// Duration constants for animations.
class AppDurations {
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 400);
  static const seal = Duration(milliseconds: 700);
}

/// Curves for animations.
class AppCurves {
  static const easeOut = Curves.easeOutCubic;
  static const seal = Curves.easeInOutCubic;
}

/// Builds the app-wide ThemeData.
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accentSoft,
      surface: AppColors.bg1,
      error: AppColors.error,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp8,
          vertical: AppSpacing.sp4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.radius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceStrong,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppShape.radiusSm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppShape.radiusSm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppShape.radiusSm),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.sp4),
    ),
  );
}
