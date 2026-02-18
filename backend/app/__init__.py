# Standard library imports
import os
import sys
import logging
from datetime import datetime, timedelta
from sqlalchemy.orm import sessionmaker
import time
from sqlalchemy.exc import OperationalError
from celery.schedules import crontab
import pprint
from werkzeug.middleware.proxy_fix import ProxyFix

# Third-party imports
from flask import Flask, jsonify, current_app
from flask_login import LoginManager
from flask_migrate import Migrate
from flask_mail import Mail
from dotenv import load_dotenv
import boto3
import sentry_sdk
from flask_cors import CORS
from config import USE_GMAIL_FOR_WAITLIST_EMAILS, broker_url, result_backend,CORS_ALLOWED_ORIGINS
from sentry_sdk.integrations.flask import FlaskIntegration

# AWS S3 Configuration
from botocore.client import Config

# Application-specific imports
from .models import User, Notification
from .rate_limiting import limiter
from .extensions import db, socketio  # Import db and socketio from extensions
from .utils import make_celery
from celery import Celery
from config import *
from flask import request
from twilio.rest import Client
from sqlalchemy import create_engine


# Blueprint imports
from app.api.auth import auth_v1_blueprint
from app.api.profile import profile_v1_blueprint
from app.api.comment import comments_v1_blueprint
from app.api.content import content_v1_blueprint
from app.api.user_relationships import user_relationships_v1_blueprint
from app.api.news import news_v1_blueprint
from app.api.events import events_v1_blueprint
from app.api.feed import feed_v1_blueprint
from app.api.users import users_v1_blueprint
from app.api.reaction import reaction_v1_blueprint
from app.api.upload import upload_v1_blueprint
from app.api.auth_social_login import auth_social_login_blueprint
from app.api.notification import notification_v1_blueprint
from app.api.phone_otp_verification import phone_otp_verification_blueprint
from app.api.direct_chat import chat_v1_blueprint
from app.api.seeding import seeding_blueprint
from app.api.group_chat import group_chat_blueprint
from app.api.moderation import moderation_v1
from app.api.media_moderation import media_moderation_v1
from app.api.waitlist import waitlist_v1_blueprint
from app.api.healthz import healthz_blueprint
from app.api.test_seed import test_seed_v1_blueprint

from app.analytics.mixpanel_client import get_mixpanel_client

# Error handlers
from .error_handlers import register_error_handlers

from config import SENTRY_DSN

# Load environment variables
load_dotenv()

# Configuration Values
from config import NEWS_SOURCE_KOMO
city_id = "5809844"
units = "imperial"
news_source = NEWS_SOURCE_KOMO
today = datetime.now()
formatted_date = today.strftime("%Y-%m-%d")

celery = Celery(__name__)


def create_app(config_name: str | None = None):
    global celery

    app = Flask(__name__)

    is_testing = config_name == "testing"
    
    # 1) Apply CORS *globally*, allowing only your dev origin and credentials.
    
    # ⬇︎ Trust the first proxy's X-Forwarded-For and X-Forwarded-Proto headers
    app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1)

    
    # 1) Apply CORS *globally*, allowing only your dev origin and credentials.
    CORS(
        app,
        resources={r"/api/v1/*": {"origins": CORS_ALLOWED_ORIGINS}},
        supports_credentials=True,
        intercept_exceptions=True,        # ← make sure error responses (401, etc.) get CORS headers
        methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization"],
    )
    
    app.logger.info(f"[CORS] Allowed origins: {CORS_ALLOWED_ORIGINS}")

    if is_testing:
        app.config["TESTING"] = True


    # 3) Now you can register your URL map settings, blueprints, etc.
    app.url_map.strict_slashes = False
    
    app.logger.info("===== Starting create_app() =====")

    # 1) Determine the environment
    app_env = "testing" if is_testing else os.getenv("APP_ENV", "local").lower()
    app.config["APP_ENV"] = app_env
    app.logger.info(f"[ENV] APP_ENV detected as: {app_env!r}")

    # Initialize Sentry only for non-test environments
    if not is_testing and SENTRY_DSN:
        sentry_sdk.init(
            dsn=SENTRY_DSN,
            integrations=[FlaskIntegration()],
            traces_sample_rate=1.0,
            _experiments={
                "continuous_profiling_auto_start": True,
            },
        )

    # ✅ Initialize Mixpanel client
    if is_testing:
        class _NoopMixpanel:
            def track(self, *_, **__):
                return None

        mixpanel_client = _NoopMixpanel()
    else:
        mixpanel_client = get_mixpanel_client(app_env)

    app.mixpanel = mixpanel_client

    # ✅ Load AWS Region from environment (NEW)
    aws_region = os.getenv("AWS_REGION", "us-west-2")
    app.config["AWS_REGION"] = aws_region 

    # 2) Load the correct DATABASE_URL based on APP_ENV
    # Priority: Environment-specific variable > Generic DATABASE_URL
    if app_env == "staging":
        db_url = os.getenv("DATABASE_URL_STAGING") or os.getenv("DATABASE_URL")
    elif app_env == "production":
        db_url = os.getenv("DATABASE_URL_PRODUCTION") or os.getenv("DATABASE_URL")
    else:
        db_url = os.getenv("DATABASE_URL_LOCAL") or os.getenv("DATABASE_URL")

    if not db_url:
        raise ValueError("No DATABASE_URL set for SQLAlchemy database.")

    app.config["SQLALCHEMY_DATABASE_URI"] = db_url

    # 4) Secret key
    secret_key = os.getenv("SECRET_KEY")
    if secret_key:
        app.logger.info("[SEC] SECRET_KEY found in env")
    else:
        secret_key = os.urandom(16).hex()
        app.logger.warning("[SEC] SECRET_KEY not found, using random fallback")
    app.config["SECRET_KEY"] = secret_key

    # 6) Other Flask-Mail, Twilio, API keys, etc.
    app.config.update(
        MAIL_SERVER="smtp.gmail.com",
        MAIL_PORT=465,
        MAIL_USE_TLS=False,
        MAIL_USE_SSL=True,
        MAIL_USERNAME=os.getenv("MAIL_USERNAME"),
        MAIL_PASSWORD=os.getenv("MAIL_PASSWORD"),
        REMEMBER_COOKIE_DURATION=os.getenv("REMEMBER_COOKIE_DURATION"),
        PASSWORD_RESET_SALT=os.getenv("PASSWORD_RESET_SALT"),
        GOOGLE_CLIENT_ID=os.getenv("GOOGLE_CLIENT_ID"),
        GOOGLE_CLIENT_SECRET=os.getenv("GOOGLE_CLIENT_SECRET"),
        GOOGLE_AUTH_REDIRECT_URI=os.getenv("GOOGLE_AUTH_REDIRECT_URI"),
        TWILIO_ACCOUNT_SID=os.getenv("TWILIO_ACCOUNT_SID"),
        TWILIO_AUTH_TOKEN=os.getenv("TWILIO_AUTH_TOKEN"),
        TWILIO_VERIFY_SERVICE_SID=os.getenv("TWILIO_VERIFY_SERVICE_SID"),
        
        GOOGLE_API_KEY=os.getenv("GOOGLE_API_KEY"),
        GOOGLE_SEARCH_ENGINE_ID=os.getenv("GOOGLE_SEARCH_ENGINE_ID"),
    )
    
    app.config["USE_GMAIL_FOR_WAITLIST_EMAILS"] = USE_GMAIL_FOR_WAITLIST_EMAILS
    app.logger.info(f"[init] USE_GMAIL_FOR_WAITLIST_EMAILS: {USE_GMAIL_FOR_WAITLIST_EMAILS}")

    
    # ✅ Attach Twilio client and Verify SID to app
    twilio_account_sid = app.config.get("TWILIO_ACCOUNT_SID")
    twilio_auth_token = app.config.get("TWILIO_AUTH_TOKEN")
    verify_service_sid = app.config.get("TWILIO_VERIFY_SERVICE_SID")

    if not is_testing and twilio_account_sid and twilio_auth_token and verify_service_sid:
        app.twilio_client = Client(twilio_account_sid, twilio_auth_token)
        app.twilio_verify_sid = verify_service_sid
    elif not is_testing:
        app.logger.warning("[Twilio] Twilio configuration incomplete. OTP via SMS will fail.")

    # 7) Session cookies
    # Load env flag for overriding session behavior
    override_session_env = os.getenv("APP_ENV_FOR_SESSION", "false").lower() == "true"
    app.logger.info(f"[ENV] APP_ENV: {app_env} | APP_ENV_FOR_SESSION override: {override_session_env}")

    if override_session_env or is_testing:
        # Override session settings to local/dev-friendly for testing
        app.config.update(
            SESSION_COOKIE_HTTPONLY=True,
            SESSION_COOKIE_SAMESITE="Lax",
            SESSION_COOKIE_SECURE=False,
            SESSION_COOKIE_DOMAIN=None  # ← Domainless cookie for localhost
        )
    else:
        # Use production/staging settings
        app.config.update(
            SESSION_COOKIE_NAME="session",
            SESSION_COOKIE_HTTPONLY=True,
            SESSION_COOKIE_SAMESITE="None",
            SESSION_COOKIE_SECURE=True,
            SESSION_COOKIE_DOMAIN=".seattlepulse.net"
        )

    # 8) Initialize extensions
    db.init_app(app)
    engine = create_engine(db_url)
    
    Session = sessionmaker(bind=engine)
    app.db_session = Session()

    # 9) Test DB connection with retries (skip during migrations)
    is_migration = sys.argv[0].endswith("flask") and "db" in sys.argv
    if not is_migration and not hasattr(app, "db_initialized"):
        max_retries = 5
        for attempt in range(1, max_retries + 1):
            try:
                with engine.connect():
                    app.db_initialized = True
                    break
            except OperationalError as e:
                if attempt < max_retries:
                    time.sleep(5)
                else:
                    app.logger.warning(f"[EXT] Database connection failed: {e}")
                    raise

    # 10) Continue init of other extensions
    migrate = Migrate(app, db)
    socketio.init_app(app)
    login_manager = LoginManager()
    login_manager.init_app(app)
    
    @login_manager.user_loader
    def load_user(user_id: str):
        from .models import User
        return User.query.get(int(user_id))

    mail = Mail(app)

    # 11) Register blueprints
    for bp in (
        auth_v1_blueprint, profile_v1_blueprint, comments_v1_blueprint,
        content_v1_blueprint, user_relationships_v1_blueprint,
        news_v1_blueprint, events_v1_blueprint, feed_v1_blueprint,
        users_v1_blueprint, reaction_v1_blueprint, upload_v1_blueprint,
        auth_social_login_blueprint, notification_v1_blueprint,
        phone_otp_verification_blueprint, chat_v1_blueprint,
        seeding_blueprint, group_chat_blueprint,moderation_v1,media_moderation_v1,waitlist_v1_blueprint,healthz_blueprint
    ):
        app.register_blueprint(bp)

    app.register_blueprint(test_seed_v1_blueprint)

    
    # ✅ Register error handlers (NEW)
    register_error_handlers(app)
    
    # 12) AWS S3 config
    if not is_testing:
        if app_env == "local":
            aws_access_key = os.getenv("LOCAL_AWS_ACCESS_KEY_ID")
            aws_secret_key = os.getenv("LOCAL_AWS_SECRET_ACCESS_KEY")
            s3_endpoint = os.getenv("LOCAL_S3_ENDPOINT_URL")
        elif app_env == "staging":
            aws_access_key = os.getenv("STAGING_AWS_ACCESS_KEY_ID")
            aws_secret_key = os.getenv("STAGING_AWS_SECRET_ACCESS_KEY")
            s3_endpoint = os.getenv("STAGING_S3_ENDPOINT_URL")
        else:
            aws_access_key = os.getenv("PROD_AWS_ACCESS_KEY_ID")
            aws_secret_key = os.getenv("PROD_AWS_SECRET_ACCESS_KEY")
            s3_endpoint = os.getenv("PROD_S3_ENDPOINT_URL")

        app.logger.info(f"[S3] Endpoint URL: {s3_endpoint}")

        # AWS S3 Configuration with addressing style set here
        app.s3_client = boto3.client(
            "s3",
            aws_access_key_id=aws_access_key,
            aws_secret_access_key=aws_secret_key,
            region_name=aws_region,
            endpoint_url=s3_endpoint,
            config=Config(s3={'addressing_style': 'virtual'})  # ✅ FIX HERE
        )

        # inside create_app(), after loading AWS_REGION
        app.comprehend_client = boto3.client(
            'comprehend',
            region_name=aws_region
        )

        app.rekognition_client = boto3.client(
            'rekognition',
            region_name=aws_region
        )

        app.sns_client = boto3.client(
            'sns',
            aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
            aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
            region_name=aws_region
        )
        app.config["WAITLIST_SNS_ARN"] = os.getenv("WAITLIST_SNS_ARN")

    # Update Celery Configuration
    if is_testing:
        app.config.setdefault("broker_url", "memory://")
        app.config.setdefault("result_backend", "rpc://")
        app.config.setdefault("task_always_eager", True)
    else:
        app.config.update(
            broker_url     = broker_url,
            result_backend = result_backend,
            imports=("app.fetchers.news_fetcher",),
        )

    celery = make_celery(app, celery)
    celery.conf.broker_connection_retry_on_startup = True
    
    # ➊ Define your periodic schedule
    celery.conf.beat_schedule = {
        'fetch-news-every-5-minutes': {
            'task': 'app.fetchers.news_fetcher.fetch_data',
            'schedule': 300.0,        # 300 seconds = 5 minutes
            'args': (news_source,)
        }
    }
    
    celery.conf.beat_max_loop_interval = 10.0

    # Celery Logging
    celery_logger = logging.getLogger('celery')
    celery_logger.setLevel(logging.INFO)
    celery_handler = logging.StreamHandler()
    celery_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    celery_handler.setFormatter(celery_formatter)
    celery_logger.addHandler(celery_handler)

    # App Logging
    log_level = os.getenv("LOGGING_LEVEL", "DEBUG").upper()
    handler = logging.StreamHandler()
    handler.setLevel(log_level)
    formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    handler.setFormatter(formatter)
    app.logger.addHandler(handler)
    app.logger.setLevel(log_level)

    # Health check route for ECS
    @app.route('/ecs-test', methods=['GET'])
    def ecs_test():
        return {
            "status": "ok",
            "env": app.config.get("APP_ENV", "unknown"),
            "time": datetime.utcnow().isoformat() + "Z"
        }, 200
        
    # AWS Health check route for production
    @app.route('/health-production')
    def health_production_check():
        return "OK - prod", 200

    @app.route("/test-mixpanel", methods=["POST"])
    def test_mixpanel():
        email = request.json.get("email", "test@example.com")
        try:
            current_app.mixpanel.track(
                distinct_id=email,
                event_name="waitlist_joined",
                properties={"test": True}
            )
            return {"status": "ok"}, 200
        except Exception as e:
            current_app.logger.error(f"[test-mixpanel] error: {e}")
            return {"status": "fail", "error": str(e)}, 500


    # Database table creation (skip during migrations)
    is_migration = sys.argv[0].endswith("flask") and "db" in sys.argv
    if not is_migration:
        with app.app_context():
            db.create_all()

    return app, celery
