import 'package:flutter/material.dart';

import '../services/ads.dart';

/// Reserves a fixed-height slot at the bottom of a screen for an adaptive
/// banner. Keeps layout stable whether or not an ad is available.
class BannerAdSlot extends StatelessWidget {
  const BannerAdSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final banner = AdsService.instance.banner(width: constraints.maxWidth);
        return SizedBox(
          height: 60,
          width: double.infinity,
          child: Center(child: banner ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
