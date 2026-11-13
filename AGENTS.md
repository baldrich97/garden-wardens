# AGENTS.md — Garden Wardens agent process layer

How to work on this repo as an agent. Style, vocabulary, art and layout rules live in
[docs/conventions.md](docs/conventions.md) — read it; this file does not duplicate it.
Current status and next actions live in [docs/AGENT_HANDOFF.md](docs/AGENT_HANDOFF.md).

## Baseline

- HEAD baseline: `44fabb91cb4f390d50a08dcfa251875b93c703ce` (7-level campaign landed as local commits).
- Everything on top of baseline arrives the same way: agent prepares → coordinator reviews → coordinator commits.

## Running the checks headless

From the repo root, with the Godot 4.6 console binary (set `GODOT_BIN`, or use the
locally downloaded `tools/godot/Godot_v4.6-stable_win64_console.exe`):

```
"$GODOT_BIN" --headless --path . --import
"$GODOT_BIN" --headless --path . --script res://tests/rules_test.gd   # expect RULES_OK
"$GODOT_BIN" --headless --path . --script res://tests/smoke.gd        # expect SMOKE_OK
"$GODOT_BIN" --headless --path . --script res://tests/match_test.gd   # expect MATCH_OK
```

Run these commands directly. `tools/run_tests.ps1` wraps exactly this, but PowerShell
invocations trip headless agent approval filters — do not route around the filter, just
run the underlying commands and disclose that you did. A green suite means all three
markers printed; a missing marker is a failure even if the exit code looks odd.

## Source of truth

When documents disagree, trust in this order:

1. **README.md feature claims** — the intended shipped behavior per level and mechanic.
2. **docs/conventions.md** — style, vocabulary, art policy.
3. **Code** — implementation detail; when code and README disagree, the code is the bug
   (or the README needs a creator-approved update, never a silent agent rewrite).

## Hard rules

- Typed GDScript, tabs, `##` doc summaries — full list in docs/conventions.md §Code.
- Game logic stays in `src/rules/` so headless tests can run it without the lawn scene.
- No autoload until two scenes need the same long-lived service.
- External art is CC0-or-labeled-placeholder only; every pack recorded in
  docs/ASSET_SOURCES.md with its license text.
- The four backdrop JPEG drafts are AI-generated, labeled, **non-ship** — they exist only
  to feel out composition and must be regenerated from scratch before any ship claim.
  No other AI raster images.

## VCS safety

- **NEVER push to origin.** No remote operations of any kind from agent sessions.
- Agents do not commit and do not stage. Local commits exist only after the coordinator
  (aldrich-games on the kanban board) reviews the prepared diff set and lands them.
- Creator gates: the creator (board tenant owner) approves playtest-driven behavior
  changes, art-pass timing, and anything labeled "future" below before it is touched.

## Explicitly future — do not scaffold

These are ideas with zero code credit. Do not create placeholder scripts, scenes,
enums, or catalog entries for any of them:

- Campaign meta-progression
- Roguelite runs
- Card drafting
- Abilities (the Ability button is intentionally inert)
- Synergies
- Runes
- Blight as a system (it is story language only)

docs/conventions.md §Vocabulary carries the same boundary; if this list changes, change
both.
