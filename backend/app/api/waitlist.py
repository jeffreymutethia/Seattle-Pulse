from flask import Blueprint, request, jsonify, current_app, render_template
from app.extensions import db
from app.models import WaitlistSignup, User
from app.utils import (
    is_valid_rfc_email,
    is_valid_e164_phone,
    get_geo_from_ip,
    send_email,
    send_waitlist_confirmation_email
)
import json
from datetime import datetime, timezone
import os

waitlist_v1_blueprint = Blueprint("waitlist_v1", __name__, url_prefix="/api/v1")

@waitlist_v1_blueprint.route("/waitlist", methods=["POST"])
def waitlist_signup():
    try:
        # ✅ Check content type
        if not request.is_json:
            current_app.logger.info("[waitlist] Request missing JSON content type")
            return jsonify(
                success="error",
                message="Content type must be application/json",
                data=None
            ), 409

        # ✅ Validate JSON body
        try:
            data = request.get_json()
        except Exception as e:
            current_app.logger.warning(f"[waitlist] Invalid JSON in request body: {e}")
            return jsonify(
                success="error",
                message="Malformed JSON body",
                data=None
            ), 400

        if not isinstance(data, dict):
            current_app.logger.info("[waitlist] JSON body is not an object")
            return jsonify(
                success="error",
                message="Request body must be a JSON object",
                data=None
            ), 400

        # Extract fields
        email = data.get("email")
        phone = data.get("phone")
        neighborhood = data.get("neighborhood")
        utm_source = data.get("utm_source")
        first_name = data.get("first_name", "there")  # fallback

        current_app.logger.info(f"[waitlist] Received signup for email={email}, phone={phone}, "
                                f"neighborhood={neighborhood}, utm_source={utm_source}")

        # Validate email
        if not email or not is_valid_rfc_email(email):
            current_app.logger.info(f"[waitlist] Invalid email format: {email}")
            return jsonify(
                success="error",
                message="Invalid email format",
                data=None
            ), 400

        # Validate phone (if present)
        if phone and not is_valid_e164_phone(phone):
            current_app.logger.info(f"[waitlist] Invalid phone format: {phone}")
            return jsonify(
                success="error",
                message="Invalid phone format",
                data=None
            ), 400

        # Check for duplicate email
        existing = WaitlistSignup.query.filter_by(email=email).first()
        if existing:
            current_app.logger.info(f"[waitlist] Duplicate signup attempt for email: {email}")
            return jsonify(
                success="success",
                message="Already joined",
                data={"status": "already_joined"}
            ), 409

        # Create new waitlist record
        new_entry = WaitlistSignup(
            email=email,
            phone=phone,
            neighborhood=neighborhood,
            utm_source=utm_source,
        )
        db.session.add(new_entry)
        db.session.commit()
        current_app.logger.info(f"[waitlist] Created new WaitlistSignup record for {email} (ID={new_entry.id})")

        user_ip = request.remote_addr
        city, country = get_geo_from_ip(user_ip)
        current_app.logger.info(f"[waitlist] user_ip for Mixpanel: {user_ip}, city: {city}, country: {country}")

        # ✅ Fire Mixpanel event
        current_app.logger.info(f"[waitlist] Sending Mixpanel event with ip={user_ip}, city={city}, country={country}")
        current_app.mixpanel.track(
            distinct_id=email,
            event_name="waitlist_joined",
            properties={
                "utm_source": utm_source or "unknown",
                "neighborhood": neighborhood or "unspecified",
                "city": city or "unknown",
                "country": country or "unknown",
                "ip": user_ip 
            },
        )

        # ─── Email handling block ───
        signup_timestamp = datetime.now(timezone.utc)
        payload = {
            "email": email,
            "signup_timestamp": signup_timestamp.isoformat(), 
            "first_name": first_name
        }

        use_gmail = current_app.config.get("USE_GMAIL_FOR_WAITLIST_EMAILS", False)
        current_app.logger.info(f"[waitlist] USE_GMAIL_FOR_WAITLIST_EMAILS = {use_gmail}")

        if use_gmail:
            try:
                # look up or fake a User object
                user = User.query.filter_by(email=email).first()
                if not user:
                    class _U: pass
                    user = _U()
                    user.email = email
                    user.first_name = first_name

                current_app.logger.info(f"[waitlist] Sending confirmation email via Gmail to {email}")
                send_waitlist_confirmation_email(user, signup_timestamp)
                current_app.logger.info("[waitlist] Gmail email sent successfully")
            except Exception as gmail_err:
                current_app.logger.error(f"[waitlist][GMAIL] Email send failed: {gmail_err}", exc_info=True)       
            except Exception as gmail_err:
                current_app.logger.error(f"[waitlist][GMAIL] Email send failed: {gmail_err}", exc_info=True)
        else:
            sns_arn = current_app.config.get("WAITLIST_SNS_ARN")
            current_app.logger.info(f"[waitlist] WAITLIST_SNS_ARN = {sns_arn}")

            if not sns_arn:
                current_app.logger.error("[waitlist] No SNS ARN configured (WAITLIST_SNS_ARN is empty)")
            else:
                try:
                    current_app.logger.info(f"[waitlist] Publishing to SNS: payload={payload}")
                    response = current_app.sns_client.publish(
                        TopicArn=sns_arn,
                        Message=json.dumps(payload),
                        Subject="NewWaitlistSignup"
                    )
                    message_id = response.get('MessageId')
                    current_app.logger.info(f"[waitlist] SNS publish succeeded (MessageId={message_id})")
                except Exception as sns_err:
                    current_app.logger.error(f"[waitlist][SNS] publish failed: {sns_err}", exc_info=True)

        return jsonify(
            success="success",
            message="Waitlist signup successful",
            data={"status": "joined"}
        ), 201

    except Exception as e:
        error_message = str(e)
        current_app.logger.error(f"[waitlist] Error in waitlist signup: {error_message}", exc_info=True)
        return jsonify(
            success="error",
            message=f"Internal server error: {error_message}",
            data=None
        ), 500


@waitlist_v1_blueprint.route("/delete-user", methods=["DELETE"])
def delete_user():
    try:
        # ✅ Check content type
        if not request.is_json:
            return jsonify(
                success="error",
                message="Content type must be application/json",
                data=None
            ), 400

        # ✅ Validate JSON body
        try:
            data = request.get_json()
        except Exception as e:
            current_app.logger.warning(f"Invalid JSON in request body: {str(e)}")
            return jsonify(
                success="error",
                message="Malformed JSON body",
                data=None
            ), 400

        email = data.get("email")

        # Validate email
        if not email or not is_valid_rfc_email(email):
            return jsonify(
                success="error",
                message="Invalid email format",
                data=None
            ), 400

        # Delete from WaitlistSignup
        waitlist_entry = WaitlistSignup.query.filter_by(email=email).first()
        if waitlist_entry:
            db.session.delete(waitlist_entry)
            current_app.logger.info(f"Deleted user from WaitlistSignup: {email}")

        # Delete from User model
        user_entry = User.query.filter_by(email=email).first()
        if user_entry:
            db.session.delete(user_entry)
            current_app.logger.info(f"Deleted user from User model: {email}")

        # Commit the changes
        db.session.commit()

        return jsonify(
            success="success",
            message=f"User with email {email} deleted successfully from Waitlist and User models.",
            data=None
        ), 200

    except Exception as e:
        current_app.logger.error(f"Error deleting user: {str(e)}", exc_info=True)
        return jsonify(
            success="error",
            message="Internal server error",
            data=None
        ), 500