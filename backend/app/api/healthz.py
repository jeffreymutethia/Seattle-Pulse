from flask import Blueprint, jsonify, current_app
from datetime import datetime
from app.extensions import db
from sqlalchemy import text
import os

healthz_blueprint = Blueprint("healthz", __name__, url_prefix="/")

@healthz_blueprint.route("healthz", methods=["GET"])
def health_check():
    current_app.logger.info("[healthz] Health check endpoint called")

    checks = {
        "status": "ok",
        "env": current_app.config.get("APP_ENV", "unknown"),
        "time": datetime.utcnow().isoformat() + "Z",
        "db": "unreachable",
        "broker": "unreachable"
    }

    error_details = None

    # ✅ 1. Check database connection
    try:
        db.session.execute(text("SELECT 1"))
        checks["db"] = "ok"
    except Exception as db_exc:
        current_app.logger.error(f"[healthz] DB check failed: {db_exc}")
        checks["db"] = "fail"
        error_details = str(db_exc)

    # ✅ 2. Check Celery broker connectivity
    try:
        broker_url = current_app.config.get("CELERY_BROKER_URL", os.getenv("CELERY_BROKER_URL", "memory://"))

        if broker_url.startswith("memory://"):
            checks["broker"] = "in-memory"
        elif broker_url.startswith("redis://"):
            try:
                import redis
                r = redis.StrictRedis.from_url(broker_url)
                r.ping()
                checks["broker"] = "ok"
            except Exception as broker_exc:
                current_app.logger.error(f"[healthz] Redis broker check failed: {broker_exc}")
                checks["broker"] = "fail"
                if not error_details:
                    error_details = str(broker_exc)
        else:
            checks["broker"] = "skipped"
    except Exception as outer_exc:
        current_app.logger.error(f"[healthz] Broker check error: {outer_exc}")
        checks["broker"] = "fail"
        if not error_details:
            error_details = str(outer_exc)

    current_app.logger.info(f"[healthz] Health check results: {checks}")

    if checks["db"] != "ok":
        return jsonify({**checks, "error": error_details or "Unknown error"}), 500

    return jsonify(checks), 200
