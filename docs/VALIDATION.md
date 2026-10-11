# Validation — 2026-10-11

Local checks on Apple Silicon with Rust 1.98.1 and Xcode 27:

| Check | Result |
| --- | --- |
| Rust tests, all targets | 7 passed |
| iOS cross-compile without JIT | Passed |
| iOS release build and IPA packaging, without game code | Passed |
| iOS ad-hoc signature verification | Passed |
| Android ARM64 native release build | Passed |
| Android debug APK packaging | Passed |
| Android lint | Passed; no errors |
| APK signing and 16 KB alignment checks | Passed |
| macOS Swift launcher type check | Passed |
| Shell syntax and Apple property lists | Passed |
| Android Mac USB helper with mock adb | 4 tests passed |
| Release archive integrity and iOS game-code exclusion | Passed |

Regression coverage includes archive traversal, mismatched archive builds,
failed-import recovery, guest-memory bounds, save persistence and disk-space
reporting. Android native entry points and JNI symbols were inspected in the
built shared library.

Remaining warnings include upstream wgpu unused code, legacy Android API use,
English-only UI strings, and the intentional ARM64/landscape Android target.

No compatible game archive was supplied. Actual gameplay, performance,
multiplayer interoperability, touch/controller behavior and Android
background/resume have **not** been validated on a device. The generated IPA
contains the launcher/runtime only and must be rebuilt with your game ZIP to
play. The APK imports your compatible game ZIP after installation.

The Windows batch installer has been reviewed but not executed on Windows.
The USB helper tests use a mock adb; they do not install on a real phone.
