import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tile_flip/models/tile_theme.dart';
import 'package:tile_flip/services/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('paletteForLevel', () {
    test('cycles through the four palettes by level index', () {
      expect(paletteForLevel(1).id, kTilePalettes[0].id);
      expect(paletteForLevel(2).id, kTilePalettes[1].id);
      expect(paletteForLevel(4).id, kTilePalettes[3].id);
      expect(paletteForLevel(5).id, kTilePalettes[0].id);
      expect(paletteForLevel(9).id, kTilePalettes[0].id);
    });

    test('unknown palette id falls back to the first palette', () {
      expect(paletteById('does-not-exist').id, kTilePalettes.first.id);
    });
  });

  group('ProgressStore coin wallet', () {
    test('starts at zero, adds, and exposes a live notifier', () async {
      final store = await ProgressStore.load();
      expect(store.coins, 0);
      expect(ProgressStore.coinNotifier.value, 0);

      await store.addCoins(30);
      expect(store.coins, 30);
      expect(ProgressStore.coinNotifier.value, 30);
    });

    test('spend fails when insufficient, succeeds otherwise', () async {
      final store = await ProgressStore.load();
      await store.addCoins(20);

      expect(await store.spendCoins(50), isFalse);
      expect(store.coins, 20);

      expect(await store.spendCoins(15), isTrue);
      expect(store.coins, 5);
      expect(ProgressStore.coinNotifier.value, 5);
    });

    test('resetAll wipes coins and progress', () async {
      final store = await ProgressStore.load();
      await store.addCoins(40);
      await store.unlockUpTo(5);
      await store.recordResult(level: 1, moves: 3, stars: 3);
      await store.recordInfiniteWin();

      await store.resetAll();

      expect(store.coins, 0);
      expect(store.highestUnlocked, 1);
      expect(store.starsFor(1), 0);
      expect(store.infiniteStreak, 0);
      expect(store.infiniteBestStreak, 0);
      expect(ProgressStore.coinNotifier.value, 0);
    });
  });
}
