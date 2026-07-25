#!/usr/bin/env python3
"""Regenerates game/assets/sprites/player.png through the shared pipeline -
issue #13. Hero asset: gets real directional shading per body part (all
consistent with the same upper-left light source), not just a recolor of
the old flat-plus-noise placeholder. Layout (3 facing rows x 2 frame
columns, 16x24 cells) is unchanged - only the pixels change.
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent.parent))
import palette  # noqa: E402
import shading  # noqa: E402

CW, CH = 16, 24
OUT = Path(__file__).parent.parent.parent.parent / "game" / "assets" / "sprites" / "player.png"

FACE_DOT = palette.HIDE["shadow"]


def draw_body(cell, facing, step):
    leg_off = 1 if step == 1 else 0

    # Legs (pants) + boots.
    shading.apply_edge_shading(cell, (5, 18, 7, 22 - leg_off), palette.CLOTH_COOL)
    shading.apply_edge_shading(cell, (9, 18 + leg_off, 11, 22), palette.CLOTH_COOL)
    shading.apply_edge_shading(cell, (5, 21 - leg_off, 7, 23 - leg_off), palette.HIDE)
    shading.apply_edge_shading(cell, (9, 21 + leg_off, 11, 23), palette.HIDE)

    # Torso (tunic) + belt.
    shading.apply_edge_shading(cell, (4, 10, 12, 19), palette.CLOTH_WARM)
    for x in range(4, 12):
        cell.putpixel((x, 13), (*palette.HIDE["dark"], 255))

    # Arms (sleeves).
    shading.apply_edge_shading(cell, (3, 11, 4, 17), palette.CLOTH_WARM)
    shading.apply_edge_shading(cell, (12, 11, 13, 17), palette.CLOTH_WARM)

    # Head (skin).
    shading.apply_edge_shading(cell, (4, 3, 12, 11), palette.SKIN)

    # Hair fringe under the helmet.
    for x in range(4, 12):
        for y in (2, 3):
            cell.putpixel((x, y), (*palette.BONE["base"], 255))

    # Helmet + brim.
    shading.apply_edge_shading(cell, (3, 1, 13, 5), palette.METAL, edge_width=1)
    for x in range(3, 13):
        cell.putpixel((x, 4), (*palette.METAL["dark"], 255))

    # Horns.
    shading.apply_edge_shading(cell, (1, 1, 3, 3), palette.BONE)
    shading.apply_edge_shading(cell, (13, 1, 15, 3), palette.BONE)

    if facing == "down":
        cell.putpixel((6, 7), (*FACE_DOT, 255))
        cell.putpixel((9, 7), (*FACE_DOT, 255))
    elif facing == "up":
        shading.apply_edge_shading(cell, (4, 5, 12, 11), palette.METAL)
    elif facing == "side":
        cell.putpixel((10, 7), (*FACE_DOT, 255))


def main():
    sheet = Image.new("RGBA", (CW * 2, CH * 3), (0, 0, 0, 0))
    for row, facing in enumerate(("down", "side", "up")):
        for step in (0, 1):
            cell = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
            draw_body(cell, facing, step)
            sheet.paste(cell, (step * CW, row * CH))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(f"wrote {OUT} ({sheet.size[0]}x{sheet.size[1]})")


if __name__ == "__main__":
    main()
