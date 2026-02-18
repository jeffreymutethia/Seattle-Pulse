# Beta release 1 review (PR #66)

## Test run status
- `pytest -q` was aborted after hanging during application startup. The run tried to build the full Flask app (including Socket.IO, Celery, and database connections) while importing `app`, emitted missing secret/tokens warnings, and was interrupted with `KeyboardInterrupt`.

## Release blockers / risks
1. **Eager app and Celery initialization on import**
   - `app/__init__.py` calls `create_app()` at module import time, creating the Flask app, Celery instance, and running `db.create_all()` even when the module is only imported (e.g., during tests). This double-instantiates the application because entrypoints like `run.py` also call `create_app()`, and it makes any import of `app` perform external initialization unexpectedly.【F:app/__init__.py†L387-L394】

2. **Tests inherit production-style startup requirements**
   - Because the module initializes eagerly, test imports try to build the full production stack (Sentry, AWS clients, external API config), which likely caused the stalled `pytest` run. The test fixtures intend to configure an in-memory database, but the module-level initialization happens before fixtures can adjust settings.【F:tests/__init__.py†L17-L37】

## Recommendations before merging
- Gate `create_app()` execution behind explicit entrypoints (CLI, scripts, or tests) instead of running at import time. Replace the module-level `app, celery = create_app()` with a guard such as `if __name__ == "__main__":` or move initialization solely into `run.py`/worker entrypoints. Likewise, run `db.create_all()` only inside those controlled contexts.【F:app/__init__.py†L387-L394】【F:run.py†L6-L33】
- Provide a lightweight testing configuration path that skips external clients and uses the in-memory SQLite database without requiring production env vars. Start `create_app(config_name="testing")` without touching networked services so the fixtures in `tests/__init__.py` can finalize configuration before any external calls are made.【F:tests/__init__.py†L23-L39】
- Re-run `pytest` after deferring initialization to verify the suite completes. If the run still hangs, capture the stack trace to pinpoint any remaining blocking startup hooks.
