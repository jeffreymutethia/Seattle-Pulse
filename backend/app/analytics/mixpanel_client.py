from mixpanel import Mixpanel
import os
import logging
from flask import current_app, has_app_context

def get_mixpanel_client(app_env: str) -> Mixpanel:
    token = os.getenv("MIXPANEL_TOKEN_PROD") if app_env == "production" else os.getenv("MIXPANEL_TOKEN_STAGING")

    if has_app_context():
        logger = current_app.logger
    else:
        logger = logging.getLogger(__name__)
        logging.basicConfig(level=logging.INFO)

    logger.info(f"[Mixpanel] Token for {app_env}: {token or 'MISSING'}")

    if not token:
        logger.error(f"[Mixpanel] ❌ No Mixpanel token loaded for env: {app_env}")

    return Mixpanel(token)
