<div align="center">

# GTAV Mobile
**Your game. On the move.**

Native runtime for **iOS · Android · macOS**.
Powered by Rust, Wasmtime and wgpu. Bring your own compatible game files.

[Build guide](docs/BUILDING.md) · [License](LICENSE) · [Credits](NOTICE.md)

</div>

## How it works
Runs the web port's `game.wasm` in a native app, with Metal on Apple devices and Vulkan on Android. iOS compiles the game at build time; Android and macOS compile and cache it on first launch.

## Get started
Your ZIP needs `data/manifest.json`, `b/<build>/game.wasm` and `b/<build>/shaders/`. Game files are **not included**; a standard PC installation alone is not this format.

| Platform | Build |
| --- | --- |
| iOS | `TEAM=YOUR_TEAM ./make-ios.sh game.zip --install` |
| Android | `./make-android.sh` |
| macOS | `./make-app.sh` |

See the [build guide](docs/BUILDING.md) for prerequisites, APK/IPA output and signing.

## Play together
Host a session or join a server from the launcher. Uses **UDP 47520**; story missions remain single player.

## Status
Android support is **experimental**: ARM64, Android 9+, Vulkan 1.1. Device gameplay and background/resume still need validation with compatible game data. iOS retains the upstream memory and signing constraints.

<sub>Based on [Muguet](https://github.com/c22dev/muguet) by Constantin Clerc and contributors. GPL-3.0-or-later. An independent project, unaffiliated with Rockstar Games or Take-Two Interactive.</sub>
