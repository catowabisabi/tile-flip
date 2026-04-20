import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// AdMob configuration.
///
/// ============================================================================
/// Shipping rules (enforced by [useTestAds] below):
///
///   * **Debug / profile builds** → always serve Google's test ad units. Safe,
///     earns no revenue, never violates policy.
///   * **Release builds** → always serve production ad units. `useTestAds` is
///     hard-wired to `!kReleaseMode`, so there is no way to accidentally ship
///     an APK/AAB that serves test ads in production (that's an AdMob policy
///     violation and gets accounts suspended).
///
/// TODO(you): Before cutting your first real release:
///   1. Create an AdMob account at https://admob.google.com/ and set up apps
///      for Android + iOS.
///   2. Replace the five `REPLACE_ME_*` constants below with your real IDs.
///   3. Replace the `androidAppId` / `iosAppId` constants with your real app
///      IDs (they currently point at Google's test apps).
///   4. Update `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`)
///      and `ios/Runner/Info.plist` (`GADApplicationIdentifier`) to match.
///   5. Build a release (`flutter build appbundle --release`). `useTestAds`
///      will be `false` automatically; the runtime assertion will yell at you
///      if any `REPLACE_ME_*` string is still in place.
/// ============================================================================
class AdsConfig {
  /// `true` in debug/profile builds, `false` in release builds — always.
  ///
  /// Do not add an override knob here. If you need to test production IDs on
  /// device, build with `--release` and enroll your device as an AdMob test
  /// device via `RequestConfiguration(testDeviceIds: [...])` instead.
  static const bool useTestAds = !kReleaseMode;

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

  /// Returns `id` after verifying it is not a `REPLACE_ME_*` placeholder in
  /// release mode. Crashes fast in release builds that shipped without real
  /// IDs — better a visible crash during smoke-test than months of AdMob
  /// suspension risk.
  static String _requireProd(String id, String label) {
    assert(
      !id.startsWith('REPLACE_ME'),
      'AdsConfig.$label is still a placeholder. Fill in your real AdMob unit '
      'ID in lib/config/ads_config.dart before shipping a release build.',
    );
    if (kReleaseMode && id.startsWith('REPLACE_ME')) {
      throw StateError(
        'AdsConfig.$label is a placeholder in a release build. '
        'Set the real AdMob unit ID before shipping.',
      );
    }
    return id;
  }

  static String get bannerUnitId {
    if (useTestAds) {
      if (_isAndroid) return _testBannerAndroid;
      if (_isIos) return _testBannerIos;
    } else {
      if (_isAndroid) return _requireProd(_prodBannerAndroid, 'bannerAndroid');
      if (_isIos) return _requireProd(_prodBannerIos, 'bannerIos');
    }
    return _testBannerAndroid;
  }

  static String get interstitialUnitId {
    if (useTestAds) {
      if (_isAndroid) return _testInterstitialAndroid;
      if (_isIos) return _testInterstitialIos;
    } else {
      if (_isAndroid) {
        return _requireProd(_prodInterstitialAndroid, 'interstitialAndroid');
      }
      if (_isIos) {
        return _requireProd(_prodInterstitialIos, 'interstitialIos');
      }
    }
    return _testInterstitialAndroid;
  }

  /// Whether the ads SDK should be initialized at all. We skip ads on web and
  /// in test runs; mobile platforms initialize normally.
  static bool get isSupported => _isAndroid || _isIos;
}
