#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
trap 'result=$?; if [ -t 0 ]; then read -r -p "Press Enter to close. " _ || true; fi; exit "$result"' EXIT
APK="$PWD/gtav-mobile-android.apk"
[ -f "$APK" ] || { echo 'Extract the entire download first. The APK must be beside this installer.'; exit 1; }
if [ -x "$PWD/platform-tools/adb" ]; then
  ADB="$PWD/platform-tools/adb"
elif command -v adb >/dev/null 2>&1; then
  ADB="$(command -v adb)"
elif [ -x "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
  ADB="$HOME/Library/Android/sdk/platform-tools/adb"
else
  echo 'Download Android SDK Platform-Tools for Mac from:'
  echo 'https://developer.android.com/tools/releases/platform-tools'
  echo 'Extract its platform-tools folder beside this script, then run this again.'
  exit 1
fi
echo 'Connect one Android phone by USB. Enable USB debugging and approve the prompt on the phone.'
"$ADB" -d get-state >/dev/null || { echo 'No single authorized USB phone found. Unlock it, approve USB debugging, and connect only one phone.'; exit 1; }
"$ADB" -d install -r "$APK"
echo 'Installed GTAV Mobile. Open it on your phone and tap Download game.'
echo 'Game setup downloads about 17 GB. Use Wi-Fi and keep the app open.'
