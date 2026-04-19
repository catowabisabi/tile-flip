import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/puzzle.dart';
import '../services/ads.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/puzzle_grid.dart';

/// Endless mode: solve one puzzle, get another. Difficulty scales with the
/// current streak. No stars, no par — just keep going.
class InfiniteScreen extends StatefulWidget {
  const InfiniteScreen({super.key});

  @override
  State<InfiniteScreen> createState() => _InfiniteScreenState();
}

class _InfiniteScreenState extends State<InfiniteScreen> {
  late Puzzle _puzzle;
  late int _currentSize;
  late int _currentShuffleTaps;
  final List<Puzzle> _history = [];
  bool _won = false;
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
    _loadNext();
  }

  ({int size, int taps}) _difficultyForStreak(int streak) {
    if (streak < 10) return (size: 4, taps: 2 + (streak ~/ 3));
    if (streak < 30) return (size: 5, taps: 5 + ((streak - 10) ~/ 4));
    if (streak < 100) return (size: 6, taps: 8 + ((streak - 30) ~/ 7));
    return (size: 7, taps: (12 + ((streak - 100) ~/ 10)).clamp(12, 25));
  }

  void _loadNext() {
    final streak = _store?.infiniteStreak ?? 0;
    final diff = _difficultyForStreak(streak);
    _currentSize = diff.size;
    _currentShuffleTaps = diff.taps;
    _puzzle = Puzzle.generate(
      size: diff.size,
      shuffleTaps: diff.taps,
      seed: _rng.nextInt(1 << 31),
    );
    _history.clear();
    _won = false;
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
    await store.recordInfiniteWin();
    final winCount = await store.incrementWinCount();
    if (winCount % kInterstitialEveryNWins == 0) {
      unawaited(AdsService.instance.maybeShowInterstitial());
    }
    if (!mounted) return;
    setState(() => _store = store);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InfiniteWinDialog(
        moves: _puzzle.moves,
        streak: store.infiniteStreak,
        bestStreak: store.infiniteBestStreak,
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

  void _restart() {
    setState(() {
      _puzzle = Puzzle.generate(
        size: _currentSize,
        shuffleTaps: _currentShuffleTaps,
        seed: _rng.nextInt(1 << 31),
      );
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

  @override
  Widget build(BuildContext context) {
    final streak = _store?.infiniteStreak ?? 0;
    final best = _store?.infiniteBestStreak ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _history.isEmpty || _won ? null : _undo,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'New puzzle',
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
                    _InfiniteStatsBar(
                      streak: streak,
                      best: best,
                      moves: _puzzle.moves,
                      size: _currentSize,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Stat(label: 'GRID', value: '$size×$size'),
        _Stat(label: 'MOVES', value: '$moves'),
        _Stat(label: 'STREAK', value: '$streak'),
        _Stat(label: 'BEST', value: '$best'),
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
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
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
    required this.onNext,
    required this.onQuit,
  });

  final int moves;
  final int streak;
  final int bestStreak;
  final VoidCallback onNext;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final newBest = streak == bestStreak && streak > 0;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SOLVED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.inkSoft.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Streak $streak',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$moves moves · best $bestStreak${newBest ? " (new!)" : ""}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(onPressed: onQuit, child: const Text('Quit')),
              FilledButton(onPressed: onNext, child: const Text('Next')),
            ],
          ),
        ],
      ),
    );
  }
}
