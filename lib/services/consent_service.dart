import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';

/// Thin wrapper around Google's User Messaging Platform (UMP) SDK.
///
/// UMP is Google's implementation of the IAB TCF v2 consent framework. It is
/// required for any app that serves AdMob ads to EEA / UK / Swiss users.
/// Without valid consent, AdMob either stops serving personalized ads (big
/// revenue hit) or stops serving ads at all, and Google Play can take the app
/// down.
///
/// Flow on app launch:
///
///   1. `initialize()` calls `ConsentInformation.requestConsentInfoUpdate`
///      with the device's current locale / GDPR context.
///   2. If a form is required (user is in a GDPR region and hasn't answered
///      yet, or settings changed), it loads & shows the form immediately.
///   3. Once dismissed (or not required at all), `canRequestAds` becomes true
///      and ad loading proceeds.
///
/// Re-triggering:
///
///   * `showPrivacyOptionsForm()` lets users re-open the form later (e.g. from
///     a "Privacy choices" button in Settings). This is **required** by UMP
///     policy whenever `privacyOptionsRequired` is true.
///
/// All methods are no-ops on unsupported platforms (web, desktop, tests), so
/// callers don't need to guard.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  bool _initialized = false;
  bool _privacyOptionsRequired = false;

  /// Whether the app must expose a "Privacy choices" entry point.
  ///
  /// Updated after every UMP call. Reflects the latest value of
  /// [ConsentInformation.getPrivacyOptionsRequirementStatus].
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  /// Initialize UMP and show the consent form if UMP says we need to.
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized || !AdsConfig.isSupported) return;
    _initialized = true;

    final params = ConsentRequestParameters();
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) {
            if (error != null) {
              debugPrint(
                'UMP loadAndShowConsentFormIfRequired error: '
                '${error.errorCode} ${error.message}',
              );
            }
          });
          await _refreshPrivacyOptionsRequirement();
        } catch (e, st) {
          debugPrint('UMP consent flow failed: $e\n$st');
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (error) {
        debugPrint(
          'UMP requestConsentInfoUpdate error: '
          '${error.errorCode} ${error.message}',
        );
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  /// Re-present the privacy options form. Call this from a "Privacy choices"
  /// button in Settings.
  ///
  /// Returns `true` if the form was shown, `false` otherwise (unsupported
  /// platform, or UMP reports no form available).
  Future<bool> showPrivacyOptionsForm() async {
    if (!AdsConfig.isSupported) return false;
    try {
      var shown = false;
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          debugPrint(
            'UMP privacy options form error: '
            '${error.errorCode} ${error.message}',
          );
        } else {
          shown = true;
        }
      });
      await _refreshPrivacyOptionsRequirement();
      return shown;
    } catch (e, st) {
      debugPrint('UMP showPrivacyOptionsForm failed: $e\n$st');
      return false;
    }
  }

  Future<void> _refreshPrivacyOptionsRequirement() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      _privacyOptionsRequired =
          status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      // If the lookup fails, keep the last known value. Worst case we show a
      // privacy button that does nothing — still compliant.
      debugPrint('UMP getPrivacyOptionsRequirementStatus failed: $e');
    }
  }
}
