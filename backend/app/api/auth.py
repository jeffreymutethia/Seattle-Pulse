import os
from flask import request, jsonify, current_app, Blueprint, session
from flask_login import current_user, login_user, logout_user
from app.models import User, db, EmailVerification, OTP
from app.utils import (
    is_valid_email,
    validate_password,
    send_reset_email,
    generate_otp,
    send_otp_email,
    send_account_verification_email_template,
    send_welcome_email,
    send_email,
    is_valid_phone_number,
)
from datetime import datetime, timedelta, timezone
from sqlalchemy.exc import SQLAlchemyError
from itsdangerous import URLSafeTimedSerializer
from config import get_auth_verification_url, get_auth_reset_password_url

# Create the auth blueprint
auth_v1_blueprint = Blueprint("auth_v1", __name__, url_prefix="/api/v1/auth")


def generate_and_send_otp(user_id):
    """
    Send OTP via email or phone using Twilio Verify for phone-based users.
    """
    user = User.query.get(user_id)
    if not user:
        return {"status": "error", "message": "User not found."}

    try:
        if user.phone_number:
            # ✅ Use Twilio Verify to send SMS OTP
            verification = current_app.twilio_client.verify.v2.services(
                current_app.twilio_verify_sid
            ).verifications.create(to=user.phone_number, channel="sms")

            current_app.logger.info(f"Twilio OTP sent to {user.phone_number} with status: {verification.status}")
            return {"status": "success", "message": f"OTP sent to {user.phone_number}"}

        elif user.email:
            # ✅ Fallback to old logic for email (including DB OTP storage)
            otp = generate_otp()
            expiration_time = datetime.now(timezone.utc) + timedelta(minutes=10)

            otp_entry = OTP.query.filter_by(user_id=user_id).first()
            if otp_entry:
                otp_entry.otp = otp
                otp_entry.expiration = expiration_time
                otp_entry.last_sent = datetime.now(timezone.utc)
            else:
                otp_entry = OTP(
                    user_id=user_id,
                    otp=otp,
                    expiration=expiration_time,
                    last_sent=datetime.now(timezone.utc),
                )
                db.session.add(otp_entry)

            db.session.commit()
            send_otp_email(user.email, otp, user.username)

            current_app.logger.info(f"Email OTP sent to {user.email}")
            return {"status": "success", "message": f"OTP sent to {user.email}"}

        else:
            raise ValueError("User has neither email nor phone number.")

    except SQLAlchemyError as e:
        db.session.rollback()
        current_app.logger.error(f"Database error during OTP generation: {e}", exc_info=True)
        return {"status": "error", "message": "Database error occurred while sending OTP."}
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Unexpected error during OTP generation: {e}", exc_info=True)
        return {"status": "error", "message": "Failed to send OTP."}


def generate_and_store_verification_token(user):
    """
    Generate an email verification token, store it in the database, and return the verification link.

    Args:
        user (User): The user object for whom the verification token is generated.

    Returns:
        str: The verification link containing the generated token.
    """

    # Generate a secure token
    serializer = URLSafeTimedSerializer(current_app.config["SECRET_KEY"])
    token = serializer.dumps({"user_id": user.id}, salt="email-verification")

    # Construct the verification URL
    verification_link = get_auth_verification_url(token)
    current_app.logger.info(f"[EMAIL] Verification email - Frontend URL: {verification_link}")

    # Store the token in the database
    email_verification = EmailVerification(user_id=user.id, token=token)
    db.session.add(email_verification)
    db.session.commit()

    return verification_link  # Return the verification link for use in the email


@auth_v1_blueprint.route("/register", methods=["POST"])
def register():
    """Register a new user with email or phone number, with verification."""
    if current_user.is_authenticated:
        return (
            jsonify({"status": "error", "message": "User already authenticated."}),
            400,
        )

    # ✅ BLOCK_SIGNUPS kill-switch check
    block_signups = os.getenv("BLOCK_SIGNUPS", "false").lower() == "true"
    
    is_mobile = request.args.get("isMobile", "false").lower() == "true"
    data = request.get_json()

    required_fields = [
        "first_name",
        "last_name",
        "username",
        "emailOrPhoneNumber",  # Updated field name
        "password",
        "accepted_terms_and_conditions",
    ]
    missing_fields = [field for field in required_fields if not data.get(field)]

    if missing_fields:
        return (
            jsonify({"status": "error", "message": f"Missing fields: {', '.join(missing_fields)}"}),
            400,
        )

    first_name = data["first_name"].strip()
    last_name = data["last_name"].strip()
    username = data["username"].strip()
    identifier = data["emailOrPhoneNumber"].strip()  # Updated to match new field name
    password = data["password"]
    home_location = data.get("home_location", "").strip()
    accepted_terms = data.get("accepted_terms_and_conditions")

    if accepted_terms is not True:
        return (
            jsonify({"status": "error", "message": "You must accept the Terms and Conditions to register."}),
            400,
        )

    is_email_input = is_valid_email(identifier)
    is_phone_input = is_valid_phone_number(identifier)

    if not is_email_input and not is_phone_input:
        return jsonify({"status": "error", "message": "Invalid email or phone number format."}), 400

    # ✅ BLOCK_SIGNUPS: Check if user exists, if not return success without creating account
    existing_user = None
    if is_email_input:
        existing_user = User.query.filter(db.func.lower(User.email) == db.func.lower(identifier)).first()
    elif is_phone_input:
        existing_user = User.query.filter(User.phone_number == identifier).first()
    
    if block_signups:
        if not existing_user:
            # Kill-switch active: return success without creating account (no leak)
            current_app.logger.info(f"[BLOCK_SIGNUPS] Signup blocked for new identifier: {identifier}")
            return jsonify({"ok": True}), 200
        # Existing user can still proceed (e.g., if they're trying to re-verify)
        current_app.logger.info(f"[BLOCK_SIGNUPS] Allowing signup attempt for existing user: {identifier}")

    # Uniqueness checks (only if not blocked)
    if is_email_input and existing_user:
        return jsonify({"status": "error", "message": "Email address already registered."}), 409
    if is_phone_input and existing_user:
        return jsonify({"status": "error", "message": "Phone number already registered."}), 409
    if User.query.filter(db.func.lower(User.username) == db.func.lower(username)).first():
        return jsonify({"status": "error", "message": "Username already taken."}), 409

    is_valid, message = validate_password(password)
    if not is_valid:
        return jsonify({"status": "error", "message": message}), 400

    try:
        user = User(
            first_name=first_name,
            last_name=last_name,
            username=username,
            accepted_terms_and_conditions=True,
            location=home_location if home_location else None,
        )

        if is_email_input:
            user.email = identifier
        else:
            user.phone_number = identifier

        user.set_password(password)
        db.session.add(user)
        db.session.flush()

        if is_mobile:
            response = generate_and_send_otp(user.id)
            if response["status"] == "success":
                db.session.commit()

                # Determine whether user registered with a phone or email
                contact_type = "phone" if is_phone_input else "email"

                return (
                    jsonify({
                        "status": "success",
                        "message": f"OTP sent successfully. Please check your {contact_type}.",
                        "data": {
                            "user_id": user.id,
                            "username": user.username,
                            "contact": identifier,
                        },
                    }),
                    201,
                )
            else:
                db.session.rollback()
                # Log detailed error context
                current_app.logger.error(
                    f"OTP sending failed for user ID {user.id} ({identifier}). "
                    f"Reason: {response.get('message', 'Unknown')}"
                )
                return jsonify({
                    "status": "error",
                    "message": "Failed to send OTP. Please try again later."
                }), 500
        
        else:
            db.session.commit()
            verification_link = generate_and_store_verification_token(user)
            send_account_verification_email_template(user, verification_link)
            return jsonify({
                "status": "success",
                "message": "Registration successful.",
                "data": {
                    "user_id": user.id,
                    "username": user.username,
                    "emailOrPhoneNumber": identifier,
                },
            }), 201
    
    except SQLAlchemyError as e:
        db.session.rollback()
        current_app.logger.error(f"Database error: {e}", exc_info=True)
        return jsonify({"status": "error", "message": "An error occurred during registration."}), 500
    except Exception as e:
        db.session.delete(user)
        db.session.rollback()
        current_app.logger.error(f"Unexpected error: {e}", exc_info=True)
        return jsonify({"status": "error", "message": "Registration failed. Please try again."}), 500


from flask import jsonify

@auth_v1_blueprint.route("/terms-and-conditions", methods=["GET"])
def get_terms_and_conditions():
    """Return dummy terms and conditions text for the social media app."""
    terms_text = """
    Welcome to Seattle Pulse!

    By using our platform, you agree to the following terms:
    1. You must be at least 13 years old to use this app.
    2. You are responsible for any content you post.
    3. Hate speech, harassment, or illegal content is strictly prohibited.
    4. We may suspend or terminate accounts that violate these terms.
    5. We respect your privacy and do not share your data without consent.

    For the full legal version, visit our official website.

    Thank you for using SocialPulse!
    """

    return jsonify({
        "title": "Terms and Conditions",
        "content": terms_text.strip()
    }), 200


@auth_v1_blueprint.route("/verify-account", methods=["POST"])
def verify_account():
    """Verify user account via email token or OTP (if mobile)."""

    # Extract `isMobile` from query parameters (default to False if not provided)
    is_mobile = request.args.get("isMobile", "false").lower() == "true"

    # Extract JSON body
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return (
            jsonify({"status": "error", "message": "Invalid JSON payload provided."}),
            400,
        )

    if is_mobile:
        # Mobile OTP Verification
        return verify_otp_verification(data)
    else:
        # Email Token Verification
        return verify_email_verification(data)


def verify_email_verification(data):
    """Handles email verification using a token."""
    token = data.get("token")
    if not token:
        return (
            jsonify({"status": "error", "message": "Verification token is missing."}),
            400,
        )

    serializer = URLSafeTimedSerializer(current_app.config["SECRET_KEY"])

    try:
        # Decode token and check expiration (30 minutes max)
        decoded_data = serializer.loads(token, salt="email-verification", max_age=1800)

        # Retrieve user
        user = User.query.get(decoded_data["user_id"])
        if not user:
            return jsonify({"status": "error", "message": "User not found."}), 404

        # Ensure the token exists in the database
        email_verification = EmailVerification.query.filter_by(
            user_id=user.id, token=token
        ).first()
        if not email_verification:
            return (
                jsonify({"status": "error", "message": "Invalid or expired token."}),
                400,
            )

        # Mark user as verified
        user.is_email_verified = True
        db.session.delete(email_verification)  # Remove verification record

        try:
            db.session.commit()
        except SQLAlchemyError as e:
            db.session.rollback()
            current_app.logger.error(
                f"Database error during email verification: {e}", exc_info=True
            )
            return (
                jsonify(
                    {
                        "status": "error",
                        "message": "An error occurred during verification.",
                    }
                ),
                500,
            )

        # Send welcome email after successful verification
        try:
            send_welcome_email(user)
            current_app.logger.info(f"Welcome email sent successfully to {user.email}")
        except Exception as e:
            current_app.logger.error(
                f"Failed to send welcome email to {user.email}: {e}", exc_info=True
            )
            # Don't fail verification if email fails

        # Automatically log in the user after verification
        try:
            login_user(user)
            current_app.logger.info(f"User {user.id} ({user.email}) logged in after verification")
        except Exception as e:
            current_app.logger.error(
                f"Failed to log in user {user.id} after verification: {e}", exc_info=True
            )
            # Continue even if login fails, but log it

        # Prepare user data response
        user_data = {
            "user_id": user.id,
            "username": user.username,
            "email": user.email,
            "first_name": user.first_name or "",
            "last_name": user.last_name or "",
            "profile_picture_url": user.profile_picture_url or "",
            "login_type": user.login_type or "normal",
            "bio": user.bio or "",
            "home_location": user.location or "",
        }

        return (
            jsonify({
                "status": "success",
                "message": "Email verified successfully.",
                "data": user_data,
            }),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Token verification failed: {e}", exc_info=True)
        return jsonify({"status": "error", "message": "Invalid or expired token."}), 400


def verify_otp_verification(data):
    """Handles OTP verification for mobile users."""
    user_id = data.get("user_id")
    otp = data.get("otp")

    if not user_id or not otp:
        return (
            jsonify({"status": "error", "message": "User ID and OTP are required."}),
            400,
        )

    # Retrieve the user
    user = User.query.get(user_id)
    if not user:
        return jsonify({"status": "error", "message": "User not found."}), 404

    # Retrieve the OTP entry from the database
    otp_entry = OTP.query.filter_by(user_id=user_id, otp=otp).first()
    if not otp_entry:
        return jsonify({"status": "error", "message": "Invalid OTP."}), 400

    # Convert expiration time to timezone-aware UTC datetime
    if otp_entry.expiration.tzinfo is None:
        otp_entry.expiration = otp_entry.expiration.replace(tzinfo=timezone.utc)

    # Check if OTP is expired
    if datetime.now(timezone.utc) > otp_entry.expiration:
        return jsonify({"status": "error", "message": "OTP has expired."}), 400

    # Mark user as verified and delete OTP record
    user.is_email_verified = True
    db.session.delete(otp_entry)

    try:
        db.session.commit()
        
        # Send welcome email after successful verification
        try:
            send_welcome_email(user)
        except Exception as e:
            current_app.logger.error(
                f"Failed to send welcome email: {e}", exc_info=True
            )
        
        # Automatically log in the user after verification
        login_user(user)
        
        return (
            jsonify({
                "status": "success",
                "message": "Account verified successfully.",
                "data": {
                    "user_id": user.id,
                    "username": user.username,
                    "email": user.email,
                    "first_name": user.first_name,
                    "last_name": user.last_name,
                    "profile_picture_url": user.profile_picture_url,
                    "login_type": user.login_type,
                    "bio": user.bio,
                    "home_location": user.location,
                },
            }),
            200,
        )
    except SQLAlchemyError as e:
        db.session.rollback()
        current_app.logger.error(
            f"Database error during OTP verification: {e}", exc_info=True
        )
        return (
            jsonify(
                {"status": "error", "message": "An error occurred during verification."}
            ),
            500,
        )


@auth_v1_blueprint.route("/resend-email-verification", methods=["POST"])
def resend_email_verification():
    """Resend the email verification link to users who haven't verified their email."""
    data = request.get_json()

    if not data or not isinstance(data, dict):
        return (
            jsonify({"status": "error", "message": "Invalid JSON payload provided."}),
            400,
        )

    email = data.get("email")

    if not email:
        return jsonify({"status": "error", "message": "Email is required."}), 400

    # Check if the email exists in the database
    user = User.query.filter(db.func.lower(User.email) == db.func.lower(email)).first()

    if not user:
        # Security measure: Always return the same response to prevent enumeration attacks
        return (
            jsonify(
                {
                    "status": "success",
                    "message": "If your email exists, a verification email has been sent.",
                }
            ),
            200,
        )

    if user.is_email_verified:
        return (
            jsonify(
                {
                    "status": "success",
                    "message": "Your email is already verified. You can log in.",
                }
            ),
            200,
        )

    # Check if a verification token already exists
    email_verification = EmailVerification.query.filter_by(user_id=user.id).first()

    # Fix: Use the correct logic for rate limiting based on the last sent time, not expiration
    # We'll store a "last_sent" timestamp (if not present, fallback to expiration - 30min)
    now = datetime.utcnow()
    last_sent = None
    if email_verification:
        # If the expiration is in the future, assume last_sent = expiration - 30min (token valid for 30min)
        if email_verification.expiration and email_verification.expiration > now:
            last_sent = email_verification.expiration - timedelta(minutes=30)
        else:
            # If expired, treat as never sent
            last_sent = None

    # Only rate limit if last_sent is within 2 minutes
    if last_sent and (now - last_sent).total_seconds() < 120:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Please wait before requesting another verification email.",
                }
            ),
            429,
        )

    # Generate a new token
    serializer = URLSafeTimedSerializer(current_app.config["SECRET_KEY"])
    token = serializer.dumps({"user_id": user.id}, salt="email-verification")

    # Update the verification record if it exists, otherwise create a new one
    if email_verification:
        email_verification.token = token
        email_verification.expiration = now + timedelta(minutes=30)
    else:
        email_verification = EmailVerification(user_id=user.id, token=token)
        email_verification.expiration = now + timedelta(minutes=30)
        db.session.add(email_verification)

    db.session.commit()

    # Generate verification link
    verification_link = get_auth_verification_url(token)
    current_app.logger.info(f"[EMAIL] Resend verification email - Frontend URL: {verification_link}")

    # Send email
    send_account_verification_email_template(user, verification_link)

    return (
        jsonify(
            {"status": "success", "message": "A new verification email has been sent."}
        ),
        200,
    )

@auth_v1_blueprint.route("/login", methods=["POST"])
def login():
    """Log in a user."""

    # Check if the user is already authenticated
    if current_user.is_authenticated:
        return (
            jsonify({"status": "error", "message": "User already authenticated."}),
            400,
        )

    # Get JSON data from the request
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return (
            jsonify({"status": "error", "message": "Invalid JSON payload provided."}),
            400,
        )

    # Check for missing required fields
    required_fields = ["email", "password"]
    missing_fields = [field for field in required_fields if not data.get(field)]

    if missing_fields:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": f"Missing required fields: {', '.join(missing_fields)}",
                }
            ),
            400,
        )

    # Extract fields from the JSON payload
    email = data.get("email").strip()
    password = data.get("password").strip()

    try:
        # Check if the user exists in the database
        user = User.query.filter_by(email=email).first()

        if user is None:
            return (
                jsonify({"status": "error", "message": "Invalid email or password."}),
                401,
            )

        # If user is registered with Google, prevent password login
        if user.login_type == "google":
            return (
                jsonify(
                    {
                        "status": "error",
                        "message": "This email is registered via Google. Please use Google Login.",
                    }
                ),
                400,
            )

        # Check password for normal users
        if not user.check_password(password):
            return (
                jsonify({"status": "error", "message": "Invalid email or password."}),
                401,
            )

        # Check if the email is verified
        if not user.is_email_verified:
            return (
                jsonify(
                    {
                        "status": "error",
                        "message": "Email is not verified. Please verify your email.",
                    }
                ),
                403,
            )

        # Log in the user
        login_user(user)

        return (
            jsonify(
                {
                    "status": "success",
                    "message": "Login successful.",
                    "data": {
                        "user_id": user.id,
                        "username": user.username,
                        "email": user.email,
                        "first_name": user.first_name,
                        "last_name": user.last_name,
                        "profile_picture_url": user.profile_picture_url,
                        "login_type": user.login_type,
                        "bio": user.bio,
                        "home_location": user.location,
                    },
                }
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Error during login: {e}", exc_info=True)
        return (
            jsonify({"status": "error", "message": "An error occurred during login."}),
            500,
        )


@auth_v1_blueprint.route("/logout", methods=["POST"])
def logout():
    """Log out the current user."""
    # Check if the user is authenticated
    if not current_user.is_authenticated:
        return (
            jsonify({"status": "error", "message": "No user is currently logged in."}),
            400,
        )

    # Log out the user
    logout_user()
    return jsonify({"status": "success", "message": "Logout successful."}), 200


@auth_v1_blueprint.route("/reset_password_request", methods=["POST"])
def reset_password_request():
    """Request a password reset via email or OTP for mobile users."""

    data = request.get_json()
    if not data or not isinstance(data, dict):
        return (
            jsonify({"status": "error", "message": "Invalid JSON payload provided."}),
            400,
        )

    email = data.get("email")
    if not email:
        return jsonify({"status": "error", "message": "Email is required."}), 400

    user = User.query.filter_by(email=email).first()

    if not user:
        return (
            jsonify(
                {"status": "error", "message": "No user found with this email address."}
            ),
            404,
        )

    # Prevent Google users from resetting passwords via email/OTP
    if user.login_type == "google":
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "This account is registered via Google. Please change your password via Google.",
                }
            ),
            404,
        )

    is_mobile = request.args.get("isMobile", "false").lower() == "true"

    if is_mobile:
        # Generate OTP for mobile users
        otp = generate_otp()
        otp_expiration = datetime.utcnow() + timedelta(minutes=10)

        otp_entry = OTP.query.filter_by(user_id=user.id).first()
        if otp_entry:
            otp_entry.otp = otp
            otp_entry.expiration = otp_expiration
        else:
            otp_entry = OTP(user_id=user.id, otp=otp, expiration=otp_expiration)
            db.session.add(otp_entry)

        db.session.commit()
        send_otp_email(user.email, otp)

        return (
            jsonify(
                {"status": "success", "message": "OTP sent for mobile password reset."}
            ),
            200,
        )

    else:
        # Generate reset token for web users
        token = user.get_reset_token()
        reset_url = get_auth_reset_password_url(token)
        send_reset_email(user, reset_url)

        return (
            jsonify({"status": "success", "message": "Password reset email sent."}),
            200,
        )


@auth_v1_blueprint.route("/reset_password", methods=["POST"])
def reset_password():
    """Reset the user's password."""
    # Get the token from the query parameters
    token = request.args.get("token")
    if not token:
        return jsonify({"status": "error", "message": "Token is required."}), 400

    # Get JSON data from the request
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return (
            jsonify({"status": "error", "message": "Invalid JSON payload provided."}),
            400,
        )

    # Extract password and confirm password from the data
    password = data.get("password")
    confirm_password = data.get("confirm_password")

    if not password or not confirm_password:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Password and confirm password are required.",
                }
            ),
            400,
        )

    if password != confirm_password:
        return jsonify({"status": "error", "message": "Passwords do not match."}), 400

    # Verify the reset token
    user = User.verify_reset_token(token)
    if not user:
        return jsonify({"status": "error", "message": "Invalid or expired token."}), 400

    # Set the new password and commit changes to the database
    user.set_password(password)
    db.session.commit()

    # Return success response
    return jsonify({"status": "success", "message": "Password has been reset."}), 200


@auth_v1_blueprint.route("/verify_reset_token", methods=["GET"])
def verify_reset_token():
    """Verify the password reset token."""
    token = request.args.get("token")
    if not token:
        return jsonify({"status": "error", "message": "Token not provided."}), 400

    # Verify the reset token
    user = User.verify_reset_token(token)
    if not user:
        return jsonify({"status": "error", "message": "Invalid or expired token."}), 400

    # Return success response with user ID
    response = jsonify(
        {"status": "success", "message": "Token is valid.", "user_id": user.id}
    )
    return response, 200


# 2️⃣ **Verify OTP and Return JWT**
@auth_v1_blueprint.route("/verify_reset_password_otp", methods=["POST"])
def verify_reset_otp():
    """Verify the OTP for password reset and return a reset token."""
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return (
            jsonify({"status": "error", "message": "Invalid JSON payload provided."}),
            400,
        )

    otp = data.get("otp")
    email = data.get("email")

    if not otp or not email:
        return (
            jsonify({"status": "error", "message": "OTP and email are required."}),
            400,
        )

    # Find the user
    user = User.query.filter_by(email=email).first()
    if not user:
        return jsonify({"status": "error", "message": "User not found."}), 404

    # Find the OTP entry
    otp_entry = OTP.query.filter_by(user_id=user.id, otp=otp).first()
    if not otp_entry:
        return jsonify({"status": "error", "message": "Invalid OTP."}), 400

    # Check if OTP is expired
    if otp_entry.expiration < datetime.utcnow():
        return jsonify({"status": "error", "message": "OTP has expired."}), 400

    # Generate reset token
    token = user.get_reset_token()

    # Delete OTP from the database
    db.session.delete(otp_entry)
    db.session.commit()

    return (
        jsonify(
            {
                "status": "success",
                "message": "Reset Password OTP verified successfully.",
                "token": token,
            }
        ),
        200,
    )


@auth_v1_blueprint.route("/update_password_and_email", methods=["PATCH"])
def update_password_and_email():
    """Update user's password and/or email."""

    # Get JSON data from request
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return jsonify({"status": "error", "message": "Invalid JSON payload."}), 400

    # Ensure user_id is provided
    user_id = data.get("user_id")
    if not user_id:
        return jsonify({"status": "error", "message": "Missing user_id."}), 400

    # Fetch user from database
    user = User.query.get(user_id)
    if not user:
        return jsonify({"status": "error", "message": "Invalid user ID."}), 400

    # Prevent manual changes for users authenticated via Google
    if user.login_type == "google":
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "This account is registered via Google. You cannot change email or password manually.",
                }
            ),
            403,
        )

    # Track which fields were updated for reporting later
    updated_fields = []

    # ----------- Handle email update -----------
    new_email = data.get("email")
    if new_email is not None:
        # Ensure email is not empty
        if not new_email.strip():
            return (
                jsonify({"status": "error", "message": "Email cannot be empty."}),
                400,
            )
        # Validate email format
        if not is_valid_email(new_email):
            return jsonify({"status": "error", "message": "Invalid email format."}), 400

        # Update email in user object
        user.email = new_email
        updated_fields.append("email")

    # ----------- Handle password update -----------
    old_password = data.get("old_password")
    new_password = data.get("new_password")
    confirm_new_password = data.get("confirm_new_password")

    # If any password field is provided, all must be present
    if any([old_password, new_password, confirm_new_password]):
        if not all([old_password, new_password, confirm_new_password]):
            return (
                jsonify(
                    {
                        "status": "error",
                        "message": "All password fields must be provided.",
                    }
                ),
                400,
            )

        # Check if old password matches the one in the database
        if not user.check_password(old_password):
            return (
                jsonify({"status": "error", "message": "Incorrect old password."}),
                400,
            )

        # Ensure new password and confirmation match
        if new_password != confirm_new_password:
            return (
                jsonify({"status": "error", "message": "New passwords do not match."}),
                400,
            )

        # Validate password strength and rules
        is_valid, msg = validate_password(new_password)
        if not is_valid:
            return jsonify({"status": "error", "message": msg}), 400

        # Set new password on the user object
        user.set_password(new_password)
        updated_fields.append("password")

    # If no valid fields were updated, return an error
    if not updated_fields:
        return (
            jsonify({"status": "error", "message": "No fields to update provided."}),
            400,
        )

    # Commit changes to the database
    db.session.commit()

    # Respond with success and indicate what was updated
    return (
        jsonify(
            {
                "status": "success",
                "message": f"Successfully updated: {', '.join(updated_fields)}.",
            }
        ),
        200,
    )


@auth_v1_blueprint.route("/verify_otp", methods=["POST"])
def verify_otp():
    """Verify the OTP for email verification."""
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return (
            jsonify({"status": "error", "message": "Invalid JSON payload provided."}),
            400,
        )

    otp = data.get("otp")
    user_id = data.get("user_id")

    if not otp or not user_id:
        return jsonify({"status": "error", "message": "OTP or user ID missing."}), 400

    # Retrieve the OTP entry from the database
    otp_entry = OTP.query.filter_by(user_id=user_id, otp=otp).first()
    if not otp_entry:
        return jsonify({"status": "error", "message": "Invalid OTP."}), 400

    # Check if the OTP is expired
    if otp_entry.expiration < datetime.utcnow():
        return jsonify({"status": "error", "message": "OTP has expired."}), 400

    # Retrieve the user from the database
    user = User.query.get(user_id)
    if not user:
        return jsonify({"status": "error", "message": "User not found."}), 404

    # Verify the OTP
    if otp_entry.otp == otp:
        user.is_email_verified = True
        db.session.delete(
            otp_entry
        )  # Remove the OTP entry after successful verification
        db.session.commit()
        
        # Send welcome email after successful verification
        try:
            send_welcome_email(user)
        except Exception as e:
            current_app.logger.error(
                f"Failed to send welcome email: {e}", exc_info=True
            )
            # Don't fail verification if email fails
        
        # Automatically log in the user after verification
        login_user(user)
        
        return (
            jsonify({
                "status": "success",
                "message": "Email verified successfully.",
                "data": {
                    "user_id": user.id,
                    "username": user.username,
                    "email": user.email,
                    "first_name": user.first_name,
                    "last_name": user.last_name,
                    "profile_picture_url": user.profile_picture_url,
                    "login_type": user.login_type,
                    "bio": user.bio,
                    "home_location": user.location,
                },
            }),
            200,
        )
    else:
        return jsonify({"status": "error", "message": "Invalid OTP."}), 400


# Resend OTP endpoint
@auth_v1_blueprint.route("/resend_otp", methods=["POST"])
def resend_otp():
    """Resend OTP for email verification."""
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return (
            jsonify({"status": "error", "message": "Invalid JSON payload provided."}),
            400,
        )

    user_id = data.get("user_id")
    if not user_id:
        return jsonify({"status": "error", "message": "User ID is required."}), 400

    # Retrieve the OTP entry from the database
    otp_entry = OTP.query.filter_by(user_id=user_id).first()
    if not otp_entry:
        return jsonify({"status": "error", "message": "OTP entry not found."}), 404

    # Check if 90 seconds have passed since the last OTP was sent
    if datetime.utcnow() - otp_entry.last_sent < timedelta(seconds=90):
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "You can only resend OTP after 90 seconds.",
                }
            ),
            400,
        )

    # Generate a new OTP
    otp = generate_otp()
    otp_entry.otp = otp
    otp_entry.expiration = datetime.utcnow() + timedelta(minutes=10)
    otp_entry.last_sent = datetime.utcnow()

    try:
        db.session.commit()
        # Send the new OTP email
        user = User.query.get(user_id)
        send_otp_email(user.email, otp)
        return (
            jsonify({"status": "success", "message": "OTP resent successfully."}),
            200,
        )
    except SQLAlchemyError as e:
        db.session.rollback()
        current_app.logger.error(
            f"Database error during OTP resend: {e}", exc_info=True
        )
        return (
            jsonify(
                {"status": "error", "message": "An error occurred during OTP resend."}
            ),
            500,
        )
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error during OTP resend: {e}", exc_info=True)
        return (
            jsonify(
                {"status": "error", "message": "An error occurred during OTP resend."}
            ),
            500,
        )


@auth_v1_blueprint.route("/is_authenticated", methods=["GET"])
def is_authenticated():
    """Check if the current user is authenticated."""
    if current_user.is_authenticated:
        response = {
            "status": "success",
            "message": "User is authenticated.",
            "data": {
                "authenticated": True,
                "user_id": current_user.id,
                "username": current_user.username,
            },
        }
        return jsonify(response), 200
    else:
        response = {
            "status": "error",
            "message": "User is not authenticated.",
            "data": {"authenticated": False},
        }
        return jsonify(response), 200


