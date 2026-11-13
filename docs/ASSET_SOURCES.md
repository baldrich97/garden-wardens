# Asset sources

Checked 22 October 2026, updated 12 November 2026 for the backdrop drafts. The only external art pack in the game is Kenney's New Platformer Pack; the one exception is four unpublished AI backdrop drafts, recorded under "Backdrop drafts" below. Sprites in `assets/sprites/` are copies of the 2x PNGs. The unpacked archive is in `third_party/kenney/new-platformer/` and is marked `.gdignore` so Godot does not import the unused files.

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

No AI images were generated for anything in the game except the four backdrop drafts below. No other packs were downloaded.

## Backdrop drafts (AI-generated, non-ship)

The match can cycle five backgrounds. `assets/sprites/board/background.png` is still the Kenney hills. The four files below are AI-generated comparison drafts, kept deliberately to feel out the backgrounds and switchable from the backdrop button. They are marked here so nobody mistakes them for shippable art:

- Provenance: AI-generated placeholder, made during development. Not from any pack.
- License: none / unpublished. They carry no usage rights.
- Status: non-ship. Each one MUST be regenerated from scratch (or replaced with licensed art) before any ship build.

| Name in the button | File | Status |
| --- | --- | --- |
| Flat garden | `assets/sprites/board/backdrops/flat_garden.jpg` | AI draft, non-ship |
| Morning dew | `assets/sprites/board/backdrops/morning_dew.jpg` | AI draft, non-ship |
| Late afternoon | `assets/sprites/board/backdrops/late_afternoon.jpg` | AI draft, non-ship |
| Blight edge | `assets/sprites/board/backdrops/blight_edge.jpg` | AI draft, non-ship |

## Sprites in use

| Role | File in the game | Source file | Notes |
| --- | --- | --- | --- |
| Regular soil | `assets/sprites/board/grass.png` | `Sprites/Tiles/Double/terrain_grass_block.png` | Green top, brown side. Plants and vermin use their normal pace. |
| Stony soil | `assets/sprites/board/stone.png` | `Sprites/Tiles/Double/terrain_stone_block.png` | Gray stone block. The center column, however wide the lawn is. |
| Sandy soil | `assets/sprites/board/sand.png` | `Sprites/Tiles/Double/terrain_sand_block.png` | Pale sand block. Three columns to either side of the stone. |
| Unused dirt | `assets/sprites/board/dirt.png` | `Sprites/Tiles/Double/terrain_dirt_block.png` | Kept in the folder. It is not placed on the lawn. |
| Backdrop | `assets/sprites/board/background.png` | `Sprites/Backgrounds/Double/background_color_trees.png` | Hills and trees behind the board. |
| Water counter | `assets/sprites/board/water.png` | `Sprites/Tiles/Double/water.png` | A water surface tile used for the counter and for collectible droplets. |
| Needle Spitter | `assets/sprites/wardens/cactus.png` | `Sprites/Tiles/Double/cactus.png` | Static prop. Idle, attack, and hurt reuse this drawing, with a squash and a flash. |
| Bark Block | `assets/sprites/wardens/bark_block.png` | `Sprites/Tiles/Double/block_planks.png` | Wooden crate. Idle and hurt reuse this drawing. |
| Dew Dropper | `assets/sprites/wardens/bush.png` | `Sprites/Tiles/Double/bush.png` | Stand-in bush prop, not a finished plant. Idle, produce, and hurt reuse it. |
| Basic Vermin idle | `assets/sprites/vermin/bee_rest.png` | `Sprites/Enemies/Double/bee_rest.png` | Faces left. Also used for chew and hurt. |
| Basic Vermin walk | `assets/sprites/vermin/bee_a.png`, `bee_b.png` | `Sprites/Enemies/Double/bee_a.png`, `bee_b.png` | Two-frame walk. |
| Fast Vermin idle | `assets/sprites/vermin/fly_rest.png` | `Sprites/Enemies/Double/fly_rest.png` | Faces left. Also used for chew and hurt. |
| Fast Vermin walk | `assets/sprites/vermin/fly_a.png`, `fly_b.png` | `Sprites/Enemies/Double/fly_a.png`, `fly_b.png` | Two-frame walk. |
| Armored Vermin idle | `assets/sprites/vermin/ladybug_rest.png` | `Sprites/Enemies/Double/ladybug_rest.png` | Faces left. Also used for chew and hurt. |
| Armored Vermin walk | `assets/sprites/vermin/ladybug_walk_a.png`, `ladybug_walk_b.png` | `Sprites/Enemies/Double/ladybug_walk_a.png`, `ladybug_walk_b.png` | Two-frame walk. |
| Snail idle | `assets/sprites/vermin/snail_rest.png` | `Sprites/Enemies/Double/snail_rest.png` | Faces left. Also used for chew and hurt. |
| Snail walk | `assets/sprites/vermin/snail_walk_a.png`, `snail_walk_b.png` | `Sprites/Enemies/Double/snail_walk_a.png`, `snail_walk_b.png` | Two-frame walk. |
| Grub idle | `assets/sprites/vermin/grub_rest.png` | `Sprites/Enemies/Double/worm_normal_rest.png` | Worm stand-in for the grub. Also used for chew and hurt. |
| Grub walk | `assets/sprites/vermin/grub_a.png`, `grub_b.png` | `Sprites/Enemies/Double/worm_normal_move_a.png`, `worm_normal_move_b.png` | Two-frame walk. |

Filtering is linear. Every copied sprite is the pack's Double size so they share one scale.

## Gaps

- **Dew Dropper** uses the pack's bush as a temporary body. It is not a finished plant character.
- **Rain Barrel** and **Seed Lobber** have no sprite. The lawn shows a labeled color block.
- **Grub** uses the pack's worm until it has its own drawing.
- **Ability** has no icon and does nothing yet. Remove and Speed are text buttons: Remove digs up a Warden without refunding water, and Speed runs the match at double time.
- The five platformer heroes were not used. They are people, not plants.
- Mouse, frog, fish, slimes, and the saw stay in the archive. The snail and the worm are on the lawn as the Snail and the Grub.

## Keep or replace

- Keep this pack for the lawn, the backdrop, the three insects, the cactus, and the crate.
- Replace Dew Dropper before the game is shown as a finished garden. It needs an original plant, drawn to the same outline weight.
- Needle Spitter and Bark Block can stay for the prototype. They are props, so replace them when real Warden characters exist.
- Do not add Platformer Art Mushrooms (2013), Monster Builder (2022), or a pixel pack. They do not match this outline.
- The adventure UI pack, particle pack, and input prompts are still unused. Add one of them only if these flat buttons are not enough.
