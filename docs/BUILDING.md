# Building GTAV Mobile

Clone this repository and run commands from its root. Rust **1.98.1** is pinned
in `rust-toolchain.toml`; install [rustup](https://rustup.rs/) first.

## Android

Use macOS or Linux, JDK 17, Android SDK command-line tools, and an ARM64 Android
9+ device with Vulkan 1.1. Allow plenty of disk space for the SDK, NDK, Rust
artifacts, the imported ZIP and its extracted data. High-memory devices are
recommended; hardware requirements and gameplay performance are not yet measured.

```sh
rustup target add aarch64-linux-android
sdkmanager "platforms;android-35" "build-tools;35.0.0" "ndk;28.2.13676358" "platform-tools"
export ANDROID_HOME=/path/to/your/android-sdk
./make-android.sh
```

Output: `build/gtav-mobile-debug.apk`, signed with your local debug key.
Install with `adb install -r build/gtav-mobile-debug.apk`. Open **GTAV Mobile**,
choose **Download game**, then **Play**. Keep the app open during setup.
The first launch compiles the game on the device and may take several minutes.

The launcher uses the system file picker and private app storage; it does not
request all-files access. It preserves the previous import if extraction fails.
Uninstalling the app removes its game files and saves.

Touch: left stick moves; drag the right side to look; labeled buttons handle
combat, vehicles and menus. Standard Android gamepads and keyboards are also
supported. Gameplay runs in a separate process so returning to the launcher
can start a fresh session.

`./make-android.sh release` produces `build/gtav-mobile-unsigned.apk`.
Sign and verify it using Android SDK `apksigner` and your own release key.
For the release helper, set `GTAV_KEYSTORE`, `GTAV_KEY_PASSWORD_FILE` and
`GTAV_KEY_ALIAS`, then run `./scripts/sign-android.sh`. It writes the verified
`build/gtav-mobile-release.apk`. Back up the private key securely: future app
updates must use the same signing key. Never commit keys or passwords. Android Studio can open the `android/` folder;
its Gradle build invokes the same Rust build automatically.

Diagnostics for a debug build:

```sh
adb shell run-as com.alihammoud21.gtavmobile cat files/runtime.log
```

Android is experimental. A successful APK build does not establish game,
GPU-driver, multiplayer or background/resume compatibility on a real device.

## iOS

Requires an Apple Silicon Mac, Xcode 26+, XcodeGen, and an iOS 15+ device.
The source project's recommendation is 8 GB RAM. Install its Rust target:

```sh
rustup target add aarch64-apple-ios
brew install xcodegen
TEAM=YOUR_TEAM_ID ./make-ios.sh /absolute/path/to/game.zip --install
```

For an IPA to sideload:

```sh
./make-ios.sh /absolute/path/to/game.zip --ipa
```

Output: `build/GTAVMobile.ipa`. For free-account installation, set `FREE=1`
and a unique `BUNDLE_ID`. The normal signed build requests increased memory;
free/sideload builds use a smaller heap. Signing and memory availability depend
on the provisioning profile and device. Game code is compiled into the app;
use **Download game** for the pinned release, or import matching data for a custom build.

For the pinned release, `python3 scripts/fetch-game-code.py` verifies and extracts
the source executable, then run `./make-ios.sh build/game-source/game.wasm --ipa`.
The automatic downloader is pinned to build `8b0b5899ed`; custom game builds
need a matching manifest or manual data import.

A build without a game ZIP can check packaging, but cannot run the game.

## macOS

Requires an Apple Silicon Mac, macOS 14+, and Xcode 26+.

```sh
./make-app.sh
```

Output: `build/GTAVMobile.app`. Open it and import your ZIP.
`./build.sh` provides the interactive Apple build flow.

## Multiplayer

Choose Host in the launcher, or run `cargo run --release --bin gtav-mobile-server`.
Other players join with `host:47520`. Use matching game builds. This is the
project's custom multiplayer protocol, not GTA Online.

## Checks

```sh
cargo test --locked --all-targets
cargo check --locked --no-default-features --target aarch64-apple-ios --bin gtav-mobile
./make-android.sh
./android/gradlew -p android lintDebug
```

Upstream `MUGUET_*` environment variables and native iOS symbols remain for
compatibility. User-facing app names and bundle identifiers use GTAV Mobile.
