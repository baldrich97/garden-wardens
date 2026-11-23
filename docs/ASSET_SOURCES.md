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

## Unwired inventory (definitive)

Verified 2026-11-22 at baseline `86efd22`: 2,417 asset files (excluding `.import`),
2,022 referenced, **395 unwired**. GW-AA (2026-11-23) wired `board_v1_compost_eyes.png`,
`main_noclouds_nosun.png` and `white_stick_tile_medium.png` and unwired `main_noclouds.png`,
so the count became **393**. GW-AA pass 2 (2026-11-23) wired needle smoke (16), lobber
spin (8) + burst (20), `A3`, `A4`, `B3`, the leaf ring, three origami water drops and
`win_banner_B` (52 files) and unwired the Kenney `sprites/board/water.png` (1), so the
count is now **342** (rows below updated):

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

## Not included

Preview videos, GIFs, contact sheets, review pages and generator scripts stay in the art workspace.
