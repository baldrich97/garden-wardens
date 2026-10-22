# Garden Wardens

A 2D lane-defense game for phones and desktop, made in Godot 4.6.

The project opens on a short match. Select Dew Dropper, Needle Spitter, or Bark Block, then tap a tile to plant it. Keys 1, 2, and 3 select those cards. Arrow keys move the tile cursor and Enter plants. Esc or right click clears the selection. Pause freezes the wave. Stop every Vermin before one crosses the left edge.

Dew Dropper still has no sprite. It shows a labeled placeholder and adds water over time. Needle Spitter shoots along its row. Bark Block only blocks. The fly is fast, the bee is ordinary, and the ladybug is slow and tough. Speed, Ability, and Remove do not affect the match yet.

## Run

Open the folder in Godot 4.6 and press F5. The main scene is `src/prototype/garden_board.tscn`.

The layout is landscape, 1280×720, and stretches with the window. Touch is treated as a mouse click. Rendered checks from the first prototype pass are in [docs/screenshots](docs/screenshots).

## Check

Headless rules, scene, and match checks:

```powershell
.\tools\run_tests.ps1
```

That uses `GODOT_BIN` when it is set, otherwise `tools/godot/Godot_v4.6-stable_win64_console.exe`. The binary is downloaded locally and is not part of the game.

## Art

Sprites are copied from Kenney's New Platformer Pack (CC0). The license, the file map, and the missing Dew Dropper sprite are recorded in [docs/ASSET_SOURCES.md](docs/ASSET_SOURCES.md). Style rules are in [docs/conventions.md](docs/conventions.md).
