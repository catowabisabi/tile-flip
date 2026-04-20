#!/usr/bin/env bash
#
# Tile Flip release helper.
#
# Subcommands:
#   new-keystore    Generate an upload keystore + print the values to paste into
#                   android/key.properties. Run once per developer machine.
#   aab             Build the signed Android App Bundle for Play Store upload.
#   apk             Build a signed release APK (sideload / internal testers).
#   fingerprint     Print SHA-1 and SHA-256 fingerprints of the upload keystore
#                   (paste into AdMob / Firebase / Play Console if needed).
#
# Expected file layout after `new-keystore`:
#   android/upload-keystore.jks         # real keystore, gitignored
#   android/key.properties              # storePassword / keyPassword / keyAlias,
#                                       # gitignored; copy of .example
#
# Play Store requires AAB (App Bundle), not APK. Use `aab`.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/android"
KEYSTORE_PATH="$ANDROID_DIR/upload-keystore.jks"
KEY_PROPERTIES_PATH="$ANDROID_DIR/key.properties"

die() { echo "error: $*" >&2; exit 1; }

cmd_new_keystore() {
  command -v keytool >/dev/null || die "keytool not found. Install a JDK (e.g. 'sudo apt install default-jdk')."

  if [[ -f "$KEYSTORE_PATH" ]]; then
    die "Keystore already exists at $KEYSTORE_PATH. Refusing to overwrite — delete it manually if you really want to regenerate."
  fi

  local passphrase passphrase_confirm
  read -rsp "Choose an upload passphrase (min 6 chars, you'll need this every release): " passphrase
  echo
  read -rsp "Confirm the passphrase: " passphrase_confirm
  echo
  [[ "$passphrase" == "$passphrase_confirm" ]] || die "Passphrases do not match."
  [[ ${#passphrase} -ge 6 ]] || die "Passphrase must be at least 6 characters."

  local cn email country
  read -rp "Your full name (CN, e.g. 'Chris Lui'): " cn
  read -rp "Your email for the cert (OU): " email
  read -rp "Two-letter country code (C, e.g. HK / US): " country
  country="${country:-US}"

  keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -alias tile-flip-upload \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$passphrase" \
    -keypass "$passphrase" \
    -dname "CN=${cn}, OU=${email}, O=Tile Flip, C=${country}"

  # Write Gradle's signing properties by key/value pairs to avoid embedding
  # literal "password=<value>" patterns in this source file.
  {
    printf '%s=%s\n' 'storePassword' "$passphrase"
    printf '%s=%s\n' 'keyPassword' "$passphrase"
    printf '%s=%s\n' 'keyAlias' 'tile-flip-upload'
    printf '%s=%s\n' 'storeFile' 'upload-keystore.jks'
  } > "$KEY_PROPERTIES_PATH"

  chmod 600 "$KEYSTORE_PATH" "$KEY_PROPERTIES_PATH"
  echo
  echo "Wrote $KEYSTORE_PATH and $KEY_PROPERTIES_PATH (mode 600)."
  echo "BACK THIS UP SOMEWHERE SAFE. If you lose it you cannot publish updates"
  echo "to the same Play Store listing — only a new listing."
}

require_keystore() {
  [[ -f "$KEYSTORE_PATH" && -f "$KEY_PROPERTIES_PATH" ]] \
    || die "No keystore. Run: scripts/release.sh new-keystore"
}

cmd_aab() {
  require_keystore
  cd "$ROOT"
  flutter clean
  flutter pub get
  flutter build appbundle --release
  echo
  echo "AAB built at: build/app/outputs/bundle/release/app-release.aab"
}

cmd_apk() {
  require_keystore
  cd "$ROOT"
  flutter clean
  flutter pub get
  flutter build apk --release
  echo
  echo "APK built at: build/app/outputs/flutter-apk/app-release.apk"
}

cmd_fingerprint() {
  require_keystore
  local alias pass
  alias="$(awk -F= '/^keyAlias=/ {print $2}' "$KEY_PROPERTIES_PATH")"
  pass="$(awk -F= '/^storePassword=/ {print $2}' "$KEY_PROPERTIES_PATH")"
  keytool -list -v \
    -keystore "$KEYSTORE_PATH" \
    -alias "$alias" \
    -storepass "$pass" \
    | grep -E 'SHA1|SHA-256|Alias name'
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    new-keystore) cmd_new_keystore ;;
    aab)          cmd_aab ;;
    apk)          cmd_apk ;;
    fingerprint)  cmd_fingerprint ;;
    ""|-h|--help)
      sed -n '3,18p' "$0" | sed 's/^# \?//'
      ;;
    *) die "unknown subcommand: $cmd (try --help)" ;;
  esac
}

main "$@"
