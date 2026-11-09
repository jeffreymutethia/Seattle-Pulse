# Portfolio demo deployment

## Verified release

Verified on **November 9, 2026**, at the public, account-free URL:

**https://seattle-pulse-demo.jeffreymutethia.chatgpt.site/**

The connected Sites integration reported deployment success for version **2**
(`appgdep_6af1a7433ebc81919e38d4e830383056`). An independent HTTP request returned
200, and the blocking Cypress journey passed against this public URL in fresh
Chrome guest sessions at **1440 × 1000** and **390 × 844**.

The journey verifies:

1. The first feed contains Capitol Hill stories and decoded bundled images.
2. Selecting **Ballard, Seattle** replaces the story set and removes Capitol Hill stories.
3. Reloading preserves Ballard and its stories without a hydration exception.
4. Opening the Ballard market story displays its title, illustration and actual seeded discussion.
5. Resource URLs stay on the demo origin, with no `/api/` or `/socket.io` requests.

The one spec runs the complete journey at both sizes, without API interception
or fixture injection by the test. It passed **1/1** against the public release.

| Public capture | Dimensions |
| --- | --- |
| [Desktop feed](screenshots/demo/desktop-feed.png) | 1440 × 1000 |
| [Mobile feed](screenshots/demo/mobile-feed.png) | 390 × 844 |
| [Desktop discussion](screenshots/demo/desktop-discussion.png) | 1440 × 1000 |
| [Mobile discussion](screenshots/demo/mobile-discussion.png) | 390 × 844 |

These screenshots come from the successful public run, with image-decoding and
modal-readiness assertions. Mobile verification uses a Chrome mobile viewport;
this is not a physical-device or Safari test.

## Build and hosting boundary

The public application was built from GitHub application revision
[`cfa417c`](https://github.com/jeffreymutethia/Seattle-Pulse/commit/cfa417c).
Later portfolio documentation and test-harness edits do not change its runtime.
The Sites source snapshot is `23d2625a9c07e812ca0b4e5a96d605642754c0e8` and records
the GitHub revision in `SOURCE_REVISION.json`.

The existing GitHub history contains a 41 MiB full-app background image, exceeding
Sites' 32 MiB source-object limit. Rather than rewrite that history, the
[`prepare-demo-source.mjs`](../scripts/prepare-demo-source.mjs) helper copies the
committed demo build inputs into a clean source checkout. The code is unchanged;
unrelated backend/mobile source and unused full-app media are omitted. The same
Sites project in [`.openai/hosting.json`](../.openai/hosting.json) is reused.

To prepare a future release from a clean, committed checkout:

```sh
node scripts/prepare-demo-source.mjs /tmp/seattle-pulse-release
cd /tmp/seattle-pulse-release
npm --prefix frontend ci
npm run build
```

Use an empty destination for snapshot generation. On subsequent releases, open
the existing Sites source checkout with the integration first, then refresh its
build inputs from the generated snapshot while preserving its `.git` history.
The connected Sites source workflow commits and pushes those inputs,
builds/packages `out/`, saves the matching version and publishes
it to the public project. No API, publisher, map, database or analytics credential
is required by the deployed application. Keep source-write credentials in the
integration session, never in repository files.

`frontend/demo/` is a dedicated static Next.js build target that imports the
existing root page and layout. `NEXT_PUBLIC_DEMO_MODE=true` selects the typed
fixtures at the services and disables live auth, notifications and analytics.
The regular frontend build and Docker Compose do not enable that flag. The
hosted walkthrough has only the feed entry point and static assets; accounts
and persistent actions stay in the full system.

To rerun the public browser check:

```sh
cd frontend
CYPRESS_BASE_URL=https://seattle-pulse-demo.jeffreymutethia.chatgpt.site npm run test:demo:preview
```

On a host that inherits `ELECTRON_RUN_AS_NODE`, prefix the command with
`env -u ELECTRON_RUN_AS_NODE`. Cypress uses installed Google Chrome. Screenshot
capture disables Cypress's timer freezing to avoid a React 19 scheduling error;
application exceptions remain test failures.

## Checks and limits

[Current PR checks](https://github.com/jeffreymutethia/Seattle-Pulse/pull/1/checks)
track the blocking frontend build, backend subset and demo browser job.

Completed locally:

- Regular Next.js production build: passed.
- Static demo production build, including type validation: passed.
- `npm run typecheck`: passed.
- Focused lint of new demo modules: passed.
- Blocking browser spec locally and at the public URL: passed at both sizes.
- Backend auth/login, guest-feed, canonical seed/ingestion and location-filter tests: **17 passed**.
- Backend syntax compilation, `docker compose config --quiet` and `git diff --check`: passed.

The backend subset was run with the CI testing environment and these files:

```sh
pytest -q tests/auth/test_login.py tests/content/test_get_guest_feed.py \
  tests/content/test_demo_seed.py tests/content/test_location_filters.py
```

The test harness stubs import-time OpenStreetMap downloads. These tests validate
stored-label filtering, seed repair and ingestion persistence; they do not
validate live geographic classification. See [the engineering walkthrough](ENGINEERING.md).

Repository-wide frontend lint reports **51 existing errors and 17 warnings**.
The obsolete `next lint` command has been replaced with the ESLint CLI so this
debt is visible. Existing lint remains advisory in CI; the new demo browser job
has no `continue-on-error` and must pass. The normal frontend build and backend
subset also remain required job results.

The Docker daemon was unavailable in this session, so the full Compose startup
and `make smoke` were not rerun. The Docker configuration validates and its
quickstart remains in [Run locally](../README.md#run-locally). Mobile, live
publisher ingestion, persistent social actions and cloud infrastructure are
implementation paths documented in the repo, outside the hosted demo check.
