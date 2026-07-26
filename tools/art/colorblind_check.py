#!/usr/bin/env python3
"""Checks the master palette (palette.py / docs/ART_BIBLE.md) for
colourblind-safety on the pairs that actually matter for play (issue #32) -
not every pairwise combination across all ~40 colors, most of which never
appear side by side in the game. The one that matters most: whether a
tile that blocks movement (water/wall/roof) stays visually distinct from a
tile the player can walk on (grass/path) once a colour-vision deficiency is
simulated. The single highest-stakes case is the south gate
(game/data/gates/south_gate.tres, game/scripts/main.gd's GATE) - the exact
same map cell renders as EARTH (path, open) or STONE (wall, locked)
depending on WorldState, so a player has to tell those two colors apart at
one spot to know whether the way south is open.

Simulates protanopia/deuteranopia/tritanopia using the widely-used Brettel/
Vienot-derived linear-RGB transform matrices (the same ones behind common
open-source CVD simulators like Coblis) - a solid approximation, not a
clinically validated tool. Distance is plain Euclidean distance in sRGB
0-255 space, a cheap, honest heuristic (not CIEDE2000) - treat the numbers
here as "clearly fine" / "worth a look" / "too close," not exact science.

Usable as a library (run_checks()) or as a CLI:
    python3 tools/art/colorblind_check.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import palette  # noqa: E402

# Machado/Vienot-Brettel-derived CVD simulation matrices, applied in linear
# RGB. Publicly circulated approximation (the same one behind Coblis and
# similar simulators) - good enough for an internal sanity check, not a
# medical-grade tool.
_MATRICES = {
    "protanopia": (
        (0.567, 0.433, 0.000),
        (0.558, 0.442, 0.000),
        (0.000, 0.242, 0.758),
    ),
    "deuteranopia": (
        (0.625, 0.375, 0.000),
        (0.700, 0.300, 0.000),
        (0.000, 0.300, 0.700),
    ),
    "tritanopia": (
        (0.950, 0.050, 0.000),
        (0.000, 0.433, 0.567),
        (0.000, 0.475, 0.525),
    ),
}

# The pairs that actually matter in play - a label, then the two RGB colors,
# each a (ramp_name, shade_name) lookup into palette.RAMPS. "walkable" means
# a tile the player can stand on; "blocked" means one that stops movement
# (game/scripts/main.gd's _build_tileset() "blocked" custom data layer).
_GAMEPLAY_PAIRS = [
    ("south gate: path (open) vs wall (locked) - same cell, two states", ("earth", "base"), ("stone", "base")),
    ("grass (walkable) vs water (blocked)", ("vegetation", "base"), ("water", "base")),
    ("path (walkable) vs water (blocked)", ("earth", "base"), ("water", "base")),
    ("grass (walkable) vs wall (blocked)", ("vegetation", "base"), ("stone", "base")),
    ("path (walkable) vs roof (blocked)", ("earth", "base"), ("timber", "base")),
    ("grass (walkable) vs roof (blocked)", ("vegetation", "base"), ("timber", "base")),
    ("grass (walkable) vs tree canopy (blocked, border-only)", ("vegetation", "base"), ("vegetation", "shadow")),
]

# Below this Euclidean sRGB distance, treat two colors as "too close to
# safely rely on for a functional distinction" - a rough heuristic threshold,
# not a validated perceptual-difference-of-noticeability number (see module
# docstring). Chosen so a same-hue same-shade case (e.g. two custom mixes of
# the same ramp) would fail while genuinely distinct hues/ramps pass.
_MIN_SAFE_DISTANCE = 45.0


def _srgb_to_linear(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _linear_to_srgb(c):
    c = max(0.0, min(1.0, c))
    out = 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055
    return max(0, min(255, round(out * 255)))


def simulate(rgb, cvd_type):
    """Returns the RGB a viewer with the given CVD type would perceive."""
    matrix = _MATRICES[cvd_type]
    linear = [_srgb_to_linear(ch) for ch in rgb]
    out = [sum(matrix[row][col] * linear[col] for col in range(3)) for row in range(3)]
    return tuple(_linear_to_srgb(ch) for ch in out)


def _distance(a, b):
    return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5


def _lookup(ref):
    ramp_name, shade_name = ref
    return palette.RAMPS[ramp_name][shade_name]


def run_checks():
    """Returns a list of dicts, one per (pair, cvd_type) combination, each
    with label/cvd_type/original colors/simulated colors/distance/ok."""
    results = []
    for label, ref_a, ref_b in _GAMEPLAY_PAIRS:
        color_a, color_b = _lookup(ref_a), _lookup(ref_b)
        for cvd_type in _MATRICES:
            sim_a, sim_b = simulate(color_a, cvd_type), simulate(color_b, cvd_type)
            distance = _distance(sim_a, sim_b)
            results.append({
                "label": label,
                "cvd_type": cvd_type,
                "color_a": color_a,
                "color_b": color_b,
                "sim_a": sim_a,
                "sim_b": sim_b,
                "distance": distance,
                "ok": distance >= _MIN_SAFE_DISTANCE,
            })
    return results


def main():
    results = run_checks()
    failures = [r for r in results if not r["ok"]]

    for r in results:
        status = "OK  " if r["ok"] else "WARN"
        print(f"{status} [{r['cvd_type']:>13}] {r['label']}: "
              f"{r['color_a']} vs {r['color_b']} -> "
              f"simulated {r['sim_a']} vs {r['sim_b']}, distance={r['distance']:.1f}")

    print()
    if failures:
        print(f"{len(failures)}/{len(results)} checks below the {_MIN_SAFE_DISTANCE} safe-distance threshold.")
        return 1
    print(f"All {len(results)} checks at or above the {_MIN_SAFE_DISTANCE} safe-distance threshold.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
