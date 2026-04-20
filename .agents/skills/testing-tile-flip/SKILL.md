# Testing Tile Flip (Flutter)

This repo is a Flutter puzzle game targeting Android + iOS, with a web build used for UI smoke testing in Devin sessions.

## Quick commands

```bash
flutter analyze            # must be 0 issues
flutter test               # 14 tests incl. Infinite stability simulation
flutter build web --release
cd build/web && python3 -m http.server 8080
google-chrome http://localhost:8080/
wmctrl -r "Tile Flip - Google Chrome for Testing" -b add,maximized_vert,maximized_horz
```

`wmctrl` may not be installed on a fresh box — install with `sudo apt-get install -y wmctrl`.

## What IS testable on web

- Full navigation: Home ↔ Levels ↔ Game ↔ Infinite ↔ Settings
- Dark/glass theme rendering, gradients, tile flips, win dialogs
- Star scoring, level-unlock persistence via `shared_preferences`
- Infinite streak counter + Skip behaviour (`resetInfiniteStreak`)
- Settings screen layout incl. the coral **Privacy choices** tile
- Privacy choices on web → shows snackbar `"Privacy options are not available on this device or region."` (this is the expected web fallback, not a bug)
- `About → Build` row reads `release` under `--release` builds (confirms `kReleaseMode == true`)

## What is NOT web-testable (flag as `untested` in reports)

- Real AdMob banner / interstitial rendering — `AdsConfig.isSupported` is `false` on web by design.
- Real UMP (GDPR) consent form — only the mobile SDK can show it; web short-circuits via the snackbar above.
- `AdsConfig.useTestAds = !kReleaseMode` effect on actual ad ID selection — requires inspecting the built AAB or running on device.
- `AdsService._initStarted` / `_adsReady` split (the Devin-Review fix) — web never reaches the SDK init path.
- Haptics, portrait lock, system back-button behaviour.

When these matter, request an AAB / APK and ask the user to sideload, or use Firebase Test Lab / a physical Android device with an EEA VPN for UMP.

## Typical test flow for UI-changing PRs

1. Build web release and serve on :8080.
2. Maximize Chrome with `wmctrl` (Super+Up only tiles to half-screen on this Plasma desktop).
3. Start `computer(action="record_start")` and add `setup` / `test_start` / `assertion` annotations at each step.
4. Walk the primary user flow introduced by the PR, not exhaustive regression — but include a one-line regression test for anything adjacent that could break.
5. Post a **single** PR comment with a results table, collapsed `<details>` for screenshots + recording, a gaps section listing mobile-only tests, and a link back to the Devin session.
6. Write `test-report-prN.md` into the repo root as the detailed companion to the PR comment.

## Important quirks

- The Xvfb viewport is 1600×1156 after maximizing. 7×7 boards (Infinite streak ≥30) may push tiles off-screen — zoom out or scroll to confirm.
- Chrome often opens with extra blank tabs; the first `Tile Flip` tab is the one to maximize (use its exact window title).
- `flutter build web` requires `--release` for `kReleaseMode` to flip to true. A debug/JIT web build will show `Build debug` in Settings.
- The repo has no .env secrets required for web testing.
- Pre-commit hooks: CI runs `dart format --set-exit-if-changed` — always run `dart format .` locally before pushing or CI turns red (we've hit this twice).

## Devin secrets needed

None for web-only smoke testing. For mobile device testing you would need:
- `ANDROID_KEYSTORE_*` / `android/key.properties` (user is handling manually)
- AdMob production App IDs + Unit IDs (user is handling manually)
- An EEA-region device or VPN for UMP verification.
