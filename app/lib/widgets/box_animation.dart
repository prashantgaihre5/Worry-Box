import 'package:flutter/material.dart';
import '../theme.dart';
import 'dart:math' as math;

enum BoxState { open, closing, closed }

class BoxAnimationWidget extends StatefulWidget {
  final BoxState boxState;
  final VoidCallback? onSealComplete;
  final VoidCallback? onOpenComplete;
  final double size;

  const BoxAnimationWidget({
    super.key,
    required this.boxState,
    this.onSealComplete,
    this.onOpenComplete,
    this.size = 200,
  });

  @override
  State<BoxAnimationWidget> createState() => _BoxAnimationWidgetState();
}

class _BoxAnimationWidgetState extends State<BoxAnimationWidget> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lidAngle;
  late Animation<double> _lockOpacity;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    // Seal animation: lid closes + lock fades in
    _sealController = AnimationController(
      vsync: this,
      duration: AppDurations.seal,
    );

    _lidAngle = Tween<double>(begin: 0.0, end: -0.5).animate(
      CurvedAnimation(parent: _sealController, curve: AppCurves.seal),
    );

    _lockOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sealController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _sealController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSealComplete?.call();
      }
    });

    // Pulsing glow: subtle accent glow behind the box
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // If starting closed, snap to closed state
    if (!widget.isOpen && !widget.isSealing) {
      _sealController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(BoxAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSealing && !oldWidget.isSealing) {
      _sealController.forward(from: 0.0);
    }
    if (widget.isOpen && !oldWidget.isOpen) {
      _sealController.reverse();
    }
  }

  @override
  void dispose() {
    _sealController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.isOpen ? 'Worry box, open' : 'Worry box, locked',
      child: SizedBox(
        width: 180,
        height: 180,
        child: AnimatedBuilder(
          animation: Listenable.merge([_sealController, _glowController]),
          builder: (context, child) {
            return CustomPaint(
              painter: _BoxPainter(
                lidAngle: _lidAngle.value,
                lockOpacity: _lockOpacity.value,
                glowValue: _glowAnimation.value,
                isLocked: !widget.isOpen,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Premium custom painter for the worry box.
/// Draws a stylized box with gradient body, animated lid, pulsing glow,
/// and detailed padlock icon.
class _BoxPainter extends CustomPainter {
  final double lidAngle;
  final double lockOpacity;
  final double glowValue;
  final bool isLocked;

  _BoxPainter({
    required this.lidAngle,
    required this.lockOpacity,
    required this.glowValue,
    required this.isLocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // ── 1. Glow effect behind the box ──
    final glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: glowValue * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.68),
        width: w * 0.75,
        height: h * 0.4,
      ),
      glowPaint,
    );

    // ── 2. Box body with gradient ──
    final Rect bodyRect = Rect.fromLTRB(w * 0.1, h * 0.4, w * 0.9, h * 0.92);
    final RRect bodyRRect =
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(14));

    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.bg1.withValues(alpha: 0.95),
        const Color(0xFF1A2548),
        AppColors.bg1,
      ],
    );
    canvas.drawRRect(
        bodyRRect, Paint()..shader = bodyGradient.createShader(bodyRect));

    // Body border
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── 3. Edge highlight lines ──
    final highlightPaint = Paint()
      ..color = AppColors.accentSoft.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Top edge of body
    canvas.drawLine(
      Offset(w * 0.15, h * 0.44),
      Offset(w * 0.85, h * 0.44),
      highlightPaint,
    );

    // Bottom trim
    canvas.drawLine(
      Offset(w * 0.2, h * 0.86),
      Offset(w * 0.8, h * 0.86),
      highlightPaint..color = AppColors.accentSoft.withValues(alpha: 0.15),
    );

    // ── 4. Lid with perspective rotation ──
    canvas.save();
    canvas.translate(w * 0.1, h * 0.4);
    canvas.rotate(lidAngle * math.pi);

    final Rect lidRect = Rect.fromLTWH(0, -22, w * 0.8, 26);
    final RRect lidRRect =
        RRect.fromRectAndRadius(lidRect, const Radius.circular(8));

    // Lid gradient (slightly lighter than body)
    final lidGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1E2D55),
        AppColors.bg1.withValues(alpha: 0.95),
      ],
    );
    canvas.drawRRect(
        lidRRect, Paint()..shader = lidGradient.createShader(lidRect));

    // Lid border
    canvas.drawRRect(
      lidRRect,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Lid accent highlight
    canvas.drawLine(
      Offset(w * 0.05, -18),
      Offset(w * 0.75, -18),
      Paint()
        ..color = AppColors.accentSoft.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );

    canvas.restore();

    // ── 5. Padlock icon (fades in with lockOpacity) ──
    if (lockOpacity > 0.01) {
      final double lockCenterX = w / 2;
      final double lockCenterY = h * 0.62;
      final double lockW = w * 0.14;
      final double lockH = h * 0.12;

      final lockPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: lockOpacity)
        ..style = PaintingStyle.fill;

      // Lock body — rounded rectangle
      final lockBodyRect = Rect.fromCenter(
        center: Offset(lockCenterX, lockCenterY),
        width: lockW,
        height: lockH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(lockBodyRect, const Radius.circular(3)),
        lockPaint,
      );

      // Shackle — arc above the lock body
      final shacklePaint = Paint()
        ..color = AppColors.accent.withValues(alpha: lockOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lockW * 0.22
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(lockCenterX, lockCenterY - lockH * 0.5),
          width: lockW * 0.55,
          height: lockH * 0.7,
        ),
        math.pi,
        math.pi,
        false,
        shacklePaint,
      );

      // Keyhole — small circle + small rect
      final keyholePaint = Paint()
        ..color = AppColors.bg1.withValues(alpha: lockOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(lockCenterX, lockCenterY - lockH * 0.08),
        lockW * 0.1,
        keyholePaint,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(lockCenterX, lockCenterY + lockH * 0.12),
          width: lockW * 0.08,
          height: lockH * 0.22,
        ),
        keyholePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) {
    return oldDelegate.lidAngle != lidAngle ||
        oldDelegate.lockOpacity != lockOpacity ||
        oldDelegate.glowValue != glowValue ||
        oldDelegate.isLocked != isLocked;
  }
}
