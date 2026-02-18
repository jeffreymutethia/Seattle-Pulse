from flask import Blueprint, jsonify, request
from flask_login import current_user, login_required
from app.models import User, db, Follow, Notification
from app.socket_events import send_notification

# Create the user relationships blueprint
user_relationships_v1_blueprint = Blueprint(
    "user_relationships_v1", __name__, url_prefix="/api/v1"
)


@user_relationships_v1_blueprint.route("/follow/<int:user_id>", methods=["POST"])
@login_required
def follow_user(user_id):
    """Handle POST requests to follow a user and send a real-time notification."""
    user = User.query.get(user_id)
    if not user:
        return jsonify(status="error", message="User not found"), 404

    if user.id == current_user.id:
        return jsonify(status="error", message="You cannot follow yourself"), 400

    if current_user.is_following(user):
        return (
            jsonify(status="error", message="You are already following this user"),
            400,
        )

    # Follow the user
    current_user.follow(user)
    db.session.commit()

    # Create a notification for the followed user
    notification = Notification(
        user_id=user.id,
        sender_id=current_user.id,
        type="follow",
        content=f"{current_user.username} started following you.",
    )
    db.session.add(notification)
    db.session.commit()

    # Convert notification to dict format
    notification_data = notification.to_dict()

    # ✅ Emit real-time notification via WebSocket
    send_notification(user.id, notification_data)

    return jsonify(
        status="success",
        message="User followed successfully",
    )


@user_relationships_v1_blueprint.route("/unfollow/<int:user_id>", methods=["POST"])
@login_required
def unfollow_user(user_id):
    """Handle POST requests to unfollow a user."""
    # Fetch the user to unfollow by user_id
    user = User.query.get(user_id)
    if not user:
        # Return an error response if the user is not found
        return jsonify(status="error", message="User not found"), 404

    # Check if the current user is following the target user
    if not current_user.is_following(user):
        return jsonify(status="error", message="You are not following this user"), 400

    # Unfollow the user
    current_user.unfollow(user)
    db.session.commit()
    # Return a success response
    return jsonify(status="success", message="User unfollowed successfully")


@user_relationships_v1_blueprint.route("/get_following", methods=["GET"])
@login_required
def get_following():
    """
    Get the total number of users the current user is following and their details.
    Optionally filter by search term (?query=searchterm).
    """
    search_query = request.args.get("query", "").strip()

    # Build the base query
    query = (
        User.query.join(Follow, Follow.followed_id == User.id)
        .filter(Follow.follower_id == current_user.id)
    )

    # If a search query is present, apply filtering
    if search_query:
        search_pattern = f"%{search_query.lower()}%"
        query = query.filter(
            db.or_(
                db.func.lower(User.username).like(search_pattern),
                db.func.lower(User.first_name).like(search_pattern),
                db.func.lower(User.last_name).like(search_pattern),
            )
        )

    following = query.all()

    following_details = [
        {
            "id": user.id,
            "username": user.username,
            "profile_picture_url": user.profile_picture_url,
            "bio": getattr(user, "bio", ""),
        }
        for user in following
    ]

    return jsonify(
        status="success",
        total=len(following_details),
        users=following_details
    )



@user_relationships_v1_blueprint.route("/get_followers", methods=["GET"])
@login_required
def get_followers():
    """Get the total number of users who follow the current user and their details."""
    followers = current_user.followers.all()
    followers_details = [
        {
            "id": user.id,
            "username": user.username,
            "profile_picture_url": user.profile_picture_url,
            "bio": user.bio,
        }
        for user in followers
    ]
    return jsonify(
        status="success", total=len(followers_details), users=followers_details
    )


@user_relationships_v1_blueprint.route("/block/<int:user_id>", methods=["POST"])
@login_required
def block_user(user_id):
    """Handle POST requests to block a user."""
    user = User.query.get(user_id)
    if not user:
        return jsonify(status="error", message="User not found"), 404

    if user.id == current_user.id:
        return jsonify(status="error", message="You cannot block yourself"), 400

    if current_user.is_blocking(user):
        return (
            jsonify(status="error", message="You have already blocked this user"),
            400,
        )

    current_user.block(user)
    db.session.commit()
    return jsonify(status="success", message="User blocked successfully")


@user_relationships_v1_blueprint.route("/unblock/<int:user_id>", methods=["POST"])
@login_required
def unblock_user(user_id):
    """Handle POST requests to unblock a user."""
    user = User.query.get(user_id)
    if not user:
        return jsonify(status="error", message="User not found"), 404

    if not current_user.is_blocking(user):
        return jsonify(status="error", message="You have not blocked this user"), 400

    current_user.unblock(user)
    db.session.commit()
    return jsonify(status="success", message="User unblocked successfully")
