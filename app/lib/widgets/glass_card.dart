import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

/// A premium glassmorphic card widget.
/// Applies a backdrop blur, translucent background, and subtle frosted border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isFocused;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppShape.radiusSm,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppShape.blur, sigmaY: AppShape.blur),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: padding ?? const EdgeInsets.all(AppSpacing.sp4),
          decoration: BoxDecoration(
            color: AppColors.surfaceStrong,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isFocused ? AppColors.accent : AppColors.glassBorder,
              width: isFocused ? 1.5 : 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
