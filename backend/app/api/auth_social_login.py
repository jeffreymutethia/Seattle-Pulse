import os
import pathlib
import requests
from flask import Blueprint, session, abort, redirect, request, jsonify
from google.oauth2 import id_token
from google_auth_oauthlib.flow import Flow
from pip._vendor import cachecontrol
import google.auth.transport.requests
from config import *  # Import all variables from config
from app.models import User
from app.extensions import db
from flask_login import login_user, logout_user
from flask import current_app, redirect, url_for
import os
import random
import re

# Create Blueprint for Google Social Login
auth_social_login_blueprint = Blueprint(
    "auth_social_login", __name__, url_prefix="/api/v1/auth_social_login"
)

# Detect if running inside AWS Lambda
IS_RUNNING_IN_LAMBDA = os.getenv("AWS_LAMBDA_FUNCTION_NAME") is not None

# Load environment variables directly
GOOGLE_CLIENT_ID = GOOGLE_CLIENT_ID
GOOGLE_REDIRECT_URI = GOOGLE_AUTH_REDIRECT_URI  # Load redirect URI from config

# ─────────────────────────────────────────────────────────────────────────────
# Choose “client_secret.json” path based on whether we’re in Lambda or not:
# - In Lambda, AWS_LAMBDA_FUNCTION_NAME is always set.
# - Locally or in your web container, that variable is absent, so use the repo-root file.
# ─────────────────────────────────────────────────────────────────────────────
if os.environ.get("AWS_LAMBDA_FUNCTION_NAME"):
    # Lambda runtime: your lambda_handler already wrote client_secret.json into /tmp
    CLIENT_SECRETS_FILE = "/tmp/client_secret.json"
else:
    # Local or “web” Docker container: expect client_secret.json at the repo root
    CLIENT_SECRETS_FILE = os.path.join(
        pathlib.Path(__file__).parent.parent.parent, 
        "client_secret.json"
    )
    
# Log the client secrets file path for debugging
@auth_social_login_blueprint.before_app_request
def log_client_secret_file():
    current_app.logger.info(f"Using client secrets file: {CLIENT_SECRETS_FILE}")

def get_flow():
    """Create OAuth flow lazily so missing local secrets don't crash app startup."""
    if not os.path.exists(CLIENT_SECRETS_FILE):
        return None
    return Flow.from_client_secrets_file(
        client_secrets_file=CLIENT_SECRETS_FILE,
        scopes=[
            "openid",
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://www.googleapis.com/auth/userinfo.email",
        ],
        redirect_uri=GOOGLE_REDIRECT_URI,
    )

def login_required(func):
    """Decorator to check if the user is logged in"""

    def wrapper(*args, **kwargs):
        if "google_id" not in session:
            return abort(401)  # Unauthorized
        return func(*args, **kwargs)

    return wrapper

@auth_social_login_blueprint.route("/login", methods=["GET"])
def login():
    """Redirect user to Google for authentication or return URL for mobile."""
    flow = get_flow()
    if flow is None:
        return jsonify({"status": "error", "message": "Google OAuth is not configured."}), 503

    is_mobile = request.args.get("isMobile", "false").lower() == "true"

    authorization_url, state = flow.authorization_url()
    session["state"] = state

    if is_mobile:
        return jsonify({"auth_url": authorization_url, "status": "success"}), 200
    
    return redirect(authorization_url)



def generate_unique_username(first_name, last_name):
    """Generate a unique username based on first & last name."""

    # ✅ 1. Create a base username (remove spaces & lowercase)
    base_username = re.sub(r"\W+", "", f"{first_name}{last_name}").lower()

    # ✅ 2. Check if username already exists
    existing_user = User.query.filter_by(username=base_username).first()

    if not existing_user:
        return base_username  # No conflict, return as is

    # ✅ 3. Append a random number to make it unique
    while True:
        random_number = random.randint(1000, 9999)  # 4-digit number
        new_username = f"{base_username}{random_number}"

        if not User.query.filter_by(username=new_username).first():
            return new_username  # Found unique username

@auth_social_login_blueprint.route("/callback", methods=["GET"])
def callback():
    """Handle Google OAuth callback and authenticate user (Web & Mobile)."""
    flow = get_flow()
    if flow is None:
        return jsonify({"status": "error", "message": "Google OAuth is not configured."}), 503

    os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"  # Allow HTTP in local dev

    try:
        is_mobile = request.args.get("isMobile", "false").lower() == "true"

        # Fetch token from Google
        flow.fetch_token(authorization_response=request.url)

        credentials = flow.credentials
        token_request = google.auth.transport.requests.Request()

        # Verify Google ID Token
        id_info = id_token.verify_oauth2_token(
            credentials.id_token, token_request, GOOGLE_CLIENT_ID
        )

        if not id_info:
            return (
                jsonify(
                    error={"code": 401, "message": "Invalid Google token"},
                    status="error",
                ),
                401,
            )

        # Extract user details
        email = id_info.get("email")
        first_name = id_info.get("given_name")
        last_name = id_info.get("family_name")
        profile_picture = id_info.get("picture")

        # ✅ Generate a unique username
        username = generate_unique_username(first_name, last_name)

        # Check if user exists
        user = User.query.filter_by(email=email).first()

        if not user:
            # Create new user
            user = User(
                first_name=first_name,
                last_name=last_name,
                username=username,  # ✅ Store generated username
                email=email,
                profile_picture_url=profile_picture,
                login_type="google",
                is_email_verified=True,
            )
            db.session.add(user)
            db.session.commit()

        # Log the user in
        login_user(user)

        if is_mobile:
            # ✅ Redirect mobile users to Flutter app via deep link
            #wer are not gooding to use this
            mobile_redirect_url = f"seattlepulse://callback?user_id={user.id}&name={user.first_name}&username={user.username}&email={user.email}&login_type=google"
            return redirect(mobile_redirect_url)

        # ✅ Redirect web users to frontend
        from config import get_frontend_url
        frontend_base_url = get_frontend_url()
        frontend_redirect_url = f"{frontend_base_url}/?user_id={user.id}&name={user.first_name}&username={user.username}&email={user.email}&login_type=google"
        return redirect(frontend_redirect_url)

    except Exception as e:
        current_app.logger.error(f"Google login error: {str(e)}", exc_info=True)
        return (
            jsonify(
                error={
                    "code": 500,
                    "message": "An error occurred during the callback process.",
                },
                status="error",
            ),
            500,
        )


@auth_social_login_blueprint.route("/logout")
def logout():
    """Logout the user and clear the session."""
    session.clear()
    return jsonify({"message": "Logged out successfully"})


@auth_social_login_blueprint.route("/protected")
@login_required
def protected_area():
    """Protected route that requires authentication."""
    return jsonify({"message": f"Hello, {session['name']}!", "email": session["email"]})
