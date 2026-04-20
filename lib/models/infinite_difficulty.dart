/// Difficulty curve for Infinite mode.
///
/// Pure function of the current streak → board size and shuffle-tap count.
/// Exposed as a top-level class so it can be unit-tested independently of the
/// Infinite screen's widget state.
class InfiniteDifficulty {
  final int size;
  final int taps;

  const InfiniteDifficulty({required this.size, required this.taps});

  /// Streak tiers:
  ///   0..9   : 4×4, 2 → 5 taps
  ///   10..29 : 5×5, 5 → 9 taps
  ///   30..99 : 6×6, 8 → 17 taps
  ///   100+   : 7×7, 12 → 25 taps (capped)
  static InfiniteDifficulty forStreak(int streak) {
    if (streak < 10) {
      return InfiniteDifficulty(size: 4, taps: 2 + (streak ~/ 3));
    }
    if (streak < 30) {
      return InfiniteDifficulty(size: 5, taps: 5 + ((streak - 10) ~/ 4));
    }
    if (streak < 100) {
      return InfiniteDifficulty(size: 6, taps: 8 + ((streak - 30) ~/ 7));
    }
    return InfiniteDifficulty(
      size: 7,
      taps: (12 + ((streak - 100) ~/ 10)).clamp(12, 25),
    );
  }
}
