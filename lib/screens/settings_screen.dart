import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/ads_config.dart';
import '../services/ads.dart';
import '../services/consent_service.dart';
import '../theme.dart';
import '../widgets/glass.dart';

/// Simple settings screen. The primary purpose is to surface the "Privacy
/// choices" re-entry point that UMP / AdMob policy requires.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AppBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
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
