# Demo deployment

The public demo is a static Next.js export at
[seattle-pulse-demo.vercel.app](https://seattle-pulse-demo.vercel.app/).
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
CYPRESS_BASE_URL=https://seattle-pulse-demo.vercel.app npm run test:demo:preview
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

On **November 9, 2026**, the [Vercel production deployment](https://vercel.com/jt254/seattle-pulse-demo/9qFEeKYo6xX99QMy1MBNkH3nTzZv)
was published from application commit
[`8d1f008`](https://github.com/jeffreymutethia/Seattle-Pulse/commit/8d1f0086acff09fe124b81a061a31b43513be08a).
The public browser journey passed **1/1 in 17 seconds** across both viewport
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

## Vercel configuration

The `seattle-pulse-demo` project in the `jt254` account is connected to
`jeffreymutethia/Seattle-Pulse`. It tracks `main` for production and creates
previews for other branches. The production domain is publicly accessible;
preview deployments retain Vercel authentication.

The project uses these settings:

| Setting | Value |
| --- | --- |
| Root Directory | `frontend/demo` |
| Framework Preset | Other |
| Node.js | `22.x` |
| Install Command | `CYPRESS_INSTALL_BINARY=0 npm --prefix .. ci` |
| Build Command | `npm --prefix .. run build:demo` |
| Output Directory | `out` |
| Include source files outside Root Directory | Enabled |
| Application environment variables | None |

[`frontend/demo/vercel.json`](../frontend/demo/vercel.json) declares the install,
build and output settings. Using the demo directory as the project root keeps
the full app's `frontend/middleware.ts` out of the static deployment. Shared UI
and dependencies remain in the parent `frontend` directory, enabled by
[Vercel's outside-root source setting](https://vercel.com/docs/monorepos/monorepo-faq).
The regular API-backed build keeps its middleware.

For CLI deployment, run from the repository root:

```sh
npx vercel login
npx vercel link --project seattle-pulse-demo --scope jt254
npx vercel deploy
```

See Vercel's [monorepo CLI guidance](https://vercel.com/docs/monorepos). Use
`feat/portfolio-demo` until the PR is merged. `vercel deploy` creates a preview;
`vercel deploy --prod` publishes to the production domain. After merge, pushes
to `main` deploy automatically.

Keep the production domain public in
[Deployment Protection](https://vercel.com/docs/deployment-protection). Test a
release with the browser command above and check all four direct routes before
updating public links or screenshots.

## Alternate Sites deployment

The [existing public Site](https://seattle-pulse-demo.jeffreymutethia.chatgpt.site/)
also serves this version of the application.

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
