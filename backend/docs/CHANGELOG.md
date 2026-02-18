# Location flow hardening

## B-2 – remove over-broad LIKE filters
- Introduced structured filter parsing in `app/location_service.py` and applied it across feed queries in `app/api/content.py` and `app/api/feed.py`.
- Added deterministic request validation to `guest_feed` and `combined_feed` with shared formatting helpers.
- Tests: `tests/content/test_location_filters.py::test_feed_filters_*`, `tests/mypulse/test_mypulse.py::test_mypulse_location_filter_passed_to_fetch`.

## B-3 – deterministic location labels
- Added `format_post_location` usage across serializers (`app/api/content.py`, `app/api/profile.py`, `app/api/events.py`, `app/api/news.py`, `app/api/feed.py`, `app/models.py`).
- Responses now ship `location_label` and `is_in_seattle` consistently for feeds, profiles, and guest endpoints.
- Tests: `tests/content/test_location_filters.py::test_location_labels_consistent_across_views`.

## B-4 – profile/thumbnail alignment
- Profile serializers (`serialize_user_content`, location listings) now reuse the shared formatter ensuring parity with feed output.
- Tests: `tests/content/test_location_filters.py::test_location_labels_consistent_across_views`.

## B-5 – guest feed parity & validation
- Guest and combined feeds reuse the normalized filters, include `location_label`, and reject empty location strings.
- Tests: `tests/content/test_location_filters.py::test_combined_feed_matches_primary`, `tests/content/test_location_filters.py::test_guest_feed_rejects_blank_location`.

## B-6 – canonical labels persisted on create
- `post_add_story` enforces coordinate coercion, canonical labels, and boolean flags via the shared helpers.
- Tests: `tests/content/test_post_add_story_canonical.py`.

## B-7 – seed helpers for E2E
- Added testing-only blueprint `app/api/test_seed.py` registered when `TESTING` is enabled for consistent location fixtures.
- Tests leverage helper in `tests/content/test_location_filters.py`.

## B-8 – backend hardening & changelog
- Replaced legacy wildcard matching with structured filters, memoized formatting reuse, and documented changes in this changelog.
- Added regression coverage across feeds and composer flows as listed above.
