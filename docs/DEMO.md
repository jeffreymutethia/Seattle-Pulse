# Running Seattle Pulse

## Public demo

The [hosted demo](https://seattle-pulse-demo.vercel.app/) opens
in **All Seattle** with eight original place guides. Choose a neighborhood and
open a story to read its sample discussion. Guests can browse immediately.

Choose **Sign in**, then **Continue as demo reader** to use the fictional Alex
Morgan account. Sign-in returns to the feed with the selected neighborhood
intact. The desktop sidebar and mobile navigation connect these routes:

| Route | Interaction |
| --- | --- |
| `/` | Citywide feed, neighborhood filters and discussions |
| `/auth/login/` | Demo sign-in and a return to browsing |
| `/mypulse/` | A feed from three initially followed publishers; follow and unfollow sources |
| `/profile/` | Six saved guides, comment activity and an editable sample profile |

Comments, follows, profile edits and the demo session persist in the current
tab's `sessionStorage`. They do not authenticate against Flask or write to a
server. Publisher identities, accounts, conversations and engagement are
fictional. The guides describe real places; photography credits are available
under **About this edition and photo credits** on The Feed.

### Run the static build

Use Node 20 or 22 and Python 3:

```sh
cd frontend
npm ci
npm run build:demo
npm run serve:demo
```

Open [localhost:3000](http://localhost:3000). Stop the server before running
`npm run test:demo`, which starts its own server. If the shell inherits
`ELECTRON_RUN_AS_NODE`, use `env -u ELECTRON_RUN_AS_NODE npm run test:demo`.

The [deployment runbook](DEPLOYMENT.md) covers hosting, direct-route checks,
screenshots and the blocking browser test.

## Full local system

The Docker stack runs the API-backed web app with PostgreSQL and Redis. Demo
mode is off, and seed data replaces live publisher fetching for this setup.

### Start the stack

With Docker Desktop running, execute from the repository root:

```sh
make demo
```

This builds and starts the services, waits for backend health, and seeds the
database. Open [localhost:3000](http://localhost:3000); the API is exposed at
[localhost:5050](http://localhost:5050).

The guest feed is populated immediately. Sign in with
`demo@seattlepulse.local` / `DemoPass123!`, then reload to check the server-backed
session. These credentials belong to the local seed and are separate from the
hosted demo's password-free session.

### Check the API and session

```sh
make smoke
```

The script checks `/healthz`, the guest feed, login, authenticated session and
the frontend. Each successful check prints `PASS`.

### Logs and seed maintenance

`make logs` follows service logs. `make seed` adds missing demo rows and repairs
their canonical neighborhood labels without duplicating posts.

To stop the services while keeping database data, run `docker compose down`.
`make down` also removes the stack's volumes and local database; use it only
when resetting the data is intended.

### Troubleshooting

| Symptom | Check |
| --- | --- |
| Stack fails to start | Confirm Docker Desktop is running; inspect `docker compose ps` and `make logs`. |
| Backend is unreachable on port 5050 | Check for a host port conflict and inspect backend logs. |
| Browser login or API calls fail | Use `NEXT_PUBLIC_API_BASE_URL=http://localhost:5050/api/v1`; Docker's `backend:5000` address is for server-side calls. |
| Seeded feed data is missing or has old labels | Run `make seed`. |

Configuration defaults are in [`.env.example`](../.env.example),
[`backend/.env.example`](../backend/.env.example) and
[`frontend/.env.example`](../frontend/.env.example). See
[architecture](ARCHITECTURE.md) for service boundaries and
[deployment and checks](DEPLOYMENT.md) for verification scope.
