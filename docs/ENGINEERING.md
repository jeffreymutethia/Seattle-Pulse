# How Seattle Pulse works

Seattle Pulse combines local content with neighborhood filtering and a feed
shaped by followed sources. The web app and Flutter client share a Flask API;
the hosted demo uses a static build of the web interface.

## Ingest local content

The backend has adapters for My Ballard, Capitol Hill Seattle, KOMO, The
Stranger, The Needling and Seattle Times. The
[multi-source Lambda handler](../backend/lambda-news-fetcher/lambda_handler.py)
fetches each publisher and delegates parsing to its
[adapter](../backend/app/fetchers/). Adapters extract a headline, source URL,
timestamp, short body and image URL.

The shared [news saver](../backend/app/fetchers/news_saver.py) rejects missing
headlines or links. Before writing a `UserContent` record, it checks existing
seeded news for exact URLs, normalized headlines and similar titles. Each
record belongs to a publisher user and retains its source link, `is_seeded`
flag and `seed_type`.

Publisher coverage supplies the location: My Ballard maps to `Ballard,
Seattle`, Capitol Hill Seattle to `Capitol Hill, Seattle`, and citywide
publishers to `Seattle`. This is source-level classification, so it does not
infer the neighborhood of every individual article.

The [Flask app factory](../backend/app/__init__.py) configures a five-minute
Celery schedule for KOMO. The [container entrypoint](../backend/entrypoint.py)
supports web, worker and beat processes; the repository also contains ECS
definitions and Lambda ingestion code. The root Docker quickstart runs the web
process with deterministic seeds and disables startup fetching.

## Filter by neighborhood

The web feed calls [`postServices.ts`](../frontend/app/services/postServices.ts),
which requests `/api/v1/content/combined_feed` in the API-backed build. The
backend [location service](../backend/app/location_service.py) normalizes
whitespace and distinguishes Seattle-wide, outside-Seattle and exact-location
scopes. `Capitol Hill, Seattle`, for example, requires `is_in_seattle = true`
and a case-insensitive match on the canonical label.

That suffix matters: `Capitol Hill` and `Capitol Hill, Seattle` are different
stored values. The [Docker seed](../backend/scripts/seed_demo.py) and publisher
mappings use the canonical form. `make seed` repairs existing demo rows without
duplicating them; it leaves previously ingested publisher rows unchanged.

## Order the feed

The [combined feed](../backend/app/api/content.py) queries matching posts
newest-first, groups them by publisher or author, then takes one item from each
group in turn. Pagination follows this round-robin pass. Recency is preserved
within each source while consecutive stories from a single publisher are
spread across the feed. The implementation loads matching posts before
interleaving, which becomes a scaling concern as the dataset grows.

The separate [My Pulse query](../backend/app/api/feed.py) selects followed
authors, excludes blocked accounts and orders by an engagement expression with
time decay:

```text
(2 × reactions + 3 × comments + 5 × shares) × exp(−age_seconds / 86400)
```

This is the backend ranking path. The static demo demonstrates following by
filtering a small fixture set; it does not execute this query or score.

## Build a self-contained demo

The build flag in [`lib/demo.ts`](../frontend/lib/demo.ts) selects typed
[fixtures](../frontend/app/demo/fixtures.ts) at the post and content service
boundaries. The demo contains eight original place guides, bundled Seattle
photographs with credits, and fictional publishers such as Market Notes and
Hill Notes. Each publisher has a distinct bundled avatar.

The Feed reuses the neighborhood selector, cards and discussion components.
The sign-in route adapts the original login artwork and layout. The sidebar
and mobile navigation expose static routes for The Feed, My Pulse and Profile;
Profile reuses the existing header and displays saved guides with publisher
credits.

[`DemoSessionBoundary`](../frontend/app/demo/demo-session.tsx) is mounted only
in demo mode. It keeps the sample reader session, follows, comments and profile
edits in the current tab's `sessionStorage`. The selected feed location is
stored separately, so signing in preserves it. Both feeds and the profile
collections open the same discussion component.

| Public demo | API-backed system |
| --- | --- |
| Bundled guides and photos | Publisher ingestion and database content |
| Neighborhood filtering over typed fixtures | Location filters in SQLAlchemy queries |
| Followed-source fixture feed | Followed-author query and engagement ranking |
| Browser-local demo session and edits | Server authentication and persistent writes |
| The Feed, My Pulse, Profile and discussions | Additional upload, messaging, notification, settings and map paths |

The regular build retains its API behavior. Optional demo callbacks on shared
components retain their original defaults. The
[Docker stack](../docker-compose.yml) runs Next.js, Flask, PostgreSQL and Redis;
see [architecture](ARCHITECTURE.md) and [local setup](DEMO.md#full-local-system).

The [Flutter app](../mobile/lib/) contains feed, story, comment, profile and
messaging screens backed by Flask. Its
[API client](../mobile/lib/src/core/api/api_client.dart) currently targets the
deployed API; using Docker requires changing the base URL for the simulator or
device. It is separate from the hosted demo and optional for the web/API
quickstart.

## Verification boundaries

The blocking browser journey covers the static product at desktop and mobile
Chrome viewport sizes, including routes, reloads, images and the absence of
backend or socket calls. It does not test the Flutter app or physical mobile
devices.

Backend regressions cover login, guest-feed location filtering and seed
maintenance. Their harness stubs import-time OpenStreetMap downloads, so these
tests do not validate live boundary retrieval or geographic classification.
See [deployment and verification](DEPLOYMENT.md) for commands and release
evidence.
