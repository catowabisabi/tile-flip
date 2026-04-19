import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// AdMob configuration.
///
/// ============================================================================
/// TODO(you): Replace the placeholder IDs below with your real AdMob units
/// before shipping. The values shipped in this file are the official Google
/// test ad unit IDs — they are safe to use during development and will never
/// earn revenue. Shipping test IDs to production is against AdMob policy.
///
/// Steps when you're ready:
///   1. Create an AdMob account at https://admob.google.com/
///   2. Create an app entry for tile_flip (Android and/or iOS) and copy the
///      "App ID" into `androidAppId` / `iosAppId` below.
///   3. Create ad units (Banner, Interstitial) and paste their unit IDs into
///      `androidBannerUnitId` / `iosBannerUnitId` / etc.
///   4. Update `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`)
///      and `ios/Runner/Info.plist` (`GADApplicationIdentifier`) to match the
///      production app IDs.
///   5. Flip `AdsConfig.useTestAds` to `false`.
/// ============================================================================
class AdsConfig {
  /// When `true`, Google's always-on test ad units are served instead of the
  /// configured production unit IDs. Keep this `true` until you have real
  /// AdMob inventory set up.
  static const bool useTestAds = true;

  // ---------------------------------------------------------------------------
  // Google official test IDs (safe placeholders — do NOT ship to production).
  // Source: https://developers.google.com/admob/android/test-ads
  // ---------------------------------------------------------------------------
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  // ---------------------------------------------------------------------------
  // Production IDs (replace these after setting up AdMob).
  // ---------------------------------------------------------------------------
  static const String androidAppId =
      'ca-app-pub-3940256099942544~3347511713'; // test app ID
  static const String iosAppId =
      'ca-app-pub-3940256099942544~1458002511'; // test app ID
  static const String _prodBannerAndroid = 'REPLACE_ME_ANDROID_BANNER_UNIT_ID';
  static const String _prodBannerIos = 'REPLACE_ME_IOS_BANNER_UNIT_ID';
  static const String _prodInterstitialAndroid =
      'REPLACE_ME_ANDROID_INTERSTITIAL_UNIT_ID';
  static const String _prodInterstitialIos =
      'REPLACE_ME_IOS_INTERSTITIAL_UNIT_ID';

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get _isIos => !kIsWeb && Platform.isIOS;

  static String get bannerUnitId {
    if (useTestAds) {
      if (_isAndroid) return _testBannerAndroid;
      if (_isIos) return _testBannerIos;
    } else {
      if (_isAndroid) return _prodBannerAndroid;
      if (_isIos) return _prodBannerIos;
    }
    return _testBannerAndroid;
  }

  static String get interstitialUnitId {
    if (useTestAds) {
      if (_isAndroid) return _testInterstitialAndroid;
      if (_isIos) return _testInterstitialIos;
    } else {
      if (_isAndroid) return _prodInterstitialAndroid;
      if (_isIos) return _prodInterstitialIos;
    }
    return _testInterstitialAndroid;
  }

  /// Whether the ads SDK should be initialized at all. We skip ads on web and
  /// in test runs; mobile platforms initialize normally.
  static bool get isSupported => _isAndroid || _isIos;
}
