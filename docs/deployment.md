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

## Act 1 full playtest (issue #23, 2026-07-26)

Per `docs/PROJECT_VISION.md`'s verification strategy ("structured playtest each milestone... log findings as issues"), Act 1 was played start-to-finish twice against a locally-served `--export-release` web build (not just the editor), driven with Playwright/Chromium: once following only the main quest thread, once also pursuing side content (the cairn subplot and its "hold still" challenge encounter - both success and fail/retry paths, the carved-token pickup and Ingrid's reactive line, and the cross-NPC `asked_about_cairn` flag). Both areas (village and the returned longship) were covered, with save/reload exercised at three points in each pass (mid-village, on the ship, and after Act 1's resolution beat), confirming position, inventory, and quest-flag state all survive a real page reload and an area transition correctly. Zero console/page errors across both passes.

No fixes were needed - every interaction, dialogue branch, gate/item check, area transition, and challenge encounter (including the ship's own memory encounter, success and fail/retry) behaved exactly as coded. One discoverability gap was found and filed as its own follow-up (issue #25) rather than patched inline, since it's a content/design call: the hint text never points the player back to `water_npc` for the rusted key needed to pass the south gate.

No external testers were available for this pass; self-playtest was the fallback, consistent with M1/M2.

## Note: release-export audio had an unexplained flaky episode (2026-07-26)

Verifying issue #14's audio direction, the `--export-release` build produced by the redeploy steps above was consistently silent (no audio at all, zero console/page errors) across roughly a dozen varied test runs. Substantial further retesting afterward (26 consecutive runs, same real build, same real interaction path) played audio correctly every time, with no code changes in between. The earlier failures couldn't be reproduced again despite trying, and no root cause was confirmed — see `docs/DECISIONS.md`'s audio-decision addendum (2026-07-26) for the full investigation. Currently verified working, but given the unexplained flakiness, a real-device/real-browser spot-check of audio before any actual public release is worthwhile due diligence, not just a formality.
