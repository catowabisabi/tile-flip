import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// A single board tile. Flips with a smooth colour + scale animation when its
/// state changes. Taps trigger [onTap] and a light haptic.
class TileWidget extends StatelessWidget {
  const TileWidget({super.key, required this.dark, required this.onTap});

  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2F386A), Color(0xFF1F2649)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFAFBFF), Color(0xFFDDE2F2)],
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
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
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: dark ? 14 : 0,
            height: dark ? 14 : 0,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: dark
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
