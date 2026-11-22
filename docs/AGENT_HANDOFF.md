# AGENT_HANDOFF.md — Garden Wardens takeover packet

Read this first when picking up the project. Process rules are in
[../AGENTS.md](../AGENTS.md); style/art rules in [conventions.md](conventions.md).

## Current snapshot (post-landing)

- Baseline: `44fabb91cb4f390d50a08dcfa251875b93c703ce` — the uncommitted 7-level campaign
  pass landed as local commits (rules systems, board/UX, vermin/warden behaviors +
  levels, tests, docs + asset provenance).
- Contents: 7 levels, 5 Wardens (Dew Dropper, Rain Catcher, Needle Spitter, Seed Lobber,
  Stubborn Cone), 5 Vermin (Fly, Bee, Ladybug, Snail, Grub), soil kinds (regular/sand/stone),
  droplets, speed/pause/remove tools, vermin side panel, tooltips.
- Checks: rules + smoke + match suites green at baseline (see ../AGENTS.md for the
  headless commands).
- Art is template/placeholder (Kenney New Platformer Pack, CC0) plus four labeled
  AI-draft backdrops that are non-ship.

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

1. **Creator playtest of levels 1–7** with felt-feedback notes (pacing, difficulty
   curve, which tools feel dead). This gates everything below.
2. **Data-format pass** — move const costs and the seven level definitions from GDScript
   (`src/rules/unit_catalog.gd`, `src/rules/level_catalog.gd`) into data files. Do this
   **after** the playtest, so the playtest's numeric feedback lands in the new format in
   one pass instead of two.
3. **Art pass** replaces the labeled placeholders when the creator calls it. Placeholders
   are sanctioned policy until then — keep them labeled, do not improvise substitutions.
4. **Mobile**: `export_presets.cfg` does not exist yet. The phone claim is layout-only
   (landscape stretch, square cells, 64px touch targets). Do not echo a "runs on phone"
   claim beyond that.
5. **Save file**: level progress is a static var — it does not survive restart. A real
   save file belongs in the project before any ship talk.
