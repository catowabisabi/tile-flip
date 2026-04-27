import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/coin_hud.dart';
import '../widgets/glass.dart';
import 'infinite_screen.dart';
import 'levels_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.playMenuBgm();
  }

  void _openLevels() {
    AudioService.instance.playButtonTap();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const LevelsScreen()))
        .then((_) {
      if (mounted) AudioService.instance.playMenuBgm();
    });
  }

  void _openInfinite() {
    AudioService.instance.playButtonTap();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const InfiniteScreen()))
        .then((_) {
      if (mounted) AudioService.instance.playMenuBgm();
    });
  }

  void _openSettings() {
    AudioService.instance.playButtonTap();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CoinHud(),
                    _SettingsButton(onPressed: _openSettings),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(flex: 2),
                      const _LogoMark(),
                      const SizedBox(height: 28),
                      Text(
                        'Tile Flip',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap a tile.\nFlip its neighbours.\nMake the board one colour.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(flex: 3),
                      _PrimaryCta(
                        label: 'LEVELS',
                        icon: Icons.grid_view_rounded,
                        onPressed: _openLevels,
                      ),
                      const SizedBox(height: 14),
                      _GlassCta(
                        label: 'INFINITE',
                        icon: Icons.all_inclusive_rounded,
                        onPressed: _openInfinite,
                      ),
                      const SizedBox(height: 14),
                      const _HowToHint(),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
              const BannerAdSlot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: AppGradients.accentButton,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.bg0, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.bg0,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
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

class _GlassCta extends StatelessWidget {
  const _GlassCta({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 18,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.ink, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
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

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x22FFFFFF), Color(0x0AFFFFFF)],
        ),
        border: Border.all(color: AppColors.glassBorder()),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _logoSquare(AppColors.tileLight),
          _logoSquare(AppColors.tileDark),
          _logoSquare(AppColors.tileDark),
          _logoSquare(AppColors.accent),
        ],
      ),
    );
  }

  Widget _logoSquare(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Settings',
      button: true,
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 14,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.settings_rounded,
                color: AppColors.ink,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HowToHint extends StatelessWidget {
  const _HowToHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Fewer taps → more stars ★',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.inkSoft.withValues(alpha: 0.8),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
