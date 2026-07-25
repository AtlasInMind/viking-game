# Viking Game

## Project overview

A top-down 2D exploration RPG for the browser, built in Godot with GDScript, in the spirit of GBA-era Pokemon games: grid-based overworld movement, tile-based maps, readable pixel art, simple systems that read clearly at a glance. **Primary platform is web (browser)**; Android/iOS are possible later exports from the same codebase, not prioritized yet.

Creative direction (world, story, characters, tone beyond "GBA-style viking adventure") is not yet decided — that's open work, not something to assume from the project name. Don't invent lore/setting details and treat them as established; if a decision is needed to move a task forward, make the smallest reasonable choice and record it, or ask.

Placeholder art/audio is expected and fine — the current tileset and character sprite were generated programmatically (see `game/assets/`) purely to make the scaffold playable and demonstrable in a browser. Replace it if/when real art direction is set; don't block gameplay/systems work on having real assets.

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
- `docs/` — deployment notes and any design/decision docs as they accumulate. Not yet a large corpus; don't assume documents exist that aren't actually there.

## Maintaining documentation

- Non-obvious decisions (technical or creative) go in `docs/DECISIONS.md` (create it when the first decision worth recording comes up) with date, rationale, and consequence.
- Don't overwrite existing, verified content without reason — integrate carefully.
