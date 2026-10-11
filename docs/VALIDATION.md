# Validation — 2026-10-11

Local checks on Apple Silicon with Rust 1.98.1 and Xcode 27:

| Check | Result |
| --- | --- |
| Rust tests, all targets | 10 passed |
| Android Mac USB helper with mock adb | 4 tests passed |
| iOS Swift launcher type check | Passed |
| Pinned source archive and game.wasm SHA-256 | Verified |
| Actual game ahead-of-time compilation for iOS | Passed |

The downloader tests cover bad archive/file hashes, unsafe paths, interrupted
setup markers, incomplete installation, platform-specific resume state, and
preserving an existing installation. Other regressions cover archive build
mismatches, guest-memory bounds, save persistence and disk-space reporting.

The iOS build uses the verified 63,201,802-byte executable from playgta5 build
`8b0b5899ed`. Its SHA-256 is
`11ca8d2c04c5e843d18ff4aea4899d72c86973c6b031df334e67c446b2ae83e0`.
The original executable is patched by the runtime and compiled ahead of time;
the IPA includes that compiled code, not an empty runtime preview.

The complete 17 GB network setup, actual gameplay, performance, multiplayer,
touch/controller behavior and background/resume have **not** been validated on
a physical device. Build success is not a guarantee of phone compatibility.
The Windows batch helper has been reviewed but not executed on Windows.
The USB helper tests use a mock adb; they do not install on a real phone.
