import 'package:flutter/material.dart';

/// Design tokens from SPEC.md §7.
/// All colors, text styles, and shapes are defined here.
class AppColors {
  static const bg0 = Color(0xFF0B1020);
  static const bg1 = Color(0xFF101730);
  static const bg2 = Color(0xFF151D3B);
  
  static const glassPanelBg = Color(0x73151D3B); // rgba(21, 29, 59, 0.45)
  static const glassPanelBorder = Color(0x1EFFFFFF); // rgba(255, 255, 255, 0.12)
  static const glassInputBg = Color(0x800B1020); // rgba(11, 16, 32, 0.5)
  static const glassInputBorder = Color(0x1AFFFFFF); // rgba(255, 255, 255, 0.1)
  
  static const surface = Color(0x1AFFFFFF); // 10% white for glass
  static const surfaceStrong = Color(0x33FFFFFF); // 20% white
  static const border = Color(0x1EFFFFFF); // 12% white
  static const borderHighlight = Color(0x38FFFFFF); // 22% white

  // Glowing Orbs
  static const orb1 = Color(0xFF2563EB); // Blue 600
  static const orb2 = Color(0xFF6366F1); // Indigo 500
  static const orb3 = Color(0xFF38BDF8); // Sky 400

  static const text = Color(0xFFF3F4F6); // Gray 100
  static const textMuted = Color(0xFF9CA3AF); // Gray 400
  static const accent = Color(0xFF60A5FA); // Blue 400
  static const accentSoft = Color(0xFF93C5FD); // Blue 300
  static const error = Color(0xFFF87171); // Red 400
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
