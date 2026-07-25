"""Generates the dialogue-box-open SFX (issue #14's minimal working
example): a short two-note rising chime, the classic "a menu/box just
opened" UI cue. Triangle wave (softer than square, less harsh than sine
at short durations) with a quick attack/decay envelope per note.

Run from repo root: python3 tools/audio/generate/dialogue_open.py
Output: game/assets/audio/sfx/dialogue_open.wav
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from synth import triangle, apply_envelope, mix, save_wav  # noqa: E402

OUTPUT_PATH = os.path.join(
	os.path.dirname(__file__), "..", "..", "..", "game", "assets", "audio", "sfx", "dialogue_open.wav"
)

NOTE_DURATION = 0.09
# Note B starts before note A's own release tail has finished (release
# alone is 0.05s of the 0.09s note), so the two notes overlap in a short
# legato rather than leaving a silent gap - a deliberate, pleasant chime
# characteristic, not the "silence in between" the name might suggest.
NOTE_B_OFFSET = 0.05
FREQ_LOW = 523.25   # C5
FREQ_HIGH = 659.25  # E5


def build() -> None:
	note_a = apply_envelope(triangle(FREQ_LOW, NOTE_DURATION), attack=0.005, decay=0.02, sustain_level=0.6, release=0.05)
	note_b = apply_envelope(triangle(FREQ_HIGH, NOTE_DURATION), attack=0.005, decay=0.02, sustain_level=0.6, release=0.06)

	offset_samples = int(NOTE_B_OFFSET * 44100)
	padded_b = [0.0] * offset_samples
	padded_b.extend(note_b.tolist())

	clip = mix(note_a, np.array(padded_b))

	os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
	save_wav(clip, OUTPUT_PATH)
	print(f"Wrote {OUTPUT_PATH}")


if __name__ == "__main__":
	build()
