# Tile Flip — Google Play Store Release Checklist

Follow this top-to-bottom. Items marked **AUTO** are already handled by this
repo's build setup; items marked **YOU** need your input.

---

## 0. Prerequisites (one-time)

- [ ] **YOU**: Play Console developer account — [https://play.google.com/console](https://play.google.com/console) (USD 25 one-time).
- [ ] **YOU**: AdMob account linked to the same Google account — [https://admob.google.com](https://admob.google.com).
- [ ] **YOU**: A domain for `app-ads.txt` + Privacy Policy URL. No domain? Free options:
  - GitHub Pages on a repo like `tile-flip-privacy` (privacy policy + `/app-ads.txt` at same root), or
  - Cloudflare Pages + a $10/yr domain (Namecheap / Porkbun).

## 1. Finalize identifiers

- [ ] **YOU**: Decide final `applicationId`. Currently `com.catowabisabi.tile_flip` in `android/app/build.gradle.kts`. **This cannot change after first Play Store upload.**
- [ ] **YOU**: Confirm `versionName` (human-readable, e.g. `1.0.0`) and `versionCode` (monotonic integer; bump every upload) in `pubspec.yaml` (`version: 1.0.0+1` → `versionName=1.0.0`, `versionCode=1`).

## 2. Keystore (one-time, critical)

> **Lose this file → you cannot publish updates to the same listing, ever.** Back it up in 2+ places (password manager + encrypted cloud).

- [ ] Run:
  ```bash
  scripts/release.sh new-keystore
  ```
  This creates `android/upload-keystore.jks` + `android/key.properties` (both gitignored).
- [ ] Back up `android/upload-keystore.jks` + the password. Consider encrypted storage (1Password / Bitwarden attachment).
- [ ] **AUTO**: `android/app/build.gradle.kts` automatically picks up `key.properties` when it exists.
- [ ] (Optional, strongly recommended) **Enroll in Play App Signing**: Play Console → Setup → App integrity → App signing. You upload the keystore once; Play re-signs with Google's master key. If you later lose your upload key, Google can issue a new one.

## 3. Ad IDs — switch from test to production

- [ ] **YOU**: Create AdMob app entries (Android + iOS each get their own). Copy:
  - App ID (format `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`)
  - Banner Ad Unit ID (format `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`)
  - Interstitial Ad Unit ID
- [ ] Edit `lib/config/ads_config.dart` — replace every `REPLACE_ME_*` constant with your real IDs.
- [ ] Edit `android/app/src/main/AndroidManifest.xml` — replace the `com.google.android.gms.ads.APPLICATION_ID` meta-data value with your real Android App ID.
- [ ] Edit `ios/Runner/Info.plist` — replace the `GADApplicationIdentifier` value with your real iOS App ID.
- [ ] **AUTO**: `AdsConfig.useTestAds` is hardwired to `!kReleaseMode`. Release builds automatically use production IDs; `_requireProd` throws `StateError` if you forgot to replace a `REPLACE_ME_*`.

## 4. UMP (GDPR / EEA consent)

- [ ] **YOU**: AdMob → Privacy & messaging → create a GDPR consent message. Toggle it on for EEA + UK + Switzerland users.
- [ ] **AUTO**: `ConsentService.initialize()` runs before `MobileAds.initialize()` and shows the form if required.
- [ ] **AUTO**: Settings → **Privacy choices** re-opens the form (regulator requirement).

## 5. Build the AAB

```bash
scripts/release.sh aab
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Sanity-check the output:
```bash
cd build/app/outputs/bundle/release && \
  unzip -p app-release.aab BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map >/dev/null && \
  echo "obfuscation map present"
```

## 6. Play Console — app setup

- [ ] Create new app. Name: **Tile Flip** (≤ 30 chars). Default language: English (US). Game, Free, Contains ads = **Yes**.
- [ ] **Main store listing**:
  - [ ] Short description (≤ 80 chars). Suggested: `Flip tiles. Flip neighbours. Fewer taps, more stars.`
  - [ ] Full description (≤ 4000 chars). Draft provided in `docs/play-store/listing-copy.md` (create from template below).
  - [ ] App icon — 512×512 PNG, 32-bit, no alpha. Must match `android/app/src/main/res/mipmap-*/ic_launcher.png`.
  - [ ] Feature graphic — 1024×500 PNG/JPG, no transparency.
  - [ ] **Phone screenshots** — minimum 2, maximum 8. 16:9 portrait or landscape. Min side ≥ 320px, max side ≤ 3840px. Suggest: Home, Levels grid, Game mid-solve, Win dialog, Infinite stats.
  - [ ] (Optional) 7-inch tablet + 10-inch tablet screenshots — not required for phone-only launch.
  - [ ] Developer contact email (public).
  - [ ] Developer website (same domain as `app-ads.txt`).
  - [ ] **Privacy Policy URL** — see `docs/play-store/privacy-policy.md`.
- [ ] **App content**:
  - [ ] **Privacy Policy**: paste URL above.
  - [ ] **Ads**: `Yes, my app contains ads`.
  - [ ] **App access**: No restricted functionality; no login required.
  - [ ] **Content rating**: complete the IARC questionnaire. Tile Flip → **Everyone / PEGI 3** expected (no violence, gambling, user-generated content, or communication features).
  - [ ] **Target audience**: primary 13+ (if you answer "younger", you inherit a lot of COPPA/Data Safety obligations — avoid unless you're sure).
  - [ ] **News app / COVID tracing / Financial / Government**: all No.
  - [ ] **Data safety**:
    - Data collected: **Yes** (ads SDK collects Advertising ID + device info).
    - Data shared: **Yes** (with AdMob / Google + any mediation partners).
    - Encrypted in transit: **Yes**.
    - User can request deletion: ads SDK uses Google account — point users at Google's ad settings.
    - Required declarations (check each): **Device or other IDs** (Advertising ID), **App info and performance** (crash logs, if you add crashlytics later).
  - [ ] **Government apps / Financial features / Health**: all No.
- [ ] **Pricing & distribution**: Free. Select countries (start with All; you can exclude later).
- [ ] **Ads declaration**: `Yes, my app has ads`. Families policy: leave unchecked unless targeting kids.

## 7. app-ads.txt (AdMob invalid-traffic verification)

- [ ] **YOU**: Host `app-ads.txt` at the **root** of your developer website (same domain you listed in the Play Console → Store listing → Developer website). Example: `https://yourdomain.example/app-ads.txt`.
- [ ] **YOU**: Copy the contents from AdMob → Apps → `app-ads.txt` (generates a unique `DIRECT, <hash>` line for your publisher ID). Template in `docs/play-store/app-ads.txt.template` shows the expected format.
- [ ] Wait 24h–7 days. AdMob → Apps → `app-ads.txt` should show a green tick. Without this your eCPM will be 30-70% lower.

## 8. Release track

- [ ] **Internal testing** first (up to 100 testers, no review delay). Add yourself + a few friends via email list. Install → poke around 10 minutes → confirm ads render with real IDs.
- [ ] Promote to **Closed testing** (open/closed Alpha). Keep in closed testing for at least 14 days before production — Google now requires this for new personal accounts.
- [ ] Production rollout: start at 10% → monitor ANRs/crashes for 48h → ramp to 100%.

## 9. Submission & review

- First submission review: typically 3–7 days for new developer accounts.
- Keep an eye on Play Console → Quality → Android vitals for ANRs, crashes, excessive wakelocks.
- Reply to every policy email within 72h — inaction can result in suspension.

## 10. Post-launch (nice to have)

- [ ] **Firebase Crashlytics** — [https://firebase.google.com/docs/crashlytics/get-started?platform=flutter](https://firebase.google.com/docs/crashlytics/get-started?platform=flutter). Invaluable for catching field crashes.
- [ ] **AdMob mediation** (Unity Ads, AppLovin, IronSource) — typically +20-40% eCPM.
- [ ] **In-app review prompt** after level 10 win — `in_app_review` Flutter package. Limit: ≤ once per 3 months per device.
- [ ] Iterate on difficulty curve based on completion funnel in Firebase Analytics.
