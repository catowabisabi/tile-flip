import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tile_flip/models/puzzle.dart';
import 'package:tile_flip/screens/home_screen.dart';
import 'package:tile_flip/theme.dart';

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

  testWidgets('HomeScreen renders title and mode buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
    );
    expect(find.text('Tile Flip'), findsOneWidget);
    expect(find.text('LEVELS'), findsOneWidget);
    expect(find.text('INFINITE'), findsOneWidget);
  });
}
