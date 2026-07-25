# Viking Game

A top-down 2D exploration RPG for the browser, in the spirit of the GBA-era Pokemon games — grid-based movement, a tile-based overworld, readable pixel art. Built in Godot with GDScript.

## Status

Early scaffold: a small explorable overworld with grid-based movement, collision, and camera follow. No battle system, NPCs, or content yet — see open issues/milestones on GitHub for what's next. All art is placeholder, generated programmatically; it's expected to be replaced once real art direction is set.

## Platform

- Engine: Godot 4.x, language: GDScript. Built and tested against 4.7.
- **Primary platform: web (browser)**, exported via Godot's HTML5/WebAssembly export. Android/iOS are possible later exports from the same codebase, not prioritized yet.

## Development

The Godot project lives in `game/`, not the repo root, to keep engine/source separate from repo-level docs and planning.

### Open/run the project

1. Install [Godot 4.x](https://godotengine.org/download) (tested with 4.7).
2. Clone this repo.
3. Open Godot, choose "Import", and point it at `game/project.godot`.
4. Press F5 ("Run Project").

### Folder structure (`game/`)

- `scenes/` — `.tscn` scenes (the overworld, the player, UI).
- `scripts/` — GDScript files.
- `assets/` — sprites and tile art (currently placeholder, generated programmatically).

The overworld tileset and map are built at runtime (`scripts/main.gd`) from the tile atlas in `assets/tiles/`, rather than hand-authored as a `.tscn`/`.tres` resource — simpler to keep in sync while the map is still just a procedurally-laid-out placeholder.

### Project settings of note

- Default Texture Filter: Nearest (crisp pixel art).
- Stretch Mode: `canvas_items`, Stretch Aspect: `expand`.
- Renderer: GL Compatibility (required for web export).

### Web export

1. Download the Godot export templates matching the editor version from `github.com/godotengine/godot/releases` (`Godot_v<version>-stable_export_templates.tpz`) and unpack to `~/Library/Application Support/Godot/export_templates/<version>.stable/` (macOS). Not bundled with the editor — one-time setup per machine.
2. Export from the command line (run from `game/`): `mkdir -p ../builds/web && godot --headless --export-release "Web" ../builds/web/index.html`. The target folder must exist beforehand — Godot doesn't create it. Output goes to `builds/` at the repo root (git-ignored).
3. To test locally: serve `builds/web/` with a simple HTTP server (e.g. `python3 -m http.server`) and open in a browser — it won't work opened directly as `file://`.

### Deployment

Published to GitHub Pages — see `docs/deployment.md` for the live URL and the redeploy steps.
