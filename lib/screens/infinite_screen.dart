import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/infinite_difficulty.dart';
import '../models/puzzle.dart';
import '../models/tile_theme.dart';
import '../services/ads.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/coin_hud.dart';
import '../widgets/confetti.dart';
import '../widgets/glass.dart';
import '../widgets/puzzle_grid.dart';

/// Coins granted per Infinite mode win.
const int kInfiniteCoinsPerWin = 5;

/// Endless mode: solve one puzzle, get another. Difficulty scales with the
/// current streak. No stars, no par — just keep going.
class InfiniteScreen extends StatefulWidget {
  const InfiniteScreen({super.key});

  @override
  State<InfiniteScreen> createState() => _InfiniteScreenState();
}

class _InfiniteScreenState extends State<InfiniteScreen> {
  Puzzle? _puzzle;
  int _currentSize = 4;
  final List<Puzzle> _history = [];
  bool _won = false;
  bool _celebrate = false;
  ProgressStore? _store;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    ProgressStore.load().then((store) {
      if (!mounted) return;
      setState(() {
        _store = store;
        _loadNext();
      });
    });
    AudioService.instance.playGameplayBgm();
  }

  void _loadNext() {
    final streak = _store?.infiniteStreak ?? 0;
    final diff = InfiniteDifficulty.forStreak(streak);
    _currentSize = diff.size;
    _puzzle = Puzzle.generate(
      size: diff.size,
      shuffleTaps: diff.taps,
      seed: _rng.nextInt(1 << 31),
    );
    _history.clear();
    _won = false;
    _celebrate = false;
  }

  void _onTap(int row, int col) {
    if (_won) return;
    final current = _puzzle;
    if (current == null) return;
    final next = current.tap(row, col);
    setState(() {
      _history.add(current);
      _puzzle = next;
    });
    if (next.isSolved) {
      _handleWin();
    }
  }

  Future<void> _handleWin() async {
    setState(() {
      _won = true;
      _celebrate = SettingsService.instance.effects.value;
    });
    if (SettingsService.instance.haptics.value) {
      unawaited(HapticFeedback.mediumImpact());
    }
    unawaited(AudioService.instance.playWin());
    final store = _store ?? await ProgressStore.load();
    // Snapshot before recording so we can distinguish a brand-new best
    // streak from merely tying the existing one.
    final previousBest = store.infiniteBestStreak;
    await store.recordInfiniteWin();
    await store.addCoins(kInfiniteCoinsPerWin);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      AudioService.instance.playCoinEarn();
    });
    final winCount = await store.incrementWinCount();
    if (winCount % kInterstitialEveryNWins == 0) {
      unawaited(AdsService.instance.maybeShowInterstitial());
    }
    if (!mounted) return;
    setState(() => _store = store);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _InfiniteWinDialog(
        moves: _puzzle?.moves ?? 0,
        streak: store.infiniteStreak,
        bestStreak: store.infiniteBestStreak,
        isNewBest: store.infiniteBestStreak > previousBest,
        coinsEarned: kInfiniteCoinsPerWin,
        onShare: () => _shareWin(streak: store.infiniteStreak),
        onNext: () {
          Navigator.of(context).pop();
          setState(() => _loadNext());
        },
        onQuit: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _shareWin({required int streak}) async {
    final text =
        'Tile Flip Infinite — streak $streak 🔥 and still going. '
        'Can you beat me? #TileFlip';
    await Share.share(text);
  }

  /// Skip the current puzzle. Giving up breaks the streak — resets to 0 and
  /// re-picks difficulty accordingly so the player doesn't stay stuck on a
  /// board they can't solve.
  Future<void> _skip() async {
    unawaited(AudioService.instance.playStreakBreak());
    await _store?.resetInfiniteStreak();
    if (!mounted) return;
    setState(_loadNext);
  }

  void _undo() {
    if (_history.isEmpty || _won) return;
    setState(() {
      _puzzle = _history.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final streak = _store?.infiniteStreak ?? 0;
    final best = _store?.infiniteBestStreak ?? 0;
    final puzzle = _puzzle;
    return ValueListenableBuilder<String>(
      valueListenable: SettingsService.instance.infinitePaletteId,
      builder: (context, paletteId, _) {
        final palette = paletteById(paletteId);
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Infinite'),
            actions: [
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Center(child: CoinHud()),
              ),
              IconButton(
                tooltip: 'Undo',
                onPressed: _history.isEmpty || _won ? null : _undo,
                icon: const Icon(Icons.undo_rounded),
              ),
              IconButton(
                tooltip: 'Skip (resets streak)',
                onPressed: puzzle == null || _won ? null : _skip,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: AppBackdrop(
            child: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: puzzle == null
                            ? const Center(child: CircularProgressIndicator())
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  16,
                                ),
                                child: Column(
                                  children: [
                                    _InfiniteStatsBar(
                                      streak: streak,
                                      best: best,
                                      moves: puzzle.moves,
                                      size: _currentSize,
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: Center(
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: PuzzleGrid(
                                            puzzle: puzzle,
                                            onTap: _onTap,
                                            palette: palette,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const BannerAdSlot(),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ConfettiBurst(
                      active: _celebrate,
                      colors: [
                        palette.accent,
                        palette.lightStart,
                        palette.darkStart,
                        AppColors.ink,
                      ],
                      onComplete: () {
                        if (mounted) setState(() => _celebrate = false);
                      },
                    ),
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

class _InfiniteStatsBar extends StatelessWidget {
  const _InfiniteStatsBar({
    required this.streak,
    required this.best,
    required this.moves,
    required this.size,
  });
  final int streak;
  final int best;
  final int moves;
  final int size;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Stat(label: 'GRID', value: '$size×$size'),
          _Stat(label: 'MOVES', value: '$moves'),
          _Stat(label: 'STREAK', value: '$streak', highlight: true),
          _Stat(label: 'BEST', value: '$best'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
            color: AppColors.inkSoft.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.accent : AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _InfiniteWinDialog extends StatelessWidget {
  const _InfiniteWinDialog({
    required this.moves,
    required this.streak,
    required this.bestStreak,
    required this.isNewBest,
    required this.coinsEarned,
    required this.onNext,
    required this.onQuit,
    required this.onShare,
  });

  final int moves;
  final int streak;
  final int bestStreak;
  final bool isNewBest;
  final int coinsEarned;
  final VoidCallback onNext;
  final VoidCallback onQuit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: GlassCard(
        borderRadius: 26,
        fillAlpha: 0.14,
        blurSigma: 28,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SOLVED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: AppColors.inkSoft.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Streak $streak',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$moves moves · best $bestStreak${isNewBest ? " (new!)" : ""}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.inkSoft.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '+$coinsEarned coins',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onQuit,
                    child: const Text('Quit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onNext, child: const Text('Next')),
            ),
          ],
        ),
      ),
    );
  }
}
