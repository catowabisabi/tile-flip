import 'dart:async';

import 'package:flutter/material.dart';

import '../models/puzzle.dart';
import '../services/ads.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/puzzle_grid.dart';

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
  ProgressStore? _store;

  @override
  void initState() {
    super.initState();
    _puzzle = widget.level.build();
    ProgressStore.load().then((store) {
      if (mounted) setState(() => _store = store);
    });
  }

  void _onTap(int row, int col) {
    if (_won) return;
    setState(() {
      _history.add(_puzzle);
      _puzzle = _puzzle.tap(row, col);
    });
    if (_puzzle.isSolved) {
      _handleWin();
    }
  }

  Future<void> _handleWin() async {
    setState(() => _won = true);
    final store = _store ?? await ProgressStore.load();
    final stars = widget.level.starsFor(_puzzle.moves);
    await store.recordResult(
      level: widget.level.index,
      moves: _puzzle.moves,
      stars: stars,
    );
    await store.unlockUpTo(widget.level.index + 1);
    final winCount = await store.incrementWinCount();

    if (winCount % kInterstitialEveryNWins == 0) {
      // Fire-and-forget — don't block the UI on ad load.
      unawaited(AdsService.instance.maybeShowInterstitial());
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WinDialog(
        stars: stars,
        moves: _puzzle.moves,
        par: widget.level.par,
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

  void _restart() {
    setState(() {
      _puzzle = widget.level.build();
      _history.clear();
      _won = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${widget.level.index}'),
        actions: [
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    _StatsBar(
                      moves: _puzzle.moves,
                      par: widget.level.par,
                      size: widget.level.size,
                    ),
                    const Spacer(),
                    PuzzleGrid(puzzle: _puzzle, onTap: _onTap),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            const BannerAdSlot(),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Stat(label: 'GRID', value: '$size×$size'),
        _Stat(label: 'MOVES', value: '$moves'),
        _Stat(label: 'PAR', value: '$par'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.inkSoft.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
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
    required this.onReplay,
    required this.onNext,
    required this.onMenu,
  });
  final int stars;
  final int moves;
  final int par;
  final VoidCallback onReplay;
  final VoidCallback onNext;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
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
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final filled = i < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 42,
                    color: filled ? AppColors.accent : AppColors.muted,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              '$moves moves · par $par',
              style: const TextStyle(fontSize: 15, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 24),
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
                  child: OutlinedButton(
                    onPressed: onReplay,
                    child: const Text('Replay'),
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
