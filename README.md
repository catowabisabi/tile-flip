# Tile Flip

A minimal, addictive tile-flip puzzle game built in Flutter.

**Goal:** tap any tile to flip its colour — and the colour of its four orthogonal neighbours. Win when every tile shares the same colour. Fewer taps = more stars.

Designed to be ultra-easy to pick up (one-finger play, no timers, no reading required) — great for non-core / casual / young / older players.

## Platforms
- Android
- iOS
- Web (for quick testing; ads are disabled on web)

## Features
- 15 hand-tuned levels across 4×4, 5×5 and 6×6 boards
- 3-star rating per level based on your move count vs. par
- Undo + restart at any time
- Level progression with persistent best-score + stars (via `shared_preferences`)
- Minimal geometric design (navy / off-white / coral)
- Haptic feedback on each tap
- AdMob banner + interstitial ads (see AdMob setup below)

## Getting started

```bash
flutter pub get
flutter run           # run on connected device/emulator
flutter run -d chrome # run in browser (no ads)
flutter test          # run unit + widget tests
flutter analyze       # static analysis
```

## AdMob setup

Out of the box, the app ships with Google's **official test ad unit IDs** as safe placeholders. They will serve test ads only and will never earn revenue — shipping test IDs to production is against AdMob policy.

When you're ready to go live:

1. Create an AdMob account at <https://admob.google.com/>.
2. Register the app (once per platform) and copy the **App ID** values.
3. Create ad units (Banner + Interstitial) and copy the **unit IDs**.
4. In `lib/config/ads_config.dart`:
   - Fill in the `_prodBanner*` and `_prodInterstitial*` constants.
   - Update `androidAppId` / `iosAppId`.
   - Set `useTestAds = false`.
5. Update the native manifests to match the production App IDs:
   - `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
   - `ios/Runner/Info.plist` → `GADApplicationIdentifier`

## Project layout

```
lib/
  config/ads_config.dart   # AdMob IDs (test + production slots)
  models/puzzle.dart       # Puzzle + Level domain model
  screens/                 # Home, Levels, Game
  services/
    ads.dart               # google_mobile_ads wrapper (no-ops on web/desktop)
    storage.dart           # shared_preferences-backed progress store
  theme.dart               # Minimal geometric theme
  widgets/                 # Tile, PuzzleGrid, BannerAdSlot
```
