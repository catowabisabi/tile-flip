import 'package:flutter/material.dart';

/// A palette used to colour the tiles on the puzzle board.
///
/// Tiles have a binary "dark / light" state; each palette provides a gradient
/// pair for each state plus an accent colour used for the centre dot on dark
/// tiles and the confetti burst on win.
@immutable
class TilePalette {
  final String id;
  final String name;

  final Color darkStart;
  final Color darkEnd;
  final Color lightStart;
  final Color lightEnd;
  final Color accent;

  const TilePalette({
    required this.id,
    required this.name,
    required this.darkStart,
    required this.darkEnd,
    required this.lightStart,
    required this.lightEnd,
    required this.accent,
  });

  LinearGradient get darkGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkStart, darkEnd],
  );

  LinearGradient get lightGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightStart, lightEnd],
  );
}

/// Built-in tile palettes. Index 0 is the default / fallback and matches the
/// original navy-and-coral look.
const List<TilePalette> kTilePalettes = <TilePalette>[
  TilePalette(
    id: 'navy',
    name: 'Navy',
    darkStart: Color(0xFF2F386A),
    darkEnd: Color(0xFF1F2649),
    lightStart: Color(0xFFFAFBFF),
    lightEnd: Color(0xFFDDE2F2),
    accent: Color(0xFFFF8A65),
  ),
  TilePalette(
    id: 'sunset',
    name: 'Sunset',
    darkStart: Color(0xFF6B1E3C),
    darkEnd: Color(0xFF3A0F2B),
    lightStart: Color(0xFFFFE5D4),
    lightEnd: Color(0xFFF5B79B),
    accent: Color(0xFFFFC857),
  ),
  TilePalette(
    id: 'forest',
    name: 'Forest',
    darkStart: Color(0xFF1F4A2E),
    darkEnd: Color(0xFF0F2A1A),
    lightStart: Color(0xFFE6F3DB),
    lightEnd: Color(0xFFB5D39D),
    accent: Color(0xFF9BE081),
  ),
  TilePalette(
    id: 'neon',
    name: 'Neon',
    darkStart: Color(0xFF3A0F6B),
    darkEnd: Color(0xFF1A0B3A),
    lightStart: Color(0xFFEAE0FF),
    lightEnd: Color(0xFFB49BFF),
    accent: Color(0xFF39D7FF),
  ),
];

/// Returns the palette with the given [id], falling back to the default when
/// the id is unknown (e.g. persisted from an older build).
TilePalette paletteById(String id) {
  for (final p in kTilePalettes) {
    if (p.id == id) return p;
  }
  return kTilePalettes.first;
}

/// Palette automatically picked for a given level index. Used in Levels mode
/// so the board colour changes every level without the player having to
/// configure anything.
TilePalette paletteForLevel(int levelIndex) {
  final idx = ((levelIndex - 1) % kTilePalettes.length).clamp(
    0,
    kTilePalettes.length - 1,
  );
  return kTilePalettes[idx];
}
