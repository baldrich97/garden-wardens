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
  Unwired leftovers inside the new sets: `needle_spitter/fx/smoke/` (16 frames) and
  `seed_lobber/fx/projectile/` burst + spin + strips (30 files) — see the inventory below.
- `assets/sprites/anim/fx/poof/`: the defeat poof (8 frames + strip).
  **Status: approved** — loaded by `poof_actor.gd` and `AnimLibrary.poof()`.
- `assets/sprites/wardens/<needle_spitter|dew_dropper|rain_catcher|seed_lobber>/`
  Paper-texture touched-up loops from before the anim/ chain.
  **Status: unwired** — superseded by `assets/sprites/anim/`; nothing in `src/`,
  `tests/` or `project.godot` references these four folders (only `bush.png`,
  `cactus.png` and `bark_block.png` from the same tree are used — as the BARK brace).
  Byte-identical to the work PC install. Do not overwrite them.
- `assets/sprites/board/`: `grass.png`, `sand.png`, `stone.png` (soil), `water.png`
  (droplets) and `background.png` — **status: approved** (board scene + droplets).
  `dirt.png` — **status: unwired**. `backdrops/` (blight edge, flat garden, late
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
  - `board/`: vermin end 4 (compost eyes) and player end 1 (porch) —
    **status: approved** (board end pieces). `board_v1_compost_eyes.png` (the locked
    Round 3b felt board, delivered only as a 1280x720 composite) — **status: approved**
    (GW-AA 2026-11-23): `src/prototype/lawn_view.gd` draws the board frame and the
    5x12 felt cells straight from it through atlas regions; the file is untouched.
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
  **status: unwired** (the chain uses banner A). `summon_bell.png` — **status: unwired**
  (optional, for later; the Ability button is intentionally inert).
- `assets/art/fx/`
  - `A6` cellophane slime trail (snail) — **status: approved** (snail trail actor).
  - `A1` paper-airplane projectile, `A3` impact burst, `A4` small burst, `A7` defeat
    poof, `A8` small poof / paper wad, `B2` parachute gem drop, `B3` collect flecks,
    `B5` placement hover (leaf ring with a ghost sticker), `B6` can't-place hover,
    `leaf_ring_rotating.png`, `water/` (the origami water set) — **status: unwired**
    (the chain's fx used the per-unit fx art and the snail trail instead; placement
    hover shows a seed-packet ghost).
- `assets/art/_unsure/lineup/`: Round 3 base sticker stills for all 10 units, for
  reference only — **status: unwired**. The animation folders above supersede them.

## Unwired inventory (definitive)

Verified 2026-11-22 at baseline `86efd22`: 2,417 asset files (excluding `.import`),
2,022 referenced, **395 unwired**. GW-AA (2026-11-23) wired `board_v1_compost_eyes.png`,
`main_noclouds_nosun.png` and `white_stick_tile_medium.png` and unwired `main_noclouds.png`,
so the count is now **393** (rows below updated):

| Count | Path | Note |
| --- | --- | --- |
| 304 | `assets/sprites/wardens/<dew_dropper 113, needle_spitter 62, rain_catcher 51, seed_lobber 78>/` | legacy pre-chain loops, superseded by `sprites/anim/` |
| 46 | `assets/sprites/anim/wardens/needle_spitter/fx/smoke/` (16) + `seed_lobber/fx/projectile/{burst 20, spin 8, 2 strips}` | new-set fx leftovers, unused |
| 14 | `assets/art/fx/` A1, A3, A4, A7, A8, B2, B3, B5, B6, leaf ring + `water/` x4 | pre-chain fx stills |
| 10 | `assets/art/_unsure/lineup/` | Round 3 stills, reference only |
| 8 | `assets/art/sky/clouds/sticks/` x2 (small, large) + `assets/art/sky/rain/` x6 | stick tiles; unused rain stills |
| 4 | `assets/art/environment/` (backdrops 1: `main_noclouds.png`, golden_hour 3) | helper stills |
| 4 | `assets/sprites/board/backdrops/` | non-ship draft gardens, superseded |
| 2 | `assets/art/ui/` (summon_bell, win_banner_B) | optional / superseded by banner A |
| 1 | `assets/sprites/board/dirt.png` | unreferenced soil tile |

## Not included

Preview videos, GIFs, contact sheets, review pages and generator scripts stay in the art workspace.
