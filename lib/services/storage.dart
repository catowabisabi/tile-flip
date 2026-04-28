import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists local progress: which levels are unlocked, best moves and stars
/// per level, a global win counter (used to time interstitial ads), and the
/// player's coin wallet (effects branch).
class ProgressStore {
  static const _kUnlocked = 'unlocked_level';
  static const _kBestMovesPrefix = 'best_moves_';
  static const _kStarsPrefix = 'stars_';
  static const _kWinCount = 'win_count';
  static const _kCoins = 'coins';

  final SharedPreferences _prefs;
  ProgressStore._(this._prefs);

  /// Live coin balance. Exposed as a [ValueListenable] so widgets like
  /// `CoinHud` can rebuild without the caller having to setState on every
  /// screen after a purchase / earn.
  static final ValueNotifier<int> coinNotifier = ValueNotifier<int>(0);

  static Future<ProgressStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = ProgressStore._(prefs);
    coinNotifier.value = store.coins;
    return store;
  }

  int get highestUnlocked => _prefs.getInt(_kUnlocked) ?? 1;

  Future<void> unlockUpTo(int level) async {
    if (level > highestUnlocked) {
      await _prefs.setInt(_kUnlocked, level);
    }
  }

  int starsFor(int level) => _prefs.getInt('$_kStarsPrefix$level') ?? 0;
  int? bestMovesFor(int level) => _prefs.getInt('$_kBestMovesPrefix$level');

  Future<void> recordResult({
    required int level,
    required int moves,
    required int stars,
  }) async {
    final prevStars = starsFor(level);
    if (stars > prevStars) {
      await _prefs.setInt('$_kStarsPrefix$level', stars);
    }
    final prevMoves = bestMovesFor(level);
    if (prevMoves == null || moves < prevMoves) {
      await _prefs.setInt('$_kBestMovesPrefix$level', moves);
    }
  }

  int get winCount => _prefs.getInt(_kWinCount) ?? 0;
  Future<int> incrementWinCount() async {
    final n = winCount + 1;
    await _prefs.setInt(_kWinCount, n);
    return n;
  }

  // --- Infinite mode stats ---
  static const _kInfiniteStreak = 'infinite_streak';
  static const _kInfiniteBestStreak = 'infinite_best_streak';
  static const _kInfiniteTotalWins = 'infinite_total_wins';

  int get infiniteStreak => _prefs.getInt(_kInfiniteStreak) ?? 0;
  int get infiniteBestStreak => _prefs.getInt(_kInfiniteBestStreak) ?? 0;
  int get infiniteTotalWins => _prefs.getInt(_kInfiniteTotalWins) ?? 0;

  Future<void> recordInfiniteWin() async {
    final nextStreak = infiniteStreak + 1;
    await _prefs.setInt(_kInfiniteStreak, nextStreak);
    if (nextStreak > infiniteBestStreak) {
      await _prefs.setInt(_kInfiniteBestStreak, nextStreak);
    }
    await _prefs.setInt(_kInfiniteTotalWins, infiniteTotalWins + 1);
  }

  Future<void> resetInfiniteStreak() async {
    await _prefs.setInt(_kInfiniteStreak, 0);
  }

  // --- Coin wallet (effects branch) ---

  int get coins => _prefs.getInt(_kCoins) ?? 0;

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    final next = coins + amount;
    await _prefs.setInt(_kCoins, next);
    coinNotifier.value = next;
  }

  /// Attempt to spend [amount] coins. Returns true on success, false if the
  /// balance is insufficient. (No negative balances allowed.)
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (coins < amount) return false;
    final next = coins - amount;
    await _prefs.setInt(_kCoins, next);
    coinNotifier.value = next;
    return true;
  }

  /// Wipe all progress: unlocked levels, stars, best-moves, infinite stats,
  /// and coins. Intended to back the Settings "Reset progress" button.
  Future<void> resetAll() async {
    final keys = _prefs.getKeys().toList();
    for (final k in keys) {
      if (k == _kUnlocked ||
          k == _kWinCount ||
          k == _kCoins ||
          k == _kInfiniteStreak ||
          k == _kInfiniteBestStreak ||
          k == _kInfiniteTotalWins ||
          k.startsWith(_kBestMovesPrefix) ||
          k.startsWith(_kStarsPrefix)) {
        await _prefs.remove(k);
      }
    }
    coinNotifier.value = 0;
  }
}
