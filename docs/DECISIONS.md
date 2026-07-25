# Decisions Log

## Purpose

Chronological log of significant project decisions, with rationale, consequences, and status (final/provisional).

## Last updated

2026-07-25

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
**Status:** final (specific tooling/pipeline steps: provisional, to be built out in M2).

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
