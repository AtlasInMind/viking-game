# Performance & Web Payload

## Purpose

Baseline measurement of the exported web build's size, compression, and load time, and a concrete asset budget for content growth going forward (issue #27). Methodology follows `norse-game`'s documented approach directly (see `../norse-game/docs/research/web_export_findings.md` and `../norse-game/docs/deployment.md` in this environment) rather than reinventing one, per `docs/PROJECT_VISION.md`'s verification strategy.

## Method

- `godot --headless --export-release "Web" ../builds/web/index.html` — same export command this project's `docs/deployment.md` already documents, not a special measurement-only build.
- Raw file sizes read directly off disk.
- Compression measured locally: `gzip -9` and `brotli -q 11` against `index.wasm`/`index.js`/`index.pck` (the three files large enough to matter — icons and `index.html` are a few KB each).
- Load time measured with Playwright/Chromium, using CDP's `Network.emulateNetworkConditions` to simulate ~10 Mbps / 40ms RTT ("roughly 4G"), same as norse-game's method. Since plain `python3 -m http.server` doesn't compress anything, three small local servers were used instead, each serving a precomputed `.gz`/`.br`/raw variant of the three large files with the matching `Content-Encoding` header — real compressed bytes over the wire, not simulated.
- "Boot-to-title" is this project's equivalent of norse-game's "boot-to-menu": time from navigation start until the loading status overlay (`#status`) is hidden and the title screen's canvas is up.
- Live hosting verified directly against both of this project's actual published hosts (GitHub Pages and itch.io — see `docs/deployment.md`), not assumed from local measurement alone.

## Results (measured 2026-07-26, Godot 4.7.1, same dev machine as the rest of this project)

### Raw file sizes

| File | Size |
|---|---|
| `index.wasm` (engine) | 39,513,091 bytes (~37.7 MiB) |
| `index.js` (engine glue) | 279,815 bytes (~273 KiB) |
| `index.pck` (project content) | 67,712 bytes (~66 KiB) |
| `index.html` | 5,440 bytes |
| Icons (png) | ~22 KB combined |
| **Total** | **~38.0 MiB** |

`index.wasm` is the Godot engine itself and completely dominates the total — this is engine overhead, not content, identical byte-for-byte to norse-game's own measurement on the same Godot version (confirms it's genuinely engine-only weight, not something specific to either project). `index.pck` is everything this project actually built: two full areas (village + ship) with their runtime-built tilesets, all NPCs/dialogue, the item/inventory/gate data, and the one procedural audio SFX from issue #14 — and it amounts to 66 KB, about 0.17% of the total payload.

### Compression

| File | Uncompressed | gzip -9 | brotli -q 11 |
|---|---|---|---|
| `index.wasm` | 39,513,091 | 10,054,511 (~25.4%) | 6,901,775 (~17.5%) |
| `index.js` | 279,815 | 68,479 (~24.5%) | 59,857 (~21.4%) |
| `index.pck` | 67,712 | 45,882 (~67.8%) | 43,550 (~64.3%) |

**Total core payload (wasm+js+pck): ~9.70 MiB gzip, ~6.68 MiB brotli.** `index.pck` compresses noticeably worse proportionally than the engine binary (audio/compiled-script bytes don't compress as well as the mostly-text `.tres` resources norse-game's `.pck` was dominated by at the same stage) — but in absolute terms it's trivial either way (43.5 KB brotli vs. 6.9 MB brotli for the engine alone).

### Load time (simulated ~10 Mbps / 40ms RTT, Playwright/Chromium CDP)

| Scenario | Boot-to-title time |
|---|---|
| Uncompressed | 32.71s |
| gzip | 8.96s |
| brotli | 6.42s |
| gzip, unlimited bandwidth (local) | 0.68s |

Consistent with norse-game's own numbers on the same engine version (32.7s / ~10s / ~6.4s) — expected, since `index.wasm` (the number that actually dominates load time) is byte-identical between the two projects at this stage.

### Live hosting: which compression is actually served

| Host | gzip | brotli |
|---|---|---|
| GitHub Pages (`atlasinmind.github.io/viking-game`) | Yes (confirmed via `curl -H "Accept-Encoding: gzip"`, `index.wasm` → 10,248,573 bytes) | **No** (`curl -H "Accept-Encoding: br"` → full 39,513,091 bytes, no `Content-Encoding` header) |
| itch.io (`html-classic.itch.zone`, Cloudflare-fronted) | Yes (10,616,441 bytes) | **No** (full uncompressed size returned despite Cloudflare generally supporting brotli elsewhere) |

Both of this project's actual live hosts land in the same "gzip yes, brotli no" bucket norse-game found for GitHub Pages — real players on either distribution channel get the ~9.7 MiB gzip payload, not the theoretical ~6.7 MiB brotli best case measured locally above. This isn't a per-project or per-host quirk worth re-litigating; it's just what these hosts do.

## Asset budget

**Current state easily satisfies any reasonable budget** — 66 KB of actual game content (both areas combined) against a ~38 MiB engine floor isn't something atlasing or lazy-loading needs to solve today. Building that infrastructure now would be unneeded complexity for a problem that doesn't exist yet, so this issue doesn't add one. Recording the *actual constraint* and a concrete forward budget instead, so M5's content scaling has something real to check against:

- **The engine floor already spends nearly the whole realistic load-time budget.** On the only compression real players actually get (gzip, per the table above), boot-to-title is already ~9s on a throttled ~10 Mbps connection before a single byte of game content loads. Using ~10s boot time as a working UX ceiling (an ordinary, not aggressive, target for a web game), there is very little room left for content to add meaningfully to *initial* payload without pushing past it — the lever that actually matters here is not shrinking content (it's already negligible) but keeping it from being forced to load all at once.
- **There is currently no per-region network lazy-loading, and that's worth being explicit about.** Godot's web export bundles the entire project's resources into a single `.pck`, fetched once at boot — moving between the village and ship scenes (`change_scene_to_file()`) frees and re-instantiates in-memory nodes, but doesn't fetch any new bytes over the network, since everything was already downloaded upfront. "Per-region lazy-loading" in the sense `docs/PROJECT_VISION.md` means it (only downloading a region's assets when the player first reaches it) isn't happening today - it doesn't need to yet, since total content is 66 KB, but this stops being true automatically once real (non-placeholder) art/audio or many more regions get added.
- **Forward budget: ~1-2 MB raw per region** (tileset art + sprites + any per-region audio combined) as a working ceiling for M5 content, to be treated as a trigger for building real lazy-loading (via Godot's `ProjectSettings.load_resource_pack()` to split content into supplementary `.pck` files fetched on demand, rather than reinventing a different mechanism), not a hard content-size limit in itself. At `docs/PROJECT_VISION.md`'s ~8-12 region target for the full game, this budget would put total *eager* content around 8-24 MB raw if lazy-loading were never built - the point at which it's worth actually building the on-demand `.pck`-splitting mechanism rather than continuing to bundle everything upfront.
- **Re-measure when:** M2's placeholder art/audio gets replaced with hand-tuned "premium" hero assets (per `docs/PROJECT_VISION.md`'s art priority, these are explicitly meant to get disproportionate attention/iteration, which could mean disproportionate size too), when real music (not just short SFX) is added, or when the region count approaches the ~1-2 MB/region budget above cumulatively - whichever comes first. Don't re-litigate this measurement without one of those concrete triggers.

## Sources/methodology

- `../norse-game/docs/research/web_export_findings.md` and `../norse-game/docs/deployment.md` — the reference methodology this directly follows.
- `docs/deployment.md` (this project) — the actual export/publish process being measured.
- Measured 2026-07-26, Godot 4.7.1, Playwright/Chromium, same dev machine as the rest of this project's verification work.

## Last updated

2026-07-26 — initial measurement and budget, issue #27.
