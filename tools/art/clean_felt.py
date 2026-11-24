"""Build the clean felt board texture the perspective lawn samples
(GW-AA pass 4, "felt looks patchy/pixelated").

Root cause of the patchy look: the lawn sampled the 955x354 felt frame baked
into board_v1_compost_eyes.png and stretched it to ~1200 px on the front rail.
That composite carries fibre noise, JPEG-style blocking and stair-stepped tile
edges at 1x, so the 1.26x magnification showed them as blotches and jaggies.

This script crops the same frame (plus a margin), upscales it 2x with Lanczos,
smooths the fibre noise inside each tile with an edge-preserving filter,
re-sharpens the bevel seams, and adds back a fine, even felt grain so the board
reads tactile instead of plastic. Output: assets/art/environment/board/
felt_board_clean.png at 2x the source pixel scale; LawnView.FELT_SRC_ORIGIN /
FELT_SRC_SCALE map board-composite pixels into it.

Usage (repo root): python tools/art/clean_felt.py   (needs opencv-python, numpy)
"""
import os
import cv2
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "assets/art/environment/board/board_v1_compost_eyes.png")
OUT = os.path.join(ROOT, "assets/art/environment/board/felt_board_clean.png")
# Board frame in the composite (LawnView.BOARD_FRAME_SRC) plus a margin.
FRAME = (149, 334, 955, 354)
MARGIN = 4
SCALE = 2


def main():
    img = cv2.imread(SRC, cv2.IMREAD_COLOR)
    x, y, w, h = FRAME
    crop = img[y - MARGIN:y + h + MARGIN, x - MARGIN:x + w + MARGIN]
    big = cv2.resize(crop, None, fx=SCALE, fy=SCALE, interpolation=cv2.INTER_LANCZOS4)
    # Edge-preserving smoothing: flattens the blotchy fibre noise inside each
    # tile while the tile-to-seam steps (large colour jumps) survive.
    smooth = big
    for _ in range(3):
        smooth = cv2.bilateralFilter(smooth, d=9, sigmaColor=18, sigmaSpace=6)
    # Re-crisp the seams: unsharp mask on the smoothed image.
    blur = cv2.GaussianBlur(smooth, (0, 0), 2.0)
    sharp = cv2.addWeighted(smooth, 1.45, blur, -0.45, 0)
    # Even felt grain: fine, low-amplitude noise, slightly stretched so it
    # reads as fibre rather than digital speckle. Seeded, so reruns match.
    rng = np.random.default_rng(20261123)
    grain = rng.normal(0.0, 1.0, sharp.shape[:2]).astype(np.float32)
    grain = cv2.GaussianBlur(grain, (0, 0), 0.8)
    grain = cv2.resize(cv2.resize(grain, None, fx=0.5, fy=1.0), (sharp.shape[1], sharp.shape[0]))
    grain = grain / max(grain.std(), 1e-6) * 2.6
    out = np.clip(sharp.astype(np.float32) + grain[..., None], 0, 255).astype(np.uint8)
    cv2.imwrite(OUT, out)
    print("wrote %s %dx%d origin (%d, %d) scale %d" % (
        OUT, out.shape[1], out.shape[0], x - MARGIN, y - MARGIN, SCALE))


if __name__ == "__main__":
    main()
