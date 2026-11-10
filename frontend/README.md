# Seattle Pulse web app

The Next.js client for Seattle Pulse: neighborhood feeds, story discussions, followed sources and profiles. It uses React, TypeScript, Tailwind and Radix components.

The repository supports two builds:

| Build | Data and state | Entry point |
| --- | --- | --- |
| API-backed app | Flask API, database records and server sessions | `app/` |
| Public demo | Bundled guides, photographs and browser-local interactions | `demo/app/` |

The demo shares the existing cards, discussions, navigation and profile components. It supplies fixtures through the service layer and keeps reader state in the current tab's `sessionStorage`. The regular build retains API authentication and persistence. See the [engineering walkthrough](../docs/ENGINEERING.md) for that boundary.

## Run locally

For the full stack, start Docker Desktop and run `make demo` from the repository root. This starts the web app, Flask, PostgreSQL and Redis, then seeds local data. Open [localhost:3000](http://localhost:3000). The [local walkthrough](../docs/DEMO.md#full-local-system) covers login and smoke checks.

To run the static demo alone, use Node 20 or 22 and Python 3:

```sh
cd frontend
npm ci
npm run build:demo
npm run serve:demo
```

No application credentials are needed. Open [localhost:3000](http://localhost:3000); the exported routes are `/`, `/auth/login/`, `/mypulse/` and `/profile/`.

For API-backed development outside Docker, run `npm run dev` with the backend available. Start with [`.env.example`](.env.example) in a local `.env.local` file. The template's `backend:5000` internal URLs resolve inside Docker; when Next.js runs on the host, set both internal URLs to the backend's host address:

```dotenv
INTERNAL_API_BASE_URL=http://localhost:5050/api/v1
INTERNAL_API_URL_NOTIFICATION=http://localhost:5050
```

Browser requests use `NEXT_PUBLIC_API_BASE_URL` and `NEXT_PUBLIC_API_URL_NOTIFICATION`. Keep `NEXT_PUBLIC_APP_ENV=local` for local API development. [Configuration details](../docs/ARCHITECTURE.md)

## Check changes

From `frontend/`, after building the demo:

```sh
npm run test:demo
npm run typecheck
npm run build
```

The demo test manages its own local server; stop `serve:demo` first. It requires Chrome and checks fresh desktop and mobile viewports through browsing, sign-in, My Pulse and Profile. To check a deployed build, set `CYPRESS_BASE_URL` and run `npm run test:demo:preview`. If the shell inherits `ELECTRON_RUN_AS_NODE`, unset it before launching Cypress.

`npm run lint` reports repository-wide lint findings. Existing lint debt and the legacy Cypress suite are advisory in [CI](../.github/workflows/ci.yml); the demo walkthrough and production builds are blocking. See [deployment and verification](../docs/DEPLOYMENT.md) for the release evidence and hosting configuration.

## Code map

- [`app/services/`](app/services/) — API calls and demo fixture selection at the service boundary.
- [`app/demo/`](app/demo/) — demo screens, fixtures and session state.
- [`components/`](components/) — shared cards, navigation, discussions and UI controls.
- [`demo/`](demo/) — static-export routes and configuration; output is generated in `demo/out/`.
- [`public/`](public/) — bundled images, fonts and branding.
- [`cypress/e2e/demo-walkthrough.cy.ts`](cypress/e2e/demo-walkthrough.cy.ts) — the blocking product journey.

## License

All rights reserved.  
This project is proprietary and confidential. Unauthorized copying of this project, via any medium, is strictly prohibited.
