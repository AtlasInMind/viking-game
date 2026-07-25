"""Master palette (docs/ART_BIBLE.md) as importable, named color constants.

Every asset-generation script should import colors from here rather than
inventing RGB values inline - that's the actual fix for the "41 colors, 85%
single-use" problem the art bible's audit found (see docs/ART_BIBLE.md,
"Audit"). Values are transcribed from that document's Master Palette table;
see tools/art/check_palette_matches_doc.py, which parses the table directly
and diffs it against this module, to catch transcription drift.

Each ramp is a dict of shade-name -> (R, G, B), 0-255 int channels, no alpha
(alpha is a per-use concern - e.g. the wisp VFX uses these RGB values at
reduced alpha for its glow rings, which isn't part of the palette itself).
Not every ramp has all four shades (Shadow, Dark, Base, Light) - only the
ones docs/ART_BIBLE.md actually defines.
"""

VEGETATION = {
    "shadow": (24, 64, 24),
    "base": (74, 133, 58),
    "light": (110, 168, 88),
}

EARTH = {
    "dark": (166, 132, 88),
    "base": (196, 164, 116),
    "light": (214, 186, 142),
}

STONE = {
    "dark": (98, 86, 70),
    "base": (132, 118, 100),
    "light": (156, 142, 122),
}

TIMBER = {
    "dark": (112, 52, 36),
    "base": (140, 68, 48),
    "light": (172, 96, 68),
}

WATER = {
    "deep": (42, 88, 138),
    "base": (58, 110, 165),
    "light": (91, 143, 199),
}

SKIN = {
    "shadow": (196, 152, 116),
    "base": (233, 190, 151),
}

HIDE = {
    "shadow": (40, 30, 25),
    "dark": (58, 42, 30),
    "base": (94, 68, 46),
    "light": (139, 101, 62),
}

METAL = {
    "dark": (110, 110, 118),
    "base": (150, 150, 158),
    "light": (192, 192, 198),
}

BONE = {
    "shadow": (186, 178, 152),
    "base": (222, 214, 190),
}

CLOTH_WARM = {
    "shadow": (84, 34, 26),
    "dark": (110, 44, 32),
    "base": (140, 60, 46),
}

CLOTH_COOL = {
    "dark": (66, 52, 74),
    "base": (86, 68, 96),
}

ACCENT = {
    "gold_dark": (206, 178, 96),
    "gold_light": (232, 220, 130),
}

# App icon background only - not used in-world (found missing from the
# original art bible audit, formalized after the fact).
BRAND = {
    "dark": (42, 64, 92),
    "base": (58, 86, 122),
}

# Deliberately not part of the grounded-world ramps below - see
# docs/ART_BIBLE.md's note on why the wisp stays visually "othered".
WISP = {
    "core": (255, 250, 220),
    "mid": (232, 240, 190),
    "outer": (214, 232, 170),
}

# From docs/ART_BIBLE.md's "UI style" section (prose, not the ramp table) -
# included here so UI-adjacent generation/validation has a single source too.
UI = {
    "background": (20, 17, 14),
    "border": (217, 199, 153),
    "text": (255, 255, 255),
    "text_disabled": (166, 158, 140),
}

RAMPS = {
    "vegetation": VEGETATION,
    "earth": EARTH,
    "stone": STONE,
    "timber": TIMBER,
    "water": WATER,
    "skin": SKIN,
    "hide": HIDE,
    "metal": METAL,
    "bone": BONE,
    "cloth_warm": CLOTH_WARM,
    "cloth_cool": CLOTH_COOL,
    "accent": ACCENT,
    "brand": BRAND,
    "wisp": WISP,
    "ui": UI,
}


def all_colors():
    """Every approved RGB color across every ramp, flattened - what
    validate.py checks a generated image's pixels against."""
    colors = set()
    for ramp in RAMPS.values():
        colors.update(ramp.values())
    return colors
