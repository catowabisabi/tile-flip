import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/puzzle.dart';
import '../models/tile_theme.dart';
import '../services/ads.dart';
import '../services/settings_service.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/coin_hud.dart';
import '../widgets/confetti.dart';
import '../widgets/glass.dart';
import '../widgets/puzzle_grid.dart';
import '../widgets/tutorial_overlay.dart';

/// Coins granted on level completion: `stars × kCoinsPerStar`.
const int kCoinsPerStar = 10;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});
  final Level level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Puzzle _puzzle;
  final List<Puzzle> _history = [];
  bool _won = false;
  bool _celebrate = false;
  bool _showTutorial = false;
  ProgressStore? _store;

  @override
  void initState() {
    super.initState();
    _puzzle = widget.level.build();
    _showTutorial = !SettingsService.instance.tutorialSeen.value;
    ProgressStore.load().then((store) {
      if (mounted) setState(() => _store = store);
    });
  }

  void _onTap(int row, int col) {
    if (_won || _showTutorial) return;
    setState(() {
      _history.add(_puzzle);
      _puzzle = _puzzle.tap(row, col);
    });
    if (_puzzle.isSolved) {
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
    final store = _store ?? await ProgressStore.load();
    final stars = widget.level.starsFor(_puzzle.moves);
    await store.recordResult(
      level: widget.level.index,
      moves: _puzzle.moves,
      stars: stars,
    );
    await store.unlockUpTo(widget.level.index + 1);
    final coinsEarned = stars * kCoinsPerStar;
    await store.addCoins(coinsEarned);
    final winCount = await store.incrementWinCount();

    if (winCount % kInterstitialEveryNWins == 0) {
      unawaited(AdsService.instance.maybeShowInterstitial());
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _WinDialog(
        stars: stars,
        moves: _puzzle.moves,
        par: widget.level.par,
        coinsEarned: coinsEarned,
        onShare: () => _shareWin(stars: stars),
        onReplay: () {
          Navigator.of(context).pop();
          _restart();
        },
        onNext: () {
          Navigator.of(context).pop();
          _goToNext();
        },
        onMenu: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _shareWin({required int stars}) async {
    final starLine = '★' * stars + '☆' * (3 - stars);
    final text =
        'I just solved Tile Flip — Level ${widget.level.index} '
        '$starLine in ${_puzzle.moves} moves (par ${widget.level.par}). '
        'Can you beat me? #TileFlip';
    await Share.share(text);
  }

  void _restart() {
    setState(() {
      _puzzle = widget.level.build();
      _history.clear();
      _won = false;
      _celebrate = false;
    });
  }

  void _undo() {
    if (_history.isEmpty || _won) return;
    setState(() {
      _puzzle = _history.removeLast();
    });
  }

  void _goToNext() {
    final nextIdx = widget.level.index + 1;
    if (nextIdx > LevelCatalog.totalLevels) {
      Navigator.of(context).pop();
      return;
    }
    final next = LevelCatalog.at(nextIdx);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => GameScreen(level: next)),
    );
  }

  void _dismissTutorial() {
    SettingsService.instance.markTutorialSeen();
    setState(() => _showTutorial = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteForLevel(widget.level.index);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Level ${widget.level.index}'),
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
            tooltip: 'Restart',
            onPressed: _restart,
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        children: [
                          _StatsBar(
                            moves: _puzzle.moves,
                            par: widget.level.par,
                            size: widget.level.size,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: PuzzleGrid(
                                  puzzle: _puzzle,
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
            if (_showTutorial) TutorialOverlay(onDismiss: _dismissTutorial),
          ],
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.moves, required this.par, required this.size});
  final int moves;
  final int par;
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
          _Stat(label: 'MOVES', value: '$moves', highlight: true),
          _Stat(label: 'PAR', value: '$par'),
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

class _WinDialog extends StatelessWidget {
  const _WinDialog({
    required this.stars,
    required this.moves,
    required this.par,
    required this.coinsEarned,
    required this.onReplay,
    required this.onNext,
    required this.onMenu,
    required this.onShare,
  });
  final int stars;
  final int moves;
  final int par;
  final int coinsEarned;
  final VoidCallback onReplay;
  final VoidCallback onNext;
  final VoidCallback onMenu;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: GlassCard(
        borderRadius: 26,
        fillAlpha: 0.14,
        blurSigma: 28,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SOLVED',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final filled = i < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 48,
                    color: filled
                        ? AppColors.accent
                        : AppColors.muted.withValues(alpha: 0.7),
                    shadows: filled
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.55),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            Text(
              '$moves moves · par $par',
              style: TextStyle(
                fontSize: 15,
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
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReplay,
                    child: const Text('Replay'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMenu,
                    child: const Text('Levels'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onNext,
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
