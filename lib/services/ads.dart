import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';
import 'consent_service.dart';

/// Shows an interstitial ad after every N wins. Tuned to ~1 in 3 so the game
/// stays casual-friendly.
const int kInterstitialEveryNWins = 3;

/// Lightweight wrapper around `google_mobile_ads` that no-ops on unsupported
/// platforms (web, desktop, tests). Lets the UI stay identical across
/// platforms without littering `if (isSupported)` checks everywhere.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  /// Guards against re-entering [initialize]. Set at the start of the call.
  bool _initStarted = false;

  /// True once the MobileAds SDK has actually been initialized and consent
  /// resolved favourably. Gates [banner] and [maybeShowInterstitial] so they
  /// never touch the SDK before it is ready (or if the user denied consent).
  bool _adsReady = false;
  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  Future<void> initialize() async {
    if (_initStarted || !AdsConfig.isSupported) return;
    _initStarted = true;
    try {
      // Run UMP first; AdMob policy requires consent before ad requests in
      // EEA / UK / Swiss regions. Returns fast (no-op) for users outside
      // those regions.
      await ConsentService.instance.initialize();
      if (!await ConsentInformation.instance.canRequestAds()) {
        // User declined or UMP couldn't resolve consent yet. Leave _adsReady
        // false so banner() and maybeShowInterstitial() skip all SDK calls.
        // User can re-trigger the form from Settings, then call initialize
        // again via [retryAfterConsentChange].
        return;
      }
      await MobileAds.instance.initialize();
      _adsReady = true;
      _loadInterstitial();
    } catch (e, st) {
      debugPrint('AdsService init failed: $e\n$st');
    }
  }

  /// Re-attempt SDK initialization after the user updates their consent via
  /// Settings. Safe to call any number of times; no-op once ads are ready.
  Future<void> retryAfterConsentChange() async {
    if (_adsReady || !AdsConfig.isSupported) return;
    try {
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.initialize();
      _adsReady = true;
      _loadInterstitial();
    } catch (e, st) {
      debugPrint('AdsService retry failed: $e\n$st');
    }
  }

  /// Creates a banner ad widget sized to the given available width. Returns
  /// `null` on unsupported platforms.
  Widget? banner({required double width}) {
    if (!AdsConfig.isSupported || !_adsReady) return null;
    return _BannerAdWidget(width: width);
  }

  /// Show the preloaded interstitial if available; otherwise load one for next
  /// time and return immediately. Caller should not await the ad experience.
  Future<void> maybeShowInterstitial() async {
    if (!AdsConfig.isSupported || !_adsReady) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _loadInterstitial();
      },
    );
    await ad.show();
  }

  void _loadInterstitial() {
    if (_loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdsConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (err) {
          _interstitial = null;
          _loadingInterstitial = false;
          debugPrint('Interstitial load failed: ${err.message}');
        },
      ),
    );
  }
}

class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget({required this.width});
  final double width;

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final size = AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      widget.width.truncate(),
    );
    final resolved = await size;
    if (resolved == null || !mounted) return;
    final ad = BannerAd(
      adUnitId: AdsConfig.bannerUnitId,
      size: resolved,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          debugPrint('Banner failed: ${err.message}');
        },
      ),
    );
    ad.load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) {
      return const SizedBox(height: 50);
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
