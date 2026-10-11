# Install GTAV Mobile

Get the APK, IPA, or desktop bundle from [Releases](https://github.com/alihammoud21/gtav-mobile/releases).
This is an experimental alpha; gameplay on physical phones has not been verified.

## Android

Open **gtav-mobile-android.apk** on your phone and allow installation when asked.
For USB installation, extract the desktop bundle, enable USB debugging, connect
one unlocked phone, and run `Install-Android.cmd` (Windows) or
`Install-Android.command` (Mac). The helper uses Google's
[Platform-Tools](https://developer.android.com/tools/releases/platform-tools);
extract `platform-tools` beside it if needed.

Requires Android 9+, ARM64 and Vulkan 1.1. First launch compiles the game;
allow several minutes. Minimum RAM and compatible devices are not yet measured.

## iOS

**GTAVMobile-ios.ipa** includes the precompiled game executable. Follow AltStore
Classic's [Mac guide](https://faq.altstore.io/altstore-classic/how-to-install-altstore-macos)
or [Windows guide](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows),
then import the IPA using **My Apps → +**. Use your own Apple account and enable
Developer Mode when required. Signing must be refreshed as required by your account.

Requires iOS 15+; the original runtime recommends 8 GB RAM. Signing and device
memory limits can affect startup. The IPA needs signing for each phone; copying
it over USB alone will not install it.

## First launch

Tap **Download game**, use Wi-Fi, and keep the app open. Setup downloads about
17 GB from your maintainer's [playgta5 release](https://github.com/alihammoud21/playgta5/releases/tag/full-game-v1)
and installs about 16 GB. Allow at least 19 GB free, plus Android's compilation
cache. Downloads and extracted files are checked against pinned SHA-256 hashes.
If interrupted, tap the button again; completed parts are preserved.

Tap **Play** after setup. Single-player data is then available offline.
Uninstalling removes private game files and saves. Manual import of a complete,
matching game ZIP remains available; the separate download parts are handled
by **Download game**, not the manual importer.

The desktop bundle includes both apps and the USB helpers. Game data is fetched
on the phone, so this is not a fully offline installer. Checksums for all release
assets are in `SHA256SUMS.txt`. See [game data](../GAME-DATA.md) for the pinned source.
