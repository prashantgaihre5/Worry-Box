import 'package:flutter/material.dart';
import '../theme.dart';

/// The visual box/lid widget used across CAPTURE, LOCKED, and REVEAL screens.
///
/// This is a placeholder scaffold. The designer will provide the final
/// visual design. Developers should wire animations here.
///
/// States:
///   - [isOpen] = true  → lid is open (CAPTURE / REVEAL)
///   - [isOpen] = false → lid is closed with padlock (LOCKED)
///   - [isSealing] = true → animate the seal sequence (after submit)
class BoxAnimation extends StatefulWidget {
  final bool isOpen;
  final bool isSealing;
  final VoidCallback? onSealComplete;

  const BoxAnimation({
    super.key,
    this.isOpen = true,
    this.isSealing = false,
    this.onSealComplete,
  });

  @override
  State<BoxAnimation> createState() => _BoxAnimationState();
}

class _BoxAnimationState extends State<BoxAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lidAngle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.seal,
    );
    _lidAngle = Tween<double>(
      begin: 0.0,  // open
      end: -0.5,   // closed (rotated)
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppCurves.seal,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSealComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(BoxAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSealing && !oldWidget.isSealing) {
      _controller.forward(from: 0.0);
    }
    if (widget.isOpen && !oldWidget.isOpen) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BoxPainter(
              lidAngle: _lidAngle.value,
              isLocked: !widget.isOpen,
            ),
          );
        },
      ),
    );
  }
}

/// Placeholder painter for the box.
/// TODO: Designer will provide final visual. Replace this with their design.
class _BoxPainter extends CustomPainter {
  final double lidAngle;
  final bool isLocked;

  _BoxPainter({required this.lidAngle, required this.isLocked});

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = AppColors.surfaceStrong
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Box body
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, size.height * 0.4, size.width - 20, size.height * 0.55),
      const Radius.circular(AppShape.radiusSm),
    );
    canvas.drawRRect(boxRect, boxPaint);
    canvas.drawRRect(boxRect, borderPaint);

    // Lid
    canvas.save();
    canvas.translate(10, size.height * 0.4);
    canvas.rotate(lidAngle);
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, -20, size.width - 20, 24),
      const Radius.circular(6),
    );
    canvas.drawRRect(lidRect, boxPaint);
    canvas.drawRRect(lidRect, borderPaint);
    canvas.restore();

    // Lock icon when closed
    if (isLocked) {
      final lockPaint = Paint()..color = AppColors.accent;
      final center = Offset(size.width / 2, size.height * 0.38);
      canvas.drawCircle(center, 8, lockPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) {
    return oldDelegate.lidAngle != lidAngle || oldDelegate.isLocked != isLocked;
  }
}
