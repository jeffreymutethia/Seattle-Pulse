# Seattle Pulse
[![CI](https://github.com/jeffreymutethia/Seattle-Pulse/actions/workflows/ci.yml/badge.svg)](https://github.com/jeffreymutethia/Seattle-Pulse/actions/workflows/ci.yml)

Seattle Pulse is a neighborhood discovery and conversation platform. This monorepo ships a deterministic local demo (seeded data + smoke checks) so reviewers can run and validate the core product flow quickly without third-party keys.

## Core Features
- Guest feed browsing with location-aware content
- Email/password authentication with session-based login state
- Seeded demo account and deterministic sample posts for reliable demos
- Web UI flows for feed, navigation, and comment interactions
- One-command local stack with API, web app, Postgres, and Redis

## Tech Stack
- Backend: Python, Flask, SQLAlchemy, Celery
- Frontend: Next.js (React, TypeScript)
- Data: PostgreSQL, Redis
- Infra/Dev: Docker Compose, Makefile
- Mobile: Flutter (optional)

## Architecture Snapshot
```text
Browser (localhost:3000)
  | \
  |  \ client-side API calls
  |   -> localhost:5050 (host port mapped to backend container port 5000)
  |
  v
Frontend container (Next.js :3000)
  \ server-side API calls over compose network
   -> backend:5000

Backend container (Flask :5000) <-> Postgres
            |
            +--------------------> Redis
```

Runtime split (important):
- Browser code calls `http://localhost:5050/api/v1`.
- Next.js server-side code running inside the frontend container calls `http://backend:5000/api/v1`.
- The browser never calls `http://backend:5000` directly.

Deeper system detail: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

## Quickstart
Prereqs: Docker Desktop is required. `make` is recommended. Alternative: `docker compose up --build`.

```bash
make demo
```

Demo credentials:
- Email: `demo@seattlepulse.local`
- Password: `DemoPass123!`

Demo URLs:
- Web: `http://localhost:3000`
- API: `http://localhost:5050`
- Health: `http://localhost:5050/healthz`

## 60-Second Demo Flow
1. Open `http://localhost:3000`.
2. Show guest feed content loading.
3. Log in with the demo credentials.
4. Refresh and confirm session-backed state still works.
5. Optional terminal proof: run `make smoke`.

Scripted walkthrough: [`docs/DEMO.md`](docs/DEMO.md)

## Troubleshooting
- Port conflict on `3000` or `5050`: stop the conflicting process, then rerun `make demo`.
- Stack stale/unhealthy: run `make down`, then `make demo`.
- Login fails with SSL/protocol errors: verify `NEXT_PUBLIC_API_BASE_URL=http://localhost:5050/api/v1`.
- Data looks stale: run `make seed`.
- Need fast end-to-end checks: run `make smoke`.
- Need service logs: run `make logs`.
- Best-effort quality checks: run `make lint` and `make test`.

## Repo Structure
```text
.
├── backend/                # Flask API, models, templates, scripts
├── frontend/               # Next.js web app
├── mobile/                 # Flutter app (optional)
├── docs/
│   ├── DEMO.md
│   └── ARCHITECTURE.md
├── docker-compose.yml      # Root demo stack
├── Makefile                # dev/demo/seed/smoke/down/logs/test/lint
├── SECURITY.md
└── .env.example
```

## Mobile (Optional)
`mobile/` is included for completeness but is not required for the main web/API demo.
Use a locally installed Flutter SDK (see [`mobile/README.md`](mobile/README.md)); do not vendor Flutter SDK source inside this repo.

## Security & Secrets
- Never commit real secrets or tokens.
- Configure local values from:
  - [`.env.example`](.env.example)
  - [`backend/.env.example`](backend/.env.example)
  - [`frontend/.env.example`](frontend/.env.example)
- See [`SECURITY.md`](SECURITY.md) for disclosure and rotation policy.
