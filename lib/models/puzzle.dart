import 'dart:math';

/// Immutable snapshot of a tile-flip puzzle.
///
/// Tiles are stored as a row-major list of booleans. `true` means "dark".
/// Tapping a tile toggles itself and its 4 orthogonal neighbors.
class Puzzle {
  final int size;
  final List<bool> tiles;
  final int moves;

  Puzzle({required this.size, required this.tiles, this.moves = 0})
    : assert(tiles.length == size * size);

  Puzzle copyWith({List<bool>? tiles, int? moves}) => Puzzle(
    size: size,
    tiles: tiles ?? this.tiles,
    moves: moves ?? this.moves,
  );

  bool tileAt(int row, int col) => tiles[row * size + col];

  bool get isSolved {
    final first = tiles.first;
    for (final t in tiles) {
      if (t != first) return false;
    }
    return true;
  }

  /// Apply a tap at (row, col): toggle self + 4 orthogonal neighbors.
  Puzzle tap(int row, int col) {
    final next = List<bool>.from(tiles);
    void flip(int r, int c) {
      if (r < 0 || r >= size || c < 0 || c >= size) return;
      next[r * size + c] = !next[r * size + c];
    }

    flip(row, col);
    flip(row - 1, col);
    flip(row + 1, col);
    flip(row, col - 1);
    flip(row, col + 1);

    return copyWith(tiles: next, moves: moves + 1);
  }

  /// Generate a solvable puzzle by starting from a solved board and applying
  /// [shuffleTaps] random taps. Since every tap is self-inverse, the board is
  /// guaranteed solvable in at most [shuffleTaps] moves.
  static Puzzle generate({
    required int size,
    required int shuffleTaps,
    int? seed,
  }) {
    final rng = Random(seed);
    var puzzle = Puzzle(
      size: size,
      tiles: List<bool>.filled(size * size, false),
    );
    final applied = <int>{};
    var attempts = 0;
    while (applied.length < shuffleTaps && attempts < shuffleTaps * 10) {
      final r = rng.nextInt(size);
      final c = rng.nextInt(size);
      final idx = r * size + c;
      if (!applied.add(idx)) {
        attempts++;
        continue;
      }
      puzzle = puzzle.tap(r, c);
      attempts++;
    }
    if (puzzle.isSolved) {
      // Guarantee at least one tap so the starting board isn't already solved.
      puzzle = puzzle.tap(0, 0);
    }
    return Puzzle(size: size, tiles: puzzle.tiles, moves: 0);
  }
}

/// Static level catalog. Each level picks a size, shuffle amount, and par
/// (move target for a 3-star rating).
class Level {
  final int index;
  final int size;
  final int shuffleTaps;
  final int par;
  final int seed;

  const Level({
    required this.index,
    required this.size,
    required this.shuffleTaps,
    required this.par,
    required this.seed,
  });

  Puzzle build() =>
      Puzzle.generate(size: size, shuffleTaps: shuffleTaps, seed: seed);

  /// Stars: 3 if moves <= par, 2 if <= par * 1.5, else 1 (on win).
  int starsFor(int movesUsed) {
    if (movesUsed <= par) return 3;
    if (movesUsed <= (par * 1.5).ceil()) return 2;
    return 1;
  }
}

/// Procedurally-generated level catalog with [totalLevels] entries.
///
/// Rather than hand-rolling 1000 rows, size and shuffle-count are derived from
/// the level index via [_curveFor]. This keeps the binary tiny and makes the
/// difficulty curve easy to re-tune in one place.
class LevelCatalog {
  static const int totalLevels = 1000;

  /// Size / shuffle-tap curve. Each tier linearly ramps shuffle taps across a
  /// range of levels; size steps up at tier boundaries.
  ///
  /// Tiers (inclusive ranges):
  ///   1..20    : 4x4, 2 → 5 taps   (warm-up)
  ///   21..100  : 4x4, 4 → 9
  ///   101..300 : 5x5, 5 → 12
  ///   301..600 : 6x6, 8 → 18
  ///   601..1000: 7x7, 12 → 25       (hardcore)
  static const List<_Tier> _tiers = [
    _Tier(startIndex: 1, endIndex: 20, size: 4, minTaps: 2, maxTaps: 5),
    _Tier(startIndex: 21, endIndex: 100, size: 4, minTaps: 4, maxTaps: 9),
    _Tier(startIndex: 101, endIndex: 300, size: 5, minTaps: 5, maxTaps: 12),
    _Tier(startIndex: 301, endIndex: 600, size: 6, minTaps: 8, maxTaps: 18),
    _Tier(startIndex: 601, endIndex: 1000, size: 7, minTaps: 12, maxTaps: 25),
  ];

  static _Tier _tierFor(int index) {
    for (final t in _tiers) {
      if (index >= t.startIndex && index <= t.endIndex) return t;
    }
    return _tiers.last;
  }

  /// Returns the level descriptor for [index] (1-based).
  static Level at(int index) {
    final clamped = index.clamp(1, totalLevels);
    final tier = _tierFor(clamped);
    final span = (tier.endIndex - tier.startIndex).clamp(1, 1 << 30);
    final t = (clamped - tier.startIndex) / span;
    final taps = tier.minTaps + ((tier.maxTaps - tier.minTaps) * t).round();
    return Level(
      index: clamped,
      size: tier.size,
      shuffleTaps: taps,
      par: taps,
      seed: 1000 + clamped,
    );
  }

  /// Kept for backward-compatibility with tests / widgets that expect a list.
  /// Use [at] for O(1) access; this realises the full list eagerly.
  static List<Level> get levels =>
      List<Level>.generate(totalLevels, (i) => at(i + 1), growable: false);

  static Level byIndex(int index) => at(index);
}

class _Tier {
  final int startIndex;
  final int endIndex;
  final int size;
  final int minTaps;
  final int maxTaps;

  const _Tier({
    required this.startIndex,
    required this.endIndex,
    required this.size,
    required this.minTaps,
    required this.maxTaps,
  });
}
