import 'package:flutter/material.dart';

/// Advanced Premium Dark Theme Tokens
class AppColors {
  // Deep space/aurora backgrounds
  static const bg0 = Color(0xFF03050F);
  static const bg1 = Color(0xFF0A0F2C);
  
  // Glassmorphic surfaces
  static const surface = Color(0x0FFFFFFF);       // 6% white
  static const surfaceStrong = Color(0x15FFFFFF);  // 8% white
  static const glassBorder = Color(0x20FFFFFF);    // 12% white for glass edges
  static const border = Color(0x1AFFFFFF);
  
  // Text
  static const text = Color(0xFFF0F4FA);
  static const textMuted = Color(0xFF8B9CB6);
  
  // Neon / Aurora accents
  static const accent = Color(0xFF00D4FF);        // Glowing Cyan
  static const accentSoft = Color(0xFFB570FF);    // Soft Violet/Pink
  
  static const error = Color(0xFFFF5252);
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
  static const double radius = 24;
  static const double radiusSm = 12;
  static const double blur = 24; // Deeper blur for premium glass
}

/// Duration constants for animations.
class AppDurations {
  static const fast = Duration(milliseconds: 200);
  static const base = Duration(milliseconds: 500);
  static const seal = Duration(milliseconds: 800);
}

/// Curves for animations.
class AppCurves {
  static const easeOut = Curves.easeOutCirc;
  static const seal = Curves.easeInOutQuart;
}

/// Builds the app-wide ThemeData.
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent, // Background rendered by Aurora
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accentSoft,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
        letterSpacing: -1.0,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        letterSpacing: -0.5,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.text,
        foregroundColor: AppColors.bg0,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp8,
          vertical: AppSpacing.sp4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.radius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent, // Controlled by GlassCard instead
      hintStyle: const TextStyle(color: AppColors.textMuted),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.all(AppSpacing.sp4),
    ),
  );
}
