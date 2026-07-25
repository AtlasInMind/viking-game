#!/usr/bin/env python3
"""Parse docs/ART_BIBLE.md's Master Palette table directly and diff it
against palette.py, so a hand-transcription error can't silently drift
between the two (this is exactly the kind of mistake independent review
caught in the art bible itself - a value computed instead of read off the
real doc). Run this after any edit to either file.

Exit code 0 = match, 1 = mismatch (prints details either way).
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import palette  # noqa: E402

DOC_PATH = Path(__file__).parent.parent.parent / "docs" / "ART_BIBLE.md"

# Maps the doc's human-readable ramp/shade labels to palette.py's keys.
RAMP_NAME_MAP = {
    "vegetation": "vegetation",
    "earth": "earth",
    "stone": "stone",
    "timber": "timber",
    "water": "water",
    "skin": "skin",
    "hide": "hide",
    "metal": "metal",
    "bone": "bone",
    "cloth_warm": "cloth_warm",
    "cloth_cool": "cloth_cool",
    "accent": "accent",
    "brand": "brand",
    "wisp": "wisp",
}


def normalize(label: str) -> str:
    label = re.sub(r"\([^)]*\)", "", label)  # drop parenthetical annotations
    label = label.replace(":", " ")
    return re.sub(r"[^a-z0-9]+", "_", label.strip().lower()).strip("_")


def parse_doc_table(text: str) -> dict:
    """Returns {ramp_key: {shade_key: (r,g,b)}} parsed from the Master
    Palette table (stops at the next ## heading)."""
    start = text.index("## Master palette")
    end = text.index("\n## ", start + 1)
    section = text[start:end]

    result = {}
    current_ramp = None
    row_re = re.compile(
        r"^\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*`(\d+),\s*(\d+),\s*(\d+)`\s*\|\s*`#([0-9A-Fa-f]{6})`\s*\|"
    )
    for line in section.splitlines():
        m = row_re.match(line.strip())
        if not m:
            continue
        ramp_label, shade_label, r, g, b, hexcode = m.groups()
        rgb = (int(r), int(g), int(b))

        expected_hex = "%02X%02X%02X" % rgb
        if expected_hex.upper() != hexcode.upper():
            print(f"DOC-INTERNAL MISMATCH: {rgb} does not match hex #{hexcode} in the doc itself")

        if ramp_label.strip():
            current_ramp = normalize(ramp_label)
        if current_ramp is None:
            continue
        shade_key = normalize(shade_label)
        result.setdefault(current_ramp, {})[shade_key] = rgb
    return result


def main() -> int:
    text = DOC_PATH.read_text()
    doc_ramps = parse_doc_table(text)

    problems = []
    for doc_ramp_key, doc_shades in doc_ramps.items():
        py_ramp_key = RAMP_NAME_MAP.get(doc_ramp_key)
        if py_ramp_key is None:
            problems.append(f"doc has ramp '{doc_ramp_key}' with no mapping to palette.py")
            continue
        py_ramp = palette.RAMPS.get(py_ramp_key)
        if py_ramp is None:
            problems.append(f"doc ramp '{doc_ramp_key}' -> palette.py has no RAMPS['{py_ramp_key}']")
            continue
        for shade_key, rgb in doc_shades.items():
            py_rgb = py_ramp.get(shade_key)
            if py_rgb is None:
                problems.append(f"{py_ramp_key}.{shade_key}: doc has {rgb}, palette.py is missing this shade")
            elif py_rgb != rgb:
                problems.append(f"{py_ramp_key}.{shade_key}: doc has {rgb}, palette.py has {py_rgb}")

    doc_ramp_keys = set(doc_ramps.keys())
    mapped_py_keys = {RAMP_NAME_MAP[k] for k in doc_ramp_keys if k in RAMP_NAME_MAP}
    extra_py_ramps = (set(palette.RAMPS.keys()) - mapped_py_keys) - {"ui"}
    if extra_py_ramps:
        problems.append(f"palette.py has ramps not present in the doc's table: {sorted(extra_py_ramps)} (ok if intentionally sourced elsewhere, e.g. 'ui' from prose - verify manually)")

    if problems:
        print(f"MISMATCH: {len(problems)} problem(s) between docs/ART_BIBLE.md and palette.py:")
        for p in problems:
            print(f"  - {p}")
        return 1

    total_shades = sum(len(s) for s in doc_ramps.values())
    print(f"OK: all {total_shades} doc-table shades across {len(doc_ramps)} ramps match palette.py exactly.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
