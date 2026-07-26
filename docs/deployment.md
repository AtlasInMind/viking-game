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

## Hosting: itch.io (issue #24)

**Live page:** https://atlasinmind.itch.io/viking-game

Publishes the same `--export-release` web build (see above) as a second, independent distribution channel alongside GitHub Pages, per `docs/DECISIONS.md`'s publishing decision. Uses itch.io's official CLI, `butler`, rather than manual web-dashboard uploads, so builds can be pushed repeatedly without a human re-uploading through the browser each time.

### One-time setup (already done, kept here for a future machine/session)

- `butler` binary lives at `.tools/butler/butler` (git-ignored — see `.gitignore` — it's a downloaded tool, not project source). Fetched from `https://broth.itch.zone/butler/darwin-arm64/LATEST/archive/default` (swap the platform segment for other OSes/architectures).
- Login must happen from a real terminal with a TTY (Terminal.app/iTerm), not through an automated/non-interactive shell bridge — `butler login`'s browser-authorization flow fails with "stdin is not a terminal" otherwise, and falls back to asking for `BUTLER_API_KEY`, which would mean typing the API key somewhere it could be captured/logged. Run `.tools/butler/butler login` directly in a real terminal; it opens a browser to authorize and stores the credential at `~/Library/Application Support/itch/butler_creds` (macOS) — nothing else needs to see the key itself.
- The itch.io project page itself (title, classification, description, tags, pricing, visibility) has no public API — it's created and edited entirely through itch.io's web dashboard by whoever owns the account. `butler` only pushes builds to a project that already exists.

### How to push a new build

```sh
cd game && godot --headless --export-release "Web" ../builds/web/index.html   # from docs/deployment.md's existing export step
cd .. && .tools/butler/butler push builds/web atlasinmind/viking-game:web --userversion-file <(git rev-parse --short HEAD)
```

`butler status atlasinmind/viking-game:web` confirms once the pushed build has finished processing on itch.io's end (can lag behind the push completing by up to a minute or two — poll rather than assume it's instant).

### Known limitation: description/devlog text needs a manual paste

Store-page copy and devlog posts are plain text/rich-text fields in itch.io's dashboard with no API — pasting Markdown-formatted text (e.g. `**bold**`) into them does not render as formatting, since the editor isn't a Markdown parser; it shows the literal asterisks instead. Any bold/emphasis needs to be applied by selecting the text and using itch.io's own toolbar buttons after pasting, then deleting the leftover Markdown characters. Copy drafts for this project live in `docs/promo/` (`store_page_copy.md`, `devlog_01.md`) as plain reference text to paste from, not literal Markdown to render as-is.

### Last verified

2026-07-26 — page set to public, build pushed via `butler` and confirmed processed, first devlog post published. Verified in a real (headless Chromium) browser, not just "uploaded": loaded the live itch.io page, clicked through itch.io's "Run game" load gate into the embedded iframe, confirmed the title screen renders, Start works, and movement works, with zero console/page errors.

## Act 1 full playtest (issue #23, 2026-07-26)

Per `docs/PROJECT_VISION.md`'s verification strategy ("structured playtest each milestone... log findings as issues"), Act 1 was played start-to-finish twice against a locally-served `--export-release` web build (not just the editor), driven with Playwright/Chromium: once following only the main quest thread, once also pursuing side content (the cairn subplot and its "hold still" challenge encounter - both success and fail/retry paths, the carved-token pickup and Ingrid's reactive line, and the cross-NPC `asked_about_cairn` flag). Both areas (village and the returned longship) were covered, with save/reload exercised at three points in each pass (mid-village, on the ship, and after Act 1's resolution beat), confirming position, inventory, and quest-flag state all survive a real page reload and an area transition correctly. Zero console/page errors across both passes.

No fixes were needed - every interaction, dialogue branch, gate/item check, area transition, and challenge encounter (including the ship's own memory encounter, success and fail/retry) behaved exactly as coded. One discoverability gap was found and filed as its own follow-up (issue #25) rather than patched inline, since it's a content/design call: the hint text never points the player back to `water_npc` for the rusted key needed to pass the south gate.

No external testers were available for this pass; self-playtest was the fallback, consistent with M1/M2.

## Note: release-export audio had an unexplained flaky episode (2026-07-26)

Verifying issue #14's audio direction, the `--export-release` build produced by the redeploy steps above was consistently silent (no audio at all, zero console/page errors) across roughly a dozen varied test runs. Substantial further retesting afterward (26 consecutive runs, same real build, same real interaction path) played audio correctly every time, with no code changes in between. The earlier failures couldn't be reproduced again despite trying, and no root cause was confirmed — see `docs/DECISIONS.md`'s audio-decision addendum (2026-07-26) for the full investigation. Currently verified working, but given the unexplained flakiness, a real-device/real-browser spot-check of audio before any actual public release is worthwhile due diligence, not just a formality.
