"""Procedural audio synthesis (numpy + stdlib wave) - the audio-side analog
of tools/art's Pillow-based procedural pipeline. See docs/DECISIONS.md
("Audio production: procedural synthesis") for why: no AI audio-generation
tool is available in this environment, so SFX/ambience are synthesized from
basic waveforms rather than generated or sourced externally.

No dependency beyond numpy (already used by tools/art) and Python's stdlib.
"""

import numpy as np
import wave

SAMPLE_RATE = 44100


def sine(freq: float, duration: float, sample_rate: int = SAMPLE_RATE) -> np.ndarray:
	t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
	return np.sin(2 * np.pi * freq * t)


def square(freq: float, duration: float, sample_rate: int = SAMPLE_RATE) -> np.ndarray:
	t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
	return np.sign(np.sin(2 * np.pi * freq * t))


def triangle(freq: float, duration: float, sample_rate: int = SAMPLE_RATE) -> np.ndarray:
	t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
	return 2 * np.abs(2 * (t * freq - np.floor(t * freq + 0.5))) - 1


def white_noise(duration: float, sample_rate: int = SAMPLE_RATE, seed: int = 0) -> np.ndarray:
	rng = np.random.default_rng(seed)
	return rng.uniform(-1.0, 1.0, int(sample_rate * duration))


def apply_envelope(samples: np.ndarray, attack: float, decay: float,
					sustain_level: float, release: float,
					sample_rate: int = SAMPLE_RATE) -> np.ndarray:
	"""Standard ADSR envelope, applied over the full length of `samples`.
	attack/decay/release are durations in seconds; whatever length remains
	after those three is held at sustain_level. Segment lengths are clamped
	to fit short clips instead of raising, since generated SFX are often
	shorter than attack+decay+release would naively require.
	"""
	n = len(samples)
	a = min(int(attack * sample_rate), n)
	d = min(int(decay * sample_rate), n - a)
	r = min(int(release * sample_rate), n - a - d)
	s = n - a - d - r

	envelope = np.concatenate([
		np.linspace(0.0, 1.0, a, endpoint=False) if a > 0 else np.array([]),
		np.linspace(1.0, sustain_level, d, endpoint=False) if d > 0 else np.array([]),
		np.full(s, sustain_level) if s > 0 else np.array([]),
		np.linspace(sustain_level, 0.0, r) if r > 0 else np.array([]),
	])
	return samples * envelope


def mix(*tracks: np.ndarray) -> np.ndarray:
	"""Sum tracks of possibly different lengths (padding the shorter ones
	with silence) and normalize so the result stays within [-1, 1].
	"""
	length = max(len(t) for t in tracks)
	total = np.zeros(length)
	for t in tracks:
		total[: len(t)] += t
	peak = np.max(np.abs(total))
	if peak > 1.0:
		total /= peak
	return total


def save_wav(samples: np.ndarray, path: str, sample_rate: int = SAMPLE_RATE) -> None:
	"""Write mono 16-bit PCM. Godot imports .wav natively - no external
	encoder (sox/ffmpeg, neither of which is available here) is needed.
	"""
	clipped = np.clip(samples, -1.0, 1.0)
	pcm = (clipped * 32767).astype(np.int16)
	with wave.open(path, "w") as f:
		f.setnchannels(1)
		f.setsampwidth(2)
		f.setframerate(sample_rate)
		f.writeframes(pcm.tobytes())
