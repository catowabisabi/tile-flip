# Play Store prep — what's in this folder

| File | Purpose |
|---|---|
| [`CHECKLIST.md`](CHECKLIST.md) | End-to-end checklist: from creating the AdMob account to production rollout. Start here. |
| [`listing-copy.md`](listing-copy.md) | Ready-to-paste English copy for Play Console → Store listing. |
| [`privacy-policy.md`](privacy-policy.md) | Privacy policy template with `{{ placeholders }}` to fill. GDPR + CCPA + AdMob + UMP clauses. |
| [`app-ads.txt.template`](app-ads.txt.template) | Template for the `app-ads.txt` file you must host on your developer website for AdMob to verify inventory. |

## Release helper

The actual build automation lives at [`../../scripts/release.sh`](../../scripts/release.sh):

```
scripts/release.sh new-keystore    # one-time: generate upload keystore
scripts/release.sh aab             # build signed App Bundle for Play Console
scripts/release.sh apk             # build signed APK (sideload / internal testers)
scripts/release.sh fingerprint     # print SHA-1 / SHA-256 of upload keystore
```

Signing is wired up in `android/app/build.gradle.kts` — it reads `android/key.properties` if present, otherwise falls back to the debug key (so CI / contributors without a keystore can still build `flutter run --release`).

## What this PR does **not** do

- Does **not** include a real keystore, password, or `key.properties` (would be a security violation).
- Does **not** create the Play Console app / upload the AAB (only you have Play Console access).
- Does **not** set real AdMob IDs — `lib/config/ads_config.dart` still has `REPLACE_ME_*` constants, hardened by a release-mode `StateError` so you can't accidentally ship with placeholders.
- Does **not** host the privacy policy or `app-ads.txt` — you need a domain / GitHub Pages / Cloudflare Pages for that.
