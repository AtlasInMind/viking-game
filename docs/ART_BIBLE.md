# Art Bible

## Purpose

The style rules every generated asset follows, so the game reads as one deliberately-designed world instead of a set of independently-improvised placeholders. Written for a **procedural** pipeline — every rule here is something a Python/Pillow generation script can hold as a constant or apply as a function, not a prompt for an AI image generator. See `docs/DECISIONS.md` ("Art production, revised") for why: this project is built by an AI agent with no image-generation tool access, so procedural generation is the actual, permanent method, not a stopgap.

## Audit: what M0/M1's placeholder art actually did wrong

Before setting rules, the existing art (`game/assets/`) was measured, not just eyeballed — each asset's actual pixel colors were extracted and compared.

**Finding: 41 unique colors across 5 small assets (tileset, player, NPC, wisp, icon), and 35 of those 41 (85%) are used in only one asset.** Concretely: the tileset's grass green, the tree canopy's greens, and nothing else — three different, independently-chosen greens that happen to look similar but were never actually the same value. Same pattern for the browns (path earth vs. wall stone vs. roof timber vs. NPC robe: four unrelated brown families where a real palette would share one or two, varied by shade). Every generation script (`player.gd`'s art, the tileset script, the NPC script, the wisp script) picked its own colors from scratch with no shared source of truth.

**Finding: zero directional shading anywhere.** Every asset uses flat base color plus scattered random-position speckle noise for texture (`rng.randrange` picking random pixels to lighten/darken). No asset has a consistent light-from-one-direction rule — the "light" and "dark" speckle pixels are placed randomly, not on any particular edge or face. This is why the placeholder art reads as flat/generic rather than dimensional.

**What already worked, worth preserving deliberately rather than by accident:** the player and NPC sprites already share an identical skin tone (`(233,190,151)`) and the darkest boot-brown (`(58,42,30)`) — not by design, just because both scripts happened to reuse similar values. The player sprite's horn/hair tone (`(222,214,190)`) also happens to match the icon's horn color. The master palette below formalizes these accidental matches as deliberate shared colors, and fixes the rest.

## Method going forward

1. Every generated asset pulls its colors from the master palette below — no script invents a new RGB value inline. (Enforced by shared tooling in a later issue, not just convention.)
2. Shading uses the lighting convention below, not random speckle noise, though a *little* fine noise/dither for texture on top of correct directional shading is fine (texture and shading are different things — this audit's complaint is about the total absence of the latter, not the presence of the former).
3. Small one-off accent details (a flower center, a doorknob) don't need a whole ramp - see the Accent entry below - but everything structural (ground, walls, characters) does.

## Base resolution & grid

- Base viewport: 480×270 (`project.godot` `window/size/viewport_*`), `canvas_items` stretch mode with `expand` aspect - the game is authored at this logical resolution and scales up from there.
- Tile grid: 16×16 pixels. All ground/structure tiles are exactly one grid cell.
- Texture filtering: Nearest (`textures/canvas_textures/default_texture_filter=0`) - pixel art stays crisp at any scale, never smoothed.

## Master palette

Named ramps, each 2-4 shades (Shadow → Dark → Base → Light, not every ramp needs all four). Values already in production use are marked *(existing)*; everything else is new, added to fill a gap the audit found (mainly: shadow shades needed for actual directional shading, since flat-plus-noise never needed a "shadow" tone before).

| Ramp | Shade | RGB | Hex | Used for |
|---|---|---|---|---|
| **Vegetation** (green) | Shadow | `24, 64, 24` | `#184018` | Tree canopy shadow *(existing)* |
| | Base | `74, 133, 58` | `#4A853A` | Grass ground *(existing)* |
| | Light | `110, 168, 88` | `#6EA858` | Grass/canopy highlight (new) |
| **Earth** (path/dirt) | Dark | `166, 132, 88` | `#A68458` | Path speckle *(existing)* |
| | Base | `196, 164, 116` | `#C4A474` | Path ground *(existing)* |
| | Light | `214, 186, 142` | `#D6BA8E` | Path highlight *(existing)* |
| **Stone** (walls) | Dark | `110, 98, 80` | `#6E6250` | Wall mortar *(revised - see "Colourblind-safety check")* |
| | Base | `144, 130, 110` | `#90826E` | Wall base *(revised - see "Colourblind-safety check")* |
| | Light | `168, 154, 132` | `#A89A84` | Wall highlight *(revised - see "Colourblind-safety check")* |
| **Timber** (roofs/doors) | Dark | `88, 32, 22` | `#582016` | Roof shingle *(revised - see "Colourblind-safety check")* |
| | Base | `116, 48, 34` | `#743022` | Roof base *(revised - see "Colourblind-safety check")* |
| | Light | `148, 76, 54` | `#944C36` | Roof/door highlight *(revised - see "Colourblind-safety check")* |
| **Water** | Deep | `42, 88, 138` | `#2A588A` | Water dot detail *(existing)* |
| | Base | `58, 110, 165` | `#3A6EA5` | Water base *(existing)* |
| | Light | `91, 143, 199` | `#5B8FC7` | Water wave highlight *(existing)* |
| **Skin** | Shadow | `196, 152, 116` | `#C49874` | Skin shading (new) |
| | Base | `233, 190, 151` | `#E9BE97` | Player + NPC skin *(existing, shared)* |
| **Hide** (leather/robe/boots) | Shadow | `40, 30, 25` | `#281E19` | Face-detail shadow *(existing, shared)* |
| | Dark | `58, 42, 30` | `#3A2A1E` | Boots *(existing, shared)* |
| | Base | `94, 68, 46` | `#5E442E` | Consolidated NPC hood/robe dark tone (new, replaces two near-duplicate ad-hoc browns) |
| | Light | `139, 101, 62` | `#8B653E` | NPC robe base *(existing)* |
| **Metal** (helmet, icon) | Dark | `110, 110, 118` | `#6E6E76` | Helmet shadow *(existing, shared)* |
| | Base | `150, 150, 158` | `#96969E` | Helmet base *(existing, shared)* |
| | Light | `192, 192, 198` | `#C0C0C6` | Helmet highlight (new) |
| **Bone** (horns/hair) | Shadow | `186, 178, 152` | `#BAB298` | Horn/hair shading (new) |
| | Base | `222, 214, 190` | `#DED6BE` | Player horns + hair, icon horns *(existing, shared)* |
| **Cloth: Warm** (player tunic) | Shadow | `84, 34, 26` | `#54221A` | Tunic deep shadow (new) |
| | Dark | `110, 44, 32` | `#6E2C20` | Tunic shadow *(existing)* |
| | Base | `140, 60, 46` | `#8C3C2E` | Tunic base *(existing)* |
| **Cloth: Cool** (player pants) | Dark | `66, 52, 74` | `#42344A` | Pants shadow (new) |
| | Base | `86, 68, 96` | `#564460` | Pants base *(existing)* |
| **Accent** | Gold Dark | `206, 178, 96` | `#CEB260` | Doorknob, small metal trim *(existing)* |
| | Gold Light | `232, 220, 130` | `#E8DC82` | Flower centers *(existing)* |
| **Brand** (app icon background only - not used in-world) | Dark | `42, 64, 92` | `#2A405C` | Icon circle edge shading (new) |
| | Base | `58, 86, 122` | `#3A567A` | Icon circle background *(existing - found missing from the original audit, formalized here)* |
| **Wisp** (VFX, deliberately outside the grounded palette - see below) | Core | `255, 250, 220` | `#FFFADC` | Wisp center *(existing)* |
| | Mid | `232, 240, 190` | `#E8F0BE` | Wisp glow *(existing)* |
| | Outer | `214, 232, 170` | `#D6E8AA` | Wisp fringe *(existing)* |

**The Wisp ramp is intentionally not part of the grounded-world palette.** It's paler and cooler than everything else on purpose - the game never confirms what a wisp is (`docs/PROJECT_VISION.md`, "grounded world, mythic edges"), and visually standing slightly outside the normal palette is part of how that ambiguity reads. Don't pull wisp colors into other assets, and don't reuse other ramps for future supernatural/folkloric elements without deciding deliberately whether they should share the Wisp ramp's "othered" quality.

## Lighting & shading convention

**Light source: upper-left**, a standard convention for top-down pixel art (and the direction that reads most naturally against this game's camera). Concretely:

- On tiles: the top and left 1-2px edges of a raised/detailed element (a tree canopy, a wall's top course, a roof ridge) get that ramp's **Light** shade. The bottom and right edges get the **Dark**/**Shadow** shade. Flat, undetailed ground fill uses **Base**, with sparse, non-directional fine noise still allowed for ground texture (that's texture, not shading - see "Method" above).
- On character sprites: the same logic applies to body-part edges (e.g. the left/top side of a helmet or robe gets **Light**, the right/bottom or an inward fold gets **Dark**/**Shadow**).
- On rounded/organic shapes (tree canopy blobs, the wisp), concentrate **Light** patches toward the upper-left arc of the shape and **Dark**/**Shadow** toward the lower-right arc, rather than picking literal pixel edges.
- This replaces the current uniform random-position speckle approach for *shading*. Fine random speckle can stay layered on top purely for ground-texture variety (grass/path already do this reasonably well) - the fix is adding real directional shading underneath it, not removing texture.

## Character & NPC proportions

- Grid unit: 16px tiles, characters occupy one tile horizontally.
- Sprite cell: 16 wide × 24 tall (taller than the tile, feet anchored at the tile's bottom edge via a `-12px` sprite offset) - deliberately GBA-Pokemon-scaled, a bit taller than the ground tile rather than a strict 1:1 square.
- Sheet layout: 3 facing rows (down, side, up) × frame columns (player: idle + 1 step frame for a walk cycle; stationary NPCs: idle only, no walk frames needed). Side-facing sprites are drawn once and mirrored (`flip_h`) for left/right rather than drawn twice - keep this convention, it's a real efficiency win, not a shortcut to fix.
- Silhouette: chibi-proportioned - oversized head relative to body (roughly 40% of sprite height), simplified 2-3-color-block body shapes (head/torso/legs read as distinct blocks even at 16×24). This is a deliberate style choice (matches the GBA-era reference point), not a limitation to "fix" toward realism later.

## UI style

Established in `dialogue_box.gd`/`title_screen.tscn`, formalized here so it's followed deliberately rather than copy-pasted without knowing why:

- Panel background: `rgba(20, 17, 14, 0.94)` (near-black, warm-toned, slightly translucent).
- Panel border: `rgb(217, 199, 153)` (a warm tan, distinct from the Earth/Timber ramps above - this is a deliberately UI-only color, not reused in-world), 2-3px width, 3-6px corner radius depending on panel size (larger panels get larger radius).
- Body text: white `(255,255,255)` with a black outline at `0.8` alpha, `3-4px` outline size depending on font size - ensures readability over any background without needing a solid text-backing box.
- Disabled text (e.g. the Continue button before a save exists): muted tan-gray `(166, 158, 140)` / `#A69E8C`.
- Buttons: same panel background/border language as the outer panel, at a smaller scale, with distinct (not just alpha-faded) normal/hover/pressed/disabled fill shades - see `title_screen.tscn`'s `StyleBoxFlat_btn_*` sub-resources for the concrete values already in use, which this rule formalizes rather than changes.

## Colourblind-safety check

Issue #32 required checking the master palette against a colourblind simulation, not just eyeballing it. `tools/art/colorblind_check.py` simulates protanopia/deuteranopia/tritanopia (Brettel/Vienot-derived linear-RGB matrices, the same family of approximation behind common open-source simulators like Coblis - not a clinically validated tool, but a real, checkable heuristic rather than a guess) and checks Euclidean sRGB distance on the pairs that actually matter for play, not every combination across all ~40 palette colors: whether a tile the player can walk on (grass/path) stays visually distinct from one that blocks movement (water/wall/roof) once colour-vision deficiency is simulated. The single highest-stakes case is the south gate (`game/scripts/main.gd`'s `GATE`) - the exact same map cell renders as Earth (path, open) or Stone (wall, locked) depending on `WorldState`, so a player has to tell those two colors apart at one spot to know whether the way south is open.

**Finding:** the south gate's own path-vs-wall pair was already comfortably safe (distance 78-87 against a 45.0 threshold, all three CVD types) even before any change. Two related pairs were not: grass-vs-wall and grass-vs-roof both fell short under protanopia (36.4 and 33.5) and grass-vs-wall also fell short under deuteranopia (43.9) - `Vegetation.base`'s luminance (≈115) sits almost exactly between `Stone.base`'s (≈120) and `Timber.base`'s (≈82), so once red/green hue discrimination is impaired, grass collapses toward wall/roof gray-brown rather than staying visually separate. This wasn't purely theoretical: village houses (`game/scripts/main.gd`'s `HOUSE_A_WALL`/`HOUSE_B_WALL`) sit directly in open grass, not fenced off by a path, so the wall/grass boundary is a real navigation edge a player relies on.

**Adjustment made:** `Stone` shifted uniformly lighter (+12,+12,+10 across dark/base/light, preserving the ramp's own internal contrast rather than just bumping one shade) and `Timber` shifted uniformly darker (-24,-20,-14) - both chosen by iterating candidate shifts against the actual simulation until every check cleared the threshold with real margin, not by eye. All 21 checks (7 pairs × 3 CVD types) now pass; see `tools/art/colorblind_check.py`'s own output for the full table. `Stone`/`Timber` were chosen over adjusting `Vegetation` because grass is the game's single most pervasive tile - walls and roofs are a much smaller visual footprint to change. The master palette table above reflects the revised values; `game/assets/tiles/overworld_tileset.png` was regenerated from them via `tools/art/generate/tileset.py`.

**Caveat, stated plainly:** this check compares each ramp's flat "base" swatch, which is a reasonable proxy for a tile's dominant color (per this doc's own "flat, undetailed ground fill uses Base" rule) but doesn't account for the directional edge-shading walls/roofs actually carry in the rendered tile (`tools/art/shading.py`'s `apply_edge_shading`) - real in-game tiles likely read even more distinctly than this table suggests, not less, since edge highlights/shingle lines add luminance contrast this check doesn't model. Euclidean sRGB distance is also a cheap heuristic, not CIEDE2000 - treat the numbers as "clearly fine" / "worth a look," not exact science.

## Last updated

2026-07-26 - Stone/Timber ramps revised for colourblind safety (issue #32); see "Colourblind-safety check" above.

2026-07-25
