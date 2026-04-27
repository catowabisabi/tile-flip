import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'settings_service.dart';

/// One-line-per-event audio surface for the rest of the app. Owns a small
/// pool of short-lived [AudioPlayer]s for SFX (so overlapping taps don't
/// cut each other off) and one long-lived player for BGM.
///
/// Volumes are sourced from [SettingsService] via [ValueListenable]s, so
/// changing a slider in the Settings screen takes effect immediately.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  // SFX filenames (without `assets/audio/sfx/`). Match the files emitted by
  // `tools/generate_audio.sh`.
  static const _sfxTileFlip = 'audio/sfx/tile_flip.ogg';
  static const _sfxButtonTap = 'audio/sfx/button_tap.ogg';
  static const _sfxCoinEarn = 'audio/sfx/coin_earn.ogg';
  static const _sfxWin = 'audio/sfx/win.ogg';
  static const _sfxThreeStar = 'audio/sfx/three_star_chime.ogg';
  static const _sfxStreakBreak = 'audio/sfx/streak_break.ogg';

  static const _bgmMenu = 'audio/bgm/menu_loop.ogg';
  static const _bgmGameplay = 'audio/bgm/gameplay_loop.ogg';

  final _sfxPool = <AudioPlayer>[];
  static const _sfxPoolSize = 4;
  int _sfxCursor = 0;

  final AudioPlayer _bgmPlayer = AudioPlayer(playerId: 'tile_flip_bgm')
    ..setReleaseMode(ReleaseMode.loop);

  String? _currentBgmAsset;
  bool _loaded = false;

  /// One-time setup. Safe to call before `runApp`.
  Future<void> load() async {
    if (_loaded) return;
    try {
      for (var i = 0; i < _sfxPoolSize; i++) {
        final p = AudioPlayer(playerId: 'tile_flip_sfx_$i')
          ..setReleaseMode(ReleaseMode.stop);
        _sfxPool.add(p);
      }
      // React to volume changes so the BGM fades up/down live.
      SettingsService.instance.musicVolume.addListener(_applyBgmVolume);
      _loaded = true;
    } catch (e) {
      // Audio is non-critical. Never let a playback failure crash the app.
      debugPrint('AudioService.load failed: $e');
    }
  }

  // ---- SFX -------------------------------------------------------------

  Future<void> playTileFlip() => _playSfx(_sfxTileFlip);
  Future<void> playButtonTap() => _playSfx(_sfxButtonTap);
  Future<void> playCoinEarn() => _playSfx(_sfxCoinEarn);
  Future<void> playWin() => _playSfx(_sfxWin);
  Future<void> playThreeStar() => _playSfx(_sfxThreeStar);
  Future<void> playStreakBreak() => _playSfx(_sfxStreakBreak);

  Future<void> _playSfx(String assetPath) async {
    final vol = SettingsService.instance.sfxVolume.value;
    if (vol <= 0 || _sfxPool.isEmpty) return;
    final player = _sfxPool[_sfxCursor];
    _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;
    try {
      await player.stop();
      await player.setVolume(vol);
      await player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('sfx $assetPath failed: $e');
    }
  }

  // ---- BGM -------------------------------------------------------------

  Future<void> playMenuBgm() => _playBgm(_bgmMenu);
  Future<void> playGameplayBgm() => _playBgm(_bgmGameplay);

  Future<void> _playBgm(String assetPath) async {
    if (_currentBgmAsset == assetPath) {
      // Already on the right track; just make sure it's playing & at the
      // right volume (e.g. after resume from background, audio focus loss,
      // or an incoming call interrupting playback).
      _applyBgmVolume();
      if (_bgmPlayer.state != PlayerState.playing &&
          SettingsService.instance.musicVolume.value > 0) {
        try {
          // Use play(AssetSource) instead of resume(): resume() only works
          // from `paused`, but the player may be in `stopped`/`completed`
          // after an interruption.
          await _bgmPlayer.play(AssetSource(assetPath));
        } catch (_) {}
      }
      return;
    }
    _currentBgmAsset = assetPath;
    final vol = SettingsService.instance.musicVolume.value;
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setVolume(vol);
      if (vol > 0) {
        await _bgmPlayer.play(AssetSource(assetPath));
      } else {
        // Preload the source so un-muting later resumes instantly.
        await _bgmPlayer.setSource(AssetSource(assetPath));
      }
    } catch (e) {
      debugPrint('bgm $assetPath failed: $e');
    }
  }

  Future<void> stopBgm() async {
    _currentBgmAsset = null;
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
  }

  // Listener callback must be sync; delegate to an async worker so the
  // try/catch can actually catch errors from the platform channel.
  void _applyBgmVolume() {
    unawaited(_doApplyBgmVolume());
  }

  Future<void> _doApplyBgmVolume() async {
    final vol = SettingsService.instance.musicVolume.value;
    try {
      await _bgmPlayer.setVolume(vol);
      if (vol <= 0) {
        await _bgmPlayer.pause();
      } else if (_currentBgmAsset != null &&
          _bgmPlayer.state != PlayerState.playing) {
        // Player may be in `stopped` (source set, never played — happens when
        // BGM was first loaded while muted) or `paused`. `resume()` only
        // works from `paused`; `play(AssetSource)` covers both.
        await _bgmPlayer.play(AssetSource(_currentBgmAsset!));
      }
    } catch (_) {}
  }
}
