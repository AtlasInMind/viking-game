# Audio pipeline tooling

Procedural (Python/numpy) audio-generation support code, the audio-side analog of `tools/art`'s Pillow-based pipeline. See `docs/DECISIONS.md` ("Audio production: procedural synthesis, following the art precedent") for why: no AI audio-generation tool is available in the environment this project is built in, and neither `sox` nor `ffmpeg` is installed on this machine.

- `synth.py` — waveform generators (`sine`, `square`, `triangle`, `white_noise`), an ADSR envelope (`apply_envelope`), `mix` for combining tracks, and `save_wav` for writing standard 16-bit PCM `.wav` files that Godot imports natively.
- `generate/` — per-asset generation scripts (e.g. `dialogue_open.py`) that produce the real files in `game/assets/audio/`, all built on `synth.py` rather than shelling out to an external encoder.

## Requirements

Python 3 with `numpy` (already a dependency via `tools/art`) — no other dependencies.

## Regenerating a real game asset

`game/assets/audio/` holds the actual files the Godot project imports — they're generated output, not hand-edited directly. To change one, edit the relevant script under `generate/`, re-run it (e.g. `python3 tools/audio/generate/dialogue_open.py`), then re-import in Godot (`godot --headless --editor --path game --quit` picks up new/changed files).

## Current ceiling

This approach is proven for short UI SFX (the dialogue-open chime). It has not been used for anything longer or more musical — convincing instrumental music is a much harder procedural target than a two-note chime, and should be expected to stay out of reach without a real composer or a licensed track, per the same "craft ceiling" trade-off the art decision accepted. Noise-based ambience (wind, water) is a plausible next step within this approach; full musical scoring likely isn't.
