# Project Vision

## What this is

A **Pokemon-scale exploration/story RPG** for the browser, built in Godot. "Pokemon-scale" means *length* — a world worth 15–25+ hours across many connected regions — not the creature-collection/battling mechanic. The draw here is exploration, atmosphere, quests, and story.

- **Genre:** exploration/story RPG, Pokemon-scale length.
- **Combat:** a **light/stylized challenge layer** (tense encounters, puzzles, simple non-grindy confrontations) — deliberately *not* a full turn-based battle engine. This was an open question early on (see the now-superseded "[Epic] Turn-based battle system" issue) and was decided against in favor of keeping the focus on exploration/story.
- **Setting & tone:** a **grounded Viking-Age world with mythic edges** — folklore and myth are present as belief and atmosphere (a rumor, a place people avoid, a story half-told), never confirmed as objectively true. This is the same stance as the sibling project `norse-game` (see "Relationship to norse-game" below).
- **Team & budget:** solo developer directing + AI-assisted engineering, **no cash budget**. This shapes everything below — art production, scope pacing, and how "full length" gets reached.
- **Publishing:** free, on the web — itch.io + GitHub Pages.

## The honest scope reality

A mainline Pokemon game is 20–40 hours built by a studio over years. Solo + AI + no budget cannot brute-force that by working harder — it has to be reached differently, through:

1. **Repeatable pipelines over bespoke work.** Art, maps, dialogue, and quests are produced through tooling and data wherever possible, so content *scales* instead of being hand-built per instance.
2. **Ship early, ship often.** Every milestone produces something publicly playable. The first *publishable* thing is a polished 1–2h demo, not the finished game. Shipping early is the main defense against the project stalling.
3. **Content in acts.** Full length is approached by shipping self-contained story acts on top of a proven engine, not one monolithic release at the end.

A strong publishable demo is realistically a few months of steady part-time work; full Pokemon-length is realistically a multi-year commitment. That's the actual cost of this ambition — the milestone structure below exists so the project stays valuable and shippable at every stop along the way, not just at a distant finish line.

## Design pillars

1. **Exploration first** — the world rewards curiosity; secrets, vistas, and small stories everywhere.
2. **Premium, cohesive pixel art** — consistency (palette, grid, lighting, proportion) enforced by tooling, not vibes. Art is the stated top priority of the project. A believable, hand-crafted *feel* even though art is procedurally generated — see `docs/ART_BIBLE.md`.
3. **Grounded, mythic atmosphere** — a real Viking-Age texture; myth lives as belief, never confirmed. See "Relationship to norse-game."
4. **Quality over quantity** — a smaller world that feels intentional beats a large one that feels generated.

## Relationship to norse-game

`norse-game` (sibling repo, same GitHub account, not a code dependency) already established a "grounded world, mythic edges" tone and did serious research toward it — see its `docs/research/` corpus, `docs/research/authenticity_and_sensitive_topics.md`, and its source-register discipline. This project reuses that *stance and discipline*, not its code or its specific narrative content:

- No romanticizing Viking-Age violence/slavery.
- No reducing "the Vikings" to one homogeneous culture/religion.
- Careful, non-stereotyping treatment of Sámi history and presence if/when the setting touches that region — see `norse-game`'s `authenticity_and_sensitive_topics.md` §2.7 for the standard to meet.
- Historical grounding held *internally* (writers should know what's fact vs. plausible reconstruction vs. legend) but never displayed to the player as citations/certainty tags — myth shows up as belief, not footnotes.

This project's own setting, story, and characters are still undecided beyond this tonal stance — see "What's not decided yet" below.

## Milestone roadmap

| Milestone | Theme | Public deliverable |
|---|---|---|
| **M0** | Foundation | Done — scaffold + live web deploy |
| **M1** | Core systems vertical slice | A 15–30 min hand-crafted playable slice that *feels* premium |
| **M2** | Art bible + production pipeline | Locked visual identity + tooling; M1 re-skinned to look cohesive |
| **M3** | Publishable demo (Act 1) | First public itch.io + web release; devlog begins |
| **M4** | Long-game systems & depth | Engine that can carry a 20h+ game |
| **M5** | Content scaling (the long haul) | Full world built act-by-act via the pipeline |
| **M6** | Polish, balance & launch prep | Store page, trailer, playtested release candidate |
| **M7** | Launch & post-launch | 1.0 release; patches; optional ports |

Full detail per milestone, including concrete scope, lives on the GitHub milestones themselves (issues + milestone descriptions) — that's the live, authoritative backlog. This document is the *why* and the *shape*; GitHub Issues is the *what's next*.

### M1 — Core systems vertical slice
Prove all the pillars in one hand-crafted region, built data-driven so it scales later: title screen, save/load (verified against a real browser reload — the classic web-export gotcha), data-driven NPC + dialogue system, a quest/flag/world-state system as the backbone all content hangs on, one authored map (replacing the current procedural placeholder), and a first working version of the light challenge mechanic. Art for this slice should be at target quality so "premium" becomes concrete, not aspirational.

### M2 — Art bible + production pipeline
The single most important milestone given the project's stated priority. Art here is **procedural** (Python/Pillow-generated), not AI-generated as originally planned — there's no image-generation tool available in this environment, so the M0/M1 placeholder art was already produced this way; M2 invests further in that approach rather than replacing it (see `docs/DECISIONS.md` "Art production, revised"). Produces `docs/ART_BIBLE.md` (palette, resolution, proportions, lighting/shading rules, tile-grid rules, UI style) and a substantially deeper procedural pipeline (palette discipline, shading, silhouette detail, consistency validation), extending the Pillow tooling already used for M0/M1. Hero/signature art gets hand-tuned parameters and more iteration; tiles/props/filler go through more templated generation. Exit: the M1 slice re-skinned through this pipeline and reading as one cohesive world.

### M3 — Publishable demo (Act 1)
M1 expanded into a self-contained 1–2h story arc, released publicly (itch.io + web) with a devlog started. Needs inventory/items and progression gating (item/ability/story-flag gates — the "HM" equivalent) on top of M1's systems.

### M4 — Long-game systems & depth
Everything a 20h+ game needs that a demo can fake: cutscene/dialogue-scripting for story beats, journal/quest-log/world-map/fast-travel, accessibility (remappable input, text size, colourblind-safe palette, touch controls), asset-budget/atlasing/lazy-loading for web payload management (measured using `norse-game`'s documented methodology), and a decision on whether to also offer a downloadable desktop build for the full-length game.

### M5 — Content scaling
The full world, built region-by-region via M2's pipeline and M4's systems, shipped as public content acts (Act 2, Act 3, …), each separately playtested. Rough targets to tune against, not hard requirements: ~8–12 explorable settlements/regions, a main questline of ~15–25h, a web of side content, a memorable cast, recurring secrets.

### M6 — Polish, balance & launch prep
Full-playthrough passes, pacing/balance, bug-fix bar, final performance pass, store presence (copy, screenshots, trailer), external playtest cohort, release candidate.

### M7 — Launch & post-launch
1.0 release, patch loop from feedback, optional mobile/desktop ports revisited once the full game exists.

## What's not decided yet

Deliberately open — don't invent and treat as established:

- The actual setting specifics: which coastline/region, what the central mystery/story is, who the cast are.
- The exact form of the "light challenge layer" mechanic (puzzle? tense/stealth encounter? something else?) — to be prototyped and chosen in M1.
- Whether a desktop build ships alongside the web version (M4 decision point).
- Whether mobile ports happen at all (M7 decision point, revisited once the game exists).

## Key risks & mitigations

- **Art consistency at scale** (top risk, given procedural generation as the method) → art bible + tooling-enforced palette/grid + hand-tuned hero assets + an art-direction pass on every batch (M2).
- **Solo scope / burnout** → every milestone independently valuable and shippable; content shipped in acts; demo out early (M3) for motivation and feedback.
- **Procedural art hitting a craft ceiling** (a trained illustrator's judgment isn't procedurally reproducible) → an art bible enforcing deliberate palette/shading/proportion choices, iteration/reference-driven parameter tuning rather than shipping first-pass output, hero assets getting disproportionate attention.
- **Web payload growth for a long game** → strict asset budgets, atlasing, per-region lazy-loading, optional desktop build (M4).
- **"Pokemon-length" expectation vs. solo reality** → explicit north-star-vs-first-publishable framing (this document); track progress by shippable acts, not distance from a 40-hour ideal.

## Verification strategy (per increment, all milestones)

- **Godot headless run** of the target scene — catches parse/scene errors before commit.
- **Playwright browser tests** against the *exported* web build — scripted movement/interaction, before/after screenshots, zero-console-error check.
- **Deploy to GitHub Pages and verify the live URL** actually renders and plays.
- **Structured playtest** each milestone (self-playtest from the start, external feedback from M3 on) — log findings as issues.
- **Performance/payload measurement** from M4 on, using `norse-game`'s documented method (`docs/deployment.md` there is the reference for methodology).

## Last updated

2026-07-25 — initial roadmap, following the M0 scaffold-and-deploy session.
