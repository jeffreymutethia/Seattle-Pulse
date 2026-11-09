# Seattle Pulse backend

The Flask API for Seattle Pulse's web and Flutter clients. It handles session authentication, content, neighborhood feeds, profiles, follows and discussions. SQLAlchemy stores application records in PostgreSQL; Celery and Redis support background ingestion. Flask-SocketIO supplies the messaging and notification paths.

Publisher adapters extract headlines, source links, timestamps, descriptions and images. The saver checks for duplicates and assigns a neighborhood from each publisher's coverage area. The combined feed filters those records by location and interleaves sources; My Pulse has separate following and engagement-ranking logic. The [engineering walkthrough](../docs/ENGINEERING.md) traces these paths through the code.

The public static demo uses bundled fixtures and does not call this API.

## Run locally

Start Docker Desktop, then run from the repository root:

```sh
make demo
make smoke
```

The root Compose file starts Flask, Next.js, PostgreSQL and Redis. `make demo` waits for backend health and seeds fictional content; `make smoke` checks the API, guest feed, login and session persistence. The backend is exposed at [localhost:5050](http://localhost:5050), mapped to port `5000` inside the container.

Local login: `demo@seattlepulse.local` / `DemoPass123!`.

Useful commands from the repository root:

```sh
make seed
docker compose logs -f backend
```

`make seed` can be repeated without duplicating demo rows and repairs the demo's canonical neighborhood labels. See the [local walkthrough](../docs/DEMO.md#full-local-system) for configuration and troubleshooting.

The root quickstart disables live startup fetching and leaves LocalStack optional. It starts the web process; Celery worker and beat are separate deployment processes supported by [`entrypoint.py`](entrypoint.py). The repository also contains an older backend-specific Compose configuration; use the root quickstart for the documented web/API setup.

## Configuration

[`backend/.env.example`](.env.example) lists backend settings; [the root template](../.env.example) supplies Compose defaults. Python dependencies are listed in [`requirements.txt`](requirements.txt), and the Docker image uses Python 3.10.

For development outside Docker, provide a reachable PostgreSQL database, install the requirements in a virtual environment, and configure the local database, session salts and frontend URLs. Container hostnames such as `db`, `redis` and `localstack` must be replaced with addresses reachable from the host. [`run.py`](run.py) starts the API on port `5000`, or the configured `PORT`.

The [app factory](app/__init__.py) initializes extensions and routes. [Flask-Migrate revisions](migrations/) record schema changes. External integrations such as email, OAuth, storage and live ingestion need their own configuration; the seeded Docker walkthrough does not require those services. See [SECURITY.md](../SECURITY.md) for secret handling.

## Check changes

[CI](../.github/workflows/ci.yml) installs the Python requirements, compiles `app` and `tests`, and runs this regression subset against a disposable SQLite database:

```sh
python -m compileall -q app tests
pytest -q tests/auth/test_login.py tests/content/test_get_guest_feed.py tests/content/test_demo_seed.py
```

Run these commands from `backend/` in a configured virtual environment, using the test environment from the workflow. The fixtures clear database tables, so use an isolated test database. The test harness stubs import-time OpenStreetMap downloads; these checks cover stored location labels and API behavior, not live geographic classification. Other tests live in [`tests/`](tests/); the CI subset does not establish that the entire suite passes.

## Code map

- [`app/api/`](app/api/) — authentication, content, feed, relationships, profiles and other API routes.
- [`app/models.py`](app/models.py) — relational models.
- [`app/fetchers/`](app/fetchers/) — publisher adapters, saving and scheduled fetches.
- [`app/location_service.py`](app/location_service.py) — canonical location filtering.
- [`scripts/seed_demo.py`](scripts/seed_demo.py) — deterministic local accounts, stories and discussions.
- [`lambda-news-fetcher/`](lambda-news-fetcher/) — multi-source ingestion handler.
- [`ecs-task-def.json`](ecs-task-def.json) — container deployment definition.

[Local architecture](../docs/ARCHITECTURE.md) · [Web client](../frontend/) · [Flutter client](../mobile/)

## License

All rights reserved.  
This project is proprietary and confidential. Unauthorized copying of this project, via any medium, is strictly prohibited.
