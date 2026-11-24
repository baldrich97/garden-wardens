"""GW-AA pass 6: clean the sky Golden Hour shows through the porch opening.

Asset Gen's batch2 golden_hour/sky_backdrop.png still carries a ghost of the
porch opening behind the shack (a peach patch with a dark teal outline at about
x 88-120, y 100-132). Only the part the punched porch opening reveals is touched:
inside the shack plate's transparent opening (x 86..122, y 96..134), every pixel
becomes that row's median peach sky colour (sampled from x 0..180), blended back
to the original over the last 6 rows so the trees below stay as painted.

Usage (repo root): python tools/art/clean_golden_porch_sky.py
"""
import numpy as np
from PIL import Image

SKY = "assets/art/environment/stage/golden_hour/sky_backdrop.png"
SHACK = "assets/art/environment/stage/golden_hour/stage_shack.png"
X0, X1, Y0, Y1, FADE = 86, 122, 96, 134, 6


def main():
    im = Image.open(SKY).convert("RGBA")
    a = np.array(im).astype(float)
    shack = np.array(Image.open(SHACK).convert("RGBA"))[:, :, 3]
    lum = a[:, :, :3].sum(2)
    changed = 0
    for y in range(Y0, Y1 + 1):
        row = a[y, 0:180, :3][lum[y, 0:180] > 550]
        if len(row) == 0:
            continue
        peach = np.median(row, axis=0)
        w = 1.0 if y <= Y1 - FADE else (Y1 - y) / float(FADE)
        for x in range(X0, X1 + 1):
            if shack[y, x] < 8:
                a[y, x, :3] = a[y, x, :3] * (1 - w) + peach * w
                changed += 1
    Image.fromarray(a.round().clip(0, 255).astype(np.uint8)).save(SKY)
    print("cleaned", changed)


if __name__ == "__main__":
    main()
