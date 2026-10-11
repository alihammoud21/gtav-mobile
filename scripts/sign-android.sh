#!/bin/sh
# Sign the APK using an existing private key. Never put signing secrets in git.
set -eu
cd "$(dirname "$0")/.."
: "${ANDROID_HOME:=${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
: "${GTAV_KEYSTORE:=$HOME/.config/gtav-mobile/release-signing.p12}"
: "${GTAV_KEY_PASSWORD_FILE:=$HOME/.config/gtav-mobile/release-signing.password}"
: "${GTAV_KEY_ALIAS:=gtav-mobile}"
if [ -z "${JAVA_HOME:-}" ] && [ -d /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ]; then
  export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
fi
SDK_TOOLS="$ANDROID_HOME/build-tools/35.0.0"
[ -f "$GTAV_KEYSTORE" ] && [ -f "$GTAV_KEY_PASSWORD_FILE" ] || { echo 'Set GTAV_KEYSTORE and GTAV_KEY_PASSWORD_FILE to your release signing key files.' >&2; exit 1; }
"$SDK_TOOLS/zipalign" -P 16 -f 4 build/gtav-mobile-unsigned.apk build/gtav-mobile-aligned.apk
"$SDK_TOOLS/apksigner" sign --ks "$GTAV_KEYSTORE" --ks-key-alias "$GTAV_KEY_ALIAS" --ks-pass "file:$GTAV_KEY_PASSWORD_FILE" --out build/gtav-mobile-release.apk build/gtav-mobile-aligned.apk
"$SDK_TOOLS/apksigner" verify --verbose build/gtav-mobile-release.apk
"$SDK_TOOLS/zipalign" -c -P 16 4 build/gtav-mobile-release.apk
