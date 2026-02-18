import sys
import os
import subprocess
from dotenv import load_dotenv

# Load environment variables before setting anything
load_dotenv()

def write_client_secret_file():
    json_blob = os.getenv("GOOGLE_CLIENT_SECRET_JSON")
    if json_blob:
        # ensure the directory exists
        os.makedirs("/app", exist_ok=True)
        with open("/app/client_secret.json", "w") as f:
            f.write(json_blob)
        print("Wrote /app/client_secret.json")

def main():
    # First thing: dump your Google secret if present
    write_client_secret_file()

    if len(sys.argv) < 2:
        print("Invalid argument. Use 'web', 'worker', or 'beat'.")
        sys.exit(1)

    command = sys.argv[1]

    if command == "web":
        # Optional one‑time fetch
        if os.getenv("PERFORM_STARTUP_FETCH", "false").lower() == "true":
            run_one_time_fetch()

        app_env = os.getenv("APP_ENV", "local").lower()
        if app_env == "local" and os.getenv("USE_LOCALSTACK", "false").lower() == "true":
            print("Starting create_bucket.py script with --mode docker...")
            result = subprocess.run(["python", "/app/create_bucket.py", "--mode", "docker"])
            if result.returncode != 0:
                print("create_bucket.py script failed.")
                sys.exit(1)

        print("Starting Flask-SocketIO (Eventlet) server…")
        os.execvp("python", ["python", "/app/run.py"])

    elif command == "worker":
        def _clean(var, fallback):
            val = os.getenv(var, "").strip()
            return fallback if not val else val

        broker_url = _clean("CELERY_BROKER_URL", "memory://")
        backend_url = _clean("CELERY_RESULT_BACKEND", "cache+memory://")

        print("=== [WORKER STARTUP] ===")
        print(f"✅ CELERY_BROKER_URL: {broker_url}")
        print(f"✅ CELERY_RESULT_BACKEND: {backend_url}")
        sys.stdout.flush()

        # ← Replace the old ping block below with the new one:
        if broker_url.startswith("redis://"):
            try:
                print("🔍 Attempting Redis connection test using redis-py...")
                sys.stdout.flush()

                import redis
                r = redis.StrictRedis.from_url(broker_url)
                response = r.ping()
                print(f"✅ Redis ping passed: {response}")
                sys.stdout.flush()

            except Exception as e:
                print(f"❌ Redis ping failed: {e}")
                sys.stdout.flush()
        else:
            print("ℹ️ Redis check skipped (non-redis broker).")
            sys.stdout.flush()

        print("🚀 Starting Celery worker with Eventlet pool...")
        sys.stdout.flush()
        os.system("celery -A run.celery worker --loglevel=debug -P eventlet")


    elif command == "beat":
        print("Starting Celery Beat scheduler (DEBUG)…")
        os.system("celery -A run.celery beat --loglevel=debug")

    else:
        print("Invalid argument. Use 'web', 'worker', or 'beat'.")
        sys.exit(1)


def run_one_time_fetch():
    print("=== One‑time fetch_data at startup ===")
    cmd = [
        "celery",
        "-A", "run",
        "call", "app.fetchers.news_fetcher.fetch_data",
        "--args", '["https://komonews.com/news/local"]',
    ]
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print("News fetch at startup failed.")
    else:
        print("Startup fetch succeeded.")

if __name__ == "__main__":
    main()
