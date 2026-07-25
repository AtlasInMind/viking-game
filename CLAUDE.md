# Viking Game

## Project overview

A **Pokemon-scale exploration/story RPG** for the browser, built in Godot with GDScript: grid-based overworld movement, tile-based maps, readable premium pixel art, a light challenge layer instead of a full battle system. "Pokemon-scale" means *length* (15-25h+ across many regions), not the creature-collection mechanic — see `docs/PROJECT_VISION.md` for the full picture and `docs/DECISIONS.md` for how these calls were made. **Primary platform is web (browser)**; a desktop build and mobile ports are open decisions for later milestones, not commitments — see `docs/PROJECT_VISION.md`.

This is a solo project (one developer + AI-assisted engineering) with no cash budget — that constraint shapes the whole roadmap (content shipped in acts, pipelines over bespoke work; see `docs/PROJECT_VISION.md` "The honest scope reality"). Genre, combat approach, art-production method, team/budget, publishing target, and setting/tone are decided (`docs/DECISIONS.md`) — the actual setting, story, and cast are **not**; don't invent lore/setting details and treat them as established. If a decision is needed to move a task forward, make the smallest reasonable choice and record it, or ask.

Placeholder art/audio is expected and fine early on — the current tileset and character sprite were generated programmatically (see `game/assets/`) purely to make the scaffold playable and demonstrable in a browser. M2 exists specifically to replace ad-hoc placeholder generation with a real art bible + production pipeline; don't block gameplay/systems work on having final assets before then.

## Documents to read first

1. `docs/PROJECT_VISION.md` — what the project is, the milestone roadmap, and why it's shaped the way it is.
2. `docs/DECISIONS.md` — decisions made so far, with rationale.
3. `README.md` — how to open/run/export the project.

Don't rely on prior conversation context or Claude's memory — everything load-bearing should be in `docs/`. If something important is missing there, it hasn't been established yet.

## Platform and engine

- Engine: Godot 4.x, language: GDScript. Built and tested against 4.7.
- Web export uses the GL Compatibility renderer (required), `canvas_items` stretch mode with `expand` aspect, and Nearest texture filtering (crisp pixel art) — see `game/project.godot`.

## Development workflow

Work is tracked via GitHub Issues, grouped into milestones. Per issue:

1. Take the lowest-numbered open issue in the earliest open milestone. Don't jump ahead unless the issue's "Dependencies" section says otherwise.
2. Read the issue's description and any linked docs — every issue should be understandable on its own, without relying on memory of past sessions.
3. Follow the issue's "Acceptance criteria".
4. Before commit/push: get the code reviewed by a fresh, independent agent with no context from the conversation (it should find background itself, from the repo, not be briefed on what was just built). Fix real findings before moving on.
5. Once criteria are met and review is handled: commit, push to `main`, and close the issue with a short comment on what was done. Don't commit/push unless the issue's acceptance criteria are met.
6. Before moving to the next issue, verify it's safe to end the session: `git status` clean, local `main` in sync with `origin/main`, issue closed with a summary comment.
7. Go back to step 1.

If an issue is labeled `epic`, it hasn't been detailed yet — break it into concrete issues using `.github/ISSUE_TEMPLATE/task.md`, tied to the same milestone, based on what's actually been built so far.

## Project structure

- `game/` — the Godot project (kept separate from repo-root docs/planning). See `README.md` for the full folder breakdown and how to open/run/export it.
- `docs/` — `PROJECT_VISION.md`, `DECISIONS.md`, `deployment.md`, `ART_BIBLE.md` today. `WORLD_BIBLE.md` (as setting/story get decided) will join these. Don't assume other documents exist beyond what's actually there.

## Maintaining documentation

- Non-obvious decisions (technical or creative) go in `docs/DECISIONS.md` with date, rationale, and consequence.
- Keep `docs/PROJECT_VISION.md`'s milestone table in sync with reality as milestones complete or the roadmap changes.
- Don't overwrite existing, verified content without reason — integrate carefully.
