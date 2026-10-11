# Validation — 2026-10-11

Local checks on Apple Silicon with Rust 1.98.1 and Xcode 27.
[GitHub CI](https://github.com/alihammoud21/gtav-mobile/actions/runs/38163103160)
also passed both Apple and Android jobs for the integrated game setup:

| Check | Result |
| --- | --- |
| Rust tests, all targets | 10 passed |
| Android Mac USB helper with mock adb | 4 tests passed |
| iOS Swift launcher type check | Passed |
| Pinned source archive and game.wasm SHA-256 | Verified |
| Actual game ahead-of-time compilation for iOS | Passed |
| iOS IPA build, ARM64 executable and embedded game segment | Passed; 210,976,768-byte game segment |
| iOS ad-hoc signature verification | Passed |
| Android ARM64 release APK build and signing | Passed; release key, signature scheme v3 |
| Android release lint | Passed; zero errors |
| APK 16 KB alignment | Passed |
| Both packaged download UIs, native bridge and pinned manifest | Verified |

The downloader tests cover bad archive/file hashes, unsafe paths, interrupted
setup markers, incomplete installation, platform-specific resume state, and
preserving an existing installation. Other regressions cover archive build
mismatches, guest-memory bounds, save persistence and disk-space reporting.

The iOS build uses the verified 63,201,802-byte executable from playgta5 build
`8b0b5899ed`. Its SHA-256 is
`11ca8d2c04c5e843d18ff4aea4899d72c86973c6b031df334e67c446b2ae83e0`.
The original executable is patched by the runtime and compiled ahead of time;
the IPA includes that compiled code.

The complete 17 GB network setup, actual gameplay, performance, multiplayer,
touch/controller behavior and background/resume have **not** been validated on
a physical device. Build success is not a guarantee of phone compatibility.
The Windows batch helper has been reviewed but not executed on Windows.
The USB helper tests use a mock adb; they do not install on a real phone.

## Mac USB installation update — v0.1.0-alpha.2

- All eight desktop-helper tests passed (four Android, four iPhone).
- The actual Mac USB ZIP was extracted into a path containing spaces and built
  with Xcode for a physical iOS destination, with provisioning disabled for this check.
- The resulting app retained the selected bundle identifier and exactly matched
  the released game executable and icon resources before signing.
- Signing with empty custom entitlements and an ad-hoc identity passed strict
  signature verification. This verifies package preparation, not Personal Team provisioning.
- The ZIP retains executable permissions and includes the IPA checksum, shared
  Xcode scheme, and complete signing project.

No Apple Account was used to provision a phone during this check. Actual
Personal Team signing, USB installation, seven-day refresh, and gameplay still
need a physical-device test. The Android APK and iOS game binary are unchanged
from alpha.1; this update changes the computer installation flow.
