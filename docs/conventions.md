# Conventions

Garden Wardens is a 2D lane-defense game made with Godot 4.6 and GDScript. The current scene is a short playable match: place Wardens, spend water, and stop one wave of Vermin.

## Vocabulary

- **Wardens** are the living plants that defend the garden.
- **Vermin** are the corrupted creatures that cross the lawn. The first cast is insects.
- **Blight** is the corruption that affects the Vermin. It is story language, not a system yet.
- **Water** is the placement resource.

Campaign progression, roguelite runs, drafting, soil, abilities, synergies, and runes are future ideas. Do not add placeholder scripts for them.

## Code

- GDScript is typed. Use tabs.
- Give a `class_name` to a node other scenes reuse.
- Start each script with a `##` summary. Document public methods the same way.
- Keep a scene and its script in the same folder.
- Placement, water, cooldowns, and row targeting live in `src/rules/` so tests can run them without the lawn.
- Demo costs and the wave live in `src/rules/unit_catalog.gd`. The board in `src/prototype/garden_board.gd` ticks the match.
- Do not add an autoload until two scenes need the same long-lived service.

## Art

- External art has to be free to use in a commercial game. Prefer CC0.
- Record every pack in `docs/ASSET_SOURCES.md`, including the license text that shipped with the files.
- Do not generate raster images with AI, and do not buy asset packs.
- The New Platformer Pack is the visual source. Do not mix in older Kenney packs or pixel art.
- Sprites use linear filtering and one shared scale.
- If a role has no sprite, show a labeled placeholder. Do not substitute a humanoid or an unrelated icon.

## Input and layout

- Design size is 1280×720, landscape, with the Compatibility renderer.
- Touch and mouse share one path: the project emulates mouse events from touch.
- Buttons and cards are at least 64 pixels on their short side.
- The board keeps square cells and stays the largest part of the screen.
