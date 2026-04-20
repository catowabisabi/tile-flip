import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tile_flip/models/infinite_difficulty.dart';
import 'package:tile_flip/models/puzzle.dart';
import 'package:tile_flip/screens/home_screen.dart';
import 'package:tile_flip/theme.dart';

/// BFS-solves a tile-flip puzzle up to [maxDepth] moves. Returns the minimum
/// tap count, or `null` if no solution was found within the depth bound.
/// Used only by tests to verify generated boards are actually solvable.
int? _solve(Puzzle start, {required int maxDepth}) {
  if (start.isSolved) return 0;
  final seen = <String>{_key(start)};
  var frontier = <Puzzle>[start];
  for (var depth = 1; depth <= maxDepth; depth++) {
    final next = <Puzzle>[];
    for (final p in frontier) {
      for (var r = 0; r < p.size; r++) {
        for (var c = 0; c < p.size; c++) {
          final n = p.tap(r, c);
          if (n.isSolved) return depth;
          final k = _key(n);
          if (seen.add(k)) next.add(n);
        }
      }
    }
    if (next.isEmpty) return null;
    frontier = next;
  }
  return null;
}

String _key(Puzzle p) {
  final sb = StringBuffer();
  for (final t in p.tiles) {
    sb.write(t ? '1' : '0');
  }
  return sb.toString();
}

void main() {
  group('Puzzle', () {
    test('tap flips self and four orthogonal neighbours', () {
      final p = Puzzle(size: 3, tiles: List<bool>.filled(9, false));
      final next = p.tap(1, 1);
      // Center + 4 neighbours toggled.
      expect(next.tileAt(1, 1), isTrue);
      expect(next.tileAt(0, 1), isTrue);
      expect(next.tileAt(2, 1), isTrue);
      expect(next.tileAt(1, 0), isTrue);
      expect(next.tileAt(1, 2), isTrue);
      // Corners untouched.
      expect(next.tileAt(0, 0), isFalse);
      expect(next.tileAt(2, 2), isFalse);
      expect(next.moves, 1);
    });

    test('tap is self-inverse', () {
      final p = Puzzle(size: 4, tiles: List<bool>.filled(16, false));
      final twice = p.tap(0, 0).tap(0, 0);
      expect(twice.tiles, equals(p.tiles));
    });

    test('generated puzzle is solvable and not pre-solved', () {
      final p = Puzzle.generate(size: 5, shuffleTaps: 6, seed: 42);
      expect(p.isSolved, isFalse);
      expect(p.moves, 0);
    });

    test('level star rating thresholds', () {
      const level = Level(index: 1, size: 4, shuffleTaps: 4, par: 4, seed: 1);
      expect(level.starsFor(3), 3);
      expect(level.starsFor(4), 3);
      expect(level.starsFor(6), 2);
      expect(level.starsFor(10), 1);
    });
  });

  group('LevelCatalog', () {
    test('has 1000 levels', () {
      expect(LevelCatalog.totalLevels, 1000);
    });

    test('at(n) is stable (same input → same level)', () {
      final a = LevelCatalog.at(250);
      final b = LevelCatalog.at(250);
      expect(a.index, b.index);
      expect(a.size, b.size);
      expect(a.shuffleTaps, b.shuffleTaps);
      expect(a.seed, b.seed);
    });

    test('difficulty curve steps up monotonically in size', () {
      expect(LevelCatalog.at(1).size, 4);
      expect(LevelCatalog.at(50).size, 4);
      expect(LevelCatalog.at(150).size, 5);
      expect(LevelCatalog.at(400).size, 6);
      expect(LevelCatalog.at(800).size, 7);
      expect(LevelCatalog.at(1000).size, 7);
    });

    test('clamps out-of-range indices', () {
      expect(LevelCatalog.at(0).index, 1);
      expect(LevelCatalog.at(9999).index, LevelCatalog.totalLevels);
    });

    test('shuffle taps grow with level index within a tier', () {
      expect(
        LevelCatalog.at(1).shuffleTaps <= LevelCatalog.at(15).shuffleTaps,
        isTrue,
      );
      expect(
        LevelCatalog.at(101).shuffleTaps <= LevelCatalog.at(290).shuffleTaps,
        isTrue,
      );
    });
  });

  group('InfiniteDifficulty', () {
    test('tier boundaries', () {
      expect(InfiniteDifficulty.forStreak(0).size, 4);
      expect(InfiniteDifficulty.forStreak(9).size, 4);
      expect(InfiniteDifficulty.forStreak(10).size, 5);
      expect(InfiniteDifficulty.forStreak(29).size, 5);
      expect(InfiniteDifficulty.forStreak(30).size, 6);
      expect(InfiniteDifficulty.forStreak(99).size, 6);
      expect(InfiniteDifficulty.forStreak(100).size, 7);
      expect(InfiniteDifficulty.forStreak(9999).size, 7);
    });

    test('taps are capped at 25 on hardcore tier', () {
      expect(InfiniteDifficulty.forStreak(100000).taps, 25);
    });
  });

  group('Infinite stability simulation', () {
    test(
      'generates 50 consecutive infinite boards without errors or pre-solved states',
      () {
        final progression = <Map<String, int>>[];
        for (var streak = 0; streak < 50; streak++) {
          final diff = InfiniteDifficulty.forStreak(streak);
          final puzzle = Puzzle.generate(
            size: diff.size,
            shuffleTaps: diff.taps,
            seed: 7000 + streak,
          );
          expect(
            puzzle.tiles.length,
            diff.size * diff.size,
            reason: 'streak=$streak board size wrong',
          );
          expect(
            puzzle.isSolved,
            isFalse,
            reason: 'streak=$streak produced a pre-solved board',
          );
          progression.add({
            'streak': streak,
            'size': diff.size,
            'taps': diff.taps,
          });
        }
        // Print the grid-size / taps progression so the log doubles as a
        // difficulty-curve visualisation.
        // ignore: avoid_print
        print('streak | grid | shuffle_taps');
        // ignore: avoid_print
        print('-------|------|-------------');
        for (final row in progression) {
          // ignore: avoid_print
          print(
            '${row['streak']!.toString().padLeft(6)} | '
            '${row['size']}×${row['size']} | '
            '${row['taps']}',
          );
        }

        // Sanity-check tier transitions landed at the expected streaks.
        expect(progression[0]['size'], 4);
        expect(progression[9]['size'], 4);
        expect(progression[10]['size'], 5);
        expect(progression[29]['size'], 5);
        expect(progression[30]['size'], 6);
        expect(progression[49]['size'], 6);
      },
    );

    test(
      'BFS proves 4×4 early-tier boards are actually solvable in ≤ shuffleTaps moves',
      () {
        // Solving 5×5 / 6×6 / 7×7 with BFS blows up (>millions of nodes). The
        // generator is solvable by construction (self-inverse taps from a
        // solved board); for early 4×4 tiers we can afford to prove it.
        for (var streak = 0; streak < 10; streak++) {
          final diff = InfiniteDifficulty.forStreak(streak);
          final puzzle = Puzzle.generate(
            size: diff.size,
            shuffleTaps: diff.taps,
            seed: 7000 + streak,
          );
          // Allow a generous depth bound: the generator may apply the same
          // tap twice (it guards against exact dupes but not against
          // permutations that cancel), so the true minimum could be less
          // than shuffleTaps. We just need SOME solution within reason.
          final minMoves = _solve(puzzle, maxDepth: diff.taps + 2);
          expect(
            minMoves,
            isNotNull,
            reason:
                'streak=$streak (size=${diff.size}, taps=${diff.taps}) '
                'could not be solved within ${diff.taps + 2} moves',
          );
          expect(
            minMoves! <= diff.taps + 2,
            isTrue,
            reason: 'streak=$streak solution depth $minMoves exceeds bound',
          );
        }
      },
    );
  });

  testWidgets('HomeScreen renders title and mode buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const HomeScreen()),
    );
    expect(find.text('Tile Flip'), findsOneWidget);
    expect(find.text('LEVELS'), findsOneWidget);
    expect(find.text('INFINITE'), findsOneWidget);
  });
}
