# Deployment

## Hosting choice: GitHub Pages

Zero additional accounts/credentials, same reasoning as norse-game: the repo is public, served from an orphan `gh-pages` branch containing only the exported web build.

**Live URL:** https://atlasinmind.github.io/viking-game/

## How it works

- `gh-pages` (root) contains only the exported build (`index.html`, `index.js`, `index.wasm`, `index.pck`, icons, `.nojekyll`) — no project source, no shared history with `main`. It's replaced wholesale on each deploy.
- GitHub auto-detected the branch on first push and enabled Pages against it automatically.

## How to redeploy after a change

From `game/`, with a clean `main` working tree:

```sh
mkdir -p ../builds/web
godot --headless --export-release "Web" ../builds/web/index.html
```

Then, from the repo root, publish via a disposable worktree (keeps `main`'s working tree untouched):

```sh
git worktree add -B gh-pages-update /tmp/viking-game-ghpages-update gh-pages
rm -rf /tmp/viking-game-ghpages-update/*
cp -r builds/web/* /tmp/viking-game-ghpages-update/
cd /tmp/viking-game-ghpages-update
git add -A
git commit -m "Update web export"
git push origin gh-pages-update:gh-pages
cd - && git worktree remove /tmp/viking-game-ghpages-update --force && git branch -D gh-pages-update
```

This is a manual process, not yet automated via GitHub Actions — worth revisiting once deploys become frequent enough to justify the CI setup cost (Godot + export templates in CI).

## Last verified

2026-07-25 — live URL loads, playable (movement/collision/camera confirmed via a scripted Playwright pass), zero console errors.

## Known issue: release export has no audio output (2026-07-26)

Verifying issue #14's audio direction found that the `--export-release` build produced by the redeploy steps above plays **no audio at all** — confirmed with a minimal isolated test scene, in both headless and a real headed Chromium window, with zero console/page errors (the failure is silent). The `--export-debug` export of the identical scene/asset plays audio correctly. See `docs/DECISIONS.md`'s audio-decision addendum (2026-07-26) for the full investigation and its resemblance to the open upstream bug `godotengine/godot#119026`. Until this is root-caused or fixed upstream, **any audio shipped via this deploy process will be silent for real players** — this is not specific to one sound effect. Re-check this whenever the Godot version used for export changes.
