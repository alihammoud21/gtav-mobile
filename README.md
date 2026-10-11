<div align="center">

# GTAV Mobile
**Your game. On the move.**

iOS · Android · macOS — powered by Rust, Wasmtime and wgpu.

[**Download**](https://github.com/alihammoud21/gtav-mobile/releases/tag/v0.1.0-alpha.1) · [Install](docs/INSTALLING.md) · [Build](docs/BUILDING.md) · [Credits](NOTICE.md)

</div>

### Get started

1. Download the **Android APK**, **iOS IPA**, or **desktop installer bundle**.
2. Install on your phone. iOS uses [AltStore](docs/INSTALLING.md#ios); USB helpers are included for Android.
3. Open the app → **Download game** → **Play**.

Setup fetches the matching game from [playgta5](https://github.com/alihammoud21/playgta5/releases/tag/full-game-v1), verifies every file, and resumes completed parts. Use Wi-Fi: about **17 GB downloaded**, **16 GB installed**. Allow **19 GB free**, plus Android's compilation cache.

### Made for mobile

Touch controls, controller support, graphics settings, and custom multiplayer.
iOS includes precompiled game code; Android compiles it on first launch.
Single-player data stays available offline after setup.

**Experimental alpha.** Builds and installer checks pass; physical-device gameplay is not yet verified. Android: ARM64, Android 9+, Vulkan 1.1. iOS: 15+, high-memory device recommended.

<sub>Based on [Muguet](https://github.com/c22dev/muguet) by Constantin Clerc and contributors. Runtime: [GPL-3.0-or-later](LICENSE). [Game data](GAME-DATA.md) has separate rights. Independent project, unaffiliated with Rockstar Games or Take-Two.</sub>
