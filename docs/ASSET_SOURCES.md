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

AI-generated art is allowed as of 18 November 2026 (see `docs/conventions.md` §Art). Record each AI asset in the AI art section below. No other packs were downloaded.

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

## AI art

Most art is expected to be AI-generated and curated. List each AI asset here once it is in `assets/`.

| File | Replaces | Status |
| --- | --- | --- |
| `assets/sprites/wardens/needle_spitter/frames/needle_spitter_fire_01.png` to `_19.png` | `assets/sprites/wardens/cactus.png`, once wired in | Approved 18 November 2026 |
| `assets/sprites/wardens/needle_spitter/needle_spitter_fire_strip.png` | `assets/sprites/wardens/cactus.png`, once wired in | Approved 18 November 2026 |
| `assets/sprites/wardens/needle_spitter/needle_spitter_idle.png` | `assets/sprites/wardens/cactus.png`, once wired in | Approved 18 November 2026 |
| `assets/sprites/wardens/needle_spitter/needle_spine.png` | Nothing. New projectile sprite. | Approved 18 November 2026 |
| `assets/sprites/wardens/needle_spitter/frames_nosmoke/needle_spitter_fire_nosmoke_01.png` to `_19.png` | Nothing. Optional, used with the smoke overlay. | Approved 18 November 2026 |
| `assets/sprites/wardens/needle_spitter/smoke_overlay/smoke_01.png` to `_19.png` | Nothing. Optional smoke layer. | Approved 18 November 2026 |
| `assets/sprites/wardens/dew_dropper/frames/dew_dropper_01.png` to `_54.png` | `assets/sprites/wardens/bush.png`, once wired in | Approved 18 November 2026 |
| `assets/sprites/wardens/dew_dropper/dew_dropper_strip.png` | `assets/sprites/wardens/bush.png`, once wired in | Approved 18 November 2026 |
| `assets/sprites/wardens/dew_dropper/dew_dropper_idle.png` | `assets/sprites/wardens/bush.png`, once wired in | Approved 18 November 2026 |
| `assets/sprites/wardens/dew_dropper/dew_droplet.png` | Nothing. New collectible droplet sprite. | Approved 18 November 2026 |
| `assets/sprites/wardens/dew_dropper/dew_splash.png` | Nothing. New splash sprite. | Approved 18 November 2026 |
| `assets/sprites/wardens/dew_dropper/frames_nodrop/dew_dropper_nodrop_01.png` to `_54.png` | Nothing. Optional, for use with the game's own collectible node. | Approved 18 November 2026 |
| `assets/sprites/wardens/rain_catcher/frames/rain_catcher_01.png` to `_47.png` | Nothing. Rain Barrel has no sprite yet; the lawn shows a labeled color block. | Approved 18 November 2026 |
| `assets/sprites/wardens/rain_catcher/rain_catcher_strip.png` | Nothing. Rain Barrel has no sprite yet. | Approved 18 November 2026 |
| `assets/sprites/wardens/rain_catcher/rain_catcher_idle.png` | Nothing. Rain Barrel has no sprite yet. | Approved 18 November 2026 |
| `assets/sprites/wardens/rain_catcher/rain_drop.png` | Nothing. New water drop sprite. | Approved 18 November 2026 |
| `assets/sprites/wardens/seed_lobber/frames/seed_lobber_01.png` to `_43.png` | Nothing. Seed Lobber has no sprite yet; the lawn shows a labeled color block. | Approved 19 November 2026 |
| `assets/sprites/wardens/seed_lobber/seed_lobber_strip.png` | Nothing. Seed Lobber has no sprite yet. | Approved 19 November 2026 |
| `assets/sprites/wardens/seed_lobber/seed_lobber_idle.png` | Nothing. Seed Lobber has no sprite yet. | Approved 19 November 2026 |
| `assets/sprites/wardens/seed_lobber/projectile/fluff_ball.png` | Nothing. New projectile sprite. | Approved 19 November 2026 |
| `assets/sprites/wardens/seed_lobber/projectile/spin/fluff_ball_01.png` to `_08.png`, `projectile/fluff_ball_spin_strip.png` | Nothing. Optional projectile spin. | Approved 19 November 2026 |
| `assets/sprites/wardens/seed_lobber/projectile/burst/seed_burst_01.png` to `_20.png`, `projectile/seed_burst_strip.png` | Nothing. New burst effect. | Approved 19 November 2026 |
| `assets/sprites/wardens/seed_lobber/projectile/seed_single.png` | Nothing. New single seed sprite. | Approved 19 November 2026 |

Needle Spitter: a papercraft die-cut sticker with a cardboard-tube snout and a pink flower. The frames are AI-generated keyframes plus procedural in-betweens, as a 19-frame fire loop on one shared 339×339 transparent canvas, with the pot locked in place. `assets/sprites/wardens/needle_spitter/frames.json` holds the per-frame timing, the pivot, and the frame and snout-tip position where the spine spawns. Nothing is wired into the game yet; `cactus.png` stays until it is.

Dew Dropper: a papercraft die-cut sticker of a forget-me-not with a bowl-shaped leaf on a short stem. The frames are AI-generated keyframes plus procedural in-betweens, as a 54-frame produce loop (about 4.9 s) on one shared 400×622 transparent canvas, with the pot locked in place: the leaf fills and tips, a droplet lands on the head, the flower startles, and the droplet pops out. The stem is drawn in code. `frames/` keeps the popped droplet baked in; `frames_nodrop/` removes it from the spawn frame on. `assets/sprites/wardens/dew_dropper/frames.json` holds the per-frame timing, the head pivot, the leaf joint, the frame and position where the drop lands, and the frame and position where the collectible spawns. Nothing is wired into the game yet; `bush.png` stays until it is.

Rain Catcher: a papercraft die-cut sticker of a hollow-topped tree stump with copper barrel bands, fishing with a twig rod, with a small red-spotted mushroom on the rim. The frames are AI-generated keyframes plus procedural in-betweens, as a 47-frame catch loop (3.85 s) on one shared 581×634 transparent canvas, with the ground locked in place: he winds up and casts, the line runs off the right edge, he hooks a water drop, yanks it up and flings it into his mouth, then gulps. The mushroom teeters back on the wind-up and forward on the fling with a startled face. The rod, line and hook are drawn in code; the fists move with the rod. The drop is baked into the frames, and `rain_drop.png` is the same drop on its own. `assets/sprites/wardens/rain_catcher/frames.json` holds the per-frame timing, the pivots, the cast-out, hooked and caught frames, the mouth position, and the rod tip and grip for each frame. The unit is still named Rain Barrel in code (`src/rules/unit_catalog.gd`). Renaming it to Rain Catcher is Brandon's call and has not been done. Nothing is wired into the game yet.

Seed Lobber: a papercraft die-cut sticker of a potted dandelion Warden with a big white seed-puff head and a green face. The frames are AI-generated keyframes plus procedural in-betweens, as a 43-frame throw loop (3.68 s) on one shared 444×638 transparent canvas, with the pot locked in place: he cocks a fluff ball behind his head, throws it overhand with his eyes squeezed shut, then winces as he plucks a tuft from his own puff and it grows into the next ball. The stem and seeds are drawn in code. The ball leaves his hand on frame 23; the projectile spawns at (376.7, 287.0) on the frame canvas. The burst is a separate, non-looping 20-frame effect (1.33 s) on a 480×480 canvas centered on the landing point, with the damage frame at 3. The engine sets the burst scale so it covers the 3 by 3 area; the seeds in it are cosmetic and do not show which tiles the rules hit. `assets/sprites/wardens/seed_lobber/frames.json` holds the per-frame timing, the pivots, the release frame, the spawn point, the ball position for each frame, and the projectile and burst timing. Nothing is wired into the game yet.

Paper-texture pass (19 November 2026): every frame, strip and idle still of the four Wardens above got a subtle paper finish: paper fibers, newsprint strips on the pots and stems, and a strip of tape on the pot. The pass is heavier on Dew Dropper and Seed Lobber and light on Needle Spitter and Rain Catcher (no tape on Rain Catcher). Seed Lobber's fluff ball and its spin frames have fibers only. The needle spine, the drops and splash, the smoke and the seed burst are unchanged. Alpha, outlines, the white border, frame sizes, pivots and timing are unchanged, so every `frames.json` stays valid.

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
