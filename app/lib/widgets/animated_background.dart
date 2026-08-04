import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _orb1Controller;
  late final AnimationController _orb2Controller;

  @override
  void initState() {
    super.initState();
    // Ambient glow shifting
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);

    // Floating orb 1
    _orb1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    // Floating orb 2 (offset)
    _orb2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
      value: 0.2, // Start at an offset
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Ambient animated gradient background
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final t = _glowController.value;
            // Shift the center slightly based on animation
            final alignment = Alignment(
              -0.2 + (math.sin(t * math.pi * 2) * 0.1),
              -0.2 + (math.cos(t * math.pi * 2) * 0.1),
            );
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: alignment,
                  radius: 1.5,
                  colors: const [
                    AppColors.bg2,
                    AppColors.bg1,
                    AppColors.bg0,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        ),

        // 2. Floating Orbs (with heavy blur applied to them)
        AnimatedBuilder(
          animation: Listenable.merge([_orb1Controller, _orb2Controller]),
          builder: (context, child) {
            final size = MediaQuery.of(context).size;
            final t1 = _orb1Controller.value;
            final t2 = _orb2Controller.value;

            // Orb 1: Top Left
            final y1 = math.sin(t1 * math.pi) * -20;
            final scale1 = 1.0 + (math.sin(t1 * math.pi) * 0.08);

            // Orb 2: Bottom Right
            final y2 = math.sin(t2 * math.pi) * -20;
            final scale2 = 1.0 + (math.sin(t2 * math.pi) * 0.08);

            return Stack(
              children: [
                Positioned(
                  top: -size.height * 0.1 + y1,
                  left: -size.width * 0.1,
                  child: Transform.scale(
                    scale: scale1,
                    child: Container(
                      width: 450,
                      height: 450,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orb1.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -size.height * 0.1 + y2,
                  right: -size.width * 0.1,
                  child: Transform.scale(
                    scale: scale2,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orb2.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: size.height * 0.4 + y1,
                  right: size.width * 0.1,
                  child: Transform.scale(
                    scale: scale1,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orb3.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Apply heavy blur to the orbs layer
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
            child: const SizedBox.shrink(),
          ),
        ),

        // Delicate star dust pattern overlay
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(
              painter: _StarDustPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class _StarDustPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // radial-gradient(circle at center, rgba(255, 255, 255, 0.8) 1px, transparent 1px)
    // backgroundSize: 28px 28px
    const double step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        // Draw a 1px dot
        canvas.drawCircle(Offset(x + (step / 2), y + (step / 2)), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
