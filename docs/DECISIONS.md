# Decisions Log

## Purpose

Chronological log of significant project decisions, with rationale, consequences, and status (final/provisional).

## Last updated

2026-07-25

---

### 2026-07-25 — Challenge layer: a "hold still while the light passes" tense encounter

**Rationale:** Issue #10 required picking one concrete form for the "light/stylized challenge layer" (already decided against a full battle system, see the 2026-07-25 combat entry above) by building it, not designing it on paper. Considered against the alternatives it explicitly named: an environmental puzzle (arranging/matching objects) felt more like a discrete minigame bolted onto the world than something that could recur naturally across future content without feeling repetitive; a "simple non-lethal confrontation minigame" risked drifting back toward stats/turns/a mini battle-system in practice, exactly what issue #4 was closed to avoid. A tense/stealth-style encounter won because it could be built as pure atmosphere with no numbers at all, and because it could directly pay off dialogue that already existed rather than inventing new lore: cairn_npc already says "some say lights move up there at night" (written in #8/#9, before this mechanic existed) - so the encounter *is* that light, made interactive, without the game ever confirming what it actually is. That directly matches the "grounded world, mythic edges" pillar (`docs/PROJECT_VISION.md`) - myth stays belief, never confirmed.

Concrete mechanic: approaching the cairn past cairn_npc, a wisp appears; the player must not move for 3 seconds while it drifts past. Moving during that window "fails" (a startled flinch, gently pushed back a couple of tiles, freely retryable); holding still "succeeds" once, permanently (sets a WorldState flag, no re-trigger, no reward loop) - see `game/scripts/cairn_encounter.gd`.
**Consequences:** No stats, health, or currency anywhere in this system - failing costs nothing but a few seconds and a short walk back; succeeding grants nothing numeric, just a flag and an atmospheric line. This sets the template for future challenge-layer content: tension from a simple, legible rule (here, stillness) plus atmosphere, not mechanical depth. `game/scripts/player.gd` gained `force_move_to()` (a scripted reposition bypassing normal input) specifically to support the "pushed back" beat - reusable for any future challenge-layer content that needs the same kind of non-player-initiated movement.
**Status:** final for this prototype instance; the general pattern (legible rule + atmosphere + flag, no numbers) is intended to guide future challenge-layer content, not just this one encounter.

---

### 2026-07-25 — Map authoring tool: named regions in GDScript, not Tiled or Godot's TileMap editor

**Rationale:** Issue #9 explicitly left the tooling choice open ("Tiled... or directly in Godot's TileMap editor, whichever proves faster in practice"). Both assume an interactive GUI (Tiled's application, or Godot's editor's TileMap paint tools); this project is built by an AI coding agent operating headless/CLI-only, with no mouse/window-driven editing available. A third option fits that constraint without adding a new toolchain dependency (Tiled + a Godot Tiled-importer plugin) or needing GUI automation: hand-author the layout as named `Rect2i`/`Vector2i` constants (house footprints, doors, the pond) checked in a fixed priority order in `main.gd::_tile_for()`, still built into the `TileMapLayer` through the same runtime `TileSet`-construction approach the procedural version used. This satisfies the actual distinction issue #9 cares about - hand-placed, deliberate structure vs. algorithmic/random generation - without depending on tooling that can't be driven in this environment.
**Consequences:** No Tiled `.tmx`/`.tmj` files or importer plugin in this repo. Adding/editing structures means editing named constants and the `_tile_for()` priority chain in `game/scripts/main.gd`, not painting in an external tool. If a human collaborator with editor/GUI access joins later and Tiled or Godot's TileMap editor genuinely becomes faster for authoring larger content, revisit this - the current approach doesn't scale gracefully much past a handful of hand-placed structures.
**Status:** final for AI-agent-only authoring; revisit if a GUI-capable collaborator takes over map content work.

---

### 2026-07-25 — Web save persistence: no manual FS.syncfs() call needed on this Godot version

**Rationale:** Godot's web export historically needed a manual JavaScript `FS.syncfs()` call (via `JavaScriptBridge.eval`) to flush `user://` writes from the in-memory IDBFS to the browser's real IndexedDB before a page reload — issue #3 was written expecting this. It was implemented first, then tested against the actual exported web build with a real Playwright-driven page reload (not just the Godot editor). That call threw `ReferenceError: FS is not defined` — on this project's Godot 4.7, that global isn't reachable from `JavaScriptBridge.eval`'s context; it's wrapped inside the engine's internal `GodotFS`/`godot_js_os_fs_sync` binding instead. The manual sync call was then removed entirely and the same real-browser-reload test was re-run: the save persisted correctly with no manual sync code at all, meaning `FileAccess.close()` already handles this internally on web in this Godot version.
**Consequences:** `game/scripts/save_system.gd` has no web-specific sync code — `save_game()`/`load_game()` are plain `FileAccess` calls that work identically across platforms. If save persistence ever appears to silently fail on web again (e.g. after a Godot version upgrade), re-verify this specifically against a real browser reload of the exported build before assuming a manual sync call is the fix — don't re-add the old `FS.syncfs()` approach blind, since the global isn't even valid in this version's export.
**Status:** final for Godot 4.7; revisit if the Godot version changes.

---

### 2026-07-25 — Genre and scope: Pokemon-scale exploration/story RPG, not creature-collection

**Rationale:** User direction — the game should match a mainline Pokemon game in *size and length* of gameplay, but the actual draw is exploration/atmosphere/story rather than monster-collecting or battling. Confirmed explicitly when offered "creature-collection RPG" vs. "viking party/companion RPG" vs. "exploration/story RPG" as options.
**Consequences:** No creature-collection mechanic, no party of collectible monsters. World/content design targets ~15–25h main length across many connected regions — see `docs/PROJECT_VISION.md`. Content built in shippable acts (M3, M5) rather than one release, given the length target and solo/no-budget constraint.
**Status:** final.

### 2026-07-25 — Combat: light/stylized challenge layer, not a full battle system

**Rationale:** User direction, chosen over a full turn-based battle engine. Supersedes the initial GitHub issue #4 ("[Epic] Turn-based battle system"), opened earlier in this same session before this decision was made — that issue is closed as superseded.
**Consequences:** M1 prototypes one concrete form of the challenge layer (exact form — puzzle, tense/stealth encounter, etc. — still open, see `docs/PROJECT_VISION.md` "What's not decided yet"). Removes a large chunk of systems/content scope (stats, moves, enemy roster, battle UI) that a full battle system would have required, which matters directly for solo/no-budget feasibility.
**Status:** final (specific mechanic form: provisional, to be prototyped in M1).

### 2026-07-25 — Art production: AI-generated + hand cleanup, systematized via a pipeline

**Rationale:** User named art/graphics as the top priority ("premium, well thought out," "pixel style like Pokemon"), while also confirming solo development with no cash budget — ruling out commissioning a dedicated pixel artist. AI-generation with hand cleanup was chosen over licensed asset packs or purely hand-made art as the best fit for that constraint pair.
**Consequences:** Consistency is the central risk of this choice (see `docs/PROJECT_VISION.md` risks). M2 is dedicated entirely to building an art bible + a scripted production pipeline (palette-clamping, seam/consistency validation, hero-vs-bulk asset split) before content production scales up, specifically to keep AI-assisted art from reading as inconsistent or generic. Extends the Pillow-based programmatic art tooling already used for the M0 placeholder assets.
**Status:** superseded 2026-07-25 (see the entry below) — the specific mechanism ("AI-generated") turned out not to be executable in this environment; the underlying rationale (top priority, no budget, needs systematized consistency) still holds and shaped the replacement.

### 2026-07-25 — Art production, revised: procedural generation, invested further rather than replaced

**Rationale:** Starting M2's breakdown surfaced that the AI-generation half of the previous decision was never actually executable — there is no image-generation tool available in this environment (no DALL-E/Stability/Midjourney-equivalent access), so every placeholder asset built through M1 (tileset, character sprites, the wisp, the icon) was already procedural/parametric pixel art via Python/Pillow, not AI-generated. Offered the choice directly (API-key-driven generation the user would need to provide credentials for; user-generated-externally-then-processed; a pivot to curated free/CC0 asset packs; or investing further in the procedural approach already in use), the user picked continuing procedural generation - it requires no new dependency or credential, stays fully within what I can actually execute end-to-end, and had already produced results the user was satisfied with through M1.
**Consequences:** M2's scope changes from "AI-generate → hand-polish → validate" to "systematize and substantially deepen the procedural pipeline" - proper palette discipline, lighting/shading rules, more detailed silhouettes/proportions, still validated for consistency, still with a hero-vs-bulk split (hand-tuned parameters for signature assets vs. templated generation for bulk tiles/props). `docs/PROJECT_VISION.md`'s M2 description and risk list are updated to match. The core risk shifts slightly: less "AI-art sameness/uncanny," more "procedural art hitting a craft ceiling a trained illustrator wouldn't" - mitigated the same way (an art bible enforcing deliberate choices, iteration/reference-driven parameter tuning, not accepting first-pass output).
**Status:** final for as long as this project is built by an AI agent without image-generation tool access; revisit immediately if that access ever becomes available.

### 2026-07-25 — Team and budget: solo developer + AI-assisted engineering, no cash budget

**Rationale:** User confirmed directly — no collaborators, no budget for art/audio/tools.
**Consequences:** This is the constraint the whole roadmap is designed around — see "The honest scope reality" in `docs/PROJECT_VISION.md`. Every milestone is scoped to be independently shippable/valuable rather than assuming a large continuous team effort toward one final release.
**Status:** final (revisit if this changes — e.g. a collaborator or budget becomes available later).

### 2026-07-25 — Publishing: free web release (itch.io + GitHub Pages)

**Rationale:** User direction, chosen over paid Steam/mobile releases for the initial target. Matches the already-working GitHub Pages deploy pipeline from M0 and keeps compliance/overhead minimal for a solo no-budget project.
**Consequences:** No store-review or payment-integration work needed for M1–M3. Desktop build (M4) and mobile ports (M7) are explicitly deferred decision points, not commitments — revisit once the game exists and playing field (revenue interest, platform reach) is clearer.
**Status:** final for the initial release; desktop/mobile explicitly open for later milestones.

### 2026-07-25 — Setting and tone: grounded Viking-Age world, mythic edges — same stance as norse-game

**Rationale:** User direction, chosen over "historically-grounded Viking Age" (heavier research/authoring burden) and "Norse-myth fantasy" (gods/beasts played as literally real). This is the exact tonal stance `norse-game` (sibling project, same account) already established and did research toward.
**Consequences:** Folklore/myth appears in the fiction as belief, rumor, atmosphere — never confirmed as objectively true to the player. Reuses `norse-game`'s authenticity discipline (no romanticizing Viking-Age violence/slavery, no treating "the Vikings" as one homogeneous culture, careful/non-stereotyping treatment of Sámi history if the setting touches that region) as a *stance to match*, not a code/content dependency — see `docs/PROJECT_VISION.md` "Relationship to norse-game". This project's own specific setting, story, and characters remain undecided.
**Status:** final (tonal stance); specific setting/story: not yet decided.
