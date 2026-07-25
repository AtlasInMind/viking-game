# Art pipeline tooling

Procedural (Python/Pillow) art-generation support code, implementing `docs/ART_BIBLE.md`'s rules mechanically instead of leaving them as conventions to remember per-script. See `docs/DECISIONS.md` ("Art production, revised") for why this is procedural rather than AI-generated - no image-generation tool is available in the environment this project is built in.

- `palette.py` — the master palette (`docs/ART_BIBLE.md`'s ramp table) as named, importable Python constants. Every asset-generation script should import colors from here, not invent RGB values inline.
- `shading.py` — reusable shading helpers implementing the art bible's upper-left lighting convention: `apply_edge_shading` for rectangular tiles/sprite parts, `apply_organic_shading` for rounded/organic shapes (canopy blobs, VFX).
- `validate.py` — checks a generated image only uses master-palette colors; run it on anything before importing it into `game/assets/`. Usable as a library function or `python3 tools/art/validate.py <image.png>`.
- `check_palette_matches_doc.py` — parses `docs/ART_BIBLE.md`'s Master Palette table directly and diffs it against `palette.py`, so a transcription error can't silently drift between the doc and the code. Run after editing either.
- `selftest.py` — generates a small demo asset using only the tooling above and validates it; the regression check that the pipeline actually works end-to-end. Run after changing `palette.py`/`shading.py`.
- `examples/demo_tile.png` — output of `selftest.py`, committed so the tooling's actual visual output is reviewable without running anything.

## Requirements

Python 3 with Pillow (`pip install pillow`) - no other dependencies.

## Regenerating the real game assets

This directory is the pipeline, not the assets themselves - `game/assets/` still holds the actual files the Godot project imports. Re-skinning the real assets through this tooling is a separate, later step (see the M2 milestone's issue for it), not something running the scripts here does automatically.
