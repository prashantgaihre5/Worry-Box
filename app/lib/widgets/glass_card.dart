import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

/// A premium glassmorphic card widget based on Figma Make Design UI.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isFocused;
  final Color? color;
  final Color? borderColor;
  final double? blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppShape.radiusSm,
    this.isFocused = false,
    this.color,
    this.borderColor,
    this.blur,
  });

  @override
  Widget build(BuildContext context) {
    // Figma default panel: rgba(21, 29, 59, 0.45), blur 20
    final defaultColor = const Color(0x73151D3B);
    final defaultBorder = const Color(0x1FFFFFFF);
    final defaultBlur = 20.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur ?? defaultBlur, 
          sigmaY: blur ?? defaultBlur
        ),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: padding ?? const EdgeInsets.all(AppSpacing.sp4),
          decoration: BoxDecoration(
            color: color ?? defaultColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isFocused ? AppColors.accent : (borderColor ?? defaultBorder),
              width: isFocused ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5E000000), // rgba(0, 0, 0, 0.37)
                blurRadius: 32,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A variant of GlassCard for Inputs
class GlassInputCard extends StatelessWidget {
  final Widget child;
  final bool isFocused;

  const GlassInputCard({
    super.key,
    required this.child,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    // Figma default input: rgba(11, 16, 32, 0.5), blur 16
    return GlassCard(
      blur: 16.0,
      color: const Color(0x800B1020),
      borderColor: const Color(0x1AFFFFFF),
      isFocused: isFocused,
      padding: EdgeInsets.zero,
      child: child,
    );
  }
}
