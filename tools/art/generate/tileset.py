#!/usr/bin/env python3
"""Regenerates game/assets/tiles/overworld_tileset.png through the shared
pipeline (docs/ART_BIBLE.md + tools/art/palette.py + tools/art/shading.py) -
issue #13. Ground tiles (grass/path/water) stay flat-fill-plus-texture-noise
per the art bible's own rule ("flat, undetailed ground fill uses Base");
raised/structural tiles (tree, wall, roof, door) get real directional
shading via shading.py instead of the old random-speckle-only look.
"""
import random
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent.parent))
import palette  # noqa: E402
import shading  # noqa: E402

TILE = 16
OUT = Path(__file__).parent.parent.parent.parent / "game" / "assets" / "tiles" / "overworld_tileset.png"

TILE_GRASS, TILE_GRASS_FLOWERS, TILE_PATH, TILE_TREE, TILE_WATER, TILE_WALL, TILE_ROOF, TILE_DOOR = range(8)


def new_tile():
    return Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))


def fill_rect(img, x0, y0, x1, y1, color, alpha=255):
    for y in range(y0, y1):
        for x in range(x0, x1):
            if 0 <= x < img.width and 0 <= y < img.height:
                img.putpixel((x, y), (*color, alpha))


def speckle(img, color, count, rng, region=(0, 0, TILE, TILE)):
    """Sparse, non-directional texture noise - the art bible's allowed
    exception, distinct from the directional shading in shading.py."""
    x0, y0, x1, y1 = region
    for _ in range(count):
        x = rng.randrange(x0, x1)
        y = rng.randrange(y0, y1)
        img.putpixel((x, y), (*color, 255))


def make_grass(seed, flowers=False):
    t = new_tile()
    fill_rect(t, 0, 0, TILE, TILE, palette.VEGETATION["base"])
    rng = random.Random(seed)
    speckle(t, palette.VEGETATION["shadow"], 12, rng)
    speckle(t, palette.VEGETATION["light"], 8, rng)
    if flowers:
        for _ in range(3):
            x, y = rng.randrange(1, TILE - 1), rng.randrange(1, TILE - 1)
            t.putpixel((x, y), (*palette.ACCENT["gold_light"], 255))
    return t


def make_path():
    t = new_tile()
    fill_rect(t, 0, 0, TILE, TILE, palette.EARTH["base"])
    rng = random.Random(42)
    speckle(t, palette.EARTH["dark"], 16, rng)
    speckle(t, palette.EARTH["light"], 10, rng)
    return t


def make_water():
    t = new_tile()
    fill_rect(t, 0, 0, TILE, TILE, palette.WATER["base"])
    for y in (3, 4, 9, 10):
        for x in range(TILE):
            if (x + y) % 4 != 0:
                t.putpixel((x, y), (*palette.WATER["light"], 255))
    for y in (7, 14):
        for x in range(0, TILE, 3):
            t.putpixel((x, y), (*palette.WATER["deep"], 255))
    return t


def make_tree():
    t = new_tile()
    shading.apply_edge_shading(t, (6, 11, 10, 16), palette.HIDE, edge_width=1)

    cx, cy, r = 7.5, 6, 6.5
    pixels = []
    for y in range(0, 12):
        for x in range(TILE):
            if ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 <= r:
                pixels.append((x, y))
    shading.apply_organic_shading(t, pixels, palette.VEGETATION)
    return t


def make_wall():
    t = new_tile()
    shading.apply_edge_shading(t, (0, 0, TILE, TILE), palette.STONE, edge_width=2)
    return t


def make_roof():
    t = new_tile()
    shading.apply_edge_shading(t, (0, 0, TILE, TILE), palette.TIMBER, edge_width=2)
    for y in range(4, TILE, 4):
        for x in range(2, TILE - 2):
            t.putpixel((x, y), (*palette.TIMBER["dark"], 255))
    return t


def make_door():
    t = make_wall()
    shading.apply_edge_shading(t, (4, 3, 12, 16), palette.HIDE, edge_width=1)
    knob = palette.ACCENT["gold_dark"]
    t.putpixel((9, 9), (*knob, 255))
    t.putpixel((10, 9), (*knob, 255))
    return t


def main():
    tiles = [None] * 8
    tiles[TILE_GRASS] = make_grass(seed=1)
    tiles[TILE_GRASS_FLOWERS] = make_grass(seed=2, flowers=True)
    tiles[TILE_PATH] = make_path()
    tiles[TILE_TREE] = make_tree()
    tiles[TILE_WATER] = make_water()
    tiles[TILE_WALL] = make_wall()
    tiles[TILE_ROOF] = make_roof()
    tiles[TILE_DOOR] = make_door()

    atlas = Image.new("RGBA", (TILE * 8, TILE), (0, 0, 0, 0))
    for i, tile in enumerate(tiles):
        atlas.paste(tile, (i * TILE, 0))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT)
    print(f"wrote {OUT} ({atlas.size[0]}x{atlas.size[1]})")


if __name__ == "__main__":
    main()
