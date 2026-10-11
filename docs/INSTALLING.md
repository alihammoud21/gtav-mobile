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

Download **gtav-mobile-mac-usb.zip** on your Mac and extract the whole folder.
It includes the compiled game and a ready-to-open Xcode project.

1. Install Xcode 26+ from the Mac App Store. Open it once and install iOS platform support.
2. Connect your unlocked iPhone by USB, tap **Trust**, and enable **Developer Mode** if prompted.
3. Open **Install-iPhone.command**. Alternatively, open `iOS-USB/GTAVMobile.xcodeproj` directly.
4. In **Xcode → Settings → Accounts**, sign in with your Apple Account.
5. Select the **GTAVMobile** target → **Signing & Capabilities**. Keep **Automatically manage signing** enabled, choose your **Personal Team**, and replace `yourname` in the bundle identifier with your own unique name.
6. Select your connected iPhone in Xcode's top toolbar and choose **Product → Run** (`⌘R`). Xcode signs, installs and launches the app over USB.

If iOS asks, trust your developer identity in **Settings → General → VPN & Device Management**.
The game is already compiled; Rust and XcodeGen are not required for this download.
Xcode still needs internet access to create or refresh your signing profile.

Free Personal Team profiles [expire after seven days](https://developer.apple.com/help/account/basics/about-your-developer-account).
The app stays installed but stops opening until you reconnect and **Run** again.
Keep the same Apple account, team and bundle identifier, and **do not delete the app**
when refreshing; reinstalling the same app preserves its data. Save the extracted
project so you can repeat this each week.

Requires a Mac, Xcode, iOS 15+, and a compatible high-memory phone; the original
runtime recommends 8 GB RAM. Free signing does not grant the increased-memory
entitlement, so device memory limits can prevent gameplay. This package's build
and signing preparation are checked; actual Personal Team installation and
physical-phone gameplay remain unverified. This USB flow is available on Mac.

Apple's [device run guide](https://help.apple.com/xcode/mac/current/en.lproj/dev5a825a1ca.html)
explains device pairing and signing. The separate IPA is the precompiled input
used by the included project; the **Mac USB bundle** is the complete installation download.

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
