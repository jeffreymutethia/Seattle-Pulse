import os
from datetime import timedelta
from dotenv import load_dotenv  # Import dotenv
from sqlalchemy import create_engine

# Load environment variables from a .env file
load_dotenv()

def _clean(var, fallback):
    val = os.getenv(var, "").strip()
    return fallback if not val else val


SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")


def get_database_url() -> str:
    """Resolve database URL lazily so config imports never crash local tooling."""
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        raise ValueError(
            "DATABASE_URL is not set. Configure backend/.env or export DATABASE_URL "
            "before running database-backed commands."
        )
    return db_url


def get_engine():
    """Create SQLAlchemy engine lazily when DB access is actually needed."""
    return create_engine(
        get_database_url(),
        pool_size=10,  # Maintain up to 10 open connections
        max_overflow=5,  # Allow 5 temporary extra connections if needed
        pool_timeout=30,  # Wait 30 seconds for a connection before raising error
        pool_recycle=1800,  # Refresh connections every 30 minutes
        pool_pre_ping=True,  # Auto-reconnect if Neon DB closes the connection
    )
# Flask app configuration (new addition)
FLASK_APP = os.getenv("FLASK_APP", "run:app")

# Security and CORS Configuration
# Use a comma-separated default string
FRONTEND_URLS_RAW = os.getenv("FRONTEND_URL", "http://localhost")
CORS_ALLOWED_ORIGINS = [url.strip() for url in FRONTEND_URLS_RAW.split(",") if url.strip()]

# Determine environment for URL configuration
APP_ENV = os.getenv("APP_ENV", "local").lower()

# Frontend URLs - environment-based with fallbacks
FRONTEND_URL_PRODUCTION = os.getenv("FRONTEND_URL_PRODUCTION", "https://seattlepulse.net")


FRONTEND_URL_STAGING = os.getenv("FRONTEND_URL_STAGING", "https://staging.seattlepulse.net")
FRONTEND_URL_LOCAL = os.getenv("FRONTEND_URL_LOCAL", "http://localhost")

_FRONTEND_BASE_URLS = {
    "production": FRONTEND_URL_PRODUCTION,
    "staging": FRONTEND_URL_STAGING,
    "local": FRONTEND_URL_LOCAL,
}

# Set FRONTEND_BASE_URL based on environment (default to local if unknown)
FRONTEND_BASE_URL = _FRONTEND_BASE_URLS.get(APP_ENV, FRONTEND_URL_LOCAL)

# Backwards compatibility for any legacy usage
FRONTEND_URL = FRONTEND_BASE_URL

# S3 Bucket Configuration
S3_PROFILE_IMAGES_BUCKET_PRODUCTION = os.getenv(
    "S3_PROFILE_IMAGES_BUCKET_PRODUCTION", 
    "seattlepulse-production-profile-images-bucket"
)
S3_PROFILE_IMAGES_BUCKET_STAGING = os.getenv(
    "S3_PROFILE_IMAGES_BUCKET_STAGING", 
    "seattlepulse-staging-profile-images-bucket"
)
S3_PROFILE_IMAGES_BUCKET_LOCAL = os.getenv(
    "S3_PROFILE_IMAGES_BUCKET_LOCAL", 
    "profile-images-bucket"
)

S3_PROFILE_IMAGES_BASE_URL_PRODUCTION = os.getenv(
    "S3_PROFILE_IMAGES_BASE_URL_PRODUCTION",
    f"https://{S3_PROFILE_IMAGES_BUCKET_PRODUCTION}.s3.us-west-2.amazonaws.com"
)
S3_PROFILE_IMAGES_BASE_URL_STAGING = os.getenv(
    "S3_PROFILE_IMAGES_BASE_URL_STAGING",
    f"https://{S3_PROFILE_IMAGES_BUCKET_STAGING}.s3.us-west-2.amazonaws.com"
)

# S3 Logo Bucket
S3_LOGO_BUCKET_BASE_URL = os.getenv(
    "S3_LOGO_BUCKET_BASE_URL",
    "https://seattlepulse-logos.s3.us-east-1.amazonaws.com"
)

# External API URLs
NOMINATIM_BASE_URL = os.getenv("NOMINATIM_BASE_URL", "https://nominatim.openstreetmap.org")
GOOGLE_CUSTOM_SEARCH_API_URL = os.getenv("GOOGLE_CUSTOM_SEARCH_API_URL", "https://www.googleapis.com/customsearch/v1")
IPINFO_API_URL = os.getenv("IPINFO_API_URL", "https://ipinfo.io")
GOOGLE_FONTS_URL = os.getenv("GOOGLE_FONTS_URL", "https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600&display=swap")
ICONS8_BASE_URL = os.getenv("ICONS8_BASE_URL", "https://img.icons8.com")

# News Source URLs
NEWS_SOURCE_KOMO = os.getenv("NEWS_SOURCE_KOMO", "https://komonews.com/news/local")

# Placeholder Image URLs
PLACEHOLDER_IMAGE_BASE_URL = os.getenv("PLACEHOLDER_IMAGE_BASE_URL", "https://via.placeholder.com")
DEFAULT_IMAGE_PLACEHOLDER = f"{PLACEHOLDER_IMAGE_BASE_URL}/500x300?text=No+Image"
PLACEHOLDER_IMAGE_UNAVAILABLE = f"{PLACEHOLDER_IMAGE_BASE_URL}/500x300?text=Image+Unavailable"

# Social Media URLs
SOCIAL_MEDIA_INSTAGRAM = os.getenv("SOCIAL_MEDIA_INSTAGRAM", "https://www.instagram.com/seattle.pulse/")
SOCIAL_MEDIA_TIKTOK = os.getenv("SOCIAL_MEDIA_TIKTOK", "https://www.tiktok.com/@seattle.pulse?lang=en")
SOCIAL_MEDIA_TWITTER = os.getenv("SOCIAL_MEDIA_TWITTER", "https://x.com/seattle_pulse")

# Support Email
SUPPORT_EMAIL = os.getenv("SUPPORT_EMAIL", "support@seattlepulse.net")


# Helper functions to get environment-specific URLs
def get_frontend_url():
    """Get the frontend URL based on current environment."""
    return FRONTEND_BASE_URL


def get_s3_profile_images_bucket_name():
    """Get S3 profile images bucket name based on environment."""
    if APP_ENV == "production":
        return S3_PROFILE_IMAGES_BUCKET_PRODUCTION
    elif APP_ENV == "staging":
        return S3_PROFILE_IMAGES_BUCKET_STAGING
    else:
        return S3_PROFILE_IMAGES_BUCKET_LOCAL


def get_s3_profile_images_base_url():
    """Get S3 profile images base URL based on environment."""
    if APP_ENV == "production":
        return S3_PROFILE_IMAGES_BASE_URL_PRODUCTION
    elif APP_ENV == "staging":
        return S3_PROFILE_IMAGES_BASE_URL_STAGING
    else:
        # Local environment uses LocalStack
        bucket_name = get_s3_profile_images_bucket_name()
        localstack_host = os.getenv("LOCALSTACK_HOST", "localhost")
        localstack_port = os.getenv("LOCALSTACK_PORT", "4566")
        return f"http://{localstack_host}:{localstack_port}/{bucket_name}"


def get_auth_verification_url(token: str):
    """Get email verification URL with token."""
    return f"{FRONTEND_BASE_URL}/auth/verify-email?token={token}"


def get_auth_reset_password_url(token: str):
    """Get password reset URL with token."""
    return f"{FRONTEND_BASE_URL}/auth/reset-password?token={token}"


def get_share_url(share_id: str):
    """Get shareable content URL."""
    return f"{FRONTEND_BASE_URL}/share/{share_id}"


def get_survey_url():
    """Get survey URL."""
    return f"{FRONTEND_BASE_URL}/survey"

UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uploads")
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "gif", "mp4", "mov", "avi"}
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
GOOGLE_SEARCH_ENGINE_ID = os.getenv("GOOGLE_SEARCH_ENGINE_ID")
SESSION_COOKIE_SECURE = True
REMEMBER_COOKIE_SECURE = True
REMEMBER_COOKIE_DURATION = timedelta(days=1)
broker_url     = _clean("CELERY_BROKER_URL",     "memory://")
result_backend = _clean("CELERY_RESULT_BACKEND", "cache+memory://")
SENTRY_DSN = os.getenv("SENTRY_DSN")

# Email configuration
MAIL_SERVER = os.getenv("MAIL_SERVER", "smtp.gmail.com")
MAIL_PORT = int(os.getenv("MAIL_PORT", 465))
MAIL_USE_TLS = os.getenv("MAIL_USE_TLS", "False").lower() in ["true", "1", "t"]
MAIL_USE_SSL = os.getenv("MAIL_USE_SSL", "True").lower() in ["true", "1", "t"]
MAIL_USERNAME = os.getenv("MAIL_USERNAME")
MAIL_PASSWORD = os.getenv("MAIL_PASSWORD")

# Security configuration
SECURITY_PASSWORD_SALT = os.getenv("SECURITY_PASSWORD_SALT")
PASSWORD_RESET_SALT = os.getenv("PASSWORD_RESET_SALT")

# CORS logging configuration
LOGGING_LEVEL = os.getenv("LOGGING_LEVEL", "DEBUG").upper()

# Google OAuth configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your_default_secret_key")
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET")
GOOGLE_AUTH_REDIRECT_URI = os.getenv(
    "GOOGLE_AUTH_REDIRECT_URI", "http://localhost:5001/api/v1/auth_social_login/callback"
)

# Twilio configuration
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_VERIFY_SERVICE_SID = os.getenv("TWILIO_VERIFY_SERVICE_SID")

# AWS S3 configuration
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
S3_ENDPOINT_URL = os.getenv("S3_ENDPOINT_URL")

# Mixpanel Tokens for Tracking
MIXPANEL_TOKEN_PROD = os.getenv("MIXPANEL_TOKEN_PROD")
MIXPANEL_TOKEN_STAGING = os.getenv("MIXPANEL_TOKEN_STAGING")

_fetch_interval_hours = os.getenv("FETCH_INTERVAL_HOURS", "8").strip()

try:
    FETCH_INTERVAL_SECONDS = int(float(_fetch_interval_hours) * 3600)
except ValueError:
    raise ValueError(f"Invalid FETCH_INTERVAL_HOURS value: '{_fetch_interval_hours}'. Must be a number.")

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
GOOGLE_SEARCH_ENGINE_ID = os.getenv("GOOGLE_SEARCH_ENGINE_ID")

# Waitlist email method configuration
raw_gmail_env = os.getenv("USE_GMAIL_FOR_WAITLIST_EMAILS", "false")
USE_GMAIL_FOR_WAITLIST_EMAILS = str(raw_gmail_env).strip().lower() == "true"
