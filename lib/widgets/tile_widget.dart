import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tile_theme.dart';
import '../services/settings_service.dart';
import '../theme.dart';

/// A single board tile. Animates a 3D Y-axis flip plus a subtle scale pop
/// whenever its [dark] state changes. Taps trigger [onTap] and a light
/// haptic (respecting the user's haptics setting).
class TileWidget extends StatefulWidget {
  const TileWidget({
    super.key,
    required this.dark,
    required this.onTap,
    required this.palette,
  });

  final bool dark;
  final VoidCallback onTap;
  final TilePalette palette;

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 1.0,
  );
  late bool _shownDark = widget.dark;

  @override
  void didUpdateWidget(covariant TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dark != oldWidget.dark) {
      _ctrl.forward(from: 0.0).then((_) {
        if (mounted) setState(() => _shownDark = widget.dark);
      });
      // Swap the shown face at the halfway point of the flip so the colour
      // change happens when the tile is edge-on and invisible.
      Future<void>.delayed(const Duration(milliseconds: 170), () {
        if (mounted) setState(() => _shownDark = widget.dark);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (SettingsService.instance.haptics.value) {
      HapticFeedback.selectionClick();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          // Scale pop: down to 0.92 at the middle, back to 1.0 at the ends.
          final scale = 1.0 - 0.08 * sin(t * pi);
          // Rotate around Y by up to pi; combined with perspective for depth.
          final angle = t * pi;
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle)
            ..scaleByDouble(scale, scale, 1.0, 1.0);
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: _TileFace(dark: _shownDark, palette: widget.palette),
          );
        },
      ),
    );
  }
}

class _TileFace extends StatelessWidget {
  const _TileFace({required this.dark, required this.palette});

  final bool dark;
  final TilePalette palette;

  @override
  Widget build(BuildContext context) {
    final gradient = dark ? palette.darkGradient : palette.lightGradient;
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark
              ? AppColors.glassBorder(0.18)
              : AppColors.glassBorder(0.45),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.18),
            blurRadius: dark ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: dark ? 14 : 0,
          height: dark ? 14 : 0,
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: dark
                ? [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.6),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
