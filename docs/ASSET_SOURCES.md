# Asset sources

All art is AI-assisted papercraft, approved by Brandon (rounds 1-3e and animations v3, Nov 2026).

## Layout

- `assets/sprites/wardens/<needle_spitter|dew_dropper|rain_catcher|seed_lobber>/`
  Paper-texture touched-up loops that the game already uses: `frames/`, `frames.json`, idle still, strip and projectile sprites.
  These are byte-identical to the work PC install. Do not overwrite them.
- `assets/sprites/anim/wardens/<unit>/` (the 4 Wardens + `stubborn_cone`) and
  `assets/sprites/anim/vermin/<fly|bee|ladybug|snail|grub>/`
  v3 stop-motion sets at 10 fps: `<anim>/<state>/` frames (`100`, `66`, `33` = health), one strip per state, `frames.json`, and `fx/` where the unit has one.
  Wardens: idle, action, hurt, place (100 only), death (33 only). Vermin: idle, move, action, hurt, spawn, death (33 only). The Bee adds rise and drop, and the Ladybug adds `flutter_takeoff`, `flutter_air` and `flutter_land`. The hop-over arc is in `ladybug/frames.json` under `hop_over`.
  Contact sheets named in `frames.json` were left out on purpose.
- `assets/sprites/anim/fx/poof/`: the defeat poof (8 frames).
- `assets/art/environment/`
  - `backdrops/`: main backdrop, with and without the sun, plus moods 1 sunny, 3 overcast and 4 dusk (no clouds, suns and moon restored). Mood 2 is Golden Hour.
  - `golden_hour/`: Golden Hour boss backdrop as layers (ray origin D). Draw order and rotation are in `golden_hour_layers.json`.
  - `board/`: board v1 and vermin end 4 (both with compost eyes), plus player end 1 (porch).
- `assets/art/sky/`
  - `clouds/{small,medium,large}/`: each cloud comes as `<name>.png` and `<name>_stick.png` (with its white stick).
  - `clouds/sticks/`: separate stick tiles.
  - `suns/`: suns 1, 2, 5, 6 and 8.
  - `rain/`: the approved rain set.
- `assets/art/ui/`: logo 2, win banners 1 and 2 (`win_banner_A` and `win_banner_B`, used interchangeably), wave flag 5, loss banner 4, summon bell (optional, for later), and `seed_packets/` (packet 2 with the stickers scaled to fit).
- `assets/art/fx/`
  - `A1` paper-airplane projectile
  - `A3` impact burst
  - `A4` small burst
  - `A6` cellophane slime trail (snail)
  - `A7` defeat poof
  - `A8` small poof / paper wad
  - `B2` parachute gem drop
  - `B3` collect flecks
  - `B5` placement hover (leaf ring with a ghost sticker)
  - `B6` can't-place hover
  - `leaf_ring_rotating.png`
  - `water/`: the origami water set
- `assets/art/_unsure/lineup/`: Round 3 base sticker stills for all 10 units, for reference only. The animation folders above supersede them.

## Not included

Preview videos, GIFs, contact sheets, review pages and generator scripts stay in the art workspace.
