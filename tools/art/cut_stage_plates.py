"""Cut the shared stage plates (fence, shack, compost, lawn ground) out of the
Main backdrop, so every mood keeps the same set while only the sky backdrop
swaps (GW-AA pass 4, Brandon: "the background is one piece, fence area
another, and the shack/compost are also separate").

Stop-gap until Asset Gen paints dedicated per-slot art: the plates are exact
pixel cut-outs of main_noclouds_nosun.png (1280x720, stage coordinates), so
Main looks identical with or without them. See docs/ASSET_SOURCES.md
"Stage layer slots" for the slot contract.

Usage (from the repo root):  python tools/art/cut_stage_plates.py
Needs Pillow, numpy and scipy.
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "assets/art/environment/backdrops/main_noclouds_nosun.png")
OUT = os.path.join(ROOT, "assets/art/environment/stage")
W, H = 1280, 720

# Fence picket line: everything at or below this is fence/ground; picket tips
# and sunflower heads above it are added by colour.
FENCE_LINE_Y = 219
TIP_BAND = (176, FENCE_LINE_Y)
# Tree trunks behind the fence (stage x ranges): never picket tips.
TRUNK_SPANS = [(196, 262), (1180, 1232)]
# The fence plate ends here; the lawn ground plate starts here.
GROUND_Y = 300
# Overlap between neighbouring plates (identical pixels), so linear filtering
# never opens a hairline seam where two plates meet.
OVERLAP = 3

# Shack (porch) silhouette, stage pixels.
SHACK_POLY = [(0, 0), (97, 0), (176, 72), (176, 104), (147, 104), (147, 284),
              (168, 292), (168, 368), (0, 368)]
# Compost heap silhouette, stage pixels.
COMPOST_POLY = [(1072, 352), (1080, 318), (1098, 292), (1122, 270), (1146, 250),
                (1166, 234), (1190, 226), (1218, 224), (1246, 228), (1268, 236),
                (1280, 240), (1280, 430), (1072, 430)]


def poly_mask(points):
    img = Image.new("L", (W, H), 0)
    ImageDraw.Draw(img).polygon(points, fill=255)
    return np.array(img) > 127


def main():
    src = Image.open(SRC).convert("RGBA")
    rgb = np.array(src.convert("RGB")).astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    yy, xx = np.mgrid[0:H, 0:W]
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    sat = (mx - mn) / np.maximum(mx, 1.0)

    # Picket wood: warm brown/tan (red > green > blue, moderately saturated).
    wood = (r > 90) & (r > g + 12) & (g > b + 10) & (sat > 0.25) & (sat < 0.75)
    # Sunflower petals: saturated yellow/orange.
    petal = (r > 200) & (g > 140) & (b < 90)
    # Sticker outline: near white, low saturation.
    outline = (mn > 200) & (sat < 0.18)

    shack = poly_mask(SHACK_POLY)
    # Sky and the tree seen past the roof edge and the porch post are
    # backdrop, not shack.
    greenish = (g > r + 8) & (g >= b)
    bluish = b > r + 20
    shack &= ~((xx >= 95) & (yy < 290) & (greenish | bluish) & ~((xx < 120) & (yy > 100)))
    shack = ndimage.binary_opening(shack, iterations=1)
    compost = poly_mask(COMPOST_POLY)

    # 1. Fence body: everything from the picket line down.
    fence_body = yy >= FENCE_LINE_Y
    # 2. Picket tips: wood pixels in the tip band connected to the body.
    band = (yy >= TIP_BAND[0]) & (yy < TIP_BAND[1])
    tips = ndimage.binary_closing(ndimage.binary_opening(wood & band, iterations=1), iterations=1) & band
    for x0, x1 in TRUNK_SPANS:
        tips &= ~((xx >= x0) & (xx < x1))
    seed = np.zeros_like(tips)
    seed[FENCE_LINE_Y - 2:FENCE_LINE_Y, :] = True
    lab, n = ndimage.label(tips | (fence_body & (yy < FENCE_LINE_Y + 1)))
    keep_ids = set(np.unique(lab[seed & (lab > 0)]).tolist()) - {0}
    tips = np.isin(lab, list(keep_ids)) & band
    # Drop tree-trunk stubs: a tip wider than a picket is not a picket.
    tip_lab, tip_n = ndimage.label(tips)
    for i, sl in enumerate(ndimage.find_objects(tip_lab), start=1):
        if sl is None:
            continue
        width = sl[1].stop - sl[1].start
        if width > 40:
            tips[tip_lab == i] = False
    # 3. Sunflower heads: each petal blob filled as a disc, plus its outline and
    #    the stem down to the picket line.
    heads = np.zeros((H, W), bool)
    head_band = (yy > 140) & (yy < 270)
    plab, pn = ndimage.label(ndimage.binary_closing(petal & head_band, iterations=2))
    for i, sl in enumerate(ndimage.find_objects(plab), start=1):
        if sl is None:
            continue
        h = sl[0].stop - sl[0].start
        w = sl[1].stop - sl[1].start
        if h < 30 or w < 30:
            continue
        cy = (sl[0].start + sl[0].stop) / 2.0
        cx = (sl[1].start + sl[1].stop) / 2.0
        rad = max(h, w) / 2.0 + 4.0
        disc = (xx - cx) ** 2 + (yy - cy) ** 2 <= rad ** 2
        blob = ndimage.binary_fill_holes(plab == i)
        grown = ndimage.binary_dilation(blob, iterations=5)
        heads |= (blob | (grown & (outline | petal))) & disc
        stem = (np.abs(xx - cx) <= 6) & (yy >= cy) & (yy <= FENCE_LINE_Y + 2)
        heads |= stem & (g > r)
    heads = ndimage.binary_fill_holes(heads)

    set_mask = fence_body | tips | heads | shack | compost
    # Shack and compost plates own their silhouettes; fence is the band above
    # the ground line; ground is everything from GROUND_Y down.
    fence = set_mask & (yy < GROUND_Y) & ~shack & ~compost
    ground = set_mask & (yy >= GROUND_Y) & ~shack & ~compost

    def grow(m):
        return ndimage.binary_dilation(m, iterations=OVERLAP) & set_mask

    plates = {
        "stage_fence.png": grow(fence),
        "stage_shack.png": grow(shack),
        "stage_compost.png": grow(compost),
        "stage_lawn_ground.png": grow(ground),
    }
    os.makedirs(OUT, exist_ok=True)
    # Soft 1 px edge against the sky backdrop only (interior seams stay hard).
    outer = Image.fromarray((set_mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7))
    outer_a = np.array(outer).astype(np.float32) / 255.0
    outer_a = np.where(ndimage.binary_erosion(set_mask, iterations=2), 1.0, outer_a)
    for name, mask in plates.items():
        alpha = np.where(mask, outer_a, 0.0)
        ys, xs = np.nonzero(alpha > 0.0)
        x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
        rgba = np.dstack([rgb, alpha * 255.0]).astype(np.uint8)
        Image.fromarray(rgba, "RGBA").crop((x0, y0, x1, y1)).save(os.path.join(OUT, name))
        print("%s offset (%d, %d) size (%d, %d)" % (name, x0, y0, x1 - x0, y1 - y0))


if __name__ == "__main__":
    main()
