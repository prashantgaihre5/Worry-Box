import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _lidAngle = Tween<double>(begin: -1.2, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _lockOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)));
    
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.boxState == BoxState.closing) {
        widget.onSealComplete?.call();
      } else if (status == AnimationStatus.dismissed && widget.boxState == BoxState.open) {
        widget.onOpenComplete?.call();
      }
    });

    if (widget.boxState == BoxState.closed) _controller.value = 1.0;
    else if (widget.boxState == BoxState.closing) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant BoxAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.boxState != oldWidget.boxState) {
      if (widget.boxState == BoxState.closing) _controller.forward();
      else if (widget.boxState == BoxState.open) _controller.reverse();
      else if (widget.boxState == BoxState.closed) _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _glowController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _Pseudo3DBoxPainter(
            lidAngle: _lidAngle.value,
            lockOpacity: _lockOpacity.value,
            glow: _glowController.value,
          ),
        );
      },
    );
  }
}

class _Pseudo3DBoxPainter extends CustomPainter {
  final double lidAngle;
  final double lockOpacity;
  final double glow;

  _Pseudo3DBoxPainter({required this.lidAngle, required this.lockOpacity, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width * 0.7;
    final h = size.height * 0.5;
    
    // Draw Glow
    final glowPaint = Paint()
      ..color = AppColors.orb1.withValues(alpha: 0.2 + (glow * 0.3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, size.width * 0.4, glowPaint);

    // Box Body (Isometric / Claymorphism)
    final bodyRect = Rect.fromCenter(center: center.translate(0, h * 0.3), width: w, height: h);
    final bodyPath = Path()..addRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(16)));
    
    // Base Gradient
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2C385E), Color(0xFF131A32)],
      ).createShader(bodyRect);
    canvas.drawPath(bodyPath, bodyPaint);

    // Inner Highlight (Claymorphism effect)
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.15);
    canvas.drawPath(bodyPath, highlightPaint);

    // Dark Inner Shadow (top rim)
    final topRim = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: center.translate(0, -h * 0.2), width: w - 8, height: 16), const Radius.circular(8)));
    canvas.drawPath(topRim, Paint()..color = Colors.black.withValues(alpha: 0.4));

    // Lid (Rotated)
    canvas.save();
    canvas.translate(center.dx, center.dy - h * 0.2); // Hinge point
    
    // Applying 3D rotation around X axis manually using matrix
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.002) // Perspective
      ..rotateX(lidAngle);
    canvas.transform(matrix.storage);

    final lidRect = Rect.fromCenter(center: const Offset(0, 0), width: w, height: h * 0.9);
    final lidPath = Path()..addRRect(RRect.fromRectAndRadius(lidRect, const Radius.circular(16)));
    
    final lidPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3F518C), Color(0xFF2C385E)],
      ).createShader(lidRect);
    canvas.drawPath(lidPath, lidPaint);
    canvas.drawPath(lidPath, highlightPaint); // Lid highlight
    
    canvas.restore();

    // Padlock
    if (lockOpacity > 0) {
      final lockPaint = Paint()..color = AppColors.accent.withValues(alpha: lockOpacity);
      final lockBody = Rect.fromCenter(center: center.translate(0, h * 0.2), width: 24, height: 20);
      canvas.drawRRect(RRect.fromRectAndRadius(lockBody, const Radius.circular(4)), lockPaint);
      
      final shacklePaint = Paint()
        ..color = AppColors.textMuted.withValues(alpha: lockOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(Rect.fromCenter(center: center.translate(0, h * 0.2 - 10), width: 14, height: 14), math.pi, math.pi, false, shacklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Pseudo3DBoxPainter oldDelegate) => true;
}
