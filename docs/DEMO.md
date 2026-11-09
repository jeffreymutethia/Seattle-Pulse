# Demo walkthroughs

## Browsable product demo

The static demo opens as a guest in **All Seattle**, with eight original place
guides covering eight areas. Choose a neighborhood, open a story, then visit
the dedicated **Sign in** page. It reuses the original login artwork and layout.
**Continue as demo reader** creates a local Alex Morgan session and returns to
the feed with the selected neighborhood intact.

The desktop rail and mobile bottom bar link real routes:

- `/` — The Feed: citywide guides, neighborhood filters and sample discussions.
- `/auth/login/` — original branded sign-in, demo entry and back to browsing.
- `/mypulse/` — guides from three initially followed fictional publishers; follow
  and unfollow sources to change this feed locally.
- `/profile/` — original profile header with a sample avatar, six saved guides,
  local comments and working local profile editing.

Guests can browse immediately. My Pulse and Profile offer the sign-in route
when the visitor has no demo session. After signing in, add a sample comment,
open My Pulse, unfollow Market Notes, then reload. Its guide remains absent.
Open Profile, explore Saved guides and Your comments, edit the bio, and reload.
Sign out to return to guest access. There are no account credentials to enter.

Sessions, selected neighborhood, follows, profile edits and added comments stay
in the current browser tab's session storage. These simulate the product's
interactions without authenticating against Flask or saving to the server.
Publisher identities and the reader account are fictional; guides are original
copy about real places. Existing photography is bundled with credits available
from **About this edition and photo credits** on The Feed.

```sh
cd frontend
npm ci
npm run build:demo
npm run test:demo
```

To browse manually, run `npm run serve:demo` and open `http://localhost:3000`.
Stop that server before `npm run test:demo`, which manages its own server. On a
host inheriting `ELECTRON_RUN_AS_NODE`, run `env -u ELECTRON_RUN_AS_NODE npm run test:demo`.

See [deployment settings and verification](DEPLOYMENT.md) for Vercel access
status, direct-route checks, screenshots and the release-blocking browser test.
The regular build retains the API-backed product and does not enable demo mode.

## Full local system

The Docker quickstart below exercises the Flask API and persistent database.
The portfolio flag is off in the normal frontend build and Docker stack.

### 1) Start the stack
```bash
make demo
```

This starts frontend, backend, Postgres, and Redis, waits for backend health, and seeds deterministic demo data.

Demo credentials:
- Email: `demo@seattlepulse.local`
- Password: `DemoPass123!`

## 2) 2-Minute User Script
1. Open `http://localhost:3000`.
2. Point out that the guest feed loads immediately (seeded local data).
3. Log in with the demo credentials.
4. Refresh the page and show session-backed state persists.
5. If needed, mention that auth verification is backed by `/api/v1/auth/is_authenticated`.
6. Optional terminal proof: run `make smoke`.

## 3) Smoke Validation
```bash
make smoke
```

Expected output (PASS lines):
```text
PASS: /healthz returned 200
PASS: guest_feed returned 200 with success payload
PASS: login returned 200 with success payload
PASS: authenticated session confirmed
PASS: frontend returned 200
Smoke test completed successfully.
```

## 4) Optional Logs During Demo
```bash
make logs
```

## 5) Reset / Recover Fast
```bash
make down
make demo
```

## 6) Optional Quality Checks
```bash
make lint
make test
```

## Common Failure Modes
- `make demo` fails immediately:
  - Ensure Docker Desktop is running.
- Backend not reachable on `5050`:
  - Check host port conflicts, then rerun `make demo`.
- Login fails due to protocol mismatch:
  - Verify `NEXT_PUBLIC_API_BASE_URL=http://localhost:5050/api/v1`.
- UI data seems stale:
  - Run `make seed`.
