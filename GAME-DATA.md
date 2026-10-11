# Game data

This release integrates build `8b0b5899ed` from
[alihammoud21/playgta5](https://github.com/alihammoud21/playgta5/releases/tag/full-game-v1).
The maintainer confirmed permission to redistribute the game code and assets.
Supporting permission terms have not been added to this repository yet.
The runtime's GPL license does not grant rights to these separate game assets.

`distribution/game-manifest.json` pins the 11 required archive hashes and every selected
file hash. Android downloads the WebAssembly executable, shaders and data;
iOS embeds the same executable after ahead-of-time compilation and downloads
the matching shaders and data. The native runtime excludes `env_test` and
`verityradio`, as its original importer does. Desktop/browser support files
from the mirror are not needed by these native apps.

The apps download one archive at a time, verify it, extract only listed files,
and delete the archive. Completed parts survive interruption. A final file
check runs before the new installation replaces the previous one. Save files
are stored separately. Keep the pinned source release available for new installs.
