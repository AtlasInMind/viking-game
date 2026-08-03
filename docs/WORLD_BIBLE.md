# World Bible

## Purpose

The actual setting, Act 1 story, and cast for this project — the specifics `docs/PROJECT_VISION.md` deliberately left open ("What's not decided yet") until this milestone. Decided directly with the user per issue #16, not invented unilaterally; see `docs/DECISIONS.md` for the decision record. Everything here is Act-1-scoped unless marked otherwise — the wider mystery is expected to unfold across later content acts (M5), not resolve entirely in this first demo. Act 2's setting/story/cast (below) was decided the same way, directly with the user, per issue #34.

## Setting

A fictionalized, composite Norwegian fjord coastal settlement, Viking Age. **Not** tied to `norse-game`'s specific Lofoten/Vesterålen/Salten region or its narrative — this project reuses that sibling project's tonal *stance and discipline* only (see `docs/PROJECT_VISION.md` "Relationship to norse-game"), not its geography or story. No real place name is attached yet; if one becomes useful later (marketing, flavor), treat that as a separate, small decision, not something to invent by drift.

The settlement lives by fishing, trade, and seasonal expeditions — voyages combining trading and exploration, not raiding. This is a deliberate choice, not an oversight: it keeps Act 1's inciting event grounded in something the community would plausibly send its people out to do repeatedly, without the story needing to romanticize or center violence/raiding to explain why a ship full of people left for five months. If raiding or conflict needs depicting in later content, it follows the same non-romanticizing discipline `norse-game` established (no treating violence as glorious spectacle, no flattening "the Vikings" into one culture/practice).

## Act 1: "One Man Remains"

A longship that left five months ago on an expedition returns unexpectedly, drifting into the fjord with no one at the oars. Of the 23 people who left, only one remains: **Hakon**, found badly injured and unconscious beneath the sailcloth. When he wakes, he recognizes everyone in the settlement but remembers nothing past the expedition's first night — and insists, calmly and repeatedly, that they "never left the fjord." The ship itself proves otherwise: foreign goods, worn gear, and other physical evidence of a real, long voyage are aboard.

The player — a resident of the settlement, close enough to the situation to plausibly get involved (exact relationship to Hakon or the missing crew is an implementation detail for the content issues to settle, not fixed here) — reconstructs what actually happened through three parallel threads:
- **Objects:** cargo and gear recovered from the ship, each a real clue (this is also where the item/inventory system, issue #17, earns its keep — these are the "items," not generic pickups).
- **Witnesses:** people in the settlement with a stake in specific missing crew members, each holding a different piece of the picture and a different emotional read on it.
- **Hakon's returning memory:** fragments surface over the course of Act 1 (through rest, through being shown specific recovered objects, through specific conversations) rather than all at once.

Gradually, this reveals that the crew found another abandoned longship partway through the voyage, and that something fractured the expedition on the way home — not necessarily violence, not necessarily anything supernatural, and Act 1 does not resolve which. The central question deliberately shifts over the course of the act, from **"where did the crew go"** to **"why were they afraid to come home."** Whatever actually happened stays exactly as ambiguous as the rest of this project's folklore/myth content is designed to be (`docs/PROJECT_VISION.md` design pillar 3) — belief, dread, and half-answers, never a confirmed monster or a confirmed mundane explanation. Act 1's ending should land on a real, satisfying revelation (the abandoned ship, the shape of what fractured the crew) without claiming to have the final answer — that's material for later acts, not a plot hole.

## Act 2: "The Second Ship"

Picks up directly from Act 1's ending rather than starting a new, unrelated mystery — the abandoned longship the crew found mid-voyage (Act 1's own revelation, never explored on-screen) is now the destination, not just a line of dialogue. Village pressure (Thora, Steinar, and Solveig all still wanting real answers) plus Hakon's own memory continuing to surface pushes toward actually going to find it. Gunnar, already established as the trader with sea knowledge, arranges passage. Hakon insists on coming along — physical proximity to where it happened is what continues to surface his memory, not distance from it.

The journey has two stops, in order:
1. **The shoreline camp** — where Hakon's own crew (the 22 who didn't return) made landfall and camped before finding the second ship. A hastily-abandoned camp: cold fire pits, gear left mid-use, and personal effects/carvings belonging to specific missing crew members — this is where a piece of Thora's son or another named-but-absent crewmate's belongings can surface, giving Act 1's grieving cast a real, concrete find rather than the story only ever engaging with the *survivor's* side of things. The traces here should read as urgency/fear, not violence — whatever happened, this crew broke camp in a hurry.
2. **The second ship's wreck** — a *different, older, unrelated* wreck: its own unknown crew, a separate disappearance, found by Hakon's crew mid-voyage. Their personal effects are present and neatly arranged — no bodies, no scattered/looted mess, no clear sign of a struggle. This is the story's central image for Act 2: an eerie, unexplained parallel to what will eventually happen to Hakon's own crew, discovered by them just before it happens to them too. It is never suggested that the two disappearances are literally the same phenomenon, only that finding this is very plausibly *what frightened Hakon's crew in the first place* — seeing an unexplained vanishing that looks exactly like an orderly, deliberate departure, with nowhere for that dread to go but home.

This deliberately does **not** resolve what fractured either crew — per the mythic-edges stance (`docs/PROJECT_VISION.md` design pillar 3), Act 2 deepens the dread with a real, concrete discovery (the second ship is real, the parallel is real) rather than explaining it away. The central question stays exactly where Act 1 left it, now with more weight behind it, not "solved."

Reuses the challenge-layer mechanic (`game/scripts/cairn_encounter.gd`'s "hold still" pattern, already reused once for Act 1's ship) for a beat at the second ship itself: another fragment of Hakon's memory surfacing, framed as recognition rather than a new symptom — he's seen this before, days before he lost the rest of his memory.

## Cast

- **Hakon** — the sole survivor. Physically recovering, mentally fogged past the first night of the voyage. Not a mystery box to be "solved" and discarded — he's a person genuinely trying to remember, frightened by the gaps, and not lying about what he believes to be true.
- **Steinar** — younger brother of the expedition's leader (who did not return). Under pressure to account for his brother's decisions and, implicitly, to step into a leadership role he didn't ask for. A source of tension around blame and succession.
- **Thora** — mother of one of the missing crew, a young rower. Grief-driven, wants concrete answers more than anyone, and is the player's likely first push toward taking the investigation seriously rather than accepting Hakon's confused account at face value.
- **Ingrid** — betrothed to another of the missing crew. Holds a different, more private kind of knowledge — letters, a promise, something personal the missing crewman told her before leaving that nobody else knows.
- **Gunnar** — the settlement's trader. Recognizes foreign goods among the ship's cargo for what they are and roughly where they'd have come from, turning objects into geography and giving the investigation real direction.
- **Solveig** — the settlement's elder, who sanctioned the original expedition. Holds the institutional memory of why it was sent out in the first place and carries the settlement's collective reaction (fear, suspicion, grief) as much as any personal stake.

Six named cast plus Hakon-as-central-figure is deliberately a *small* cast, matching `docs/PROJECT_VISION.md`'s design intent. Issue #20 placed all six in Act 1 rather than holding any back - the cast is small enough, and each person's placement (Hakon and Thora near the house he recovers in, Steinar near his family's house, Solveig and Ingrid near the crossroads, Gunnar on the ship itself examining the recovered cargo) gave every one of them a concrete reason to be exactly where they are, rather than needing to defer some to a later act for lack of a place to put them.

**Act 2** deliberately introduces no new living NPC - the second ship's own crew are long gone, and their story is told through objects/environment, not a person who explains them (keeping the "never a confirmed monster, never a confirmed mundane explanation" discipline intact; a new witness who could plausibly *know* what happened would undercut that). Existing cast carries Act 2 instead: **Hakon** travels along and continues recovering memory in proximity to where it happened; **Gunnar** arranges and provides the boat, the natural extension of his established trader/sea-knowledge role. **Thora**, **Steinar**, **Ingrid**, and **Solveig** stay in the settlement but get a coda reacting to whatever's recovered from the shoreline camp (a piece of Thora's son's, Ingrid's betrothed's, or another absent crewmate's effects) once the player returns - their arcs continue without needing to physically travel. Ingrid in particular is a natural fit for this: she already holds private knowledge nobody else does, and a personal effect surfacing from the camp is exactly the kind of concrete find that knowledge should react to.

Issue #36 placed this concretely: **Hakon** is in both `shoreline_camp.gd` (near where his crew's camp stood) and `second_ship.gd` (deck, facing the wreckage), each with its own line - the same character present wherever the player is, matching how Gunnar already works in `ship.gd`. **Gunnar** stays exactly where issue #20 put him, on the ship's deck, rather than being duplicated into the new areas - the boat he arranges *is* that ship, so a line there is already literally true without a second placement. All six Act 1 cast (Hakon, Gunnar, Thora, Steinar, Solveig, Ingrid) gained a new top-priority `dialogue_lines` entry gated on `QuestFlags.ACT_ONE_RESOLVED`, giving each an Act-2-appropriate line instead of repeating Act 1 text once that flag is true - the full "reacting to a specific recovered effect" coda described above still needs a real find/flag to react to, which is issue #37's job, not this one's.

## Areas

Full intended geography for this story thread:

1. **The coastal settlement** — home base, built in Act 1 (`game/scripts/main.gd`).
2. **The longship** — the returned ship, explorable for physical evidence, built in Act 1 (`game/scripts/ship.gd`).
3. **The shoreline camp** (Act 2) — where Hakon's crew made landfall and camped before finding the second ship; this is the renamed/clarified version of what this doc previously called "the abandoned crew camp" before issue #34 (that older entry described *Hakon's own crew's* landfall, which is this location, not the wreck below). Reached from the settlement by the boat Gunnar arranges; the concrete "how do you get there" question and any further connective area-transition detail is issue #35's to settle, not fixed here.
4. **The second ship's wreck** (Act 2) — the older, unrelated abandoned longship itself, a genuinely new location (not a renaming of anything previously in this doc), this act's biggest single revelation-location.
5. **Islands and fishing camps** more broadly — beyond the one shoreline/wreck Act 2 actually uses, still open for a later act if M5's remaining region count needs them.

## Open / deliberately undecided

- The player's exact relationship to Hakon or the missing crew.
- What actually fractured the expedition, and what the second ship's crew's own disappearance actually was — intentionally left ambiguous, not a placeholder for "to be decided later and then revealed"; the ambiguity is the point, consistent with this project's myth-as-belief stance. Act 2 deepens both without resolving either.
- A real-world-adjacent name for the settlement/region, if one turns out to be useful — if that ever gets decided, whether the chosen placement would touch a real region with Sámi history needs checking *at that point*, per the "careful, non-stereotyping treatment of Sámi history and presence if/when the setting touches that region" standard `docs/PROJECT_VISION.md` and `CLAUDE.md` both already require. The current "fictionalized composite" framing sidesteps the question for now, not resolves it. Applies equally to wherever Act 2's shoreline/wreck are placed.

## Last updated

2026-07-26 — initial version, following issue #16. Cast-placement question resolved (all six in Act 1), following issue #20.

2026-07-27 — Act 2 ("The Second Ship") setting, story, and cast decided, following issue #34.

2026-08-03 — Act 2 cast placed and given dialogue (Hakon in `shoreline_camp.gd`/`second_ship.gd`, all six Act 1 cast gaining an `ACT_ONE_RESOLVED`-gated coda line), following issue #36.
