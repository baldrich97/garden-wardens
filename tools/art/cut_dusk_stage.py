"""Builds the Dusk stage from the Dusk mood backdrop (GW-AA pass 5).

The Dusk backdrop (mood_4_dusk_noclouds.png, 640x360) paints its own
string-light fence and porch about 140 stage px lower than the Main backdrop,
so the shared Main set plates used to hide its fence completely. This script
lifts the Dusk art so its fence stands on the Main fence line and cuts the
Dusk set plates from it, so Dusk keeps its own fence:

  backdrops/mood_4_dusk_stage.png    1280x720, lifted SHIFT px, moon removed
                                     (the moon becomes a sky prop instead)
  stage/dusk/stage_shack.png         same rect as stage/stage_shack.png

The Dusk fence plate itself is Asset Gen's (batch 1: stage/dusk/stage_fence.png
and stage_fence_lights.png, cut from the same art lifted the same 141 px).
  ../sky/moon/dusk_moon.png          the paper crescent moon, cut out

Sky pixels in the plates are made transparent so clouds still pass behind
the set. Run from the repo root:  python3 tools/art/cut_dusk_stage.py
"""
import os
from PIL import Image

ENV = "assets/art/environment"
SRC = ENV + "/backdrops/mood_4_dusk_noclouds.png"
OUT_BACKDROP = ENV + "/backdrops/mood_4_dusk_stage.png"
OUT_DIR = ENV + "/stage/dusk"
OUT_MOON = "assets/art/sky/moon/dusk_moon.png"
STAGE = (1280, 720)
SHIFT = 141
# Plate rects (stage px), matching BackdropCatalog's shared plates.
FENCE_RECT = (145, 166, 145 + 1135, 166 + 137)
SHACK_RECT = (0, 0, 173, 372)
# The moon in the unshifted 1280x720 Dusk art. The sky column just right of
# it (always open sky) is the reference used to cut and paint it out; the
# left side runs into the tree crown.
MOON_BOX = (286, 10, 432, 158)
SKY_REF_X = 640
SKY_ROWS = 120  # rows (shifted) where the reference column is still sky
SKY_TOL = 24


def dist(a, b):
    return sum((int(x) - int(y)) ** 2 for x, y in zip(a[:3], b[:3])) ** 0.5


def is_leaf(p):
    # The tree crown that reaches under the moon's lower left: keep it.
    return p[1] > p[0] + 8 and p[1] >= p[2]


def sky_reference(img):
    px = img.load()
    return [px[SKY_REF_X, y] for y in range(SKY_ROWS)]


def main():
    big = Image.open(SRC).convert("RGBA").resize(STAGE, Image.LANCZOS)
    # 1) The moon sprite, cut from the unshifted art by its difference from
    #    the sky just left and right of it.
    bp = big.load()
    mx0, my0, mx1, my1 = MOON_BOX
    moon = Image.new("RGBA", (mx1 - mx0, my1 - my0), (0, 0, 0, 0))
    mp = moon.load()
    for y in range(my0, my1):
        sky = bp[mx1 + 4, y]
        for x in range(mx0, mx1):
            if is_leaf(bp[x, y]):
                continue
            d = dist(bp[x, y], sky)
            a = max(0, min(255, int((d - 10) * 255 / 30)))
            if a:
                r, g, b, _ = bp[x, y]
                mp[x - mx0, y - my0] = (r, g, b, a)
    bbox = moon.getbbox()
    moon = moon.crop(bbox) if bbox else moon
    os.makedirs(os.path.dirname(OUT_MOON), exist_ok=True)
    moon.save(OUT_MOON)
    # 2) Paint the moon out of the sky (each row takes the open sky beside
    #    it), leaving anything that is not moon (the tree crown) alone.
    for y in range(my0, my1):
        sky = bp[mx1 + 4, y]
        for x in range(mx0, mx1):
            if mp[x - mx0, y - my0][3] > 0:
                bp[x, y] = sky[:3] + (255,)
    # 3) Lift it so the fence stands on the Main fence line; the rows the lift
    #    uncovers at the bottom repeat the last row (the lawn covers them).
    stage = Image.new("RGBA", STAGE, (0, 0, 0, 255))
    stage.paste(big.crop((0, SHIFT, STAGE[0], STAGE[1])), (0, 0))
    last = big.crop((0, STAGE[1] - 1, STAGE[0], STAGE[1]))
    for y in range(STAGE[1] - SHIFT, STAGE[1]):
        stage.paste(last, (0, y))
    stage.convert("RGB").save(OUT_BACKDROP)
    # 4) Plates: exact cuts of the lifted stage, sky made transparent.
    ref = sky_reference(stage)
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, rect in (("stage_shack.png", SHACK_RECT),):
        plate = stage.crop(rect).convert("RGBA")
        pp = plate.load()
        for y in range(plate.size[1]):
            sy = y + rect[1]
            if sy >= SKY_ROWS:
                break
            for x in range(plate.size[0]):
                if dist(pp[x, y], ref[sy]) < SKY_TOL:
                    pp[x, y] = (0, 0, 0, 0)
        plate.save(os.path.join(OUT_DIR, name))
        print(name, plate.size)
    print(OUT_BACKDROP, OUT_MOON, moon.size)


if __name__ == "__main__":
    main()
