import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tile_theme.dart';

/// Player-facing toggles and cosmetic preferences. Persisted to
/// SharedPreferences.
///
/// Exposed as a singleton so every screen can `listen` to the same
/// [ValueListenable]s without wiring a provider/inherited-widget tree.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _kHaptics = 'settings_haptics';
  static const _kEffects = 'settings_effects';
  static const _kTutorialSeen = 'settings_tutorial_seen';
  static const _kInfinitePaletteId = 'settings_infinite_palette_id';

  SharedPreferences? _prefs;
  bool _loaded = false;

  final ValueNotifier<bool> haptics = ValueNotifier<bool>(true);
  final ValueNotifier<bool> effects = ValueNotifier<bool>(true);
  final ValueNotifier<bool> tutorialSeen = ValueNotifier<bool>(false);
  final ValueNotifier<String> infinitePaletteId = ValueNotifier<String>(
    kTilePalettes.first.id,
  );

  Future<void> load() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    haptics.value = _prefs!.getBool(_kHaptics) ?? true;
    effects.value = _prefs!.getBool(_kEffects) ?? true;
    tutorialSeen.value = _prefs!.getBool(_kTutorialSeen) ?? false;
    infinitePaletteId.value =
        _prefs!.getString(_kInfinitePaletteId) ?? kTilePalettes.first.id;
    _loaded = true;
  }

  Future<void> setHaptics(bool value) async {
    haptics.value = value;
    await _prefs?.setBool(_kHaptics, value);
  }

  Future<void> setEffects(bool value) async {
    effects.value = value;
    await _prefs?.setBool(_kEffects, value);
  }

  Future<void> markTutorialSeen() async {
    if (tutorialSeen.value) return;
    tutorialSeen.value = true;
    await _prefs?.setBool(_kTutorialSeen, true);
  }

  Future<void> resetTutorialSeen() async {
    tutorialSeen.value = false;
    await _prefs?.setBool(_kTutorialSeen, false);
  }

  Future<void> setInfinitePaletteId(String id) async {
    infinitePaletteId.value = id;
    await _prefs?.setString(_kInfinitePaletteId, id);
  }
}
