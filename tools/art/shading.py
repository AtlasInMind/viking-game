"""Reusable shading helpers implementing docs/ART_BIBLE.md's lighting
convention: light source from the upper-left, applied consistently instead
of the old random-position speckle noise (which stays fine as *texture*,
layered on top - see the art bible's "Method going forward" - but was
previously the only thing doing any shading work at all).

Both helpers take a `ramp` (one of the dicts in palette.py, e.g.
palette.STONE) and pick the darkest/lightest shade actually present in it,
so they work across ramps that don't define every shade name (e.g. WATER
has no "shadow", CLOTH_COOL has no "light").
"""


def _pick(ramp, candidates, fallback):
    for key in candidates:
        if key in ramp:
            return ramp[key]
    return ramp[fallback]


def darkest(ramp):
    """The darkest shade a ramp actually defines (shadow, else dark, else
    base)."""
    return _pick(ramp, ("shadow", "dark"), "base")


def lightest(ramp):
    """The lightest shade a ramp actually defines (light, else base)."""
    return _pick(ramp, ("light",), "base")


def base(ramp):
    """A ramp's mid/base shade, or its only shade if it doesn't have one
    named "base" (e.g. a two-shade accent ramp)."""
    if "base" in ramp:
        return ramp["base"]
    return next(iter(ramp.values()))


def apply_edge_shading(img, region, ramp, edge_width=1):
    """Fills a rectangular region with the ramp's base color, then applies
    the upper-left lighting convention: the top and left edges get the
    lightest available shade, the bottom and right edges get the darkest -
    for tiles/sprite parts with hard edges (walls, roofs, robe/tunic
    blocks). region is (x0, y0, x1, y1), half-open like a Pillow box (x1/y1
    exclusive). Dark edges are painted before light ones, so at ambiguous
    corners (e.g. top-right) the light edge wins and stays an unbroken
    line - a common, deliberate pixel-art convention, not an oversight.
    """
    x0, y0, x1, y1 = region
    base_color = base(ramp)
    light_color = lightest(ramp)
    dark_color = darkest(ramp)

    for y in range(y0, y1):
        for x in range(x0, x1):
            img.putpixel((x, y), (*base_color, 255))

    # All dark rings painted first, then all light rings - not interleaved
    # per i - so a multi-pixel edge_width still gets a clean, unbroken light
    # corner rather than the light ring from one i being partially
    # overwritten by the dark ring from the next.
    for i in range(edge_width):
        for x in range(x0, x1):
            img.putpixel((x, y1 - 1 - i), (*dark_color, 255))
        for y in range(y0, y1):
            img.putpixel((x1 - 1 - i, y), (*dark_color, 255))
    for i in range(edge_width):
        for x in range(x0, x1):
            img.putpixel((x, y0 + i), (*light_color, 255))
        for y in range(y0, y1):
            img.putpixel((x0 + i, y), (*light_color, 255))


def apply_organic_shading(img, pixels, ramp, light_threshold=0.6, dark_threshold=1.3):
    """Re-shades an already-drawn rounded/organic shape (a tree canopy blob,
    a wisp) by position within its own bounding box, per docs/ART_BIBLE.md:
    Light concentrated toward the upper-left arc, Dark toward the
    lower-right arc, rather than picking literal pixel edges (which doesn't
    make sense for a blob shape the way it does for a rectangular tile).

    pixels: the (x, y) coordinates that make up the shape - whatever the
    caller already used to draw it (e.g. every point inside an ellipse).
    Thresholds are compared against normalized-x + normalized-y (0..2
    range); defaults give roughly a 30% light zone, 30% dark zone, 40% base
    zone along the upper-left-to-lower-right diagonal.
    """
    pixels = list(pixels)
    if not pixels:
        return

    xs = [p[0] for p in pixels]
    ys = [p[1] for p in pixels]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    width = max(max_x - min_x, 1)
    height = max(max_y - min_y, 1)

    base_color = base(ramp)
    light_color = lightest(ramp)
    dark_color = darkest(ramp)

    for x, y in pixels:
        score = (x - min_x) / width + (y - min_y) / height
        if score < light_threshold:
            color = light_color
        elif score > dark_threshold:
            color = dark_color
        else:
            color = base_color
        img.putpixel((x, y), (*color, 255))
