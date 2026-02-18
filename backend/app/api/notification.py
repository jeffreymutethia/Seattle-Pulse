import logging
from flask import Blueprint, jsonify, request
from sqlalchemy.exc import SQLAlchemyError
from flask_login import login_required, current_user
from app.models import Notification, db

# Configure Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create Blueprint
notification_v1_blueprint = Blueprint(
    "notification_v1", __name__, url_prefix="/api/v1/notifications"
)


# ✅ Fetch all notifications for a user
@notification_v1_blueprint.route("/<int:user_id>", methods=["GET"])
@login_required
def get_all_notifications(user_id):
    """Fetch all notifications for a specific user."""
    if current_user.id != user_id:
        return jsonify({"status": "error", "message": "Unauthorized access"}), 403

    try:
        notifications = Notification.query.filter_by(user_id=user_id).all()
        return (
            jsonify(
                {
                    "status": "success",
                    "message": "Notifications retrieved successfully.",
                    "data": [n.to_dict() for n in notifications],
                }
            ),
            200,
        )
    except SQLAlchemyError as db_error:
        logger.error(
            f"Database error fetching notifications for user {user_id}: {str(db_error)}"
        )
        return jsonify({"status": "error", "message": "Database error occurred"}), 500


# ✅ Fetch only unread notifications
@notification_v1_blueprint.route("/unread/<int:user_id>", methods=["GET"])
@login_required
def get_unread_notifications(user_id):
    """Fetch only unread notifications for a specific user."""
    if current_user.id != user_id:
        return jsonify({"status": "error", "message": "Unauthorized access"}), 403

    try:
        notifications = Notification.query.filter_by(
            user_id=user_id, is_read=False
        ).all()
        return (
            jsonify(
                {
                    "status": "success",
                    "message": "Unread notifications retrieved successfully.",
                    "data": [n.to_dict() for n in notifications],
                }
            ),
            200,
        )
    except SQLAlchemyError as db_error:
        logger.error(
            f"Database error fetching unread notifications for user {user_id}: {str(db_error)}"
        )
        return jsonify({"status": "error", "message": "Database error occurred"}), 500


# ✅ Fetch a single notification
@notification_v1_blueprint.route(
    "/<int:user_id>/<int:notification_id>", methods=["GET"]
)
@login_required
def get_single_notification(user_id, notification_id):
    """Fetch a single notification."""
    if current_user.id != user_id:
        return jsonify({"status": "error", "message": "Unauthorized access"}), 403

    try:
        notification = Notification.query.filter_by(
            user_id=user_id, id=notification_id
        ).first()
        if not notification:
            return (
                jsonify({"status": "error", "message": "Notification not found"}),
                404,
            )
        return (
            jsonify(
                {
                    "status": "success",
                    "message": "Notification retrieved successfully.",
                    "data": notification.to_dict(),
                }
            ),
            200,
        )
    except SQLAlchemyError as db_error:
        logger.error(
            f"Database error fetching notification {notification_id}: {str(db_error)}"
        )
        return jsonify({"status": "error", "message": "Database error occurred"}), 500


# ✅ Mark a single notification as read
@notification_v1_blueprint.route("/read/<int:notification_id>", methods=["PUT"])
@login_required
def mark_notification_as_read(notification_id):
    """Mark a single notification as read."""
    try:
        notification = Notification.query.get(notification_id)
        if notification:
            notification.is_read = True
            db.session.commit()
            return (
                jsonify(
                    {
                        "status": "success",
                        "message": "Notification marked as read.",
                    }
                ),
                200,
            )
        return jsonify({"status": "error", "message": "Notification not found"}), 404
    except SQLAlchemyError as db_error:
        logger.error(
            f"Database error marking notification {notification_id} as read: {str(db_error)}"
        )
        return jsonify({"status": "error", "message": "Database error occurred"}), 500


# ✅ Mark all unread notifications for a user as read
@notification_v1_blueprint.route("/read/all/<int:user_id>", methods=["PUT"])
@login_required
def mark_all_notifications_as_read(user_id):
    """Mark all unread notifications for a user as read."""
    if current_user.id != user_id:
        return jsonify({"status": "error", "message": "Unauthorized access"}), 403

    try:
        notifications = Notification.query.filter_by(
            user_id=user_id, is_read=False
        ).all()
        if not notifications:
            return (
                jsonify(
                    {
                        "status": "success",
                        "message": "No unread notifications found.",
                    }
                ),
                200,
            )

        for notification in notifications:
            notification.is_read = True
        db.session.commit()
        return (
            jsonify(
                {
                    "status": "success",
                    "message": "All unread notifications marked as read.",
                }
            ),
            200,
        )
    except SQLAlchemyError as db_error:
        logger.error(
            f"Database error marking all notifications as read for user {user_id}: {str(db_error)}"
        )
        return jsonify({"status": "error", "message": "Database error occurred"}), 500


# ✅ Delete a specific notification
@notification_v1_blueprint.route("/delete/<int:notification_id>", methods=["DELETE"])
@login_required
def delete_notification(notification_id):
    """Delete a specific notification."""
    try:
        notification = Notification.query.get(notification_id)
        if notification:
            db.session.delete(notification)
            db.session.commit()
            return (
                jsonify(
                    {
                        "status": "success",
                        "message": "Notification deleted successfully.",
                    }
                ),
                200,
            )
        return jsonify({"status": "error", "message": "Notification not found"}), 404
    except SQLAlchemyError as db_error:
        logger.error(
            f"Database error deleting notification {notification_id}: {str(db_error)}"
        )
        return jsonify({"status": "error", "message": "Database error occurred"}), 500


# ✅ Delete all notifications for a user
@notification_v1_blueprint.route("/delete/all/<int:user_id>", methods=["DELETE"])
@login_required
def delete_all_notifications(user_id):
    """Delete all notifications for a user."""
    if current_user.id != user_id:
        return jsonify({"status": "error", "message": "Unauthorized access"}), 403

    try:
        notifications = Notification.query.filter_by(user_id=user_id).all()
        if not notifications:
            return (
                jsonify(
                    {
                        "status": "success",
                        "message": "No notifications found.",
                    }
                ),
                200,
            )

        for notification in notifications:
            db.session.delete(notification)
        db.session.commit()
        return (
            jsonify(
                {
                    "status": "success",
                    "message": "All notifications deleted successfully.",
                }
            ),
            200,
        )
    except SQLAlchemyError as db_error:
        logger.error(
            f"Database error deleting all notifications for user {user_id}: {str(db_error)}"
        )
        return jsonify({"status": "error", "message": "Database error occurred"}), 500
