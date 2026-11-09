# Product demo verification and deployment

## Release status

The expanded product is delivered in [PR #1](https://github.com/jeffreymutethia/Seattle-Pulse/pull/1), on `feat/portfolio-demo`.

**Account-based Vercel deployment needs login.** Plugin discovery found Vercel available but not connected, and CLI `65.12.1` reported **Logged out**. Its dry-run inspection required login, but the actual `deploy --temporary` command successfully published the static export anonymously. The time-limited preview is **https://sonic-comet-ybiyy18.tmp.now**, deployment `dpl_9kVMwCn7evigDuJ66dG8oks6JBjL`, expiring **November 9, 2026 at 13:17 UTC**. It is an expiring review URL, not a lasting portfolio address.

The README's stable public URL and GitHub About link still point to the existing citywide Site. The account owner can deploy a lasting Vercel project with the settings below; no private claim URL or credential is stored in this repository.

The source was reconciled with the live citywide edition before this work. PR head `fb39b42` lacked it. The supplied `seattle-pulse-citywide.bundle` was not present in the accessible filesystem, so the connected Site's version-3 source (`b33049162a260ac58c7d15a47266cdc94536979c`) was recovered instead. Its citywide delta was applied to the latest PR, preserving the PR's backend, documentation and regression work. Commit `2afde20` records that reconciliation. All nine imported WebP files are byte-identical to the recovered source, and the original guide copy, further-reading links and photography credits are preserved.

## Deploy on Vercel

The account owner needs to approve `vercel login`, or connect the Vercel integration. Then create or link a Vercel project for `jeffreymutethia/Seattle-Pulse` using these settings:

| Setting | Value |
| --- | --- |
| Root Directory | `frontend` |
| Framework Preset | **Other** (`framework: null`) |
| Node.js | `22.x` |
| Install Command | `CYPRESS_INSTALL_BINARY=0 npm ci` |
| Build Command | `npm run build:demo` |
| Output Directory | `demo/out` |
| Application environment variables | None required |
| Initial branch to deploy | `feat/portfolio-demo` |

[`frontend/vercel.json`](../frontend/vercel.json) already declares the install, build and output settings. The static export contains real HTML entry points for `/`, `/auth/login/`, `/mypulse/` and `/profile/`. It does not need serverless functions, Flask, a database or the Next.js server preset. See Vercel's [configuration reference](https://vercel.com/docs/project-configuration/vercel-json).

For CLI deployment from the PR checkout:

```sh
git switch feat/portfolio-demo
cd frontend
npx vercel login
npx vercel link
npx vercel deploy
```

Approve the login in your own browser, select the intended account/project, and use the settings above. Deploy the feature branch for the preview; after merge, use `main` for future production updates. Do not enter provider/API secrets for this static demo.

For recruiter access, make this demo deployment publicly reachable without Vercel authentication, using the project's Deployment Protection settings or a preview-domain exception. Verify in a fresh browser before publishing its link. [Vercel deployment protection](https://vercel.com/docs/deployment-protection) controls hosting access independently of the demo's simulated reader session.

After Vercel returns a URL:

```sh
cd frontend
CYPRESS_BASE_URL=https://YOUR-VERIFIED-DEPLOYMENT.vercel.app npm run test:demo:preview
```

On a host that inherits `ELECTRON_RUN_AS_NODE`, prefix with `env -u ELECTRON_RUN_AS_NODE`. Also check the four direct URLs and confirm an HTTP 200. Only after this passes, update the README/GitHub About public link to the lasting deployment and refresh the screenshots from that deployment.

## Verified release

The local production-export journey passed **1/1** at both viewport sizes. The same full journey also passed **1/1 in 14.8 seconds** against the temporary public Vercel URL, with no API responses mocked. The regular Next.js production build, static export, full TypeScript check, focused lint of demo modules, Docker Compose configuration and backend syntax compilation also passed.

The anonymous preview publishes only the already-built `frontend/demo/out` directory using `vercel deploy --temporary --yes --json --cwd demo/out`. It does not establish an account-linked Vercel project. The checked-in `frontend/vercel.json` is the starting configuration for the lasting account-based deployment described above.

The browser test runs against the production static export, locally and at the temporary public Vercel preview, using Chrome at **1440 × 1000** and **390 × 844**, each starting with fresh guest storage. Application errors are test failures. The single blocking journey covers:

- All Seattle with eight areas and eight distinct, consistently reused publisher images.
- Neighborhood filtering, changed stories, guide details and sample discussion.
- The original sign-in artwork, guest back-to-browsing path, and Continue as demo reader.
- Selected neighborhood retained through sign-in; added local comments retained across routes.
- The Feed, My Pulse and Profile, with one active navigation destination.
- Seeded follows, unfollow/reload/refollow, saved guides, comment activity and profile edit/reload.
- Direct URLs, signed-in reloads, sign-out and signed-out profile entry.
- Loaded images, same-origin application resources, no `/api/` or `/socket.io` requests, and zero WebSocket constructions.

There are no API response stubs. A pass-through observer records WebSocket constructions without mocking them; ResourceTiming checks fetches and loaded resources. The test disables Cypress screenshot timer-freezing to avoid a React 19 scheduling issue and never suppresses application exceptions.

[Current PR checks](https://github.com/jeffreymutethia/Seattle-Pulse/pull/1/checks) include the blocking demo browser job, the normal frontend production build and the backend subset. The regular API build remains separate from `frontend/demo/`.

### Screenshots

The ten expanded-product screenshots in [`screenshots/product/`](screenshots/product/) are captured from the **verified temporary Vercel preview** of the production export. Each screen has desktop and mobile captures: feed, branded sign-in, My Pulse, Profile and discussion. Previous public walkthrough captures remain in `screenshots/demo/` as historical evidence.

## Implementation boundaries

[`DemoSessionBoundary`](../frontend/app/demo/demo-session.tsx) is enabled only by the static demo build. Its state lives in this tab's `sessionStorage`: simulated sign-in, followed publisher IDs, comments and profile fields. Existing `feedLocation` storage preserves neighborhood selection. No personal credentials are collected or sent. Guests can read The Feed immediately; signed-in destinations offer the dedicated sign-in route to guests.

The normal frontend still uses the original login, API services, navigation, settings, messaging and story-upload flows. The ProfileHeader's local edit callback and hidden-share option are optional and retain their original defaults. The Docker quickstart and backend API are preserved. See [the engineering walkthrough](ENGINEERING.md) and [Run locally](../README.md#run-locally).

The remaining original destinations were reviewed: uploads, notifications, messages, account settings and location maps depend on APIs, uploads or map services. They are omitted from demo navigation instead of exposing unfinished interactions. The local profile editor supports the Profile screen's primary action.

Repository-wide frontend lint has existing debt and remains advisory in CI. Focused demo lint, TypeScript and both production builds are checked separately. The mobile checks use a Chrome viewport, not physical hardware or Safari. The backend test harness stubs import-time geographic downloads; those tests do not verify live geographic classification. Docker configuration is validated separately from full-stack startup/smoke.
