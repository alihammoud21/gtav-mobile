# Install a release

Download assets from [Releases](https://github.com/alihammoud21/gtav-mobile/releases).
The initial release is an **experimental runtime preview**, not a complete game.

## Android

Open `gtav-mobile-android-preview.apk` on your phone and allow installation
from your browser/file manager when prompted. Or extract
`gtav-mobile-desktop-installers.zip`, connect one phone with USB debugging enabled,
and run `Install-Android.cmd` on Windows or `Install-Android.command` on Mac.
The helper uses Android's `adb`, available in the official
[Platform-Tools download](https://developer.android.com/tools/releases/platform-tools).
Extract `platform-tools` beside the helper if it is not installed already.

After installation, import your own compatible game ZIP in the app. Android
9+, ARM64 and Vulkan 1.1 are required. The preview APK is debug-signed and has
not been gameplay-tested on a device.

## iOS

`GTAVMobile-ios-runtime-preview.ipa` contains the launcher and runtime, **without
embedded game code**. It cannot play the game, even after importing a data ZIP.
A playable iOS build requires rebuilding on a Mac with compatible game code;
see [Building](BUILDING.md).

To inspect the preview on a phone, follow AltStore's official
[Windows guide](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows)
or [Mac guide](https://faq.altstore.io/altstore-classic/how-to-install-altstore-macos),
then import the IPA in AltStore. Each user signs with their own Apple account;
the download does not bypass signing, provisioning or Developer Mode requirements.

## Game files

This release contains no game code or game assets. The referenced `playgta5`
repository explicitly claims no redistribution license for those assets, so
they are not republished here. Supply compatible files you are authorized to use.

SHA-256 checksums are provided as `SHA256SUMS.txt` alongside release downloads.
