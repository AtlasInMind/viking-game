#!/usr/bin/env python3
"""Checks that a generated image only uses colors from the master palette
(palette.py / docs/ART_BIBLE.md). Catches drift before an asset gets
imported into the Godot project - see docs/ART_BIBLE.md's "Method going
forward": every generated asset is supposed to pull colors from the master
palette, not invent new ones inline.

Usable as a function (validate_image) or as a CLI:
    python3 tools/art/validate.py path/to/image.png [more.png ...]
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import palette  # noqa: E402


def validate_image(path):
    """Returns a sorted list of (r, g, b) violations - pixel colors present
    in the image (at any non-zero alpha) that aren't in the master palette.
    Fully-transparent pixels (alpha=0) are ignored, matching the audit
    methodology used in docs/ART_BIBLE.md.
    """
    approved = palette.all_colors()
    img = Image.open(path).convert("RGBA")
    found = set()
    for r, g, b, a in img.getdata():
        if a == 0:
            continue
        found.add((r, g, b))
    return sorted(found - approved)


def main(argv):
    if not argv:
        print("usage: validate.py <image.png> [more.png ...]")
        return 2

    exit_code = 0
    for path in argv:
        violations = validate_image(path)
        if violations:
            exit_code = 1
            print(f"FAIL {path}: {len(violations)} color(s) not in the master palette:")
            for rgb in violations:
                print(f"  {rgb}  #{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}")
        else:
            print(f"OK   {path}: every pixel color is in the master palette.")
    return exit_code


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
