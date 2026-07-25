#!/usr/bin/env python3
"""Regenerates game/assets/sprites/wisp.png through the shared pipeline -
issue #13. Deliberately does NOT use shading.py's directional-lighting
helpers: docs/ART_BIBLE.md calls out the wisp as intentionally "othered",
a soft ambient glow rather than an opaque, upper-left-lit object, so this
paints concentric rings at reduced alpha directly from palette.WISP instead
of treating it as a shaded solid.
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent.parent))
import palette  # noqa: E402

SIZE = 16
OUT = Path(__file__).parent.parent.parent.parent / "game" / "assets" / "sprites" / "wisp.png"

# Smallest radius first - a pixel is painted with the innermost ring it
# falls within, so this order matters (checked via "first match wins").
RINGS = [
    (1.6, (*palette.WISP["core"], 255)),
    (3.2, (*palette.WISP["mid"], 150)),
    (5.5, (*palette.WISP["outer"], 70)),
]


def main():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE / 2 - 0.5, SIZE / 2 - 0.5

    for y in range(SIZE):
        for x in range(SIZE):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            for radius, color in RINGS:
                if d <= radius:
                    img.putpixel((x, y), color)
                    break

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)
    print(f"wrote {OUT} ({img.size[0]}x{img.size[1]})")


if __name__ == "__main__":
    main()
