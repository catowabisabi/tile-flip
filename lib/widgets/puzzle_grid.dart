import 'package:flutter/material.dart';

import '../models/puzzle.dart';
import '../models/tile_theme.dart';
import 'tile_widget.dart';

class PuzzleGrid extends StatelessWidget {
  const PuzzleGrid({
    super.key,
    required this.puzzle,
    required this.onTap,
    required this.palette,
  });

  final Puzzle puzzle;
  final void Function(int row, int col) onTap;
  final TilePalette palette;

  @override
  Widget build(BuildContext context) {
    const gap = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final tileSize = (side - gap * (puzzle.size - 1)) / puzzle.size;
        return SizedBox(
          width: side,
          height: side,
          child: Column(
            children: [
              for (var r = 0; r < puzzle.size; r++) ...[
                if (r > 0) const SizedBox(height: gap),
                Row(
                  children: [
                    for (var c = 0; c < puzzle.size; c++) ...[
                      if (c > 0) const SizedBox(width: gap),
                      SizedBox(
                        width: tileSize,
                        height: tileSize,
                        child: TileWidget(
                          dark: puzzle.tileAt(r, c),
                          palette: palette,
                          onTap: () => onTap(r, c),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
