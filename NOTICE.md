# Notices and credits

GTAV Mobile includes and modifies Muguet by Constantin Clerc (c22dev),
from https://github.com/c22dev/muguet, imported at commit
`a2f781683160993ad15a8a04fbf09e7027a831a6`.

The original code and this derivative are licensed under GPL-3.0-or-later.
The full license is in LICENSE. Original author notices are retained in source.

Modifications dated 2026-10-11 include application branding, an Android launcher
and native runtime integration, platform-specific dependencies and graphics,
Android input and surface lifecycle handling, build scripts, import and memory
validation fixes, checksum-verified game setup, release packaging, regression
tests, a precompiled Xcode USB signing project, and documentation.

Upstream contributor credits:
- Kagander: minimap fixes.
- inj-src: parallel BC texture decoding.
- Dbhardwaj99: free disk-space reporting.
- dre4moff: controller release when focus is lost.

The vendored wgpu-core component retains its own MIT/Apache-2.0 notices.
The Gradle wrapper is from Gradle 8.13 (Apache-2.0); its license is in
android/gradle/LICENSE. Other dependencies retain their respective licenses.

The mobile release integrates game code and downloads matching data from
alihammoud21/playgta5. These assets are separate from the GPL-licensed runtime;
see GAME-DATA.md. GTA V and associated marks belong to their respective owners.
