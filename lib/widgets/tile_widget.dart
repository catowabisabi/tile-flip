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

  // Track the "from" and "to" faces for the in-flight animation. Reading these
  // off `_ctrl.value` inside the builder (rather than a `Future.delayed` timer)
  // means a rapid second flip that restarts the controller self-cancels the
  // first flip's midpoint face swap — no stale callbacks possible.
  late bool _fromDark = widget.dark;
  late bool _toDark = widget.dark;

  @override
  void didUpdateWidget(covariant TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dark != oldWidget.dark) {
      // If an animation is still in flight, its mid-flight "to" face becomes
      // the starting face of the new flip.
      _fromDark = _ctrl.value < 0.5 ? _fromDark : _toDark;
      _toDark = widget.dark;
      _ctrl.forward(from: 0.0);
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
          // Rotate around Y: 0 at rest → edge-on (pi/2) at midpoint → 0 at end.
          // Using sin(t·π)·π/2 keeps t=0 and t=1 visually identical (no mirror),
          // so restarting the controller via forward(from:0) never pops.
          final angle = sin(t * pi) * (pi / 2);
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle)
            ..scaleByDouble(scale, scale, 1.0, 1.0);
          // Show the old face while the tile is rotating toward edge-on, then
          // the new face as it rotates back. At t=0.5 the tile is edge-on so
          // the swap is visually invisible.
          final showDark = t < 0.5 ? _fromDark : _toDark;
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: _TileFace(dark: showDark, palette: widget.palette),
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
