from flask import jsonify, request, current_app, Blueprint
from flask_login import current_user, login_required
from datetime import datetime
from app.models import (
    UserContent,
    db,
    Reaction,
    Comment,
    News,
    CommentReaction,
    ReactionType,
    Notification,
)
from app.socket_events import send_notification  # Import WebSocket function
import logging

reaction_v1_blueprint = Blueprint(
    "reaction_v1", __name__, url_prefix="/api/v1/reaction"
)

# Configure logger
logger = logging.getLogger("reaction_notifications")
logger.setLevel(logging.DEBUG)
handler = logging.StreamHandler()
formatter = logging.Formatter(
    "%(asctime)s - [COMMENT REACTION] - %(levelname)s - %(message)s"
)
handler.setFormatter(formatter)
logger.addHandler(handler)


@reaction_v1_blueprint.route("/<content_type>/<content_id>", methods=["POST"])
@login_required
def react_to_content(content_type, content_id):
    content = None

    if content_type == "news":
        content = News.query.filter_by(unique_id=content_id).first()
    elif content_type == "user_content":
        content = UserContent.query.filter_by(id=content_id).first()

    if not content:
        return jsonify(data=None, status="error", message="Content not found"), 404

    data = request.get_json()
    if not data or "reaction_type" not in data:
        return jsonify(data=None, status="error", message="Missing reaction type"), 400

    reaction_type_str = data["reaction_type"]
    reaction_type = ReactionType[reaction_type_str.upper()]

    reaction = Reaction.query.filter_by(
        user_id=current_user.id, content_id=content_id, content_type=content_type
    ).first()

    if reaction:

        if reaction.reaction_type == reaction_type:
            # If the reaction type is the same, remove the reaction (unreact)
            db.session.delete(reaction)
            message = "Reaction removed successfully"
        else:
            # If the reaction type is different, update the reaction type
            reaction.reaction_type = reaction_type
            message = "Reaction updated successfully"
    else:
        reaction = Reaction(
            user_id=current_user.id,
            content_id=content_id,
            content_type=content_type,
            reaction_type=reaction_type,
        )
        db.session.add(reaction)
        message = "Reaction added successfully"

    try:
        db.session.commit()
    except Exception as commit_error:
        current_app.logger.error(f"Database commit error: {commit_error}")
        db.session.rollback()
        return jsonify(data=None, status="error", message="Database commit error"), 500

    # ✅ **Send Notification to Content Owner**
    if content.user_id != current_user.id:  # Avoid notifying self-reactions
        notification = Notification(
            user_id=content.user_id,  # Content owner
            sender_id=current_user.id,  # User who reacted
            type="content_reaction",
            content=f"{current_user.username} reacted to your post.",
            post_id=content.id  # Add this line if post_id exists in the model
        )
        db.session.add(notification)
        db.session.commit()

        # Convert notification to dict format
        notification_data = notification.to_dict()

        # ✅ Emit WebSocket notification
        send_notification(content.user_id, notification_data)

    total_reactions = Reaction.query.filter_by(
        content_id=content_id, content_type=content_type
    ).count()

    return jsonify(
        data={"user_reaction": reaction_type.value, "total_reactions": total_reactions},
        status="success",
        message=message,
    )


@reaction_v1_blueprint.route("/comment/<content_id>/<comment_id>", methods=["POST"])
@login_required
def react_to_comment(content_id, comment_id):
    try:
        logger.info(
            f"Received reaction request for comment {comment_id} under content {content_id} from user {current_user.id}"
        )

        # Parse request data
        data = request.get_json()
        reaction_type_str = data.get("reaction_type")

        if not reaction_type_str:
            logger.warning("Validation failed: Missing required fields")
            return (
                jsonify(data=None, status="error", message="Missing required fields"),
                400,
            )

        # Retrieve the comment
        comment = Comment.query.get(comment_id)
        if not comment:
            logger.warning(f"Comment with ID {comment_id} not found")
            return (
                jsonify(data=None, status="error", message="Comment not found"),
                404,
            )

        # Verify content ID matches the comment
        if str(comment.content_id) != str(content_id):
            logger.warning(
                f"Comment {comment_id} does not belong to content {content_id}"
            )
            return (
                jsonify(
                    data=None, status="error", message="Comment does not match content"
                ),
                404,
            )

        # Check if the user already reacted to this comment
        reaction = CommentReaction.query.filter_by(
            user_id=current_user.id, content_id=comment_id, content_type="comment"
        ).first()

        reaction_type = ReactionType[reaction_type_str.upper()]

        if reaction:
            logger.info(
                f"Checking reaction types: current={reaction.reaction_type}, new={reaction_type}"
            )
            if reaction.reaction_type == reaction_type:
                # If the reaction type is the same, remove the reaction (unreact)
                db.session.delete(reaction)
                message = "Reaction removed successfully"
                logger.info(
                    f"Reaction removed for comment {comment_id} by user {current_user.id}"
                )
            else:
                # If the reaction type is different, update the reaction type
                reaction.reaction_type = reaction_type
                message = "Reaction updated successfully"
                logger.info(
                    f"Reaction updated for comment {comment_id} by user {current_user.id}"
                )
        else:
            # Create a new reaction
            reaction = CommentReaction(
                user_id=current_user.id,
                content_id=comment_id,
                content_type="comment",
                reaction_type=reaction_type,
            )
            db.session.add(reaction)
            message = "Reaction added successfully"
            logger.info(
                f"Reaction added for comment {comment_id} by user {current_user.id}"
            )

        # Commit reaction changes to the database
        try:
            db.session.commit()
            logger.info(
                f"Database commit successful for reaction on comment {comment_id}"
            )
        except Exception as commit_error:
            logger.error(f"Database commit error: {commit_error}")
            db.session.rollback()
            return (
                jsonify(data=None, status="error", message="Database commit error"),
                500,
            )

        # Count total reactions on the comment
        total_reactions = CommentReaction.query.filter_by(
            content_id=comment_id, content_type="comment"
        ).count()

        # ✅ **Send Notification to Comment Owner**
        if comment.user_id != current_user.id:  # Avoid notifying self-reactions
            logger.info(f"Preparing to send notification for comment {comment_id}")

            # Create notification entry in the database
            notification = Notification(
                user_id=comment.user_id,  # Comment owner
                sender_id=current_user.id,  # User who reacted
                type="comment_reaction",
                content=f"{current_user.username} reacted to your comment.",
            )
            db.session.add(notification)
            logger.info(
                f"Notification created for comment owner {comment.user_id} by user {current_user.id}"
            )

            try:
                db.session.commit()
                logger.info(
                    f"Notification committed to database for user {comment.user_id}"
                )
            except Exception as commit_error:
                logger.error(
                    f"Error committing notification to database: {commit_error}"
                )
                db.session.rollback()
                return (
                    jsonify(
                        data=None, status="error", message="Notification commit error"
                    ),
                    500,
                )

            # Convert notification to dictionary format
            notification_data = notification.to_dict()
            logger.info(f"Notification data prepared: {notification_data}")

            # ✅ Emit WebSocket notification
            send_notification(comment.user_id, notification_data)
            logger.info(f"WebSocket notification sent to notify_{comment.user_id}")

        return jsonify(
            data={
                "user_reaction": reaction_type.value,
                "total_reactions": total_reactions,
            },
            status="success",
            message=message,
        )

    except Exception as e:
        logger.error(f"Error processing reaction: {e}", exc_info=True)
        return jsonify(data=None, status="error", message="Server error"), 500
