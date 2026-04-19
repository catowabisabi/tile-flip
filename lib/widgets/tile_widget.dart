import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// A single board tile. Flips with a smooth color + scale animation when its
/// state changes. Taps trigger [onTap] and a light haptic.
class TileWidget extends StatelessWidget {
  const TileWidget({super.key, required this.dark, required this.onTap});

  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          color: dark ? AppColors.tileDark : AppColors.tileLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dark
                ? AppColors.tileDark
                : AppColors.muted.withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: dark ? 14 : 0,
            height: dark ? 14 : 0,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
