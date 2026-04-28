import 'package:flutter/material.dart';

import '../theme.dart';
import 'glass.dart';

/// A one-shot tutorial overlay explaining the rules of Tile Flip.
///
/// Shown on top of the first game board the player opens. Dismissable with
/// the "Got it" button; callers should persist the "seen" flag via
/// [SettingsService] when the callback fires.
class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: GlassCard(
              borderRadius: 26,
              fillAlpha: 0.16,
              blurSigma: 24,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppGradients.accentButton,
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          color: AppColors.bg0,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'How to play',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _Step(
                    icon: Icons.touch_app_rounded,
                    text: 'Tap any tile on the board.',
                  ),
                  const SizedBox(height: 10),
                  const _Step(
                    icon: Icons.swap_horiz_rounded,
                    text:
                        'The tile you tapped and its four neighbours '
                        '(up / down / left / right) all flip colour.',
                  ),
                  const SizedBox(height: 10),
                  const _Step(
                    icon: Icons.done_all_rounded,
                    text:
                        'Make the whole board the same colour to solve. '
                        'Fewer moves = more stars ★.',
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onDismiss,
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.accent, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.ink, height: 1.4),
          ),
        ),
      ],
    );
  }
}
