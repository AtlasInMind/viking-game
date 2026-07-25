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
