# Garden Wardens

A 2D lane-defense game for phones and desktop, made in Godot 4.6.

The project opens on level 1 of 7. Drag a card onto a tile, or select it and then tap a tile. Keys 1 through 5 select the cards on the bar. Arrow keys move the tile cursor and Enter plants. Esc or right click clears the selection and cancels a drag. Pause freezes the level. Stop every Vermin before one crosses the left edge. Winning opens the next level.

Dew Dropper leaves a droplet on its tile. Rain Barrel collects droplets on the eight tiles around it and does not make water. Needle Spitter shoots along its row. Seed Lobber lobs a bundle that bursts across a three-by-three, always hitting the landing tile and three random neighbors. Bark Block only blocks. Flies and ladybugs walk straight toward the left edge. Bees wander. Snails speed up ground vermin that are still behind them. Flies are left alone. A grub sometimes crawls out of a dead vermin, and a grub does not leave another grub. Nothing spawns until Start. The panel on the right shows one card for each vermin type in the level. Hover a card for its name and a short description.

Dew Dropper is a bush stand-in. Droplets also fall from above the lawn about every 10 seconds and drift down slowly. Hover or tap a droplet to collect it. Bees can step up, down, or occasionally back, but they still have to step forward often enough that they cannot stall. After Start the side panel leaves, and some vermin arrive together. The lawn is mostly regular soil, with sandy columns and one stony column. Stone slows vermin and slows shooters and dew plants. Sand speeds vermin and slows those plants a little. Walls only block on every soil. Pause freezes the match. Speed runs it at double time. Remove digs up a Warden and does not return the water. Anims opens the clip preview. The button on the card row, labeled with the current painting, cycles Hills and the four draft gardens. Ability does nothing yet. Hover a card, button, tile, Warden, or Vermin for a short tooltip.

## Run

Open the folder in Godot 4.6 and press F5. The main scene is `src/prototype/garden_board.tscn`.

The layout is landscape and stretches with the window, from a small phone up to a maximized monitor. The lawn stays five rows by twelve columns, and the tiles stay square. Touch is treated as a mouse click. Rendered checks from the first prototype pass are in [docs/screenshots](docs/screenshots).

## Check

Headless rules, scene, and match checks:

```powershell
.\tools\run_tests.ps1
```

That uses `GODOT_BIN` when it is set, otherwise `tools/godot/Godot_v4.6-stable_win64_console.exe`. The binary is downloaded locally and is not part of the game.

## Art

Placeholder sprites are copied from Kenney's New Platformer Pack (CC0). Most final art is planned to be AI-generated and curated. The license, the file map, and the missing Dew Dropper sprite are recorded in [docs/ASSET_SOURCES.md](docs/ASSET_SOURCES.md). Style rules are in [docs/conventions.md](docs/conventions.md).
