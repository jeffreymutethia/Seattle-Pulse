from flask import request, jsonify, current_app, Blueprint
from flask_login import current_user, login_required, logout_user
from app.models import (
    User,
    UserContent,
    Comment,
    Reaction,
    News,
    db,
    OTP,
    Repost,
    UserDeletionLog,
)
from app.location_service import format_post_location
from io import BytesIO
import base64
from werkzeug.utils import secure_filename
from datetime import datetime
import time
import traceback
import uuid
from config import get_s3_profile_images_bucket_name, get_s3_profile_images_base_url

# Create the profile blueprint
profile_v1_blueprint = Blueprint("profile_v1", __name__, url_prefix="/api/v1/profile")


def serialize_user(user):
    """Serialize a User object to a dictionary."""
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "profile_picture_url": user.profile_picture_url,
        "bio": user.bio,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "show_home_location": user.show_home_location,
        "location": user.location if user.show_home_location else None,
    }


def serialize_user_content(content, thoughts=None):
    """Serialize a UserContent object to a dictionary."""
    serialized_content = {
        "id": content.id,
        "title": content.title,
        "body": content.body,
        "created_at": content.created_at.isoformat(),
        "location": content.location,
        "location_label": format_post_location(content),
        "is_in_seattle": content.is_in_seattle,
        "thumbnail": content.thumbnail,
        # Add other fields as needed
    }
    if thoughts is not None:
        serialized_content["thoughts"] = thoughts
    return serialized_content


def serialize_comment(comment):
    """Serialize a Comment object to a dictionary."""
    return {
        "id": comment.id,
        "content": comment.content,
        "created_at": comment.created_at.isoformat(),
        "content_id": comment.content_id,
        "content_type": comment.content_type,
        "user_id": comment.user_id,
        "location": comment.location,
        # Add other fields as needed
    }


def serialize_reaction(reaction):
    """Serialize a Reaction object to a dictionary."""
    return {
        "id": reaction.id,
        "content_id": reaction.content_id,
        "content_type": reaction.content_type,
        "reaction_type": reaction.reaction_type,
        "user_id": reaction.user_id,
        # Add other fields as needed
    }


@profile_v1_blueprint.route("/<username>", methods=["GET"])
@login_required
def get_user_profile(username):
    """Get the profile of a user by username."""
    try:
        user = User.query.filter_by(username=username).first_or_404()

        user_data = serialize_user(user)

        user_relationships = {
            "total_posts": UserContent.query.filter_by(user_id=user.id).count(),
            "followers": user.followers.count(),
            "following": user.followed.count(),
        }

        # Check if the current user is following the profile user
        is_following = (
            current_user.is_following(user) if current_user.id != user.id else False
        )

        response_data = {
            "user_data": user_data,
            "relationships": user_relationships,
            "is_following": is_following,
        }

        return (
            jsonify(
                success="success",
                message="User profile fetched successfully",
                data=response_data,
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Error fetching user profile: {str(e)}")
        current_app.logger.error(traceback.format_exc())
        return (
            jsonify(success="error", message="Failed to fetch user profile", data=None),
            500,
        )


@profile_v1_blueprint.route("/<username>/posts", methods=["GET"])
def get_user_posts(username):
    """Fetch the user's posts with comments, likes, and locations."""
    try:
        user = User.query.filter_by(username=username).first_or_404()

        page = request.args.get("page", 1, type=int)
        per_page = request.args.get("per_page", 10, type=int)

        paginated_posts = (
            UserContent.query.filter_by(user_id=user.id)
            .order_by(UserContent.created_at.desc())
            .paginate(page=page, per_page=per_page, error_out=False)
        )

        posts_list = [
            {
                "post": serialize_user_content(post),
                "total_comments": Comment.query.filter_by(
                    content_id=post.id, content_type="usercontent"
                ).count(),
                "total_likes": Reaction.query.filter_by(
                    content_id=post.id, content_type="usercontent"
                ).count(),
            }
            for post in paginated_posts.items
        ]

        response_data = {
            "posts": posts_list,
            "pagination": {
                "current_page": paginated_posts.page,
                "total_pages": paginated_posts.pages,
                "total_items": paginated_posts.total,
                "has_next": paginated_posts.has_next,
                "has_prev": paginated_posts.has_prev,
            },
        }

        return (
            jsonify(
                success="success",
                message="User posts fetched successfully",
                data=response_data,
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Error fetching user posts: {str(e)}")
        return (
            jsonify(success="error", message="Failed to fetch user posts", data=None),
            500,
        )


@profile_v1_blueprint.route("/<username>/reposts", methods=["GET"])
@login_required
def get_user_reposts(username):
    """Fetch posts that the user has reposted."""
    try:
        user = User.query.filter_by(username=username).first_or_404()

        page = request.args.get("page", 1, type=int)
        per_page = request.args.get("per_page", 10, type=int)

        paginated_reposts = (
            db.session.query(UserContent, Repost.thoughts)
            .join(Repost, Repost.content_id == UserContent.id)
            .filter(Repost.user_id == user.id)
            .order_by(Repost.reposted_at.desc())
            .paginate(page=page, per_page=per_page, error_out=False)
        )

        reposts_list = [
            serialize_user_content(repost[0], repost[1])
            for repost in paginated_reposts.items
        ]

        response_data = {
            "reposts": reposts_list,
            "pagination": {
                "current_page": paginated_reposts.page,
                "total_pages": paginated_reposts.pages,
                "total_items": paginated_reposts.total,
                "has_next": paginated_reposts.has_next,
                "has_prev": paginated_reposts.has_prev,
            },
        }

        if not reposts_list:
            message = "No reposts found."
        else:
            message = "User reposts fetched successfully"

        return (
            jsonify(
                success="success",
                message=message,
                data=response_data,
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Error fetching user reposts: {str(e)}")
        return (
            jsonify(success="error", message="Failed to fetch user reposts", data=None),
            500,
        )


@profile_v1_blueprint.route("/edit_profile", methods=["PATCH"])
@login_required
def edit_profile_api():
    """Edit user profile, including profile picture upload."""
    if not current_user.is_authenticated:
        return jsonify({"status": "error", "message": "User not authenticated."}), 401

    # Convert ImmutableMultiDict (request.form) to a mutable dictionary
    if request.content_type == "application/json":
        data = request.json  # If request is JSON, use it directly
    else:
        data = (
            request.form.to_dict()
        )  # Convert ImmutableMultiDict to a normal dictionary

    protected_fields = ["first_name", "last_name", "username", "email", "location"]

    # Prevent empty values for required fields
    for field in protected_fields:
        if field in data and not data[field].strip():
            return (
                jsonify({"status": "error", "message": f"{field} cannot be empty."}),
                400,
            )

    # Trim username and email (avoid whitespace issues)
    if "username" in data:
        data["username"] = data["username"].strip()
    if "email" in data:
        data["email"] = data["email"].strip()

    # Ensure unique username (if changed)
    if "username" in data and data["username"] != current_user.username:
        existing_user = User.query.filter_by(username=data["username"]).first()
        if existing_user and existing_user.id != current_user.id:
            return (
                jsonify({"status": "error", "message": "Username already in use."}),
                409,
            )

    # Ensure unique email (if changed)
    if "email" in data and data["email"] != current_user.email:
        existing_email = User.query.filter_by(email=data["email"]).first()
        if existing_email and existing_email.id != current_user.id:
            return jsonify({"status": "error", "message": "Email already in use."}), 409

    # Handle bio update
    if "bio" in data:
        current_user.bio = data["bio"]

    # Handle profile picture upload from FormData
    if "profile_picture" in request.files:
        file = request.files["profile_picture"]
        if file:
            try:
                filename = secure_filename(
                    f"{current_user.id}_{uuid.uuid4().hex}.{file.filename.split('.')[-1]}"
                )

                # Determine correct bucket and base URL by environment
                bucket_name = get_s3_profile_images_bucket_name()
                bucket_base_url = get_s3_profile_images_base_url()

                # Upload the image
                s3_client = current_app.s3_client
                s3_client.upload_fileobj(file, bucket_name, filename)

                # Save the file URL
                current_user.profile_picture_url = f"{bucket_base_url}/{filename}"

                current_app.logger.info(
                    f"Profile picture uploaded: {current_user.profile_picture_url}"
                )

            except Exception as e:
                current_app.logger.error(f"Error uploading profile picture: {e}", exc_info=True)
                return jsonify({"status": "error", "message": "Failed to upload image."}), 400

    # Update user details
    for field in protected_fields:
        if field in data:
            setattr(current_user, field, data[field])

    # Commit changes to database
    try:
        db.session.commit()

        # Construct the updated user response
        user_data = {
            "id": current_user.id,
            "first_name": current_user.first_name,
            "last_name": current_user.last_name,
            "username": current_user.username,
            "email": current_user.email,
            "bio": current_user.bio,
            "location": current_user.location,
            "profile_picture_url": current_user.profile_picture_url,
        }

        return (
            jsonify(
                {
                    "status": "success",
                    "message": "Profile updated successfully!",
                    "user": user_data,
                }
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Error updating profile: {e}", exc_info=True)
        db.session.rollback()
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "An error occurred while updating your profile.",
                }
            ),
            500,
        )


@profile_v1_blueprint.route("/delete_user", methods=["DELETE"])
@login_required
def delete_user():
    """Delete a user by username or email."""
    try:
        data = request.get_json()

        if not data or not isinstance(data, dict):
            return (
                jsonify(
                    {"status": "error", "message": "Invalid JSON payload provided."}
                ),
                400,
            )

        username = data.get("username")
        email = data.get("email")
        reason = data.get("reason")
        comments = data.get("comments")

        if not username and not email:
            return (
                jsonify(
                    {"status": "error", "message": "Username or email is required."}
                ),
                400,
            )
        if not reason:
            return (
                jsonify(
                    {"status": "error", "message": "Reason for deletion is required."}
                ),
                400,
            )

        user = (
            User.query.filter_by(username=username).first()
            if username
            else User.query.filter_by(email=email).first()
        )

        if not user:
            return jsonify({"status": "error", "message": "User not found."}), 404

        # Ensure the user can only delete their own account
        if user.id != current_user.id:
            return jsonify({"status": "error", "message": "Unauthorized action."}), 403

        try:
            deletion_log = UserDeletionLog(
                user_id=user.id, reason=reason, comments=comments
            )
            db.session.add(deletion_log)
            db.session.commit()
        except Exception as log_error:
            db.session.rollback()
            current_app.logger.error(f"Error logging deletion reason: {log_error}")
            return (
                jsonify({"status": "error", "message": "Failed to log user deletion."}),
                500,
            )

        log_exists = UserDeletionLog.query.filter_by(user_id=user.id).first()
        if not log_exists:
            current_app.logger.error(
                f"Deletion log verification failed for user ID: {user.id}"
            )
            return (
                jsonify(
                    {"status": "error", "message": "Failed to verify deletion log."}
                ),
                500,
            )

        try:
            OTP.query.filter_by(user_id=user.id).delete()
            db.session.commit()
        except Exception as otp_error:
            db.session.rollback()
            current_app.logger.error(f"Error deleting OTP entries: {otp_error}")
            return (
                jsonify(
                    {"status": "error", "message": "Failed to delete related OTPs."}
                ),
                500,
            )

        try:
            db.session.delete(user)
            db.session.commit()

            # Verify if deletion log still exists
            log_check = UserDeletionLog.query.filter_by(user_id=user.id).first()
            if not log_check:
                current_app.logger.error(
                    f"Deletion log for user ID {user.id} was removed after user deletion."
                )

            # Log the user out after successful deletion
            logout_user()

        except Exception as delete_error:
            db.session.rollback()
            current_app.logger.error(f"Error deleting user: {delete_error}")
            return (
                jsonify({"status": "error", "message": "Failed to delete user."}),
                500,
            )

        return (
            jsonify(
                {
                    "status": "success",
                    "message": "User deleted successfully. You have been logged out.",
                }
            ),
            200,
        )

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error during user deletion: {e}", exc_info=True)
        return (
            jsonify({"status": "error", "message": "An unexpected error occurred."}),
            500,
        )


@profile_v1_blueprint.route("/repost/<int:content_id>", methods=["DELETE"])
@login_required
def undo_repost(content_id):
    """Undo a reposted content by the user."""
    try:
        repost = Repost.query.filter_by(
            user_id=current_user.id, content_id=content_id
        ).first()
        if not repost:
            return jsonify(success="error", message="Repost not found", data=None), 404

        db.session.delete(repost)
        db.session.commit()
        return (
            jsonify(
                success="success", message="Repost removed successfully", data=None
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Error undoing repost: {str(e)}")
        db.session.rollback()
        return (
            jsonify(success="error", message="Failed to remove repost", data=None),
            500,
        )


@profile_v1_blueprint.route("/<username>/location", methods=["GET"])
def get_user_location(username):
    """Fetch the user's post locations."""
    try:
        user = User.query.filter_by(username=username).first_or_404()

        page = request.args.get("page", 1, type=int)
        per_page = request.args.get("per_page", 10, type=int)

        paginated_locations = UserContent.query.filter(
            UserContent.user_id == user.id, UserContent.location.isnot(None)
        ).paginate(page=page, per_page=per_page, error_out=False)

        locations_list = [
            {
                "post_id": post.id,
                "location": post.location,
                "location_label": format_post_location(post),
                "is_in_seattle": post.is_in_seattle,
                "title": post.title,
            }
            for post in paginated_locations.items
        ]

        response_data = {
            "locations": locations_list,
            "pagination": {
                "current_page": paginated_locations.page,
                "total_pages": paginated_locations.pages,
                "total_items": paginated_locations.total,
                "has_next": paginated_locations.has_next,
                "has_prev": paginated_locations.has_prev,
            },
        }

        return (
            jsonify(
                success="success",
                message="User locations fetched successfully",
                data=response_data,
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Error fetching user locations: {str(e)}")
        return (
            jsonify(
                success="error", message="Failed to fetch user locations", data=None
            ),
            500,
        )


@profile_v1_blueprint.route("/toggle-home-location", methods=["PATCH"])
@login_required
def toggle_home_location():
    """
    Toggle the visibility of the user's home location based on frontend input.
    Only accepts a boolean value for 'show_home_location'.
    """
    try:
        data = request.get_json()

        # Ensure the key is present
        if "show_home_location" not in data:
            return (
                jsonify(
                    success="error",
                    message="Missing 'show_home_location' in request body",
                    data=None,
                ),
                400,
            )

        # Ensure the value is strictly a boolean
        if not isinstance(data["show_home_location"], bool):
            return (
                jsonify(
                    success="error",
                    message="'show_home_location' must be a boolean (true or false)",
                    data=None,
                ),
                400,
            )

        # Update user setting
        current_user.show_home_location = data["show_home_location"]
        db.session.commit()

        return (
            jsonify(
                success="success",
                message="Home location visibility updated",
                data={"show_home_location": current_user.show_home_location},
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Toggle home location failed: {str(e)}")
        current_app.logger.error(traceback.format_exc())
        return (
            jsonify(
                success="error",
                message="Unable to update home location visibility",
                data=None,
            ),
            500,
        )
