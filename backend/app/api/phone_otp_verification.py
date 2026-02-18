from flask import Blueprint, request, jsonify, current_app

phone_otp_verification_blueprint = Blueprint("otp", __name__, url_prefix="/api/v1/phone-otp")


@phone_otp_verification_blueprint.route('/send', methods=['POST'])
def send_otp():
    data = request.get_json()
    phone_number = data.get("phone_number")

    if not phone_number:
        current_app.logger.warning("Missing phone_number in request body.")
        return jsonify({"success": False, "message": "Phone number is required"}), 400

    try:
        verification = current_app.twilio_client.verify.v2.services(
            current_app.twilio_verify_sid
        ).verifications.create(to=phone_number, channel="sms")

        return jsonify({"success": True, "status": verification.status})
    except Exception as e:
        current_app.logger.error(f"Error sending OTP: {str(e)}")
        return jsonify({"success": False, "message": str(e)}), 500


@phone_otp_verification_blueprint.route('/verify', methods=['POST'])
def verify_otp():
    data = request.get_json()
    phone_number = data.get("phone_number")
    code = data.get("code")

    if not phone_number or not code:
        current_app.logger.warning("Missing phone_number or code in request body.")
        return jsonify({"success": False, "message": "Phone number and code are required"}), 400

    try:
        verification_check = current_app.twilio_client.verify.v2.services(
            current_app.twilio_verify_sid
        ).verification_checks.create(to=phone_number, code=code)

        if verification_check.status == "approved":
            return jsonify({"success": True, "message": "OTP verified"})
        else:
            return jsonify({"success": False, "message": "Invalid OTP"}), 400
    except Exception as e:
        current_app.logger.error(f"Error verifying OTP: {str(e)}")
        return jsonify({"success": False, "message": str(e)}), 500
