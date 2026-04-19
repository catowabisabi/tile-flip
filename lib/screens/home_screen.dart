import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
import 'levels_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),
                    const _LogoMark(),
                    const SizedBox(height: 28),
                    Text(
                      'Tile Flip',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap a tile.\nFlip its neighbours.\nMake the board one colour.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(flex: 3),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LevelsScreen(),
                            ),
                          );
                        },
                        child: const Text('PLAY'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _HowToHint(),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
            const BannerAdSlot(),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _logoSquare(AppColors.ink),
          _logoSquare(AppColors.surface, border: true),
          _logoSquare(AppColors.surface, border: true),
          _logoSquare(AppColors.accent),
        ],
      ),
    );
  }

  Widget _logoSquare(Color color, {bool border = false}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: border ? Border.all(color: AppColors.ink, width: 1.4) : null,
      ),
    );
  }
}

class _HowToHint extends StatelessWidget {
  const _HowToHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Fewer taps → more stars ★',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.inkSoft.withValues(alpha: 0.8),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
