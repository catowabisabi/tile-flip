# Tile Flip — Effects / Meta-game Roadmap

Branch: `devin/effects-branch`. Experimental features not yet intended for
Play Store. Ship Phase 1 → iterate on feedback → decide Phase 2 scope.

## Phase 1 — pure client, ship first (this PR)

- [x] 🎨 **Per-level colour palettes** — 4 built-in tile palettes
      auto-cycling by `level.index % 4`. Infinite mode uses the player's
      preferred palette from Settings.
- [x] ✨ **Enhanced flip animation** — 3D Y-axis rotation + scale pop per tile,
      driven by `AnimationController` (previously was an `AnimatedContainer`
      colour fade only).
- [x] 🎆 **Win confetti** — coloured particle burst rendered via `CustomPainter`
      over the board on win. Honours the "effects" Settings toggle.
- [x] 📳 **Haptics upgrade** — keeps existing light tap haptic, adds medium
      impact on win. Respects the "haptics" Settings toggle.
- [x] 🪙 **Coins (local)** — earn coins on each win, stored in
      `SharedPreferences`:
      - Level win: `stars × 10` (so 10 / 20 / 30)
      - Infinite win: `5` flat
      Displayed in a `CoinHud` on every screen.
- [x] 📚 **First-time tutorial** — single-shot overlay explaining
      "tap a tile, it and its 4 neighbours flip, make the whole board one
      colour". Dismissable, remembers it's been seen.
- [x] 📤 **Share win** — win dialogs get a "Share" button that uses
      `share_plus` to share a text summary (level / streak + app name) to
      any installed app (FB / IG / WhatsApp / SMS / ...). No image for now
      — can upgrade to screenshot+image in Phase 1.5.
- [x] ⚙️ **Settings expansion** — haptics toggle, effects toggle, preferred
      Infinite-mode palette picker, reset-progress (dangerous).

**Deliberately not in Phase 1:**
- No sound / BGM. Requires bundling audio assets + `audioplayers`. Easy
  follow-up PR when we pick royalty-free sounds.
- No coin **spending** yet. Coins accumulate; Phase 2 decides what they
  unlock (extra palettes, hint tokens, paid-skip-without-streak-break,
  cosmetic confetti packs, …).
- No hint system. Needs either an on-device LightsOut solver (matrix over
  GF(2), ~O(n⁶)) or a BFS with depth bound. Defer.

## Phase 2 — needs a design decision or backend

| Feature | Smallest viable path | Decision needed |
|---|---|---|
| 🏆 Leaderboards | Google Play Games Services (Android-only, free, native API) | PGS vs Firebase Firestore (cross-platform but needs a Firebase project) |
| 🤝 Share-for-coins rewards | Firebase Cloud Function + Firestore dedupe on user+share-id | Need Firebase project + anti-abuse policy |
| ⚔️ PvP — async "challenge" | Encode puzzle seed in a URL, friend solves on web, Cloud Function records both scores | Needs URL routing + web build + backend |
| ⚔️ PvP — realtime | Needs matchmaking + websockets; 2-4 weeks of work | Probably not worth the scope for a casual puzzle |
| 🔊 SFX + BGM | `audioplayers` + 3 royalty-free clips (tap / win / coin) bundled as assets | Pick sound pack |
| 🛒 Shop | Coins → palette packs, hint tokens, paid-skip | Phase 1 ships coins; spend economy needs balancing pass |

## Success criteria

Phase 1 lands and the build is still:
- `flutter analyze` clean.
- `flutter test` passing (no regressions + new tests for wallet + settings).
- `flutter build apk --release` succeeds with no new native deps that
  block R8 / Play Store upload.

Phase 2 starts only after Phase 1 has been played for ≥ a few real
sessions and the coin-earn curve feels right.
