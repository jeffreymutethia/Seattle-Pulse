import os
import json
import logging
import boto3
from datetime import datetime

# Init logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
log_prefix = "[Lambda News Fetcher]"

# Step 1 → Write GOOGLE_CLIENT_SECRET_JSON to /tmp/client_secret.json (optional)
def _write_client_secret_from_sm():
    arn = os.environ.get("GOOGLE_CLIENT_SECRET_JSON")
    if not arn:
        logger.info(f"{log_prefix} GOOGLE_CLIENT_SECRET_JSON not set, skipping client_secret.json write")
        return

    logger.info(f"{log_prefix} Loading GOOGLE_CLIENT_SECRET_JSON secret")
    region = os.getenv("AWS_REGION", "us-west-2")
    sm = boto3.client("secretsmanager", region_name=region)
    resp = sm.get_secret_value(SecretId=arn)
    secret_blob = resp.get("SecretString", "")
    if not secret_blob:
        raise RuntimeError(f"Secret at {arn} has no SecretString.")

    dest_path = "/tmp/client_secret.json"
    with open(dest_path, "w") as f:
        f.write(secret_blob)
    logger.info(f"{log_prefix} Client secret written to /tmp/client_secret.json")

# Step 2 → Load SECRETS_ARN env vars
def _load_env_from_sm():
    logger.info(f"{log_prefix} Loading SECRETS_ARN")
    arn = os.environ.get("SECRETS_ARN")
    if not arn:
        raise RuntimeError("Environment variable SECRETS_ARN is not set.")

    region = os.getenv("AWS_REGION", "us-west-2")
    sm = boto3.client("secretsmanager", region_name=region)
    resp = sm.get_secret_value(SecretId=arn)
    secrets_dict = json.loads(resp.get("SecretString", "{}"))
    if not isinstance(secrets_dict, dict):
        raise RuntimeError(f"Expected JSON object in secret {arn}, got: {secrets_dict}")

    for key, val in secrets_dict.items():
        os.environ[key] = val
    logger.info(f"{log_prefix} Loaded {len(secrets_dict)} environment variables")

# Execute secret loading
_write_client_secret_from_sm()
_load_env_from_sm()

# Step 3 → Imports after secrets
from app import create_app
from app.fetchers.api_handler import APIHandler
from app.fetchers.news_fetcher import NewsFetcher
from app.fetchers.myballard_fetcher import MyBallardFetcher
from app.fetchers.chs_fetcher import CHSFetcher
from app.fetchers.stranger_fetcher import StrangerFetcher
from app.fetchers.theneedling_fetcher import TheNeedlingFetcher
from app.fetchers.SeattleTimesFetcher import SeattleTimesFetcher

def handler(event, context):
    start_time = datetime.utcnow()

    try:
        app, _ = create_app()
        api_handler = APIHandler()

        # 🔁 If explicitly requested, run KOMO-only mode
        if event.get("komo_only"):
            logger.info(f"{log_prefix} [Override] KOMO-only mode enabled.")
            from config import NEWS_SOURCE_KOMO
            source = NEWS_SOURCE_KOMO
            response = api_handler.get_news_data(source)

            if not response:
                logger.error(f"{log_prefix} ❌ Failed to fetch KOMO")
                return {"status": "fetch_failed"}

            with app.app_context():
                komo_fetcher = NewsFetcher(api_handler)
                parsed = komo_fetcher.parse_data(response)
                logger.info(f"{log_prefix} ✅ KOMO parsed: {len(parsed)}")
                saved = komo_fetcher.save_data(parsed)
                logger.info(f"{log_prefix} ✅ KOMO saved: {len(saved)}")

            return {
                "source": "komo",
                "parsed": len(parsed),
                "saved": len(saved)
            }

        # 🌐 DEFAULT: Multi-source fetch
        logger.info(f"{log_prefix} Running multi-source fetch (default)")
        results = []

        sources = [
            {
                "name": "MyBallard",
                "url": "https://www.myballard.com/",
                "fetcher_class": MyBallardFetcher
            },
            {
                "name": "KOMO",
                "url": "https://komonews.com/news/local",
                "fetcher_class": NewsFetcher
            },
            {
                "name": "CHS",
                "url": "https://www.capitolhillseattle.com/",
                "fetcher_class": CHSFetcher
            },
            {
                "name": "The Stranger",
                "url": "https://www.thestranger.com/",
                "fetcher_class": StrangerFetcher
            },
            {
                "name": "The Needling",
                "url": "https://theneedling.com/",
                "fetcher_class": TheNeedlingFetcher
            },
            {
                "name": "Seattle Times",
                "url": "https://www.seattletimes.com/",
                "fetcher_class": SeattleTimesFetcher
            }
        ]

        with app.app_context():
            for src in sources:
                logger.info(f"{log_prefix} → Fetching {src['name']} from {src['url']}")

                # Special case for MyBallard
                if src["name"] == "MyBallard":
                    fetcher = src["fetcher_class"](api_handler)
                    response = fetcher.fetch_with_headers(src["url"])
                else:
                    response = api_handler.get_news_data(src["url"])

                if not response:
                    logger.warning(f"{log_prefix} ⚠️ No response from {src['name']}")
                    results.append({"source": src["name"], "status": "fetch_failed"})
                    continue

                # Continue with normal parsing
                fetcher = src["fetcher_class"](api_handler)
                parsed = fetcher.parse_data(response)
                logger.info(f"{log_prefix} ✅ {src['name']} parsed {len(parsed)} articles")

                saved = fetcher.save_data(parsed)
                saved_count = saved.get('saved', 0) if isinstance(saved, dict) else len(saved)
                logger.info(f"{log_prefix} ✅ {src['name']} saved {saved_count} new items")

                results.append({
                    "source": src["name"],
                    "parsed": len(parsed),
                    "saved": saved_count
                })

        duration = (datetime.utcnow() - start_time).total_seconds()
        logger.info(f"{log_prefix} ✅ Multi-source fetch completed in {duration:.2f}s")

        return {
            "status": "multi_parsed_and_saved",
            "sources": results,
            "duration": duration
        }

    except Exception as exc:
        logger.error(f"{log_prefix} ❌ Exception occurred: {exc}", exc_info=True)
        return {"status": "error", "message": str(exc)}
