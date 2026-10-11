#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
trap 'result=$?; if [ -t 0 ]; then read -r -p "Press Enter to close. " _ || true; fi; exit "$result"' EXIT
[ "$(uname -s)" = Darwin ] || { echo 'iPhone USB installation requires a Mac with Xcode.'; exit 1; }
[ -f GTAVMobile-ios.ipa ] && [ -d iOS-USB/GTAVMobile.xcodeproj ] && [ -f iOS-USB/Game.sha256 ] || {
  echo 'Extract the entire Mac USB download before running this helper.'; exit 1;
}
xcrun --sdk iphoneos --show-sdk-path >/dev/null 2>&1 || {
  echo 'Install and open Xcode from the Mac App Store, then install its iOS platform support.'
  echo 'In Xcode Settings > Locations, select Xcode under Command Line Tools.'
  exit 1
}
shasum -a 256 -c iOS-USB/Game.sha256 || { echo 'The IPA checksum does not match. Download and extract the bundle again.'; exit 1; }
echo 'Connect your iPhone by USB, unlock it, and trust this Mac.'
echo 'In Xcode Settings > Accounts, sign in with your Apple Account.'
echo 'Select the GTAVMobile target > Signing & Capabilities > your Personal Team.'
echo 'Replace "yourname" in the Bundle Identifier with your own unique name. Keep it for future installs.'
echo 'Select your connected iPhone at the top, then choose Product > Run (Command-R).'
echo 'Enable Developer Mode or trust your developer identity on the phone if prompted.'
echo 'With a free account, reconnect and Run again every seven days. Do not delete the app to refresh it.'
open -a Xcode "$PWD/iOS-USB/GTAVMobile.xcodeproj"
