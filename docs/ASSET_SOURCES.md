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
tinted warm (or none). Pass 5: Dusk Twilight keeps lavender cotton, Dusk Moonlit is a
clear night (moon + stars), Golden Hour uses the `cotton_sunset_*` family. The flat orange `torn_*` clouds stay listed in `SkyCatalog`
but no mood picks them since pass 4 (kept for a possible Golden Hour art pass).

## Pass 5 slots and files (GW-AA pass 5, 2026-11-24) — contract for Asset Gen

### Looks and mood keys

The look cycle is Main, Sunny, Overcast, Dusk Twilight, Dusk Moonlit (+ Golden Hour as
its own toggle). The seeded opening look still picks from the first four only
(`BackdropCatalog.SEEDED_LOOKS = 4`), so seeds, the Overcast rain and the combat hash
are unchanged. Each look reads its own files from
`assets/art/environment/stage/<mood key>/`:

| Look | Mood key (folder) | Fallback folder(s) | Tint on shared plates (`SET_TINTS`) | Tint on own art (`BACKDROP_TINTS`) |
| --- | --- | --- | --- | --- |
| Main | `main` | - | none | none |
| Sunny | `sunny` | - | none | none |
| Overcast | `overcast` | - | 0.84,0.87,0.92 | none |
| Dusk Twilight | `dusk_twilight` | `dusk` | 0.70,0.66,0.84 | none |
| Dusk Moonlit | `dusk_moonlit` | `dusk` | 0.50,0.54,0.78 | 0.50,0.56,0.86 |
| Golden Hour | `golden_hour` | - | `GOLDEN_HOUR_SET_TINT` | none |

Lookup order for every slot: `stage/<mood key>/`, then the fallback folder, then the
shared file. A missing file is never an error (`BackdropCatalog.optional`).

### Expected file names per slot (drop-in, no code change)

| Slot | Exact file name | Size / placement | Status now |
| --- | --- | --- | --- |
| Fence plate | `stage/<mood key>/stage_fence.png` | 1135x137 at 145,166 (shared plate size), or a full 1280x720 canvas drawn at 0,0 | `dusk/` installed (Asset Gen batch1); others use the shared plate + tint |
| Fence lights | `stage/<mood key>/stage_fence_lights.png` (beside an own fence plate) | same size/offset as that fence plate; drawn additive with a gentle shimmer (`StageLayers.lights_level`, 0.42 ± 0.16) | `dusk/` installed (batch1) |
| Shack plate | `stage/<mood key>/stage_shack.png` | 173x372 at 0,0, or 1280x720 | `dusk/` installed (my cut, see below) |
| Compost plate | `stage/<mood key>/stage_compost.png` | 211x213 at 1069,221, or 1280x720 | none (shared + tint) |
| Lawn-ground plate | `stage/<mood key>/stage_lawn_ground.png` | 1280x423 at 0,297, or 1280x720 | none (shared + tint) |
| Sky backdrop (batch2) | `stage/<mood key>/sky_backdrop.png` | 1280x720, replaces the look's `BackdropCatalog.PATHS` backdrop | none yet |
| Side panels (batch3) | `stage/<mood key>/side_left.png`, `side_right.png` | height 720 (stage pixels), any width; drawn just outside the stage's left/right edge at the stage's scale | none yet: the clean matte shows |
| Sunset clouds | `sky/clouds/<small\|medium\|large>/cotton_sunset_<code>.png` + `_stick.png` | listed explicitly in `SkyCatalog.SUNSET_CLOUDS` with `body_h` | installed (batch1), Golden Hour's family |
| Soil tiles | `environment/board/felt_<sand\|stone>_<light\|dark>.png` | square (160 px used); mapped per cell through the felt's perspective; light/dark follow the felt checker (light = even col+row) | installed |
| Roster portraits | `ui/roster/roster_<fly\|bee\|ladybug\|snail\|grub>.png` | square (128 px plain cutout) | installed, all 5 |
| Matte paper | `ui/matte/matte_paper_tile.png` | seamless tile behind the stage | installed |

Own plates take the look's own light (`BACKDROP_TINTS`); shared plates take `SET_TINTS`,
so Dusk keeps its tint on the shared lawn ground and compost heap.

### Newly installed files (pass 5) and status

| File(s) | Source | Status |
| --- | --- | --- |
| `environment/stage/dusk/stage_fence.png` | Asset Gen batch1 `fence/stage_fence_dusk.png` (sha verified) | **approved**, wired for both Dusks. Softer than the shared fence (cut from the 640x360 source); a sharper version may replace it with the same name. |
| `environment/stage/dusk/stage_fence_lights.png` | batch1 `stage_fence_dusk_lights.png` | **approved**, wired (additive + shimmer) |
| `environment/stage/dusk/stage_shack.png` | cut by `tools/art/cut_dusk_stage.py` from the Dusk backdrop | **approved (agent cut)**, replace with an Asset Gen plate of the same name when one exists |
| `environment/backdrops/mood_4_dusk_stage.png` | `tools/art/cut_dusk_stage.py`: Dusk backdrop lifted 141 px (Asset Gen's fence line), moon painted out | **approved**, both Dusk looks |
| `sky/moon/dusk_moon.png` (128x132) | cut from the Dusk backdrop by the same script | **approved**, Dusk Moonlit only (with 24 code-drawn stars) |
| `sky/clouds/{small,medium,large}/cotton_sunset_{s1..s4,m1..m4,L1,L3,L4,L5}[_stick].png` (24) | batch1 | **approved**, Golden Hour family; body_h s1 165, s2 135, s3 138, s4 135, m1 194, m2 188, m3 202, m4 184, L1 201, L3 213, L4 253, L5 265 |
| `environment/board/felt_{sand,stone}_{light,dark}.png` (4) | tiles_portraits kit (`_2x`, 160 px), sha verified | **approved**, replace the translucent sand/stone washes |
| `environment/board/felt_lawn_{light,dark}.png` (2) | tiles_portraits kit | **unwired (compared)**: side-by-side in game the cleaned felt (`felt_board_clean.png`) keeps its plush bevel and reads richer; the flat lawn tiles were kept as an alternative |
| `ui/roster/roster_{fly,bee,ladybug,snail,grub}.png` (5) | tiles_portraits kit, plain 128 | **approved**. The `_card` variants were compared and not installed (cream tile inside the dark roster slot reads as a frame in a frame) |
| `environment/props/prop_{grass_tuft_1,2,3,flower_white,flower_yellow,pebble_grey,pebble_slate,pebble_tan}.png` (8) | kit `extras/` | **approved**, subtle decor on the lawn ground beside the felt (never on cells; `StageLayers.DECOR`) |
| `ui/matte/matte_paper_tile.png` | kit `extras/` | **approved**, tiled over the matte colour (the side borders) |
| `fx/confetti/confetti_01_red_square.png` … `confetti_12_leaf_right.png` (12) | cut from `ui/win_banner_A.png` by `tools/art/cut_confetti.py` | **approved**, placement confetti (`ConfettiBurst`) |

Reviewed, not installed: the kit's cream hover tile (the current hover ring stays),
blocked-cell overlay, vignette, matte frame (insets ~36 px and would sit under the HUD),
the roster `_card` variants, and batch1's `stage_fence_dusk_nolights.png` (the lit plate
plus the additive lights layer covers it).

### Still to come

- batch2: per-scene plates (`stage_<slot>.png`) and skies (`sky_backdrop.png`) in each
  mood folder, names above. A full 1280x720 canvas is fine for any plate.
- batch3: `side_left.png` / `side_right.png` per mood folder (or in `dusk/` for both Dusks).
- A sharper `dusk/stage_fence.png` (same name, same 1135x137 at 145,166).

## Unwired inventory (definitive)

Verified 2026-11-22 at baseline `86efd22`: 2,417 asset files (excluding `.import`),
2,022 referenced, **395 unwired**. GW-AA (2026-11-23) wired `board_v1_compost_eyes.png`,
`main_noclouds_nosun.png` and `white_stick_tile_medium.png` and unwired `main_noclouds.png`,
so the count became **393**. GW-AA pass 2 (2026-11-23) wired needle smoke (16), lobber
spin (8) + burst (20), `A3`, `A4`, `B3`, the leaf ring, three origami water drops and
`win_banner_B` (52 files) and unwired the Kenney `sprites/board/water.png` (1), so the
count became **342**. GW-AA pass 3 (2026-11-23, Option B) parked the two board-end
cutouts (`player_end_porch.png`, `vermin_end_compost_eyes.png`), so the count is now
**344**. GW-AA pass 5 (2026-11-24) added two compared-but-unwired lawn tiles, so the
count is now **346** (rows below updated):

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
| 2 | `assets/art/environment/board/felt_lawn_light.png`, `felt_lawn_dark.png` | pass 5: compared, cleaned felt kept |
| 2 | `assets/art/environment/board/player_end_porch.png`, `vermin_end_compost_eyes.png` | parked by Option B (painted ends in the backdrop) |

## Not included

Preview videos, GIFs, contact sheets, review pages and generator scripts stay in the art workspace.
