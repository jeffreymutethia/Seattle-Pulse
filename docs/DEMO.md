# Demo Walkthrough

This is a user-focused script that works in about 2 minutes.

## 1) Start The Stack
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
