import 'dart:math';

import 'package:flutter/material.dart';

/// A one-shot confetti burst. When [active] flips true the widget plays its
/// animation; when it completes it calls [onComplete] (if provided) and
/// re-arms for the next true→false→true transition.
///
/// Rendered via [CustomPainter] so we don't pull in a package just to
/// celebrate a solved puzzle.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    required this.active,
    required this.colors,
    this.particleCount = 42,
    this.duration = const Duration(milliseconds: 1400),
    this.onComplete,
  });

  final bool active;
  final List<Color> colors;
  final int particleCount;
  final Duration duration;
  final VoidCallback? onComplete;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onComplete?.call();
          }
        });

  late List<_Particle> _particles = _spawn();

  @override
  void didUpdateWidget(covariant ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _particles = _spawn();
      _ctrl.forward(from: 0);
    } else if (!widget.active && oldWidget.active) {
      _ctrl.reset();
    }
  }

  List<_Particle> _spawn() {
    final rng = Random();
    return List<_Particle>.generate(widget.particleCount, (_) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 180 + rng.nextDouble() * 280;
      return _Particle(
        dx: cos(angle) * speed,
        dy: sin(angle) * speed - 120,
        color: widget.colors[rng.nextInt(widget.colors.length)],
        size: 4 + rng.nextDouble() * 6,
        rotation: rng.nextDouble() * 2 * pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 10,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _ctrl.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  final double dx;
  final double dy;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;

  const _Particle({
    required this.dx,
    required this.dy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final origin = Offset(size.width / 2, size.height / 2);
    // Gravity accelerates particles downward so they fall naturally.
    const gravity = 680.0;
    for (final p in particles) {
      final t = progress;
      final x = origin.dx + p.dx * t;
      final y = origin.dy + p.dy * t + 0.5 * gravity * t * t;
      // Fade out over the second half of the animation.
      final alpha = (1.0 - ((t - 0.5).clamp(0.0, 0.5) * 2)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 1.6,
            height: p.size,
          ),
          Radius.circular(p.size * 0.3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.particles != particles;
}
