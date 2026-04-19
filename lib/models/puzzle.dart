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

class LevelCatalog {
  static const List<Level> levels = [
    // Gentle intro at 4x4.
    Level(index: 1, size: 4, shuffleTaps: 2, par: 2, seed: 101),
    Level(index: 2, size: 4, shuffleTaps: 3, par: 3, seed: 102),
    Level(index: 3, size: 4, shuffleTaps: 4, par: 4, seed: 103),
    Level(index: 4, size: 4, shuffleTaps: 5, par: 5, seed: 104),
    Level(index: 5, size: 4, shuffleTaps: 6, par: 6, seed: 105),
    // Step up to 5x5.
    Level(index: 6, size: 5, shuffleTaps: 4, par: 4, seed: 201),
    Level(index: 7, size: 5, shuffleTaps: 5, par: 5, seed: 202),
    Level(index: 8, size: 5, shuffleTaps: 6, par: 6, seed: 203),
    Level(index: 9, size: 5, shuffleTaps: 7, par: 7, seed: 204),
    Level(index: 10, size: 5, shuffleTaps: 8, par: 8, seed: 205),
    // Step up to 6x6.
    Level(index: 11, size: 6, shuffleTaps: 6, par: 6, seed: 301),
    Level(index: 12, size: 6, shuffleTaps: 7, par: 7, seed: 302),
    Level(index: 13, size: 6, shuffleTaps: 8, par: 8, seed: 303),
    Level(index: 14, size: 6, shuffleTaps: 9, par: 9, seed: 304),
    Level(index: 15, size: 6, shuffleTaps: 10, par: 10, seed: 305),
  ];

  static Level byIndex(int index) =>
      levels.firstWhere((l) => l.index == index, orElse: () => levels.first);
}
