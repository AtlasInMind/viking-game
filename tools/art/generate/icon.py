#!/usr/bin/env python3
"""Regenerates game/icon.png through the shared pipeline - issue #13. Uses
the exact same Metal/Bone ramps as the player sprite's helmet (palette.py),
so the icon and the in-game hero sprite are now *literally* the same
colors rather than just accidentally similar - and the Brand ramp
(app-icon-only, see docs/ART_BIBLE.md) for the background circle instead
of an unformalized one-off blue.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent.parent))
import palette  # noqa: E402
import shading  # noqa: E402

SIZE = 128
OUT = Path(__file__).parent.parent.parent.parent / "game" / "icon.png"


def main():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background circle - organic shading (BRAND has no "light" shade, so
    # the upper-left arc reads as flat Base with the shading concentrated
    # into a Dark rim toward the lower-right, a subtle vignette rather than
    # a flat disc).
    bx0, by0, bx1, by1 = 4, 4, SIZE - 4, SIZE - 4
    bcx, bcy = (bx0 + bx1) / 2, (by0 + by1) / 2
    br = (bx1 - bx0) / 2
    circle_pixels = []
    for y in range(by0, by1):
        for x in range(bx0, bx1):
            if ((x - bcx) ** 2 + (y - bcy) ** 2) ** 0.5 <= br:
                circle_pixels.append((x, y))
    shading.apply_organic_shading(img, circle_pixels, palette.BRAND, light_threshold=0.5, dark_threshold=1.2)

    # Helmet dome - organic shading, same ramp as the player sprite's helmet.
    cx, cy = 64, 76
    rx, ry = 36, 27
    dome_pixels = []
    for y in range(cy - ry, cy + ry):
        for x in range(cx - rx, cx + rx):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                dome_pixels.append((x, y))
    shading.apply_organic_shading(img, dome_pixels, palette.METAL)

    # Helmet band.
    shading.apply_edge_shading(img, (28, 76, 100, 90), palette.METAL)

    # Horns.
    horn_color = (*palette.BONE["base"], 255)
    draw.polygon([(24, 58), (38, 58), (20, 28)], fill=horn_color)
    draw.polygon([(104, 58), (90, 58), (108, 28)], fill=horn_color)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)
    print(f"wrote {OUT} ({img.size[0]}x{img.size[1]})")


if __name__ == "__main__":
    main()
