import logging
from flask import request, jsonify, Blueprint, current_app
from flask_login import current_user, login_required
from sqlalchemy.orm import subqueryload
from app import db
from app.models import Comment, CommentReaction, Notification, User, UserContent,ContentReport,ReportReason
from app.socket_events import send_notification

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create the comments blueprint
comments_v1_blueprint = Blueprint("comments", __name__, url_prefix="/api/v1/comments")


def get_comments(content_id, content_type, page, per_page):
    """Fetch top-level comments and their replies with pagination."""
    try:
        pagination = (
            Comment.query.filter_by(
                content_type=content_type, content_id=content_id, parent_id=None
            )
            .options(
                subqueryload(Comment.user),
                subqueryload(Comment.replies).subqueryload(
                    Comment.user
                ),  # Recursive load
                subqueryload(Comment.replies).subqueryload(
                    Comment.replies
                ),  # Load replies of replies
            )
            .order_by(Comment.created_at.asc())
            .paginate(page=page, per_page=per_page, error_out=False)
        )

        comments_list = [comment.to_dict() for comment in pagination.items]
        return {
            "data": {
                "comments": comments_list,
                "total": pagination.total,
                "pages": pagination.pages,
                "current_page": pagination.page,
                "per_page": pagination.per_page,
            },
            "status": "success",
            "message": "Comments retrieved successfully",
        }
    except Exception as e:
        logger.error(
            f"Error fetching comments for content_id={content_id}: {e}", exc_info=True
        )
        return {
            "data": None,
            "status": "error",
            "message": "An error occurred while fetching comments",
        }


@comments_v1_blueprint.route("/get_comments", methods=["POST"])
def get_api_comments():
    """Handle POST requests to fetch comments."""
    try:
        data = request.get_json()
        content_id = data.get("content_id")
        content_type = data.get("content_type", "news")
        page = data.get("page", 1)
        per_page = data.get("per_page", 10)

        if not content_id:
            logger.warning("Missing content_id in get_comments request.")
            return (
                jsonify(data=None, status="error", message="content_id is required."),
                400,
            )

        comments_data = get_comments(content_id, content_type, page, per_page)
        return jsonify(comments_data)

    except Exception as e:
        logger.error(f"Error in get_api_comments: {e}", exc_info=True)
        return (
            jsonify(data=None, status="error", message="An unexpected error occurred"),
            500,
        )


@comments_v1_blueprint.route("/post_comment", methods=["POST"])
def post_api_comments():
    """Handle adding a new comment or reply and send notifications."""
    if not current_user.is_authenticated:
        logger.warning("Unauthorized attempt to post comment.")
        return (
            jsonify(data=None, status="error", message="User is not authenticated."),
            401,
        )

    try:
        data = request.get_json()
        content_id = data.get("content_id")
        content_type = data.get("content_type", "news")
        content = data.get("content")
        parent_id = data.get("parent_id")  # Parent comment ID for replies

        # Validation: Ensure content_id and content are provided
        if not content_id:
            logger.warning("Missing content_id in post_comment request.")
            return (
                jsonify(data=None, status="error", message="content_id is required."),
                400,
            )

        if not content:
            logger.warning("Empty content in post_comment request.")
            return (
                jsonify(
                    data=None, status="error", message="Comment content is required."
                ),
                400,
            )

        replied_to = None
        notification_recipient = None
        notification_type = None
        notification_message = None

        # Determine if it's a new comment or a reply
        if parent_id:
            # Handle Replies
            parent_comment = Comment.query.get(parent_id)
            if not parent_comment:
                logger.warning(f"Parent comment with ID {parent_id} not found.")
                return (
                    jsonify(
                        data=None, status="error", message="Parent comment not found."
                    ),
                    400,
                )

            replied_to = {
                "id": parent_comment.user.id,
                "username": parent_comment.user.username,
                "first_name": parent_comment.user.first_name,
                "last_name": parent_comment.user.last_name,
            }

            # Set recipient of reply notification
            notification_recipient = parent_comment.user.id
            notification_type = "comment_reply"
            notification_message = f"{current_user.username} replied to your comment."

        else:
            # Handle New Comments (Notify Content Owner)
            logger.debug(f"Looking up content owner using content_id={content_id}")

            post = UserContent.query.get(content_id)
            if not post:
                logger.warning(f"UserContent not found for content ID {content_id}.")
                logger.debug(f"Type of content_id: {type(content_id)}")
                logger.debug(
                    f"Current authenticated user: {current_user.id} ({current_user.username})"
                )
                return (
                    jsonify(
                        data=None,
                        status="error",
                        message=f"Content not found for content ID {content_id}.",
                    ),
                    400,
                )

            content_owner = post.user
            logger.debug(
                f"Found content owner: {content_owner.id} - {content_owner.username}"
            )

            notification_recipient = content_owner.id
            notification_type = "comment"
            notification_message = f"{current_user.username} commented on your post."

        # ✅ FIXED: Create the comment after determining if it’s a new comment or a reply
        new_comment = Comment(
            content=content,
            content_id=content_id,
            content_type=content_type,
            user_id=current_user.id,
            parent_id=parent_id,
        )
        db.session.add(new_comment)
        db.session.commit()
        logger.info(
            f"New comment added by user {current_user.id} for content_id={content_id}."
        )

        # Send Notification (Avoid self-notifications)
        if notification_recipient and notification_recipient != current_user.id:
            notification = Notification(
                user_id=notification_recipient,
                sender_id=current_user.id,
                type=notification_type,
                content=notification_message,
                post_id=content_id  # Fix: Use content_id instead of content.id
            )
            db.session.add(notification)
            db.session.commit()
            logger.info(
                f"Notification sent to user {notification_recipient} for {notification_type}"
            )

            # Convert notification to dictionary and emit WebSocket event
            notification_data = notification.to_dict()
            send_notification(notification_recipient, notification_data)

        # Construct response
        response_data = {
            "id": new_comment.id,
            "content": new_comment.content,
            "created_at": new_comment.created_at.isoformat(),
            "updated_at": new_comment.updated_at.isoformat(),
            "content_id": new_comment.content_id,
            "content_type": new_comment.content_type,
            "user_id": new_comment.user_id,
            "user": {
                "id": current_user.id,
                "username": current_user.username,
                "profile_picture_url": current_user.profile_picture_url or "",
            },
            "parent_id": new_comment.parent_id,
            "replied_to": replied_to,  # Include the replied_to information
        }

        return (
            jsonify(
                data=response_data,
                status="success",
                message="Comment added successfully.",
            ),
            201,
        )

    except Exception as e:
        db.session.rollback()
        logger.error(
            f"Error posting comment by user {current_user.id}: {e}", exc_info=True
        )
        return (
            jsonify(
                data=None,
                status="error",
                message="An error occurred while posting the comment.",
            ),
            500,
        )


@comments_v1_blueprint.route("/<comment_id>/replies", methods=["GET"])
@login_required
def get_comment_replies(comment_id):
    """Fetch direct and nested replies to a comment, sorted by creation time (paginated)."""
    if not current_user.is_authenticated:
        return (
            jsonify(data=None, status="error", message="User is not authenticated."),
            401,
        )

    try:
        parent_comment = Comment.query.get(comment_id)
        if not parent_comment:
            return (
                jsonify(data=None, status="error", message="Comment not found."),
                404,
            )

        # Recursively collect all nested replies
        def get_all_replies_flat(comment):
            result = []

            def recurse(cmt):
                for reply in cmt.replies:
                    result.append(reply)
                    recurse(reply)

            recurse(comment)
            return sorted(result, key=lambda x: x.created_at)

        all_replies_sorted = get_all_replies_flat(parent_comment)

        # Manual pagination
        page = request.args.get("page", 1, type=int)
        per_page = request.args.get("per_page", 10, type=int)
        total = len(all_replies_sorted)
        start = (page - 1) * per_page
        end = start + per_page
        paginated_replies = all_replies_sorted[start:end]

        # Fetch current user's reactions in advance for optimization
        user_reply_reactions = {
            reaction.content_id: reaction.reaction_type.value
            for reaction in CommentReaction.query.filter_by(user_id=current_user.id).all()
        }

        # Construct the reply list
        reply_list = []
        for reply in paginated_replies:
            top_comment_reaction_counts = (
                db.session.query(
                    CommentReaction.reaction_type,
                    db.func.count(CommentReaction.reaction_type),
                )
                .filter_by(content_id=reply.id)
                .group_by(CommentReaction.reaction_type)
                .order_by(
                    db.func.count(CommentReaction.reaction_type).desc(),
                    CommentReaction.reaction_type,
                )
                .limit(2)
                .all()
            )

            top_comment_reactions = [
                reaction_type.value
                for reaction_type, count in top_comment_reaction_counts
            ]

            reply_list.append(
                {
                    "id": reply.id,
                    "content": reply.content,
                    "created_at": reply.created_at.isoformat(),
                    "user_id": reply.user_id,
                    "user": {
                        "id": reply.user.id,
                        "username": reply.user.username,
                        "profile_picture_url": reply.user.profile_picture_url or "",
                        "first_name": reply.user.first_name,
                        "last_name": reply.user.last_name,
                    },
                    "parent_id": reply.parent_id,
                    "replied_to": (
                        {
                            "id": reply.parent.user.id,
                            "username": reply.parent.user.username,
                            "first_name": reply.parent.user.first_name,
                            "last_name": reply.parent.user.last_name,
                            "profile_picture_url": reply.parent.user.profile_picture_url
                        }
                        if reply.parent_id else None
                    ),
                    "reaction_count": CommentReaction.query.filter_by(
                        content_id=reply.id, content_type="comment"
                    ).count(),
                    "top_reactions": top_comment_reactions,
                    "has_reacted_to_comment": reply.id in user_reply_reactions,
                    "comment_reaction_type": user_reply_reactions.get(reply.id),
                }
            )

        return (
            jsonify(
               success="success",
                message="Content fetched successfully",
                data=reply_list,
                pagination={
                    "current_page": page,
                    "total_pages": (total + per_page - 1) // per_page,
                    "total_items": total,
                    "has_next": end < total,
                    "has_prev": start > 0,
                },
            ),
            200,
        )
    except Exception as e:
        current_app.logger.error(f"Server error: {e}", exc_info=True)
        return jsonify(success="error", message="Server error", data=None), 500


@comments_v1_blueprint.route("/update_comment", methods=["PUT"])
def update_api_comments():
    """Update comment content."""
    if not current_user.is_authenticated:
        logger.warning("Unauthorized access attempt to update comment.")
        return (
            jsonify(data=None, status="error", message="User is not authenticated."),
            401,
        )

    try:
        data = request.get_json()
        comment_id = data.get("comment_id")
        content = data.get("content")

        if not comment_id:
            logger.warning("Missing comment_id in update request.")
            return (
                jsonify(data=None, status="error", message="comment_id is required."),
                400,
            )

        if not content or len(content.strip()) == 0:
            logger.warning(f"Empty content provided for comment_id={comment_id}")
            return (
                jsonify(
                    data=None, status="error", message="Comment content is required."
                ),
                400,
            )

        comment = Comment.query.get(comment_id)

        if not comment:
            logger.warning(f"Comment with ID {comment_id} not found.")
            return jsonify(data=None, status="error", message="Comment not found."), 404

        if comment.user_id != current_user.id:
            logger.warning(
                f"Unauthorized update attempt by user {current_user.id} on comment {comment_id}."
            )
            return (
                jsonify(data=None, status="error", message="Unauthorized action."),
                403,
            )

        comment.content = content
        db.session.commit()
        logger.info(
            f"Comment {comment_id} updated successfully by user {current_user.id}."
        )

        return jsonify(
            data={"comment": comment.to_dict()},
            status="success",
            message="Comment updated successfully.",
        )

    except Exception as e:
        db.session.rollback()
        logger.error(f"Error updating comment {comment_id}: {e}", exc_info=True)
        return (
            jsonify(
                data=None,
                status="error",
                message="An error occurred while updating the comment.",
            ),
            500,
        )

@comments_v1_blueprint.route("/report_comment", methods=["POST"])
@login_required
def report_comment():
    try:
        data = request.get_json()
        comment_id = data.get("comment_id")
        reason_str = data.get("reason")
        custom_reason = data.get("custom_reason")

        if not comment_id or not reason_str:
            return (
                jsonify(
                    success="error",
                    message="Both 'comment_id' and 'reason' are required.",
                    data=None,
                ),
                400,
            )

        # Validate and convert to Enum
        try:
            reason = ReportReason(reason_str)
        except ValueError:
            return (
                jsonify(
                    success="error",
                    message=f"Invalid reason. Valid reasons are: {[r.value for r in ReportReason]}",
                    data=None,
                ),
                400,
            )

        # Require custom_reason if 'Other' is selected
        if reason == ReportReason.OTHER:
            if not custom_reason or not custom_reason.strip():
                return (
                    jsonify(
                        success="error",
                        message="You must provide a custom reason when selecting 'Other'.",
                        data=None,
                    ),
                    400,
                )

        # Check if comment exists
        comment = Comment.query.get(comment_id)
        if not comment:
            return jsonify(success="error", message="Comment not found", data=None), 404

        # Prevent self-reporting
        if comment.user_id == current_user.id:
            return (
                jsonify(
                    success="error",
                    message="You cannot report your own comment.",
                    data=None,
                ),
                400,
            )

        # Prevent duplicate reports
        existing_report = ContentReport.query.filter_by(
            comment_id=comment_id, reporter_id=current_user.id
        ).first()
        if existing_report:
            return (
                jsonify(
                    success="error",
                    message="You have already reported this comment.",
                    data=None,
                ),
                409,
            )

        # Save the report
        report = ContentReport(
            comment_id=comment_id,
            reporter_id=current_user.id,
            reason=reason,
            custom_reason=custom_reason if reason == ReportReason.OTHER else None,
        )

        db.session.add(report)
        db.session.commit()

        return (
            jsonify(
                success="success",
                message="Comment reported successfully.",
                data=report.to_dict(),
            ),
            201,
        )

    except Exception as e:
        current_app.logger.error(f"Error reporting comment: {str(e)}")
        return (
            jsonify(
                success="error",
                message="Failed to report comment due to a server error.",
                data=None,
            ),
            500,
        )

@comments_v1_blueprint.route("/reported_comments", methods=["GET"])
@login_required
def get_reported_comments():
    try:
        # Query all comment reports
        reports = (
            ContentReport.query
            .filter(ContentReport.comment_id.isnot(None))
            .order_by(ContentReport.created_at.desc())
            .all()
        )

        report_list = []
        for report in reports:
            comment = report.comment
            reporter = report.reporter
            author = comment.user

            report_list.append({
                "report_id": report.id,
                "comment_id": comment.id,
                "comment_content": comment.content,
                "comment_created_at": comment.created_at.isoformat(),
                "comment_author": {
                    "id": author.id,
                    "username": author.username,
                    "profile_picture_url": author.profile_picture_url or "",
                },
                "report_reason": report.reason.value,
                "custom_reason": report.custom_reason,
                "reported_by": {
                    "id": reporter.id,
                    "username": reporter.username,
                    "profile_picture_url": reporter.profile_picture_url or "",
                },
                "reported_at": report.created_at.isoformat(),
            })

        return jsonify(
            success="success",
            message="Reported comments fetched successfully.",
            data=report_list,
        ), 200

    except Exception as e:
        current_app.logger.error(f"Error fetching reported comments: {str(e)}")
        return (
            jsonify(
                success="error",
                message="Failed to fetch reported comments due to a server error.",
                data=None,
            ),
            500,
        )
