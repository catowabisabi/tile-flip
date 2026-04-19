import 'package:flutter/material.dart';

import '../models/puzzle.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
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
    // Refresh stars on return.
    final store = await ProgressStore.load();
    if (mounted) setState(() => _store = store);
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: store == null
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1,
                          ),
                      itemCount: LevelCatalog.levels.length,
                      itemBuilder: (context, i) {
                        final level = LevelCatalog.levels[i];
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
    final bg = locked
        ? AppColors.muted.withValues(alpha: 0.25)
        : AppColors.surface;
    final fg = locked ? AppColors.muted : AppColors.ink;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: locked ? AppColors.muted : AppColors.ink,
              width: 1.4,
            ),
          ),
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
                ),
              ),
              _StarRow(stars: stars, locked: locked),
            ],
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
      return const Icon(Icons.lock, size: 16, color: AppColors.muted);
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
