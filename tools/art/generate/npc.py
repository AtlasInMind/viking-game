#!/usr/bin/env python3
"""Regenerates game/assets/sprites/npc_villager.png through the shared
pipeline - issue #13. Hero-adjacent asset (stationary NPCs are on screen
throughout dialogue), gets real directional shading per part instead of the
old flat-plus-noise placeholder. Layout (3 facing rows, idle-only - NPCs
don't walk) is unchanged.
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent.parent))
import palette  # noqa: E402
import shading  # noqa: E402

CW, CH = 16, 24
OUT = Path(__file__).parent.parent.parent.parent / "game" / "assets" / "sprites" / "npc_villager.png"

FACE_DOT = palette.HIDE["shadow"]


def draw_villager(cell, facing):
    # Boots.
    shading.apply_edge_shading(cell, (5, 20, 7, 23), palette.HIDE)
    shading.apply_edge_shading(cell, (9, 20, 11, 23), palette.HIDE)

    # Robe.
    shading.apply_edge_shading(cell, (3, 10, 13, 21), palette.HIDE, edge_width=1)
    for x in range(3, 13):
        cell.putpixel((x, 17), (*palette.HIDE["shadow"], 255))

    # Head (skin).
    shading.apply_edge_shading(cell, (4, 4, 12, 11), palette.SKIN)

    # Hood.
    shading.apply_edge_shading(cell, (3, 1, 13, 6), palette.HIDE, edge_width=1)

    if facing == "down":
        cell.putpixel((6, 7), (*FACE_DOT, 255))
        cell.putpixel((9, 7), (*FACE_DOT, 255))
    elif facing == "up":
        shading.apply_edge_shading(cell, (4, 5, 12, 11), palette.HIDE)
    elif facing == "side":
        cell.putpixel((9, 7), (*FACE_DOT, 255))


def main():
    sheet = Image.new("RGBA", (CW, CH * 3), (0, 0, 0, 0))
    for row, facing in enumerate(("down", "side", "up")):
        cell = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        draw_villager(cell, facing)
        sheet.paste(cell, (0, row * CH))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(f"wrote {OUT} ({sheet.size[0]}x{sheet.size[1]})")


if __name__ == "__main__":
    main()
