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
  - Board end pieces (player porch, vermin compost eyes), win/loss banners, logo in
    the top bar, wave flag in the wave roster, seed-packet card faces + placement ghost.
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
  - Screenshot helpers: `--result-shot win|loss`, `--fall-shot <path>`,
    `--play-shot <path>`.
- Art status: docs/ASSET_SOURCES.md now carries per-asset approved/unwired statuses
  and the definitive unwired inventory (395 files, including `summon_bell.png`).
- Checks: the full gate is the 3 suites + 3 probes — see the Verification playbook
  below (it supersedes the suites-only commands in ../AGENTS.md).

## Verification playbook

Binary: the MAIN exe `tools/godot/Godot_v4.6-stable_win64.exe` for every run,
headless or windowed. Pitfalls, both learned the hard way:
- Do NOT use `Godot_v4.6-stable_win64_console.exe` — under piped capture it
  silently returns exit 0 with no output.
- Do NOT pass `--quiet` — it mutes `print()`, so logs come back empty and every
  marker check becomes a false FAIL.

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
  Needle single-target kill, Seed Lobber same-tick multi-hit.
- Synthetic input: `... --path . res://tests/probes/input_probe.tscn` — WINDOWED
  only (real frame pacing drives the animation clock and viewport picking; this
  host has no xvfb, a brief visible window is normal and not a bug). Expect 10
  `STEP_OK` lines then `INPUT_PROBE_OK`; each step is one synthetic click/drag
  through `Input.parse_input_event()`.

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
   The phone claim is layout-only (landscape stretch, square cells, 64px touch
   targets). Do not echo a "runs on phone" claim beyond that.
5. **Save file**: level progress does not survive restart. A real save file belongs
   in the project before any ship talk.

## NEEDS COORDINATOR LANDING

> No AGENTS.md changes are proposed. The three headless test invocations documented
> in AGENTS.md ("Running the checks headless") remain accurate at baseline `86efd22`
> — the chain added no new test scripts, so the same three commands (rules_test,
> smoke, match_test) are the full gate — and no other AGENTS.md line is affected by
> the asset-wiring work. If the coordinator disagrees, the exact proposed lines
> belong here before landing.
