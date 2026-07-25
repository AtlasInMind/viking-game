#!/usr/bin/env python3
"""Generates a small demonstration asset using ONLY palette.py + shading.py
(no ad-hoc inline colors), then validates it against the master palette -
proving the pipeline tooling actually works end-to-end (issue #12's
acceptance criteria), not just that the pieces exist in isolation.

Regenerate + re-check any time palette.py/shading.py change:
    python3 tools/art/selftest.py
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import palette  # noqa: E402
import shading  # noqa: E402
import validate  # noqa: E402

OUT_PATH = Path(__file__).parent / "examples" / "demo_tile.png"
TILE = 16


def make_wall_tile():
    """Rectangular edge-shaded tile - exercises apply_edge_shading."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    shading.apply_edge_shading(img, (0, 0, TILE, TILE), palette.STONE, edge_width=2)
    return img


def make_canopy_tile():
    """Rounded/organic shaded blob - exercises apply_organic_shading."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    cx, cy, r = TILE / 2 - 0.5, TILE / 2 - 0.5, TILE / 2 - 1
    pixels = []
    for y in range(TILE):
        for x in range(TILE):
            if ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 <= r:
                pixels.append((x, y))
    shading.apply_organic_shading(img, pixels, palette.VEGETATION)
    return img


def main():
    wall = make_wall_tile()
    canopy = make_canopy_tile()

    demo = Image.new("RGBA", (TILE * 2, TILE), (0, 0, 0, 0))
    demo.paste(wall, (0, 0))
    demo.paste(canopy, (TILE, 0))

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    demo.save(OUT_PATH)
    print(f"wrote {OUT_PATH} ({demo.size[0]}x{demo.size[1]})")

    violations = validate.validate_image(OUT_PATH)
    if violations:
        print(f"SELFTEST FAILED: {len(violations)} palette violation(s) in generated demo asset:")
        for rgb in violations:
            print(f"  {rgb}")
        return 1

    print("SELFTEST PASSED: demo asset uses only master-palette colors.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
