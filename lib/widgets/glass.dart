import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// A frosted-glass surface.
///
/// Wraps [child] in a `BackdropFilter` with a translucent white fill and a
/// subtle hairline border — the "glassmorphism" look that reads well on top of
/// the navy gradient backdrop.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.fillAlpha = 0.08,
    this.blurSigma = 18,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double fillAlpha;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x30FFFFFF), Color(0x0DFFFFFF)],
            ),
            color: AppColors.glassFill(fillAlpha),
            border: Border.all(color: AppColors.glassBorder(), width: 1),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Scaffold body wrapper that paints the navy → slate gradient backdrop plus
/// two soft accent glows. Every screen should wrap its body in this.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.backdrop),
        ),
        // Soft accent glows for depth.
        Positioned(
          top: -80,
          right: -80,
          child: _Glow(color: AppColors.accent.withValues(alpha: 0.28)),
        ),
        Positioned(
          bottom: -120,
          left: -80,
          child: _Glow(
            color: AppColors.secondary.withValues(alpha: 0.22),
            size: 320,
          ),
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, this.size = 260});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
