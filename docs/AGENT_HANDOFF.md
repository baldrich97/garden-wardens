# AGENT_HANDOFF.md — Garden Wardens takeover packet

Read this first when picking up the project. Process rules are in
[../AGENTS.md](../AGENTS.md); style/art rules in [conventions.md](conventions.md).

## Current snapshot (post-asset-wiring chain)

- Baseline: `86efd22` — top of the GW-AW asset-wiring chain (cards AW-1 through AW-7,
  commits `e740be9`..`86efd22`), sitting on the import commit `83b57d9` (Godot 4.6
  `.import` metadata for the locked asset set), which sits on the 7-level campaign
  baseline `44fabb91cb4f390d50a08dcfa251875b93c703ce`. All local-only; nothing pushed.
- Contents: 8 levels (7 campaign + level 8 "The Whole Cast" showcase), 5 Wardens
  (Dew Dropper, Rain Catcher, Needle Spitter, Seed Lobber, Stubborn Cone), 5 Vermin
  (Fly, Bee, Ladybug, Snail, Grub), soil kinds (regular/sand/stone), droplets,
  speed/pause/remove tools, vermin side panel, tooltips.
- What changed artistically (net effect of the chain):
  - All five Wardens and all five Vermin now animate from the v3 stop-motion clip sets
    (`src/art/anim_library.gd`, 10 fps, damage states 100/66/33), including the Bee's
    rise/drop and the Ladybug's flutter-hop over the Stubborn Cone.
  - Per-unit fx art is wired: Needle Spitter spine shot (`shot_actor.gd`), Seed Lobber
    fluff ball + seed puff (`lob_actor.gd`), Snail A6 slime trail (`snail_trail.gd`),
    defeat poof (`poof_actor.gd`).
  - Seeded per-match look: backdrop catalog (main, sunny, overcast, dusk — a seeded
    pick with a visible seed label) plus a sky layer (drifting stick clouds, per-mood
    sun, light rain). `--seed N` reproduces a look exactly.
  - Golden Hour: layered boss backdrop (`src/art/golden_hour_backdrop.gd`), the last
    stop of the backdrop tour; forcing it suppresses the seeded sky (which resolves
    the parked double-celestial note for as long as it is active).
  - Win/loss banners, logo in the top bar, wave flag in the wave roster, seed-packet card faces + placement ghost.
- Browsing anims: run scene `res://src/prototype/anim_preview.tscn` (Godot editor, or
  headless with the scene path as the last argument). 11 slots in catalog order:
  5 Wardens (0-4), 5 Vermin (5-9), poof (10). Data-driven unit/anim/state rows,
  loop + frame stepping, fps status line. Headless capture:
  `--shot <path> --unit <n> --anim <clip>` (clip names like `idle_100`, `move_66`).
- Debug toggles on the garden board:
  - F7 (or `--debug-overlay`): debug overlay on/off. Gates the seed/mood pill
    watermark; the pill also appears while a damage pin is active (GW-P1).
  - F8 (or `--damage-state 100|66|33`): pin every visible unit's art to the next
    damage state.
  - Backdrop tour button: main -> sunny -> overcast -> dusk -> Golden Hour -> main
    (Golden Hour also hides the seeded sky). `--golden-hour` forces Golden Hour.
  - `--level N` picks the level for a debug run (the showcase is `--level 8`).
  - `--seed N` reproducible sky/backdrop.
  - `--layout horizontal|vertical` forces the HUD layout (GW-AA pass 3); tests can
    set `GardenBoard.forced_layout` instead.
  - Screenshot helpers: `--result-shot win|loss`, `--fall-shot <path>`,
    `--play-shot <path>`.
- Art status: docs/ASSET_SOURCES.md now carries per-asset approved/unwired statuses
  and the definitive unwired inventory (344 files after GW-AA pass 3, including
  `summon_bell.png` and the two parked board-end cutouts).
- Checks: the full gate is the 3 suites + 3 probes — see the Verification playbook
  below (it supersedes the suites-only commands in ../AGENTS.md).

## GW-AA asset audit (2026-11-23, creator-approved local commit)

Audit of the wired art against the Asset Gen locks. Fixed:
- **Board v1 (felt checkerboard) was never wired** — the lawn still drew the Kenney
  grass/sand/stone tiles. `LawnView.board_texture` now draws the locked board straight
  from `board_v1_compost_eyes.png` (frame + 60 felt cells via atlas regions, no art
  edits). Sand and stone keep a translucent wash so soil stays readable (placeholder
  until soil art exists). The soil-tile path remains as a fallback when no board
  texture is set. The aim highlight is cream on the felt (green vanished on it).
- **Clouds had no vertical motion** and were shrunk into the sky strip with their
  sticks ending mid-sky. Every cloud now hangs from its white stick, which always runs
  past the top of the screen; each cloud bobs up and down on its own seeded cycle
  with a slight tilt around the unseen hand (`SkyLook.cloud_bobs`), as in the approved
  Round 3b sky-motion preview. Clouds, sun and rain cloud are larger; the rain cloud
  gets a white stick tile; the sun bobs gently.
- **Double celestials**: Main now uses `main_noclouds_nosun.png` (made for the random
  sun); Sunny and Dusk keep their painted sun/moon and skip the seeded sun
  (`SkyLook.mood_shows_sun`).
Open creator calls are listed in the GW-AA report (backdrop framing vs. UI, 640x360
mood art, duplicate porch/compost ends, soil look on felt, unwired fx/water sets).

### GW-AA pass 2 (2026-11-23, creator-approved local commit)

- Wired the origami water set (parachute while falling, medium drop landed/dew, small
  drop as the HUD icon), `A3`/`A4` impact bursts, `B3` collect flecks, the rotating
  leaf ring under the placement ghost (red when blocked), Needle Spitter muzzle smoke,
  Seed Lobber spin + seed burst and win banner B (seeded). Per-asset reasons for what
  stays unwired are in docs/ASSET_SOURCES.md.
- Board frame trimmed in `lawn_view.gd` (`BOARD_FRAME_SRC`): the compost-brown sliver at
  the top-right corner is gone.
- Probes: Bee lane changes and lobber volleys are seeded (combat probe 5/5 identical
  runs); the input probe is time-based and runs at native refresh.
- Deferred by the creator: the perspective (trapezoid) lawn (done in pass 3, below);
  mood backdrops; sand/stone felt tiles; cloud/sun tuning (bring back to the creator).

### GW-AA pass 3 (2026-11-23): Option B live, responsive HUD

- **Perspective lawn (Option B).** `src/rules/lawn_geometry.gd` (`LawnGeometry`) owns a
  projective homography from the felt composite's frame (`BOARD_FRAME_SRC`) onto the
  trapezoid far (168,334)-(1104,334), near (40,584)-(1240,584) in 1280x720 stage
  space, plus its exact inverse. `src/prototype/felt_perspective.gdshader` draws the
  felt by mapping each stage pixel back through the inverse (4 rotated-grid taps),
  so lines stay straight and crisp with no per-triangle affine warp. Sand/stone washes,
  the aim cursor and the leaf ring are true perspective quads. `LawnView.cell_at` /
  `cell_center` and every rail helper go through the same homography.
- **Rails.** Units stand on 5 rails (row 0 back to row 4 front) at depth 0.72 into
  each row: rail y 364/407/454/506/564, scale 0.82 to 1.00 (cell width at the rail),
  z = 10 + 4*row (wardens +0, vermin +1, shots/landed drops +2, impact fx/poofs +3;
  lobbed balls and the seed burst at absolute z 40/41). A front-rail unit's top covers
  a back-rail unit's base; health bars draw with their unit so they occlude the same way.
- **Unit size.** Every unit's art canvas is 1.62 rail cell widths tall (vermin x0.74), as
  in the approved Option B mockup; ground units pin `ground_point_px` to the rail
  point, fliers (bee, fly) centre `body_center_px` half a cell above it. Ground units
  have no idle bob (ClipView `set_idle_bob`, off by default); fliers and the wave
  roster portraits keep the bob. Soft contact shadows (`src/prototype/rail_stand.gd`).
- **Stage.** Backdrop, Golden Hour, sky and lawn live in a 1280x720 `Stage` that is
  uniformly scaled into the area the HUD leaves (whole screen in horizontal mode, right
  of the side bar in vertical mode), centred and top-aligned (so cloud sticks always run
  up behind the top bar to the screen top); `StageFill`
  (`stage_fill.gdshader`) extends the backdrop softly into any gap. The porch and
  compost heap painted into the Main backdrop frame the lawn; the cutout end pieces
  are removed (parked in docs/ASSET_SOURCES.md).
- **Responsive HUD.** Slim top bar (~60 px) and bottom tray (~122 px) at 1280x720; both
  grow with the canvas_items stretch on big windows (x1.5 at 1920x1080). A real window
  narrower than 1100 px or shorter than 640 px snaps the cards into a vertical side
  bar (2 columns of larger cards, Ability/Remove/backdrop below) and the stage fits to
  its right; it switches live on resize. `GardenBoard.layout_for_window()` holds the
  breakpoint; `--layout` / `GardenBoard.forced_layout` override it.
- **Pre-wave panel / tips.** The wave roster is a one-row strip in the sky's top-right
  corner under the top bar (never over the lawn); the level hint sits in the sky just
  above the far edge. Lawn tooltips ride in the sky above the far edge; card tooltips
  flip above the pointer near the bottom.
- **Needle smoke.** The muzzle smoke overlay is scaled x1.7 about the mouth, alpha x2.1
  and lifted 35% toward white (`ClipView.set_overlay_boost`).
- **Pass 3 follow-up fixes:** (1) the felt was double-rendered: in a canvas_item
  `fragment()`, `COLOR` already holds the node's own TEXTURE sampled flat at UV, so
  `c * COLOR` multiplied the warped felt by the unwarped composite (a straight 12x5
  grid over the slanted one). Both custom shaders now take the modulate from
  `vertex()` via a varying instead (the needle smoke overlay had the same bug, which
  had squared its alpha). (2) Stage is top-aligned. (3) Sky band kept above the fence.
- **Fixed on the way:** fliers (bee, fly) had a NaN clip fit (an INF anchor passed the
  `> 1.0` test), which hid their art; ClipView now tests for a finite anchor.
- **Caveats.** The framing is tuned to the Main backdrop. Sunny/overcast/dusk (640x360,
  horizon lower) and Golden Hour use the same geometry, so the lawn covers part of
  their fence/porch until the moods are recomposed (parked Asset Gen work). The grid is
  12x5 (60 cells), not 10x5. Far-rail cells are about 80x40 px at 1280x720 (under the
  64 px touch guideline in depth); the stretch scale enlarges them on bigger windows.
  Cloud/sun tuning is still tabled; only the sky band moved: clouds and sun lay out in
  stage y 76 to 172 (open sky above the fence), rain falls to the far edge (y 334).
- New checks: rules (homography round trip on all 60 cells plus corner probes, frame
  corners, rail y/scale/z monotonic, breakpoints), smoke (cutouts absent, felt shader,
  live layout switch), input probe step 11 (hover all 60 cells plus corner-cell corners).

## Verification playbook

Binary: the MAIN exe `tools/godot/Godot_v4.6-stable_win64.exe` for every run,
headless or windowed. Pitfalls, both learned the hard way:
- Do NOT use `Godot_v4.6-stable_win64_console.exe` — under piped capture it
  silently returns exit 0 with no output.
- Do NOT pass `--quiet` — it mutes `print()`, so logs come back empty and every
  marker check becomes a false FAIL.
- The windowed input probe waits on wall-clock time, not frame counts (GW-AA pass 2),
  so it passes at the display's native refresh (this host runs 180 Hz) with no
  `--max-fps` flag. It prints `PROBE refresh=... max_fps=...` and `PROBE measured_fps=...`
  so a log shows the rate it ran at. Do not reintroduce frame-count waits.

All commands from the repo root.

### The 4-part gate (must be green before any claim)

1. `tools/godot/Godot_v4.6-stable_win64.exe --headless --path . --import` — exit 0.
   Re-run after adding/repathing any resource so `.godot/` knows about it.
2. `... --headless --path . --script res://tests/rules_test.gd` — expect `RULES_OK`.
3. `... --headless --path . --script res://tests/smoke.gd` — expect `SMOKE_OK`.
4. `... --headless --path . --script res://tests/match_test.gd` — expect `MATCH_OK`.

A missing marker is a FAIL even if the exit code looks fine (../AGENTS.md).

### Probes — `tests/probes/` (promoted out of gitignored `build/` by GW-P4)

- Playability: `... --headless --path . --script res://tests/probes/playability_probe.gd`
  — expect `PLAYABILITY_PROBE_OK` (its missing-clip count is informational).
  Sections: anim matrix, sandbox kill loop, rain catch (L4), bee lane change (L3),
  economy win (L1).
- Combat: `... --headless --path . --script res://tests/probes/combat_probe.gd`
  — expect `COMBAT_PROBE_OK`. Live damage observation only: every vermin chews,
  Needle single-target kill, Seed Lobber same-tick multi-hit. Deterministic: it pins
  the match seed (`PROBE_SEED`), so repeated runs give byte-identical logs.
- Synthetic input: `... --path . res://tests/probes/input_probe.tscn` — WINDOWED
  only (real frame pacing drives the animation clock and viewport picking; this
  host has no xvfb, a brief visible window is normal and not a bug). Expect 10
  `STEP_OK` lines then `INPUT_PROBE_OK`; each step is one synthetic click/drag
  through `Input.parse_input_event()`. About 46 "Viewport was previously notified that
  the mouse is in its area" warnings come from the synthetic mouse events and are
  expected (same count at baseline).
- Seeded randomness: every gameplay roll draws from `MatchSeed.rng(channel)` —
  `bee_path` (Bee lane changes), `seed_burst` (lobber volley cells), `sky_drops`,
  `grub_roll`, `win_banner`. Probes pin the seed with
  `GardenBoard.forced_match_seed = N` (static; checked before `--seed`), so a probe
  run replays exactly. `BeePath.next_step` / `SeedBurst.pick` take an optional
  `RandomNumberGenerator` (falls back to the global RNG when none is passed).

### Watching gameplay/animations

Launch normally (no `--headless`), scene `res://src/prototype/garden_board.tscn`.
- `--level N` pick a level; `--level 8` is the showcase — all five vermin in wave 1.
- `--seed N` replays a look exactly.
- `--shot N <path>` captures after N frames; `--play-shot <path>` mid-match shot;
  `--result-shot win|loss <path>` banner shot (default
  `build/screenshots/result_win.png` / `result_loss.png`); `--fall-shot <path>`
  droplet shot. Anim-clip capture lives in `res://src/prototype/anim_preview.tscn`
  (`--shot <path> --unit <n> --anim <clip>` — see Current snapshot).
- F7 toggles the debug overlay + seed pill; F8 pins damage state
  (`--damage-state 100|66|33` at startup).

### Evidence + markers

Evidence screenshots go to `build/screenshots/` — gitignored like all of `build/`;
only the probe tools in `tests/probes/` are tracked. Markers: `RULES_OK` /
`SMOKE_OK` / `MATCH_OK` = the three suites green; `PLAYABILITY_PROBE_OK` /
`COMBAT_PROBE_OK` / `INPUT_PROBE_OK` = each probe's end-to-end pass (any
`STEP_FAIL`/section FAIL printed before it invalidates the run); `STEP_OK n …` =
one synthetic input interaction verified.

## Version-control authority

- Remote: never touched by agents. **No pushes, ever, from agent sessions.**
- Commits: coordinator (aldrich-games) alone lands local commits, after reviewing a
  prepared diff + commit plan. Agents prepare; they do not commit or stage.
- The board (kanban, tenant `wardens`) is the work-assignment surface; process layer
  itself arrived via board card and is coordinator-landed like everything else.

## Required takeover packet

Before making any claim about the project, a new agent must have:

1. `git log --oneline -5` and `git status` — confirm you are on the recorded baseline
   with a clean tree.
2. README.md read in full — it is the source of truth for shipped behavior.
3. docs/conventions.md read in full — vocabulary + style + art policy.
4. ../AGENTS.md read in full — headless test commands, hard rules, future-don't-scaffold
   list.
5. A green local run of the three suites (RULES_OK, SMOKE_OK, MATCH_OK).
6. docs/ASSET_SOURCES.md — what art may ship and what may not.

## Immediate next actions (in order)

0. **Creator review of the live Option B screenshots (GW-AA pass 3)**, then (only
   after that review) the parked Asset Gen work: 640x360 mood backdrop upscales
   recomposed for the Option B framing, sand/stone felt tiles; then cloud/sun tuning.
1. **Creator playtest of levels 1-8** (8 is the "The Whole Cast" showcase) with
   felt-feedback notes (pacing, difficulty curve, which tools feel dead, whether the
   showcase's cone hop reads). This gates everything below.
2. **README drift (creator-approved updates; agents did not touch README per policy)**:
   - "level 1 of 7" is stale — level 8 ("The Whole Cast") is in the catalog.
   - "Flies and ladybugs walk straight" needs the hop-over exception (AW-5b).
   - The backdrop paragraph describes the old Hills/draft-gardens cycle with a
     remembered choice; it is now the seeded 4-look catalog + Golden Hour tour stop
     (AW-6a superseded it by order; the old `user://backdrop.cfg` memory is gone).
   - AW-6a parked calls: Golden Hour ray spin sign (clockwise; one-constant flip),
     seed watermark always-on (debug-gateable), per-wheel vs post-composite mask.
   - AW-6b parked call: sunny/main moods show a baked-in celestial plus the dynamic
     sun — a one-line SkyLook suppression rule is ready if wanted.
3. **Data-format pass** — move const costs and the eight level definitions from
   GDScript (`src/rules/unit_catalog.gd`, `src/rules/level_catalog.gd`) into data
   files. Do this **after** the playtest, so the playtest's numeric feedback lands
   in the new format in one pass instead of two.
4. **Mobile**: `export_presets.cfg` still does not exist (verified at `86efd22`).
   The phone claim is layout-only (landscape stretch, the Option B perspective lawn,
   the vertical card side bar on small windows; far-rail cells are under 64 px deep
   at 1280x720). Do not echo a "runs on phone" claim beyond that.
5. **Save file**: level progress does not survive restart. A real save file belongs
   in the project before any ship talk.

## NEEDS COORDINATOR LANDING

> No AGENTS.md changes are proposed. The three headless test invocations documented
> in AGENTS.md ("Running the checks headless") remain accurate at baseline `86efd22`
> — the chain added no new test scripts, so the same three commands (rules_test,
> smoke, match_test) are the full gate — and no other AGENTS.md line is affected by
> the asset-wiring work. If the coordinator disagrees, the exact proposed lines
> belong here before landing.
