# World Bible

## Purpose

The actual setting, Act 1 story, and cast for this project — the specifics `docs/PROJECT_VISION.md` deliberately left open ("What's not decided yet") until this milestone. Decided directly with the user per issue #16, not invented unilaterally; see `docs/DECISIONS.md` for the decision record. Everything here is Act-1-scoped unless marked otherwise — the wider mystery is expected to unfold across later content acts (M5), not resolve entirely in this first demo.

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

## Cast

- **Hakon** — the sole survivor. Physically recovering, mentally fogged past the first night of the voyage. Not a mystery box to be "solved" and discarded — he's a person genuinely trying to remember, frightened by the gaps, and not lying about what he believes to be true.
- **Steinar** — younger brother of the expedition's leader (who did not return). Under pressure to account for his brother's decisions and, implicitly, to step into a leadership role he didn't ask for. A source of tension around blame and succession.
- **Thora** — mother of one of the missing crew, a young rower. Grief-driven, wants concrete answers more than anyone, and is the player's likely first push toward taking the investigation seriously rather than accepting Hakon's confused account at face value.
- **Ingrid** — betrothed to another of the missing crew. Holds a different, more private kind of knowledge — letters, a promise, something personal the missing crewman told her before leaving that nobody else knows.
- **Gunnar** — the settlement's trader. Recognizes foreign goods among the ship's cargo for what they are and roughly where they'd have come from, turning objects into geography and giving the investigation real direction.
- **Solveig** — the settlement's elder, who sanctioned the original expedition. Holds the institutional memory of why it was sent out in the first place and carries the settlement's collective reaction (fear, suspicion, grief) as much as any personal stake.

Six named cast plus Hakon-as-central-figure is deliberately a *small* cast, matching `docs/PROJECT_VISION.md`'s design intent — not every named character needs to be in Act 1's first playable version; #20 (cast/dialogue content) can decide which subset is actually necessary for a 1-2h demo versus held for later acts.

## Areas

Full intended geography for this story thread (not all required for Act 1 — see `docs/PROJECT_VISION.md`'s M3 scope and issue #19 for what's actually in-scope now):

1. **The coastal settlement** — home base. The existing M1 village map (`game/scripts/main.gd`) can likely be reflavored/adapted into this rather than rebuilt from scratch.
2. **The longship** — the returned ship itself, explorable for physical evidence. The most natural candidate for issue #19's "second connected area," since it's the most direct extension of the inciting incident and doesn't require the wider geography to be built yet.
3. **Islands and fishing camps** — nearby, likely boat-reachable. Later-act content unless Act 1's scope grows to need it.
4. **Remote shoreline** — where remnants/clues from the voyage's end may surface. Later-act content.
5. **The abandoned crew camp** — where the expedition actually made landfall on the leg of the voyage that fractured them. The story's biggest single revelation-location; likely held for a later act rather than Act 1, unless #21 (main quest) finds it necessary to reach a satisfying Act 1 ending.

## Open / deliberately undecided

- The player's exact relationship to Hakon or the missing crew.
- What actually fractured the expedition — intentionally left ambiguous, not a placeholder for "to be decided later and then revealed"; the ambiguity is the point, consistent with this project's myth-as-belief stance.
- A real-world-adjacent name for the settlement/region, if one turns out to be useful — if that ever gets decided, whether the chosen placement would touch a real region with Sámi history needs checking *at that point*, per the "careful, non-stereotyping treatment of Sámi history and presence if/when the setting touches that region" standard `docs/PROJECT_VISION.md` and `CLAUDE.md` both already require. The current "fictionalized composite" framing sidesteps the question for now, not resolves it.
- Which of the six named cast members Act 1 actually needs versus which are later-act material — for #20 to decide based on actual demo scope.

## Last updated

2026-07-26 — initial version, following issue #16.
