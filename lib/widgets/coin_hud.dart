import 'package:flutter/material.dart';

import '../services/storage.dart';
import '../theme.dart';
import 'glass.dart';

/// A small pill displaying the player's current coin balance.
///
/// Pulls from [ProgressStore.coinNotifier] so any screen showing this widget
/// gets live updates when coins are earned.
class CoinHud extends StatelessWidget {
  const CoinHud({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.coinNotifier,
      builder: (context, coins, _) {
        return GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 14,
          fillAlpha: 0.10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
