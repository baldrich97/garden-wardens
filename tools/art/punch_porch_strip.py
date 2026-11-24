"""GW-AA pass 6: finish the porch-opening punch on Asset Gen's batch2 shack plates.

The batch2 stage_shack.png plates punch the porch opening (x ~90-118) above and
below a ~26 px opaque strip (y ~148-176) that still carries baked background;
on both Dusk plates that strip holds a glowing string-light bulb, which floats
inside the porch. This clears that strip (only rows that sit between two
transparent runs in the same column, gap < 40 px, x 86..122) so the sky
backdrop shows through the whole opening.

Usage (from the repo root, on the original batch2 plates):
  python tools/art/punch_porch_strip.py            # all six scenes
Pass 6 ran it once; the Dusk plates also get paint_out_bulb() (radius 12 on
dusk_twilight, 22 on dusk_moonlit, whose glow is wider).
"""
import sys
import numpy as np
from PIL import Image

X0, X1 = 86, 122
Y0, Y1 = 80, 240
MAX_GAP = 40


def punch(path):
    im = Image.open(path).convert("RGBA")
    a = np.array(im)
    alpha = a[:, :, 3]
    cleared = 0
    for x in range(X0, X1 + 1):
        t = np.where(alpha[Y0:Y1, x] < 8)[0] + Y0
        if len(t) < 2:
            continue
        for g in np.where(np.diff(t) > 1)[0]:
            y0, y1 = t[g] + 1, t[g + 1]
            if y1 - y0 < MAX_GAP:
                a[y0:y1, x, 3] = 0
                cleared += y1 - y0
    Image.fromarray(a).save(path)
    return cleared



# The Dusk plates (dusk_twilight, dusk_moonlit) also carry a string-light bulb
# baked onto the porch post at about (118, 168); with the strip cleared it is a
# half-glow on the post's edge. paint_out_bulb() repaints the post there from the
# nearest same-column post pixels above/below the glow (linear blend between them),
# feathered over BULB_R..BULB_R + 6 px.
BULB = (118, 168)
BULB_R = 12


def paint_out_bulb(path):
    im = Image.open(path).convert("RGBA")
    a = np.array(im).astype(float)
    out = a.copy()
    cx, cy = BULB
    reach = BULB_R + 6
    for x in range(cx - reach, cx + reach + 1):
        for y in range(cy - reach, cy + reach + 1):
            if a[y, x, 3] < 8:
                continue
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if d > reach:
                continue
            w = 1.0 if d <= BULB_R else 1.0 - (d - BULB_R) / 6.0
            up = next((yy for yy in range(cy - reach - 1, cy - reach - 30, -1) if a[yy, x, 3] > 200), None)
            dn = next((yy for yy in range(cy + reach + 1, cy + reach + 30) if a[yy, x, 3] > 200), None)
            if up is None and dn is None:
                continue
            if up is None:
                src = a[dn, x, :3]
            elif dn is None:
                src = a[up, x, :3]
            else:
                k = (y - up) / float(dn - up)
                src = a[up, x, :3] * (1 - k) + a[dn, x, :3] * k
            out[y, x, :3] = a[y, x, :3] * (1 - w) + src * w
    Image.fromarray(out.round().clip(0, 255).astype(np.uint8)).save(path)


SCENES = {"main": 0, "sunny": 0, "overcast": 0, "golden_hour": 0, "dusk_twilight": 12, "dusk_moonlit": 22}

if __name__ == "__main__":
    for scene, radius in SCENES.items():
        path = "assets/art/environment/stage/%s/stage_shack.png" % scene
        print(path, punch(path))
        if radius:
            BULB_R = radius
            paint_out_bulb(path)
