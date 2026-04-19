import 'package:shared_preferences/shared_preferences.dart';

/// Persists local progress: which levels are unlocked, best moves and stars
/// per level, and a global win counter (used to time interstitial ads).
class ProgressStore {
  static const _kUnlocked = 'unlocked_level';
  static const _kBestMovesPrefix = 'best_moves_';
  static const _kStarsPrefix = 'stars_';
  static const _kWinCount = 'win_count';

  final SharedPreferences _prefs;
  ProgressStore._(this._prefs);

  static Future<ProgressStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStore._(prefs);
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
}
