import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/ads_config.dart';
import '../models/tile_theme.dart';
import '../services/ads.dart';
import '../services/consent_service.dart';
import '../services/settings_service.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/glass.dart';

/// Settings screen. Surfaces:
///   - Privacy choices re-entry (UMP / AdMob requirement)
///   - Gameplay toggles (haptics, visual effects)
///   - Preferred palette for Infinite mode
///   - Reset progress (danger zone)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _openPrivacyForm() async {
    if (_busy) return;
    setState(() => _busy = true);
    final shown = await ConsentService.instance.showPrivacyOptionsForm();
    // If the user granted consent this round, spin up the ads SDK now so the
    // banner/interstitials start working without an app restart.
    await AdsService.instance.retryAfterConsentChange();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!shown) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Privacy options are not available on this device or region.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset progress?'),
        content: const Text(
          'This will wipe all unlocked levels, stars, best-moves, '
          'Infinite-mode streak, and coins. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final store = await ProgressStore.load();
    await store.resetAll();
    await SettingsService.instance.resetTutorialSeen();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Progress reset.')));
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AppBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text('Audio', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ValueListenableBuilder<double>(
                valueListenable: settings.musicVolume,
                builder: (_, value, _) => _VolumeSlider(
                  icon: Icons.music_note_rounded,
                  label: 'Music',
                  value: value,
                  onChanged: settings.setMusicVolume,
                ),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<double>(
                valueListenable: settings.sfxVolume,
                builder: (_, value, _) => _VolumeSlider(
                  icon: Icons.graphic_eq_rounded,
                  label: 'Sound effects',
                  value: value,
                  onChanged: settings.setSfxVolume,
                ),
              ),
              const SizedBox(height: 28),
              Text('Gameplay', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ValueListenableBuilder<bool>(
                valueListenable: settings.haptics,
                builder: (_, value, _) => _ToggleTile(
                  icon: Icons.vibration_rounded,
                  label: 'Haptics',
                  subtitle: 'Subtle vibration on tap and win.',
                  value: value,
                  onChanged: settings.setHaptics,
                ),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<bool>(
                valueListenable: settings.effects,
                builder: (_, value, _) => _ToggleTile(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Visual effects',
                  subtitle: 'Confetti burst on win.',
                  value: value,
                  onChanged: settings.setEffects,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Infinite palette',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Levels mode auto-cycles palettes by level. This picks the '
                'palette used in Infinite mode.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<String>(
                valueListenable: settings.infinitePaletteId,
                builder: (_, selectedId, _) => _PalettePicker(
                  selectedId: selectedId,
                  onSelected: settings.setInfinitePaletteId,
                ),
              ),
              const SizedBox(height: 28),
              Text('Privacy', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              _PrivacyChoicesTile(busy: _busy, onTap: _openPrivacyForm),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AdsConfig.isSupported
                      ? 'Manage how ads use your data. You can change or '
                            'withdraw consent at any time. Required by GDPR '
                            '(EEA / UK / Switzerland).'
                      : 'Ads and consent are only available in the Android '
                            'and iOS builds. Nothing to configure here.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 28),
              Text('About', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AboutRow(label: 'Version', value: '1.0.0'),
                    const SizedBox(height: 8),
                    _AboutRow(
                      label: 'Build',
                      value: kReleaseMode ? 'release' : 'debug',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Danger zone',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 10),
              GlassCard(
                padding: EdgeInsets.zero,
                borderRadius: 18,
                fillAlpha: 0.10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _confirmReset,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_forever_rounded,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reset progress',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Wipe unlocked levels, stars, streaks, and '
                                  'coins.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.ink,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 18,
      fillAlpha: 0.10,
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _PalettePicker extends StatelessWidget {
  const _PalettePicker({required this.selectedId, required this.onSelected});

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final p in kTilePalettes)
          _PaletteChip(
            palette: p,
            selected: p.id == selectedId,
            onTap: () => onSelected(p.id),
          ),
      ],
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final TilePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? palette.accent : AppColors.glassBorder(0.35),
              width: selected ? 2.2 : 1.1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: palette.darkGradient,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: palette.lightGradient,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                palette.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? palette.accent : AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyChoicesTile extends StatelessWidget {
  const _PrivacyChoicesTile({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      fillAlpha: 0.12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppGradients.accentButton,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: AppColors.bg0,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy choices',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review or change how ads use your data.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  )
                else
                  const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 18,
      fillAlpha: 0.10,
      child: Row(
        children: [
          Icon(
            value <= 0 ? Icons.volume_off_rounded : icon,
            color: AppColors.accent,
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
            width: 40,
            child: Text(
              '$percent',
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}
