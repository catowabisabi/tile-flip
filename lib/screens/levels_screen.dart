import 'package:flutter/material.dart';

import '../models/puzzle.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/glass.dart';
import 'game_screen.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  ProgressStore? _store;

  @override
  void initState() {
    super.initState();
    ProgressStore.load().then((store) {
      if (mounted) setState(() => _store = store);
    });
  }

  Future<void> _openLevel(Level level) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => GameScreen(level: level)));
    final store = await ProgressStore.load();
    if (mounted) setState(() => _store = store);
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Levels')),
      body: AppBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: store == null
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.95,
                            ),
                        itemCount: LevelCatalog.totalLevels,
                        itemBuilder: (context, i) {
                          final level = LevelCatalog.at(i + 1);
                          final unlocked = level.index <= store.highestUnlocked;
                          final stars = store.starsFor(level.index);
                          return _LevelCard(
                            level: level,
                            stars: stars,
                            locked: !unlocked,
                            onTap: unlocked ? () => _openLevel(level) : null,
                          );
                        },
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.stars,
    required this.locked,
    required this.onTap,
  });

  final Level level;
  final int stars;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final fg = locked ? AppColors.muted : AppColors.ink;
    return GlassCard(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      fillAlpha: locked ? 0.04 : 0.10,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${level.index}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                Text(
                  '${level.size}×${level.size}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.7),
                    letterSpacing: 0.4,
                  ),
                ),
                _StarRow(stars: stars, locked: locked),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars, required this.locked});
  final int stars;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return const Icon(Icons.lock_rounded, size: 16, color: AppColors.muted);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: filled ? AppColors.accent : AppColors.muted,
          ),
        );
      }),
    );
  }
}
