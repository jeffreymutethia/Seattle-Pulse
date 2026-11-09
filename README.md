# Seattle Pulse

Citywide feeds bury the stories that matter a few blocks away. Seattle Pulse brings local content and neighborhood conversations together, with a personal feed shaped by the sources you follow.

**[Live citywide edition](https://seattle-pulse-demo.jeffreymutethia.chatgpt.site/)** · **[Browsable product update — PR #1](https://github.com/jeffreymutethia/Seattle-Pulse/pull/1)** · [Engineering walkthrough](docs/ENGINEERING.md) · [Verification and Vercel setup](docs/DEPLOYMENT.md)

The expanded product has a [temporary Vercel preview](https://sonic-comet-ybiyy18.tmp.now), expiring **November 9, 2026 at 13:17 UTC**. A lasting Vercel deployment requires account login, so the stable public link above still opens the earlier citywide edition. [Deploy the expanded build](docs/DEPLOYMENT.md#deploy-on-vercel) with the checked-in settings; replace the stable link after verifying that deployment.

<img src="docs/screenshots/product/desktop-feed.png" alt="Seattle Pulse citywide feed with the original product navigation and neighborhood selector" width="900">

Temporary Vercel preview capture, November 9, 2026. [Mobile feed](docs/screenshots/product/mobile-feed.png) · [Original branded sign-in](docs/screenshots/product/desktop-sign-in.png) · [My Pulse](docs/screenshots/product/desktop-my-pulse.png) · [Profile](docs/screenshots/product/desktop-profile.png)

Seattle Pulse is **Jeffrey Mutethia’s portfolio project**. He owned it end to end across the **Next.js web app, Flask backend, Flutter mobile app, and infrastructure**.

## Try the product in under a minute

1. Open **The Feed** in **All Seattle**. Browse eight original place guides, filter to a neighborhood, and open a story's sample discussion.
2. Visit the original branded **Sign in** page and choose **Continue as demo reader**. You return to the same neighborhood, with no password or account setup.
3. Open **My Pulse** to see guides from three followed sources. Follow or unfollow a source to change the feed, then explore **Profile**, its saved guides, local comments and editable bio.

The desktop sidebar and mobile bottom navigation use real, refreshable routes. A demo reader can add comments, follow publishers, edit the profile, reload a signed-in page and sign out. Those interactions stay in the current browser tab's session storage.

Publisher identities such as **Market Notes**, **Hill Notes** and **Ballard Notes**, the reader account, conversations and engagement are fictional. The guides describe real places; the existing Seattle photographs and their credits are preserved. The disclosure remains visible, and further-reading links lead to the places' existing sources. No live backend, socket, map service, analytics token or provider key is needed by the static demo.

## How it works

The full system ingests local headlines, source links, timestamps, descriptions and images through publisher adapters into Flask/SQLAlchemy and PostgreSQL. The saver checks URLs and normalized or similar headlines for duplicates, associates each story with a publisher, and assigns a neighborhood from the publisher's coverage area.

The combined feed filters by neighborhood, queries matching stories newest-first, then interleaves one item from each author or publisher before pagination. A separate MyPulse following feed applies engagement with time decay. The [engineering walkthrough](docs/ENGINEERING.md) follows the implementation and explains the demo's boundaries.

The static build supplies typed fixtures at [`postServices.ts`](frontend/app/services/postServices.ts) and [`contentService.ts`](frontend/app/services/contentService.ts). It reuses the existing feed, location selector, story cards, discussion components, sidebar, mobile navigation and profile header. Its dedicated login route adapts the original artwork and layout. Demo state is browser-local; the regular API-backed build retains its original server authentication and persistent behavior.

## Run locally

For the full stack, start Docker Desktop and run:

```sh
make demo
```

This builds Next.js and Flask, starts PostgreSQL and Redis, waits for the API, and seeds deterministic fictional posts. Open [localhost:3000](http://localhost:3000). The API is at [localhost:5050](http://localhost:5050); browser calls use that address, while server-side calls use Docker's `backend:5000`.

Optional local login: `demo@seattlepulse.local` / `DemoPass123!`. Run `make smoke` to check health, the guest feed, login and session persistence. `make seed` repairs existing demo neighborhood labels without duplicating posts. [Full local walkthrough and troubleshooting](docs/DEMO.md#full-local-system)

For the static product demo, use Node 20 or 22 and Python 3:

```sh
cd frontend
npm ci
npm run build:demo
npm run serve:demo
```

Open [localhost:3000](http://localhost:3000). Direct routes are `/`, `/auth/login/`, `/mypulse/` and `/profile/`. Stop the server before running the browser check:

```sh
npm run test:demo
npm run typecheck
npm run build
```

The blocking browser journey checks desktop and mobile guest access, all eight areas, neighborhood changes, discussions, branded sign-in, local follows/comments/profile edits, active navigation, direct URLs, signed-in reloads, sign-out, image loading and the absence of live backend or socket requests. [CI](https://github.com/jeffreymutethia/Seattle-Pulse/actions/workflows/ci.yml) also builds the regular frontend and runs backend regression tests. Existing repository-wide lint debt remains advisory.

## Inspect the implementation

- [`frontend/`](frontend/) — Next.js, React, TypeScript, Tailwind and Radix; static routes in `frontend/demo/`, shared demo state and screens in `frontend/app/demo/`.
- [`backend/`](backend/) — Flask, SQLAlchemy, Celery, publisher adapters, Lambda and ECS definitions.
- [`mobile/`](mobile/) — Flutter client; optional for the Docker web/API quickstart. See its [setup notes](mobile/README.md).
- [`docker-compose.yml`](docker-compose.yml) and [`Makefile`](Makefile) — local stack, seeding and smoke checks.

Configure local values from [`.env.example`](.env.example), [`backend/.env.example`](backend/.env.example) and [`frontend/.env.example`](frontend/.env.example). See [SECURITY.md](SECURITY.md) for disclosure and secret handling.
