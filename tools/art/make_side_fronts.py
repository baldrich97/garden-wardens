"""Builds the side panels' front layers (GW-AA pass 7b).

The game draws `stage/<scene>/side_{left,right}_front.png` over the runtime
clouds so clouds pass behind the side shack, the way they pass behind the
stage's shack plate. The fronts start from Asset Gen's batch3_v3 `_ground`
splits, but those are colour-keyed per scene and leave holes in the shack
(e.g. the eave row at y ~115-125 on the left), where a drifting cloud showed
through. So the left front also takes the shack's silhouette, measured once
from Main's split (all six scenes share the layout): for every row above the
lawn, everything from the shack's left edge to the stage edge is opaque. The
roof rows (above the eave, y < 100) take the leftmost opaque pixel of Main's
split (min over +-2 rows); from the eave down the wall's outer edge is a
straight x = 735, so the fence and trees left of the shack stay clear. Above the lawn the
left front is the shack silhouette only. Pixels always come from the combined `side_*.png`, so
the front repeats the panel exactly; only its alpha differs from `_ground`.

Usage: python tools/art/make_side_fronts.py <batch3_v3 kit dir> <repo root>
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

SCENES = ["main", "sunny", "overcast", "dusk_twilight", "dusk_moonlit", "golden_hour"]
SHACK_X0 = 600      # search window for the shack on the 960 px left panel
LAWN_Y = 300        # the splits are fully opaque from here down
ROW_SPAN = 2
EAVE_Y = 100        # below this the shack wall is a straight edge
WALL_X = 735        # the wall's outer edge on the left panel (Main, all scenes)


def shack_left_edges(main_ground: np.ndarray) -> list:
    alpha = main_ground[:, :, 3] > 0
    edges = []
    for y in range(LAWN_Y):
        xs = np.where(alpha[y, SHACK_X0:])[0]
        edges.append(int(xs[0]) + SHACK_X0 if len(xs) else None)
    out = []
    for y in range(LAWN_Y):
        if y >= EAVE_Y:
            out.append(WALL_X)
            continue
        near = [e for e in edges[max(0, y - ROW_SPAN):y + ROW_SPAN + 1] if e is not None]
        out.append(min(near) if near else None)
    return out


def main() -> None:
    kit, repo = Path(sys.argv[1]), Path(sys.argv[2])
    edges = shack_left_edges(np.array(Image.open(kit / "main/side_left_ground.png").convert("RGBA")))
    for scene in SCENES:
        for side in ("left", "right"):
            full = np.array(Image.open(kit / scene / f"side_{side}.png").convert("RGBA"))
            ground = np.array(Image.open(kit / scene / f"side_{side}_ground.png").convert("RGBA"))
            alpha = ground[:, :, 3].copy()
            if side == "left":
                # Above the lawn only the shack is in front: the split's stray
                # fence and tuft bits there would hide clouds in a hard-edged
                # block (clouds never hang below y ~220).
                alpha[:LAWN_Y, :] = 0
                for y, x0 in enumerate(edges):
                    if x0 is not None:
                        alpha[y, x0:] = 255
            front = full.copy()
            front[:, :, 3] = np.where(alpha > 0, full[:, :, 3], 0)
            out = repo / "assets/art/environment/stage" / scene / f"side_{side}_front.png"
            Image.fromarray(front).save(out, optimize=True)
            print(out, int((alpha > 0).sum()))


if __name__ == "__main__":
    main()
