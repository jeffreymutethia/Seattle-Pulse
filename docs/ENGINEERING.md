# How Seattle Pulse works

Seattle Pulse addresses a neighborhood problem: citywide feeds mix stories that matter a few blocks away with stories across town. Jeffrey Mutethia owned the project end to end across the Next.js web app, Flask backend, Flutter mobile app, and infrastructure.

## Ingest local content

The backend has publisher adapters for My Ballard, Capitol Hill Seattle, KOMO, The Stranger, The Needling, and Seattle Times. The [multi-source Lambda handler](../backend/lambda-news-fetcher/lambda_handler.py) fetches each publisher and delegates HTML parsing to its [adapter](../backend/app/fetchers/). Those adapters extract a headline, source URL, timestamp, short body, and image.

The shared [news saver](../backend/app/fetchers/news_saver.py) rejects missing headlines or links, checks existing items for exact URLs and normalized or similar titles, and writes `UserContent` records associated with a publisher user. Publisher-to-neighborhood mappings supply canonical labels such as `Ballard, Seattle`, using the publisher's coverage area to classify articles. Records retain `is_seeded`, `seed_type`, and the original source link.

The [Flask app factory](../backend/app/__init__.py) also configures a five-minute Celery schedule for the configured KOMO source; the [container entrypoint](../backend/entrypoint.py) supports separate web, worker, and beat processes. The root Docker quickstart disables startup fetching and uses deterministic fixtures, so reviewers do not need publisher availability or third-party keys.

## Filter by neighborhood

The web feed starts at [`postServices.ts`](../frontend/app/services/postServices.ts) and requests `/api/v1/content/combined_feed` in the full stack. The backend [location service](../backend/app/location_service.py) normalizes whitespace and handles Seattle-wide, outside-Seattle, and exact-location scopes. A neighborhood filter such as `Capitol Hill, Seattle` matches that label case-insensitively and requires `is_in_seattle = true`.

The canonical suffix matters because `Capitol Hill` and `Capitol Hill, Seattle` are different database values. The [Docker demo seed](../backend/scripts/seed_demo.py) and publisher mappings now use the same canonical labels. Running `make seed` also repairs existing demo rows without duplicating them; it does not rewrite previously ingested publisher rows.

## Order the feed

The current [combined feed](../backend/app/api/content.py) first queries matching posts newest-first, groups them by publisher or author, then takes one item from each group in turn. It paginates after this round-robin pass. This preserves recency within each source while reducing runs of stories from one publisher. It currently loads all matching posts before interleaving, a straightforward implementation with a scaling tradeoff for large datasets.

Separate [MyPulse logic](../backend/app/api/feed.py) limits results to followed authors and orders by an engagement score with time decay: `(2 × reactions + 3 × comments + 5 × shares) × exp(−age_seconds / 86400)`. This ranking belongs to the full-system following feed.

## What the hosted walkthrough exercises

The hosted demo uses bundled, explicitly fictional fixtures at the frontend service boundary. It reuses the application's feed, location selection, story, discussion components, and TypeScript types. A reviewer can open a populated Seattle neighborhood feed as a guest, switch from Capitol Hill to Ballard, see different stories, and open a seeded discussion. Images ship with the app. No login or live backend is required.

Ingestion, database queries, authentication, persistent writes, social ranking, messaging, and mobile behavior are full-system implementation paths documented in this repository; they are not exercised by the hosted fixtures. The [Docker stack](../docker-compose.yml) runs Next.js, Flask, PostgreSQL, and Redis. Browser API calls use `localhost:5050`; server-side calls use Docker DNS at `backend:5000`. See [the local architecture](ARCHITECTURE.md) and [Docker walkthrough](DEMO.md).

The [Flutter app](../mobile/lib/) has its own feed, story, comment, profile, and messaging implementations backed by the Flask API. Its current [API client](../mobile/lib/src/core/api/api_client.dart) targets the deployed API; running mobile against Docker requires updating that base URL for the simulator or device. Mobile is optional for the Docker web/API walkthrough.

The repository includes [ECS task definitions](../backend/ecs-task-def.json), worker/beat definitions, Lambda ingestion code, Docker builds, and [CI](../.github/workflows/ci.yml). These infrastructure paths are documented separately from the self-contained hosted walkthrough.
