# utils.py
import os
import json
import logging
import random
import re
import string
from datetime import datetime, timedelta
from functools import lru_cache
from typing import Dict, Optional

import geopandas as gpd
import osmnx as ox
import requests
from dateutil import parser
from flask import current_app, render_template, url_for
from flask_mail import Message
from shapely.geometry import Point
from shapely.ops import nearest_points
from werkzeug.utils import secure_filename

from .extensions import mail
from .models import News
from .models import db
from app.fetchers.search_providers import GoogleImageSearchProvider
from celery import Celery
from config import (
    DEFAULT_IMAGE_PLACEHOLDER,
    PLACEHOLDER_IMAGE_UNAVAILABLE,
    NOMINATIM_BASE_URL,
    GOOGLE_CUSTOM_SEARCH_API_URL,
    IPINFO_API_URL,
    get_frontend_url,
    get_survey_url,
)

logger = logging.getLogger(__name__)

# Known prefixes for placeholder images used throughout the application.
PLACEHOLDER_PREFIXES = [
    "via.placeholder.com",
    "placeholder.pagebee.io",
]

_REVERSE_GEOCODE_MAX_RETRIES = 3
_REVERSE_GEOCODE_TIMEOUT_SECONDS = 5
_REVERSE_GEOCODE_CACHE_PRECISION = 5


def is_placeholder_image(url: str | None) -> bool:
    """Return ``True`` if the given URL is considered a placeholder image."""
    if not url:
        return True

    normalized = url.strip().lower()
    for prefix in PLACEHOLDER_PREFIXES:
        if normalized.startswith(prefix) or normalized.startswith(f"http://{prefix}") or normalized.startswith(f"https://{prefix}"):
            return True
    return False


def load_json_data(filename):
    with open(filename, "r") as file:
        return json.load(file)


def clear_news():
    try:
        News.query.delete()
        db.session.commit()
    except Exception as e:
        db.session.rollback()


def make_celery(app, celery_instance: Celery | None = None):
    """Bind a Celery instance to the Flask app context.

    A Celery instance can be injected (useful for module-level decorators) or
    created on demand. Configuration is pulled from the Flask app and tasks are
    executed within an application context.
    """

    celery = celery_instance or Celery(
        app.import_name,
        backend=app.config.get("result_backend"),
        broker=app.config.get("broker_url"),
    )

    celery.conf.update(app.config)

    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask
    return celery



def send_email(subject, sender, recipients, text_body, html_body=None):
    msg = Message(subject, sender=sender, recipients=recipients)
    msg.body = text_body
    if html_body:
        msg.html = html_body
    mail.send(msg)


def send_reset_email(user, reset_url):
    """Send a password reset email to the user."""

    # Define company information
    company_name = "Seattle Pulse"
    company_country = "United States"
    company_city = "Seattle"
    company_location = f"{company_city}, {company_country}"

    # Render HTML email template with dynamic values
    html_body = render_template(
        "reset_password_email.html",
        reset_url=reset_url,
        first_name=user.first_name,  # Ensure first_name is passed
        company_name=company_name,
        company_country=company_country,
        company_city=company_city,
        company_location=company_location,
    )

    subject = "Password Reset Request"
    sender = "noreply@demo.com"
    recipients = [user.email]

    # Send the email (no need for text_body since you are using HTML email)
    send_email(subject, sender, recipients, html_body=html_body, text_body="")


def send_account_verification_email_template(
    user, verification_link, expiry_minutes=30
):
    """
    Prepare and send an account verification email.

    Args:
        user (User): The user object to whom the email is being sent.
        verification_link (str): The generated email verification link.
        expiry_minutes (int, optional): The expiration time of the link in minutes. Defaults to 30.
    """
    # Log which frontend URL is being used
    from config import FRONTEND_URL, APP_ENV
    current_app.logger.info(
        f"[EMAIL] Sending verification email to {user.email} | "
        f"Frontend URL: {FRONTEND_URL} | "
        f"Environment: {APP_ENV.upper()} | "
        f"Verification Link: {verification_link}"
    )

    # Prepare email subject and sender
    subject = "Seattle Pulse - Confirm your email"
    sender = "noreply@yourdomain.com"
    recipients = [user.email]

    # Render the HTML email using the template
    html_body = render_template(
        "account_verification_email.html",
        first_name=user.first_name,
        verification_url=verification_link,
        expiry_time=expiry_minutes,  # Dynamic expiry time
        company_name="Seattle Pulse",  # Your company name
    )

    # Call the generic send_email function
    send_email(subject, sender, recipients, text_body="", html_body=html_body)


def send_welcome_email(user):
    """
    Send a welcome email after successful email verification.

    Args:
        user (User): The user object to whom the email is being sent.
    """
    # Prepare email subject and sender
    subject = "Welcome to Seattle Pulse 🎉"
    sender = "noreply@seattlepulse.net"  # Updated to use proper domain
    recipients = [user.email]

    # Get current year for footer
    current_year = datetime.now().year

    # Render the HTML email using the template
    html_body = render_template(
        "welcome_email.html",
        first_name=user.first_name,
        app_url=get_frontend_url(),
        survey_url=get_survey_url(),
        company_name="Seattle Pulse",
        footer_year=current_year,
    )

    # Call the generic send_email function
    send_email(subject, sender, recipients, text_body="", html_body=html_body)


def send_waitlist_confirmation_email(user, signup_timestamp):
    """
    Send a waitlist confirmation email using the HTML template with built-in values.
    """
    subject = "You’re on the Seattle Pulse wait-list! 🎉"
    sender = "noreply@demo.com"
    recipients = [user.email]

    # Ensure datetime format for the template
    if isinstance(signup_timestamp, str):
        try:
            signup_dt = datetime.fromisoformat(signup_timestamp)
        except ValueError:
            signup_dt = parser.isoparse(signup_timestamp)
    else:
        signup_dt = signup_timestamp

    # Minimal context – only what the template dynamically uses
    context = {
        "company_name": "Seattle Pulse",
        "signup_timestamp": signup_dt,
        "footer_year": signup_dt.year,
    }

    html_body = render_template("waitlist_joining_confirmation_template.html", **context)

    text_body = (
        f"Hi {getattr(user, 'first_name', '')},\n\n"
        f"Thanks for joining Seattle Pulse on {signup_dt.strftime('%B %d, %Y')}.\n"
        "You're officially on the wait-list and we’ll keep you posted!\n\n"
        "– The Seattle Pulse Team"
    )

    send_email(
        subject=subject,
        sender=sender,
        recipients=recipients,
        text_body=text_body,
        html_body=html_body
    )

    

def is_valid_email(email):
    email_regex = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
    return re.match(email_regex, email) is not None


def validate_password(password):
    if len(password) < 8:
        return False, "Password must be at least 8 characters long."
    if not re.search(r"[A-Z]", password):
        return False, "Password must contain at least one uppercase letter."
    if not re.search(r"[a-z]", password):
        return False, "Password must contain at least one lowercase letter."
    if not re.search(r"[0-9]", password):
        return False, "Password must contain at least one digit."
    if not re.search(r"[!@#$%^&*(),.?\":{}|<>]", password):
        return False, "Password must contain at least one special character."
    return True, ""


def generate_otp(length=4):
    """Generate a random OTP."""
    return "".join(random.choices(string.digits, k=length))


from flask import render_template
from app.utils import send_email  # Ensure send_email is correctly imported


def send_otp_email(email, otp, user_name="User"):
    """Send an OTP email to the user with dynamic content."""
    subject = "Your OTP for Email Verification"
    sender = "noreply@demo.com"
    recipients = [email]

    # Define the variables that will be used in the template
    email_context = {
        "otp": otp,
        "user_name": user_name,  # Ensure this is passed
        "company_name": "Seattle Pulse",
        "company_location": "Seattle, WA",
        "company_country": "USA",
    }

    # Render the template with the dynamic values
    text_body = f"Your OTP for email verification is: {otp}"
    html_body = render_template("otp_email.html", **email_context)

    # Send email
    send_email(subject, sender, recipients, text_body, html_body)


def time_since_post(created_at):
    now = datetime.utcnow()
    diff = now - created_at
    if diff.days > 0:
        return f"{diff.days} days ago"
    elif diff.seconds // 3600 > 0:
        return f"{diff.seconds // 3600} hours ago"
    elif diff.seconds // 60 > 0:
        return f"{diff.seconds // 60} minutes ago"
    else:
        return "just now"


def _quantize_coordinate(value: float) -> float:
    return round(float(value), _REVERSE_GEOCODE_CACHE_PRECISION)


def _reverse_geocode_uncached(lat: float, lon: float) -> Optional[Dict[str, str]]:
    url = f"{NOMINATIM_BASE_URL}/reverse?lat={lat}&lon={lon}&format=json&zoom=14"
    headers = {"User-Agent": "SeattlePulseApp/1.0"}

    for attempt in range(1, _REVERSE_GEOCODE_MAX_RETRIES + 1):
        try:
            response = requests.get(
                url,
                headers=headers,
                timeout=_REVERSE_GEOCODE_TIMEOUT_SECONDS,
            )
            response.raise_for_status()
            data = response.json()
            return data.get("address", {})
        except requests.RequestException as exc:
            logger.warning(
                "Reverse geocode failed for (%s, %s) on attempt %s/%s: %s",
                lat,
                lon,
                attempt,
                _REVERSE_GEOCODE_MAX_RETRIES,
                exc,
            )
    return None


@lru_cache(maxsize=512)
def _reverse_geocode_cached(lat: float, lon: float) -> Optional[Dict[str, str]]:
    return _reverse_geocode_uncached(lat, lon)


def _reverse_geocode_with_cache(lat: float, lon: float) -> Optional[Dict[str, str]]:
    return _reverse_geocode_cached(
        _quantize_coordinate(lat),
        _quantize_coordinate(lon),
    )


def get_neighborhood(lat, lon):
    """Return a canonical location label for a coordinate."""

    try:
        address = _reverse_geocode_with_cache(lat, lon)
    except Exception as exc:  # pragma: no cover - defensive guard for unexpected errors
        logger.warning(
            "Reverse geocode raised unexpected error for (%s, %s): %s",
            lat,
            lon,
            exc,
        )
        address = None

    neighborhood = None
    city_or_region = None
    city = None
    state = None
    country_code = None

    if address:
        neighborhood = (
            address.get("neighbourhood")
            or address.get("suburb")
        )
        city = address.get("city") or address.get("town") or address.get("village") or address.get("hamlet")
        state = address.get("state")
        country_code = (address.get("country_code") or "").lower()
        city_or_region = (
            city
            or address.get("county")
            or state
            or address.get("country")
        )

    # Check if in Seattle using address data first (more reliable than boundary check)
    # This matches the logic in label_home_location()
    in_seattle_by_address = False
    if address and city and state:
        state_lower = state.lower()
        in_seattle_by_address = (
            city.lower() == "seattle" 
            and (state_lower == "washington" or state_lower == "wa")
            and (country_code == "us" or (address.get("country") or "").lower().startswith("united states"))
        )

    # Use boundary check as fallback if address data is unclear
    in_seattle_by_boundary = bool(is_coordinate_in_seattle(lat, lon))
    
    # Consider it in Seattle if either check indicates so
    # Prioritize boundary check if it's True, as it's more definitive
    in_seattle = in_seattle_by_boundary or in_seattle_by_address

    if in_seattle:
        # Use OSM neighborhood boundaries for more accurate neighborhood names
        # This matches what the search API uses and is more reliable than reverse geocoding
        if not _seattle_neighborhoods.empty:
            seattle_neighborhood = get_seattle_neighborhood(lat, lon, _seattle_neighborhoods)
            if seattle_neighborhood:
                return seattle_neighborhood
        
        # Fallback to reverse geocode neighborhood if OSM boundaries don't have it
        if neighborhood and neighborhood.lower() != "seattle":
            return neighborhood
        # If no neighborhood found but we know it's in Seattle, return "Seattle"
        return "Seattle"

    if city_or_region:
        if neighborhood and neighborhood.lower() != city_or_region.lower():
            return f"Outside Seattle - {neighborhood}, {city_or_region}"
        return f"Outside Seattle - {city_or_region}"

    return "Outside Seattle - Unknown Location"


def is_location_in_seattle(lat, lon):
    """Backwards-compatible alias that relies on the cached Seattle polygon."""

    return bool(is_coordinate_in_seattle(lat, lon))


def get_coordinates_from_location(neighborhood):
    """Fetch latitude and longitude for a given neighborhood using OpenStreetMap API."""
    url = f"{NOMINATIM_BASE_URL}/search?q={neighborhood}&format=json"
    headers = {"User-Agent": "SeattlePulseApp/1.0"}

    try:
        response = requests.get(url, headers=headers, timeout=5)
        response.raise_for_status()
        data = response.json()

        if data and "lat" in data[0] and "lon" in data[0]:
            return float(data[0]["lat"]), float(data[0]["lon"])

    except requests.exceptions.RequestException as e:
        print(f"Error fetching coordinates for {neighborhood}: {e}")

    return None, None  # Return None if lookup failing

def is_valid_phone_number(phone):
    return re.fullmatch(r'^\+?\d{10,15}$', phone) is not None

def is_valid_rfc_email(email: str) -> bool:
    """Validate email against simplified RFC 5322 pattern."""
    EMAIL_REGEX = r"^[\w\.-]+@[\w\.-]+\.\w+$"
    return bool(re.fullmatch(EMAIL_REGEX, email))


def is_valid_e164_phone(phone: str) -> bool:
    """Validate phone number in E.164 format (e.g., +12065551234)."""
    PHONE_REGEX = r"^\+?[1-9]\d{1,14}$"
    return bool(re.fullmatch(PHONE_REGEX, phone))


def load_seattle_neighborhoods():
    if os.getenv("APP_ENV", "").lower() == "testing" or os.getenv("SKIP_SEATTLE_NEIGHBORHOODS", "false").lower() == "true":
        return gpd.GeoDataFrame()

    gdf = ox.features.features_from_place(
        "Seattle, Washington",
        tags={"place": ["neighbourhood", "suburb", "quarter"]}
    )
    return gdf.to_crs(epsg=4326)


# Step 2: Check which one contains the point
def get_seattle_neighborhood(lat, lon, neighborhoods_gdf):
    point = Point(lon, lat)
    match = neighborhoods_gdf[neighborhoods_gdf.contains(point)]

    if not match.empty:
        name = match.iloc[0].get("name")
        return name

    # Fallback: try to find closest neighborhood within reasonable distance
    nearby = neighborhoods_gdf[neighborhoods_gdf.distance(point) < 0.005]
    if not nearby.empty:
        # Get the first (closest) nearby neighborhood
        name = nearby.iloc[0].get("name")
        if name:
            logger.debug(f"No direct match for ({lat}, {lon}), using closest: '{name}'")
            return name
    return None

ox.settings.use_cache = False
# Load the Seattle boundary once at module import; fall back to empty DataFrame if lookup fails
try:
    _seattle_boundary = ox.geocode_to_gdf("Seattle, Washington")
except Exception:
    _seattle_boundary = gpd.GeoDataFrame()

# Load Seattle neighborhoods once at module import; fall back to empty DataFrame if lookup fails
try:
    _seattle_neighborhoods = load_seattle_neighborhoods()
except Exception:
    _seattle_neighborhoods = gpd.GeoDataFrame()

def is_coordinate_in_seattle(lat, lon):
    """
    Check if a coordinate is inside the Seattle city boundary.
    """
    point = Point(lon, lat)
    return _seattle_boundary.contains(point).any()

def get_location_label(lat, lon, address, neighborhoods_gdf=None):
    if neighborhoods_gdf is None:
        neighborhoods_gdf = load_seattle_neighborhoods()
    
    if is_coordinate_in_seattle(lat, lon):
        neighborhood = get_seattle_neighborhood(lat, lon, neighborhoods_gdf)
        if neighborhood:
            return neighborhood

        # Attempt snapping
        point = Point(lon, lat)
        nearby = neighborhoods_gdf.copy()
        nearby["distance"] = nearby.centroid.distance(point)
        close = nearby[nearby["distance"] <= 0.01]  # ~1km buffer
        if not close.empty:
            return close.iloc[0].get("name", "Seattle")

        return "Seattle"
    
    elif address.get("country_code", "").upper() == "US":
        city = address.get("city") or address.get("town") or address.get("village") or "Unknown"
        state = address.get("state") or "??"
        return f"{city}, {state[:2]}"
    else:
        city = address.get("city") or address.get("town") or address.get("village") or "Unknown"
        country = address.get("country", "Unknown")
        return f"{city}, {country}"


def snap_to_neighborhood_if_close(lat, lon, neighborhoods_gdf, max_distance_km=1):
    point = Point(lon, lat)
    neighborhoods_gdf = neighborhoods_gdf.copy()
    neighborhoods_gdf["centroid"] = neighborhoods_gdf.centroid
    neighborhoods_gdf["distance"] = neighborhoods_gdf["centroid"].distance(point)
    close = neighborhoods_gdf[neighborhoods_gdf["distance"] <= max_distance_km / 111]  # degrees ~ km

    if not close.empty:
        return close.iloc[0]["name"]
    return None


def get_top_image(query: str) -> str:
    """Return the first image URL for a query using Google Image search.

    If the search fails or returns no results, a placeholder image URL is
    returned instead.
    """
    provider = GoogleImageSearchProvider()
    try:
        url = provider.search(query)
        if url:
            return url
    except Exception as exc:
        if current_app:
            current_app.logger.warning(f"Image search failed for {query}: {exc}")
    return DEFAULT_IMAGE_PLACEHOLDER

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
GOOGLE_SEARCH_ENGINE_ID = os.getenv("GOOGLE_SEARCH_ENGINE_ID")

def fetch_google_image_url(query, num_results=5):
    """
    Try multiple levels of broader queries to get a relevant image.
    If none found, return the "Image Unavailable" placeholder.
    """
    cfg = current_app.config
    key = cfg.get("GOOGLE_API_KEY")
    cx  = cfg.get("GOOGLE_SEARCH_ENGINE_ID")
    if not (key and cx):
        current_app.logger.warning("[fetch_google_image_url] missing Google API creds, using placeholder")
        return PLACEHOLDER_IMAGE_UNAVAILABLE

    def search(q):
        params = {
            "q": q,
            "cx": cx,
            "key": key,
            "searchType": "image",
            "num": num_results,
        }
        current_app.logger.info(f"[fetch_google_image_url] querying Google for: {q!r}")
        try:
            r = requests.get(GOOGLE_CUSTOM_SEARCH_API_URL, params=params, timeout=5)
            r.raise_for_status()
            return r.json().get("items", [])
        except Exception as e:
            current_app.logger.error(f"[fetch_google_image_url] Google API error for {q!r}: {e}")
            return []

    # build a series of fallback queries
    parts   = query.split(" - ", 1)
    keyword = parts[0]
    site_ctx = cfg.get("SITE_CONTEXT", "Seattle News")

    queries = [
        query,
        keyword,
        f"{site_ctx} {keyword.split()[0]}",
        f"{site_ctx} {keyword}",
        "Breaking News Seattle",
    ]

    # try each Google query
    for q in queries:
        items = search(q)
        if items:
            best = max(items, key=lambda it: it.get("image", {}).get("width", 0))
            link = best.get("link")
            if link:
                current_app.logger.info(f"[fetch_google_image_url] selected image for {q!r}: {link}")
                return link

    # Final placeholder if no Google results
    current_app.logger.warning("[fetch_google_image_url] no images found, using placeholder")
    return "https://via.placeholder.com/500x300?text=Image+Unavailable"


def get_geo_from_ip(ip_address):
    try:
        response = requests.get(f"{IPINFO_API_URL}/{ip_address}/json")
        current_app.logger.info(f"[GeoIP] Lookup for IP {ip_address}, status={response.status_code}")
        if response.status_code == 200:
            data = response.json()
            current_app.logger.info(f"[GeoIP] Full response for IP {ip_address}: {data}")
            city = data.get("city")
            country = data.get("country")
            current_app.logger.info(f"[GeoIP] Result for IP {ip_address}: city={city}, country={country}")
            return city, country
    except Exception as e:
        current_app.logger.warning(f"[GeoIP] Failed to fetch geo for IP {ip_address}: {e}")
    return None, None
