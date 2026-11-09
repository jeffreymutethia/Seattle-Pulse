# Demo deployment

The public demo is a static Next.js export at
[seattle-pulse-demo.jeffreymutethia.chatgpt.site](https://seattle-pulse-demo.jeffreymutethia.chatgpt.site/).
It contains four routes: `/`, `/auth/login/`, `/mypulse/` and `/profile/`.
Reader sessions, follows, comments and profile edits stay in the browser tab's
`sessionStorage`. The demo needs no Flask server, database or application secrets.

The regular frontend build and [Docker quickstart](../README.md#run-locally)
use the API-backed application. See [the engineering walkthrough](ENGINEERING.md)
for the differences between the two builds.

## Build and verify

Use Node 20 or 22 and Python 3:

```sh
cd frontend
npm ci
npm run build:demo
npm run test:demo
```

The browser test starts its own local server. To test a deployment instead:

```sh
CYPRESS_BASE_URL=https://seattle-pulse-demo.jeffreymutethia.chatgpt.site npm run test:demo:preview
```

If the host sets `ELECTRON_RUN_AS_NODE`, prefix the test command with
`env -u ELECTRON_RUN_AS_NODE`.

The blocking [Cypress journey](../frontend/cypress/e2e/demo-walkthrough.cy.ts)
runs in Chrome at 1440 × 1000 and 390 × 844 with fresh guest storage. It covers:

- The feed-first layout, eight areas, neighborhood filtering and discussions.
- Branded sign-in, returning to the selected neighborhood and adding a comment.
- The Feed, My Pulse and Profile, active navigation and direct route loading.
- Follow/unfollow, saved guides, comment activity, profile editing and reloads.
- Sign-out, loaded images, no API or socket requests and no WebSocket connections.

Application errors fail the test. It does not stub API responses. Mobile checks
use a Chrome viewport; they do not cover physical devices or Safari.

## Verified release

On **November 9, 2026**, Site version **4** was published from application commit
[`e0d14de`](https://github.com/jeffreymutethia/Seattle-Pulse/commit/e0d14de36dbc085b5f6eaf2a368ac001d0a6da3a).
The public browser journey passed **1/1 in 31 seconds** across both viewport
sizes. All four direct routes returned HTTP 200. Images loaded, the first story
title was visible immediately, and no backend, socket or external application
resource requests were observed.

The ten screenshots in [`screenshots/product/`](screenshots/product/) were
refreshed from that deployment and visually reviewed. They show the feed,
sign-in, My Pulse, Profile and discussion at both viewport sizes.

[CI](https://github.com/jeffreymutethia/Seattle-Pulse/actions/workflows/ci.yml)
builds the static demo and regular frontend, runs the browser journey, and checks
the backend test subset. Repository-wide frontend lint remains advisory because
of existing lint debt. Backend tests stub startup geographic downloads; Docker
configuration validation is separate from a full stack startup and smoke test.

## Publish to the existing Site

[`.openai/hosting.json`](../.openai/hosting.json) identifies the public Site and
serves the root `out/` directory. The root build runs `frontend`'s `build:demo`
and copies its export to `out/`.

Sites has a 32 MiB source-object limit. The repository history contains larger
full-app media, so [`prepare-demo-source.mjs`](../scripts/prepare-demo-source.mjs)
creates a clean snapshot of the committed demo build inputs without rewriting
GitHub history:

```sh
node scripts/prepare-demo-source.mjs /absolute/path/to/empty-directory
```

Run this from a clean checkout. Publish the snapshot through the Sites source
workflow, preserving the existing project ID and public audience. Its
`SOURCE_REVISION.json` records the originating GitHub commit. Build and package
the snapshot, deploy it, then run the browser journey against the public URL.

## Deploy on Vercel

The same export can be deployed to Vercel. Account login or a connected Vercel
integration is required for a lasting deployment; neither is configured in this
workspace. The existing public Site remains the live address.

Create or link a project for `jeffreymutethia/Seattle-Pulse` with these settings:

| Setting | Value |
| --- | --- |
| Root Directory | `frontend` |
| Framework Preset | Other |
| Node.js | `22.x` |
| Install Command | `CYPRESS_INSTALL_BINARY=0 npm ci` |
| Build Command | `npm run build:demo` |
| Output Directory | `demo/out` |
| Application environment variables | None |

[`frontend/vercel.json`](../frontend/vercel.json) declares the install, build and
output settings. For CLI deployment, run from the repository root because the
project's Root Directory is `frontend`:

```sh
npx vercel login
npx vercel link
npx vercel deploy
```

See Vercel's [monorepo CLI guidance](https://vercel.com/docs/monorepos). Use
`feat/portfolio-demo` until the PR is merged, then `main` for production. Make the
deployment publicly accessible in
[Deployment Protection](https://vercel.com/docs/deployment-protection), test the
returned URL with the command above, and check all four direct routes. Update
both the README and GitHub About link only after verification, and capture
screenshots from that deployment.
