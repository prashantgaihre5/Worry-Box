import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

class ParticleBurst extends StatefulWidget {
  final Widget child;
  final bool isBursting;
  final VoidCallback onComplete;

  const ParticleBurst({
    super.key,
    required this.child,
    required this.isBursting,
    required this.onComplete,
  });

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void didUpdateWidget(ParticleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBursting && !oldWidget.isBursting) {
      _generateParticles();
      _controller.forward(from: 0.0);
    }
  }

  void _generateParticles() {
    _particles = List.generate(40, (index) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = _random.nextDouble() * 150 + 50;
      final size = _random.nextDouble() * 6 + 2;
      return _Particle(
        angle: angle,
        speed: speed,
        size: size,
        color: [AppColors.orb1, AppColors.orb2, AppColors.orb3, AppColors.accent][_random.nextInt(4)],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Fade out the child while bursting
            Opacity(
              opacity: widget.isBursting ? 1.0 - _controller.value : 1.0,
              child: widget.child,
            ),
            if (widget.isBursting)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticlePainter(_particles, _controller.value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var p in particles) {
      // Ease out cubic for velocity
      final easeProgress = 1.0 - math.pow(1.0 - progress, 3);
      final distance = p.speed * easeProgress;
      
      final dx = center.dx + math.cos(p.angle) * distance;
      final dy = center.dy + math.sin(p.angle) * distance;

      final paint = Paint()
        ..color = p.color.withValues(alpha: (1.0 - progress))
        ..style = PaintingStyle.fill;
        
      // Add subtle glow
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawCircle(Offset(dx, dy), p.size * (1.0 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
