import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/ads.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'services/storage.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Load user settings (haptics/effects toggles, preferred palette) and warm
  // up the coin notifier before the first frame so the HUD starts at the
  // right value instead of flashing 0.
  await SettingsService.instance.load();
  await ProgressStore.load();
  await AudioService.instance.load();
  // Fire-and-forget: ad SDK init should never block the first frame.
  // `AdsService.initialize` internally runs the UMP (GDPR) consent flow
  // first — if a form is required it shows immediately; `canRequestAds`
  // must be true before the MobileAds SDK is touched.
  unawaited(AdsService.instance.initialize());
  runApp(const TileFlipApp());
}

class TileFlipApp extends StatelessWidget {
  const TileFlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tile Flip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
