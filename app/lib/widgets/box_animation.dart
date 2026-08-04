import 'dart:math' as math;
import 'package:flutter/material.dart';

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

class _BoxAnimationWidgetState extends State<BoxAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    // Replaces both CSS animations: ambientGlow and boxBreath
    _glowController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2), // Maps to the 3-4s CSS infinite alternate animations
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ReactBoxPainter(
            glow: _glowController.value,
            boxState: widget.boxState,
          ),
        );
      },
    );
  }
}

class _ReactBoxPainter extends CustomPainter {
  final double glow;
  final BoxState boxState;

  _ReactBoxPainter({
    required this.glow,
    required this.boxState,
  });

  Path _pathFromPoints(List<double> points) {
    final path = Path();
    path.moveTo(points[0], points[1]);
    for (int i = 2; i < points.length; i += 2) {
      path.lineTo(points[i], points[i + 1]);
    }
    path.close();
    return path;
  }
  
  Path _pathFromPointsNoClose(List<double> points) {
    final path = Path();
    path.moveTo(points[0], points[1]);
    for (int i = 2; i < points.length; i += 2) {
      path.lineTo(points[i], points[i + 1]);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // The React SVG viewBox is 0 0 100 100.
    final scale = size.width / 100.0;
    canvas.scale(scale, scale);

    // Gradients
    final frontGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xE62563EB), Color(0xF21D4ED8)], // #2563eb 0.9 to #1d4ed8 0.95
    ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    
    final closedGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
    ).createShader(const Rect.fromLTWH(0, 0, 100, 100));

    final lidGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xF23B82F6), Color(0xF22563EB)],
    ).createShader(const Rect.fromLTWH(0, 0, 100, 100));

    final glassHl = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x26FFFFFF), Color(0x00FFFFFF)],
    ).createShader(const Rect.fromLTWH(0, 0, 100, 100));

    if (boxState == BoxState.closed) {
      // ─── CLOSED BOX ───
      // Glow background
      canvas.drawCircle(
        const Offset(50, 50),
        40,
        Paint()
          ..color = const Color(0x1A3B82F6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );

      // Box Body Closed
      // <path d="M 10 50 L 90 50 L 90 90 L 10 90 Z" fill="url(#closedGradient)" />
      final bodyPath = _pathFromPoints([10, 50, 90, 50, 90, 90, 10, 90]);
      canvas.drawPath(bodyPath, Paint()..shader = closedGradient);
      canvas.drawPath(bodyPath, Paint()..shader = glassHl);
      canvas.drawPath(_pathFromPointsNoClose([10, 50, 90, 50]), Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x33FFFFFF));

      // Lid Closed
      // <path d="M 5 40 L 95 40 L 95 52 L 5 52 Z" fill="url(#lidGradient)" />
      final lidPath = _pathFromPoints([5, 40, 95, 40, 95, 52, 5, 52]);
      canvas.drawPath(lidPath, Paint()..shader = lidGradient);
      canvas.drawPath(_pathFromPointsNoClose([5, 40, 95, 40]), Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x66FFFFFF));
      
      // <path d="M 5 52 L 95 52 L 90 55 L 10 55 Z" fill="#1e40af" className="opacity-80" />
      canvas.drawPath(
        _pathFromPoints([5, 52, 95, 52, 90, 55, 10, 55]),
        Paint()..color = const Color(0xCC1E40AF),
      );

      // Padlock Icon (centered on box front)
      // <g transform="translate(42, 60)" className="drop-shadow-md">
      canvas.save();
      canvas.translate(42, 60);
      
      // <rect x="2" y="6" width="12" height="10" rx="2" fill="#93c5fd" />
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(2, 6, 12, 10), const Radius.circular(2)),
        Paint()..color = const Color(0xFF93C5FD)
                 ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2), // drop shadow approx
      );
      
      // <path d="M 4 6 V 4 A 4 4 0 0 1 12 4 V 6" fill="none" stroke="#93c5fd" strokeWidth="2" strokeLinecap="round" />
      final shackle = Path()
        ..moveTo(4, 6)
        ..lineTo(4, 4)
        ..arcToPoint(const Offset(12, 4), radius: const Radius.circular(4))
        ..lineTo(12, 6);
      canvas.drawPath(shackle, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = const Color(0xFF93C5FD));
      
      // <circle cx="8" cy="11" r="1.5" fill="#1e3a8a" />
      canvas.drawCircle(const Offset(8, 11), 1.5, Paint()..color = const Color(0xFF1E3A8A));
      
      // <path d="M 8 11 V 13" stroke="#1e3a8a" strokeWidth="1" />
      canvas.drawLine(const Offset(8, 11), const Offset(8, 13), Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0xFF1E3A8A));
      
      canvas.restore();

    } else {
      // ─── OPEN BOX ───
      // Glow background
      canvas.drawCircle(
        const Offset(50, 50),
        40,
        Paint()
          ..color = const Color(0x333B82F6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );

      // Back of box
      // <path d="M 20 40 L 80 40 L 90 60 L 10 60 Z" fill="#1e3a8a" className="opacity-90" />
      canvas.drawPath(_pathFromPoints([20, 40, 80, 40, 90, 60, 10, 60]), Paint()..color = const Color(0xE61E3A8A));
      
      // <path d="M 10 60 L 90 60 L 90 90 L 10 90 Z" fill="#1e40af" />
      canvas.drawPath(_pathFromPoints([10, 60, 90, 60, 90, 90, 10, 90]), Paint()..color = const Color(0xFF1E40AF));

      // Front face
      final frontPath = _pathFromPoints([10, 60, 90, 60, 90, 90, 10, 90]);
      canvas.drawPath(frontPath, Paint()..shader = frontGradient);
      canvas.drawPath(frontPath, Paint()..shader = glassHl);

      // Subtle Grid inside
      // <path d="M 30 65 L 30 85 M 50 65 L 50 85 M 70 65 L 70 85" stroke="#60a5fa" strokeWidth="0.5" strokeDasharray="2 2" className="opacity-30" />
      // (Using solid lines here since dashed paths require extra math, solid low opacity works fine for subtle effect)
      final gridPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5..color = const Color(0x4D60A5FA);
      canvas.drawLine(const Offset(30, 65), const Offset(30, 85), gridPaint);
      canvas.drawLine(const Offset(50, 65), const Offset(50, 85), gridPaint);
      canvas.drawLine(const Offset(70, 65), const Offset(70, 85), gridPaint);

      // Left/Right Inner Walls
      // <path d="M 10 60 L 20 40 L 20 70 L 10 90 Z" fill="#172554" className="opacity-80" />
      canvas.drawPath(_pathFromPoints([10, 60, 20, 40, 20, 70, 10, 90]), Paint()..color = const Color(0xCC172554));
      // <path d="M 90 60 L 80 40 L 80 70 L 90 90 Z" fill="#172554" className="opacity-80" />
      canvas.drawPath(_pathFromPoints([90, 60, 80, 40, 80, 70, 90, 90]), Paint()..color = const Color(0xCC172554));

      // Ambient Light inside box (animates opacity/radius based on glow)
      final animatedRadius = 13 + (4 * glow); // 13 to 17
      final animatedOpacity = 0.2 + (0.3 * glow); // 0.2 to 0.5
      canvas.drawCircle(
        const Offset(50, 75),
        animatedRadius,
        Paint()
          ..color = const Color(0xFF60A5FA).withValues(alpha: animatedOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Animated Lid (boxBreath scales Y slightly and translates)
      canvas.save();
      // origin-[50px_40px]
      canvas.translate(50, 40);
      // Breathing effect
      final breathScale = 1.0 + (0.02 * glow); // 1.0 to 1.02
      final breathTrans = -2.0 * glow; // 0 to -2
      canvas.scale(breathScale, breathScale);
      canvas.translate(0, breathTrans);
      canvas.translate(-50, -40);

      // <path d="M 15 35 L 85 35 L 95 55 L 5 55 Z" fill="url(#lidGradient)" />
      final openLidPath = _pathFromPoints([15, 35, 85, 35, 95, 55, 5, 55]);
      canvas.drawPath(openLidPath, Paint()..shader = lidGradient);
      
      // <path d="M 5 55 L 95 55 L 95 62 L 5 62 Z" fill="#1e40af" />
      canvas.drawPath(_pathFromPoints([5, 55, 95, 55, 95, 62, 5, 62]), Paint()..color = const Color(0xFF1E40AF));
      
      // <path d="M 5 55 L 95 55" stroke="rgba(255,255,255,0.4)" strokeWidth="1" />
      canvas.drawLine(const Offset(5, 55), const Offset(95, 55), Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x66FFFFFF));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ReactBoxPainter oldDelegate) => true;
}
