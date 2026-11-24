# Asset sources

All art is AI-assisted papercraft, approved by Brandon (rounds 1-3e and animations v3, Nov 2026).

Status legend (verified against the live tree at baseline `86efd22`, 2026-11-22):
**approved** = referenced from `src/`, `tests/`, or `project.godot` (including frames
resolved through `frames.json`); **unwired** = present in the locked asset tree but
referenced nowhere — listed honestly, left as-is (art is LOCKED; nothing here was
edited or renamed by the docs close-out).

## Layout

- `assets/sprites/anim/wardens/<dew_dropper|rain_catcher|needle_spitter|seed_lobber|stubborn_cone>/`
  and `assets/sprites/anim/vermin/<fly|bee|ladybug|snail|grub>/`
  v3 stop-motion sets at 10 fps: `<anim>/<state>/` frames (`100`, `66`, `33` = health),
  one strip per state, `frames.json`, and `fx/` where the unit has one.
  Wardens: idle, action, hurt, place (100 only), death (33 only). Vermin: idle, move,
  action, hurt, spawn, death (33 only). The Bee adds rise and drop, and the Ladybug
  adds `flutter_takeoff`, `flutter_air` and `flutter_land`; the hop-over arc is in
  `ladybug/frames.json` under `hop_over`.
  Contact sheets named in `frames.json` were left out on purpose.
  **Status: approved** — all ten unit clip sets load via `src/art/anim_library.gd`.
  New-set fx (GW-AA pass 2, 2026-11-23): `needle_spitter/fx/smoke/` (16 frames) —
  **status: approved** (muzzle-smoke overlay synced frame-for-frame to the Needle
  Spitter action clip, `ClipView.set_overlay`); `seed_lobber/fx/projectile/spin/` (8)
  and `burst/` (20) — **status: approved** (`FxArt.lobber_spin()` spins the fluff ball
  in flight, `FxArt.lobber_burst()` plays the seed burst where it lands). The two
  projectile strips stay **unwired** (the frame folders are used instead).
- `assets/sprites/anim/fx/poof/`: the defeat poof (8 frames + strip).
  **Status: approved** — loaded by `poof_actor.gd` and `AnimLibrary.poof()`.
- `assets/sprites/wardens/<needle_spitter|dew_dropper|rain_catcher|seed_lobber>/`
  Paper-texture touched-up loops from before the anim/ chain.
  **Status: unwired** — superseded by `assets/sprites/anim/`; nothing in `src/`,
  `tests/` or `project.godot` references these four folders (only `bush.png`,
  `cactus.png` and `bark_block.png` from the same tree are used — as the BARK brace).
  Byte-identical to the work PC install. Do not overwrite them.
- `assets/sprites/board/`: `grass.png`, `sand.png`, `stone.png` (soil) and
  `background.png` — **status: approved** (board scene). `water.png` (the old Kenney
  droplet) — **status: unwired** since GW-AA pass 2 (droplets and the HUD icon use the
  origami water set). `dirt.png` — **status: unwired**. `backdrops/` (blight edge, flat garden, late
  afternoon, morning dew) — **status: unwired, non-ship drafts** (superseded by the
  seeded backdrop set under `art/environment/backdrops/`).
- `assets/art/environment/`
  - `backdrops/`: main backdrop plus moods 1 sunny, 3 overcast and 4 dusk (no clouds,
    suns and moon restored). Mood 2 is Golden Hour.
    **Status: approved** (seeded backdrop catalog, `src/art/backdrop_catalog.gd`).
    Main ships as `main_noclouds_nosun.png` (the sun-free copy made for the per-match
    random sun, GW-AA 2026-11-23); `main_noclouds.png` (baked sun) — **status: unwired**.
  - `golden_hour/`: Golden Hour boss backdrop as layers (ray origin D). Draw order and
    rotation are in `golden_hour_layers.json`.
    **Status: approved** (layered composition in `src/art/golden_hour_backdrop.gd`;
    last stop of the backdrop tour). Three helper stills (`backdrop_no_rays`,
    `sun_layer_fullframe`, `with_rays_still`) — **status: unwired**.
  - `board/`: vermin end 4 (`vermin_end_compost_eyes.png`) and player end 1
    (`player_end_porch.png`) — **status: parked (unwired)** since GW-AA pass 3
    (2026-11-23): Option B frames the lawn with the porch and compost heap painted
    into the Main backdrop, so the separate cutouts are no longer drawn (kept,
    approved art, for a later board or mood that needs them). `board_v1_compost_eyes.png`
    (the locked Round 3b felt board, delivered only as a 1280x720 composite) —
    **status: approved**: since GW-AA pass 3 `src/prototype/felt_perspective.gdshader`
    warps its frame (source rect 149,334 to 1104,688) onto the Option B trapezoid with
    the exact inverse homography (`src/rules/lawn_geometry.gd`); the file is untouched.
- `assets/art/sky/`
  - `clouds/{small,medium,large}/`: each cloud comes as `<name>.png` and
    `<name>_stick.png` (with its white stick).
    **Status: approved** (seeded sky layer; all 106 catalog `res://` paths verified on disk).
  - `clouds/sticks/`: separate stick tiles. `white_stick_tile_medium.png` —
    **status: approved** (the rain cloud's stick, GW-AA); small and large — **status:
    unwired** (the stick composites are the `_stick.png` cloud variants).
  - `suns/`: suns 1, 2, 5, 6 and 8 — **status: approved** (per-match seeded sun).
  - `rain/`: the approved rain set — five clouds + `rain_08_drop_M` +
    `rain_12_ground_splash` are **approved** (the light-rain variant); six further rain
    stills (`rain_06`, `07`, `09`, `10`, `14`, `15`) — **status: unwired**.
- `assets/art/ui/`: logo, wave flag, loss banner, `win_banner_A` and `seed_packets/`
  (packet 2 with the stickers scaled to fit) — **status: approved** (top bar, wave
  roster, win/loss banners, seed-packet card faces). `win_banner_B.png` —
  **status: approved** (GW-AA pass 2: the win screen picks banner A or B from the match
  seed, channel `win_banner`). `summon_bell.png` — **status: unwired**
  (optional, for later; the Ability button is intentionally inert).
- `assets/art/fx/`
  - `A6` cellophane slime trail (snail) — **status: approved** (snail trail actor).
  - Wired in GW-AA pass 2 (2026-11-23), all through `src/art/fx_art.gd` and the
    one-shot `src/prototype/fx_actor.gd` — **status: approved**:
    - `water/water_parachute_drop.png` — sky drops while they fall.
    - `water/water_drop_medium.png` — landed sky drops and Dew Dropper drops.
    - `water/water_drop_small.png` — the HUD water icon (replaces the Kenney droplet).
    - `A3` impact burst — each Seed Lobber seed hit.
    - `A4` small burst — each Needle Spitter spine hit.
    - `B3` collect flecks — a collected water drop.
    - `leaf_ring_rotating.png` — a slowly turning ring under the placement ghost,
      tinted red when the tile can't take the selected Warden.
  - Still **status: unwired**, with the reason:
    - `A1` paper-airplane projectile — no Warden fires a generic projectile; the
      Needle Spitter keeps its approved spine.
    - `A7` defeat poof — the animated poof (`sprites/anim/fx/poof/`) already plays.
    - `A8` small poof / paper wad — no consumer yet.
    - `B2` parachute gem drop — same art as `water/water_parachute_drop.png`, which
      is the one wired.
    - `B5` placement hover / `B6` can't-place hover — composite stills with a baked
      felt tile and a placeholder flower; the live ghost + `leaf_ring_rotating.png`
      (+ red tint) implement the same intent.
    - `water/water_pile_large.png` — no consumer yet (a water-amount display).
- `assets/art/_unsure/lineup/`: Round 3 base sticker stills for all 10 units, for
  reference only — **status: unwired**. The animation folders above supersede them.

## Stage layer slots (GW-AA pass 4) — contract for Asset Gen

The 1280x720 stage is built from six slots, back to front (`src/art/stage_layers.gd`);
the lawn (felt + units) draws on top of all of them. All coordinates are stage pixels
(origin top-left, 1280x720 design size; the stage is scaled uniformly and letterboxed
with a forest-green matte, so nothing outside 0..1280 x 0..720 is ever shown).
Every plate is a straight-alpha PNG at 1x stage resolution, placed with its top-left at
the offset below (no anchors or scaling; to replace one, keep the size and offset or
update the spec in `src/art/backdrop_catalog.gd`).

| # | Slot | File(s) | Offset | Size | Notes |
|---|---|---|---|---|---|
| 0 | `SkyBackdrop` | per look: `environment/backdrops/*` (via `BackdropCatalog.PATHS`), Golden Hour layers in `environment/golden_hour/` | 0,0 | 1280x720 (stretched) | The only thing a look switch swaps. Sky must be clean above y ~300; the set covers the rest. |
| 1 | `SkyProps` | `sky/clouds/*`, `sky/rain/*`, `sky/suns/*`, sticks | - | - | Code-placed: clouds and sun in band y 76-172, sticks run to y 0; Overcast rain falls to y 334. |
| 2 | `FenceLayer` | `environment/stage/stage_fence.png` | 145,166 | 1135x137 | Fence, sunflowers, grass strip; feathered 0.7 px. |
| 3 | `ShackLayer` | `environment/stage/stage_shack.png` | 0,0 | 173x372 | Porch, left edge. |
| 4 | `CompostLayer` | `environment/stage/stage_compost.png` + `environment/board/compost_eyes_overlay.png` | 1069,221 / 1139,313 | 211x213 / 76x43 | Eyes are only the dark hollow + eyes (ellipse centre 1177,334, rx 36, ry 19, feathered), never a second pile. |
| 5 | `LawnLayer` | `environment/stage/stage_lawn_ground.png` | 0,297 | 1280x423 | Ground around the felt; the felt trapezoid (far 168..1104 @ y 334, near 40..1240 @ y 584) sits on it. |

Each look tints slots 2-5 (`BackdropCatalog.SET_TINTS`, Golden Hour
`GOLDEN_HOUR_SET_TINT`); new per-mood plates would replace the tint. Plates 2-5 were cut
from `environment/backdrops/main_noclouds_nosun` by `tools/art/cut_stage_plates.py`
(Pillow/numpy/scipy; fence line y 219, ground y 300, polygons in the script). The eyes
were cropped from `board_v1_compost_eyes.png`.

New pass 4 files (all **status: approved**, referenced from `src/`):
- `environment/stage/stage_fence.png`, `stage_shack.png`, `stage_compost.png`,
  `stage_lawn_ground.png` — the set plates above.
- `environment/board/compost_eyes_overlay.png` — the glowing eyes in the heap's hollow.
- `environment/board/felt_board_clean.png` — the felt play surface, rebuilt from the
  board_v1 composite region (145,330)-(1108,692) at 2x (`tools/art/clean_felt.py`:
  Lanczos, 3 bilateral passes, light unsharp, seeded grain); imported with mipmaps.
  Replaces direct sampling of the composite (which looked patchy).
- `sky/suns/main_sun_shadow.png` — soft drop shadow for the Main sun (the Golden Hour
  layered paper sun, `environment/golden_hour/golden_hour_sun_sprite.png`).

Sky families by mood (pass 4): Main/Sunny `sky/clouds/<small|medium|large>/cotton_*` (white), Overcast
`felt_*` (grey) + rain cloud `sky/rain/rain_01_felt_cloud_3_strands.png` /
`rain_03_felt_cloud_dense.png` on a stick, Dusk cotton tinted lavender, Golden Hour cotton
tinted warm (or none). The flat orange `torn_*` clouds stay listed in `SkyCatalog`
but no mood picks them since pass 4 (kept for a possible Golden Hour art pass).

## Unwired inventory (definitive)

Verified 2026-11-22 at baseline `86efd22`: 2,417 asset files (excluding `.import`),
2,022 referenced, **395 unwired**. GW-AA (2026-11-23) wired `board_v1_compost_eyes.png`,
`main_noclouds_nosun.png` and `white_stick_tile_medium.png` and unwired `main_noclouds.png`,
so the count became **393**. GW-AA pass 2 (2026-11-23) wired needle smoke (16), lobber
spin (8) + burst (20), `A3`, `A4`, `B3`, the leaf ring, three origami water drops and
`win_banner_B` (52 files) and unwired the Kenney `sprites/board/water.png` (1), so the
count became **342**. GW-AA pass 3 (2026-11-23, Option B) parked the two board-end
cutouts (`player_end_porch.png`, `vermin_end_compost_eyes.png`), so the count is now
**344** (rows below updated):

| Count | Path | Note |
| --- | --- | --- |
| 304 | `assets/sprites/wardens/<dew_dropper 113, needle_spitter 62, rain_catcher 51, seed_lobber 78>/` | legacy pre-chain loops, superseded by `sprites/anim/` |
| 2 | `assets/sprites/anim/wardens/seed_lobber/fx/projectile/` (2 strips) | frame folders are used instead |
| 7 | `assets/art/fx/` A1, A7, A8, B2, B5, B6 + `water/water_pile_large.png` | see the reasons above |
| 10 | `assets/art/_unsure/lineup/` | Round 3 stills, reference only |
| 8 | `assets/art/sky/clouds/sticks/` x2 (small, large) + `assets/art/sky/rain/` x6 | stick tiles; unused rain stills |
| 4 | `assets/art/environment/` (backdrops 1: `main_noclouds.png`, golden_hour 3) | helper stills |
| 4 | `assets/sprites/board/backdrops/` | non-ship draft gardens, superseded |
| 1 | `assets/art/ui/summon_bell.png` | optional, for later |
| 2 | `assets/sprites/board/dirt.png`, `water.png` | unreferenced soil tile; old Kenney droplet |
| 2 | `assets/art/environment/board/player_end_porch.png`, `vermin_end_compost_eyes.png` | parked by Option B (painted ends in the backdrop) |

## Not included

Preview videos, GIFs, contact sheets, review pages and generator scripts stay in the art workspace.
