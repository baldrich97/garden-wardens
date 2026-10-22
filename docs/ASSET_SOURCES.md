# Asset sources

Checked 22 October 2026. The only external art in the game is Kenney's New Platformer Pack. Sprites in `assets/sprites/` are copies of the 2x PNGs. The unpacked archive is in `third_party/kenney/new-platformer/` and is marked `.gdignore` so Godot does not import the unused files.

## Kenney New Platformer Pack 1.1

- Page: https://kenney.nl/assets/new-platformer-pack
- File: `kenney_new-platformer-pack-1.1.zip`
- Direct download used: https://kenney.nl/media/pages/assets/new-platformer-pack/1896103897-1764756702/kenney_new-platformer-pack-1.1.zip
- License file in the archive: `License.txt`
- License: Creative Commons Zero, CC0. Commercial use is allowed. Credit is appreciated and not required.

License text shipped in the pack:

```
New Platformer Pack (1.1)

Created/distributed by Kenney (www.kenney.nl)
Creation date: 03-12-2025

License: (Creative Commons Zero, CC0)
http://creativecommons.org/publicdomain/zero/1.0/

You can use this content for personal, educational, and commercial purposes.

Support by crediting 'Kenney' or 'www.kenney.nl' (this is not a requirement)
```

Credit line for shipping builds: Kenney (www.kenney.nl).

No AI images were generated. No other packs were downloaded.

## Sprites in use

| Role | File in the game | Source file | Notes |
| --- | --- | --- | --- |
| Lawn grass | `assets/sprites/board/grass.png` | `Sprites/Tiles/Double/terrain_grass_block.png` | Green top, brown side. |
| Dirt path | `assets/sprites/board/dirt.png` | `Sprites/Tiles/Double/terrain_dirt_block.png` | Gray fill with an orange top. It is the pack's dirt block, and it is visibly different from the grass tile. |
| Backdrop | `assets/sprites/board/background.png` | `Sprites/Backgrounds/Double/background_color_trees.png` | Hills and trees behind the board. |
| Water counter | `assets/sprites/board/water.png` | `Sprites/Tiles/Double/water.png` | A water surface tile, not a droplet. Used only beside the water number. |
| Needle Spitter | `assets/sprites/wardens/cactus.png` | `Sprites/Tiles/Double/cactus.png` | Static prop. No attack frames. |
| Bark Block | `assets/sprites/wardens/bark_block.png` | `Sprites/Tiles/Double/block_planks.png` | Wooden crate. Reads as a barrier, not a living plant. |
| Basic Vermin | `assets/sprites/vermin/bee.png` | `Sprites/Enemies/Double/bee_rest.png` | Faces left. |
| Fast Vermin | `assets/sprites/vermin/fly.png` | `Sprites/Enemies/Double/fly_rest.png` | Faces left. |
| Armored Vermin | `assets/sprites/vermin/ladybug.png` | `Sprites/Enemies/Double/ladybug_rest.png` | Faces left. The shell is the armor. The drawing fills the same 128 canvas as the bee, so it is not smaller on the board. |

Filtering is linear. Every copied sprite is the pack's Double size so they share one scale.

## Gaps

- **Dew Dropper** has no plant sprite and no water-drop character. The card and the lawn token say so. The water tile is not used as the Warden.
- **Ability, Remove, Speed, and Pause** have no matching icons. They are text buttons.
- The five platformer heroes were not used. They are people, not plants.
- Mouse, frog, fish, slimes, snail, saw, and worm stay in the archive and off the board so the first enemies stay insects.

## Keep or replace

- Keep this pack for the lawn, the backdrop, the three insects, the cactus, and the crate.
- Replace Dew Dropper before the game is shown as a finished garden. It needs an original plant, drawn to the same outline weight.
- Needle Spitter and Bark Block can stay for the prototype. They are props, so replace them when real Warden characters exist.
- Do not add Platformer Art Mushrooms (2013), Monster Builder (2022), or a pixel pack. They do not match this outline.
- The adventure UI pack, particle pack, and input prompts are still unused. Add one of them only if these flat buttons are not enough.
