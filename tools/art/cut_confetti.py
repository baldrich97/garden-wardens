"""Cuts the paper confetti pieces (squares, diamonds, leaves) out of the win
banner art (assets/art/ui/win_banner_A.png, concept "Win with confetti D3")
into assets/art/fx/confetti/confetti_XX.png for the placement burst
(GW-AA pass 5). Each piece keeps its white sticker rim.

Run from the repo root:  python3 tools/art/cut_confetti.py
"""
import os
from collections import deque
from PIL import Image, ImageFilter

SRC = "assets/art/ui/win_banner_A.png"
OUT = "assets/art/fx/confetti"
RIM = 3
# Hand-picked boxes (source pixels, 407x330) around each loose piece.
BOXES = [
    ("red_square", (78, 3, 135, 57)),
    ("red_chip", (115, 63, 155, 102)),
    ("blue_diamond", (165, 30, 215, 82)),
    ("yellow_square", (218, 5, 275, 62)),
    ("blue_card", (283, 23, 337, 75)),
    ("blue_chip", (343, 65, 387, 115)),
    ("leaf_left", (33, 53, 97, 117)),
    ("yellow_chip", (60, 265, 102, 310)),
    ("blue_tall", (115, 238, 172, 307)),
    ("yellow_chip_b", (258, 223, 307, 270)),
    ("leaf_bottom", (188, 235, 262, 310)),
    ("leaf_right", (303, 238, 382, 312)),
]


def largest_component(img):
    w, h = img.size
    px = img.load()
    seen = [[False] * w for _ in range(h)]
    best = []
    for y in range(h):
        for x in range(w):
            if seen[y][x] or px[x, y][3] < 40:
                continue
            comp = []
            q = deque([(x, y)])
            seen[y][x] = True
            while q:
                cx, cy = q.popleft()
                comp.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and px[nx, ny][3] >= 40:
                        seen[ny][nx] = True
                        q.append((nx, ny))
            if len(comp) > len(best):
                best = comp
    return set(best)


def main():
    src = Image.open(SRC).convert("RGBA")
    os.makedirs(OUT, exist_ok=True)
    for i, (label, box) in enumerate(BOXES):
        crop = src.crop(box)
        # The piece itself is the saturated paper; its rim is the white
        # sticker margin within RIM px of it (so the banner's shared margin
        # never comes along as a straight edge).
        hsv = crop.convert("RGB").convert("HSV")
        sat = Image.new("L", crop.size, 0)
        sp, hp, cp = sat.load(), hsv.load(), crop.load()
        for y in range(crop.size[1]):
            for x in range(crop.size[0]):
                if cp[x, y][3] > 200 and hp[x, y][1] > 70:
                    sp[x, y] = 255
        core = Image.new("RGBA", crop.size, (0, 0, 0, 0))
        core.putalpha(sat)
        keep = largest_component(core)
        solid = Image.new("L", crop.size, 0)
        kp = solid.load()
        for (x, y) in keep:
            kp[x, y] = 255
        solid = solid.filter(ImageFilter.MaxFilter(3))  # close tiny holes
        rim = solid.filter(ImageFilter.MaxFilter(2 * RIM + 1)).filter(ImageFilter.GaussianBlur(0.8))
        out = Image.new("RGBA", crop.size, (0, 0, 0, 0))
        op, rp = out.load(), rim.load()
        for y in range(crop.size[1]):
            for x in range(crop.size[0]):
                r, g, b, a = cp[x, y]
                op[x, y] = (r, g, b, min(a, rp[x, y]))
        bbox = out.getbbox()
        if bbox:
            out = out.crop(bbox)
        name = os.path.join(OUT, "confetti_%02d_%s.png" % (i + 1, label))
        out.save(name)
        print(name, out.size)


if __name__ == "__main__":
    main()
