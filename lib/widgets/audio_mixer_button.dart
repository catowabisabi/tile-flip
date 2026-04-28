import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';

/// AppBar action that opens a small popover with Music + SFX sliders so
/// players can tweak volumes without leaving the game screen.
class AudioMixerButton extends StatelessWidget {
  const AudioMixerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: SettingsService.instance.musicVolume,
      builder: (context, music, _) {
        return ValueListenableBuilder<double>(
          valueListenable: SettingsService.instance.sfxVolume,
          builder: (context, sfx, _) {
            final muted = music <= 0 && sfx <= 0;
            return IconButton(
              tooltip: 'Audio',
              icon: Icon(
                muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              ),
              onPressed: () => _open(context),
            );
          },
        );
      },
    );
  }

  Future<void> _open(BuildContext context) async {
    AudioService.instance.playButtonTap();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const _AudioMixerSheet(),
    );
  }
}

class _AudioMixerSheet extends StatelessWidget {
  const _AudioMixerSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.inkSoft.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Audio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                _MixerRow(
                  icon: Icons.music_note_rounded,
                  label: 'Music',
                  notifier: SettingsService.instance.musicVolume,
                  onChanged: SettingsService.instance.setMusicVolume,
                ),
                const SizedBox(height: 8),
                _MixerRow(
                  icon: Icons.graphic_eq_rounded,
                  label: 'SFX',
                  notifier: SettingsService.instance.sfxVolume,
                  onChanged: SettingsService.instance.setSfxVolume,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MixerRow extends StatelessWidget {
  const _MixerRow({
    required this.icon,
    required this.label,
    required this.notifier,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final ValueListenable<double> notifier;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (context, value, _) {
        final percent = (value * 100).round();
        return Row(
          children: [
            Icon(
              value <= 0 ? Icons.volume_off_rounded : icon,
              color: AppColors.accent,
              size: 22,
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 60,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: onChanged,
                activeColor: AppColors.accent,
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$percent',
                textAlign: TextAlign.right,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
              ),
            ),
          ],
        );
      },
    );
  }
}
