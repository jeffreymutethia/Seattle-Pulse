import logging
from flask import Blueprint, request, jsonify
from flask_login import login_required, current_user
from app.models import (
    User,
    DirectChat,
    DirectMessage,
    GroupChat,
    GroupMessage,
    GroupChatMember,
    db,
)
from sqlalchemy.exc import SQLAlchemyError
from app.extensions import socketio
from app.socket_events import send_notification  # Import the reusable function
from datetime import datetime, timedelta
from sqlalchemy.orm import aliased
from werkzeug.exceptions import BadRequest

# Configure Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create the chat blueprint
chat_v1_blueprint = Blueprint("chat_v1", __name__, url_prefix="/api/v1/chat")


# ✅ Utility function for standard API responses
def create_response(status, message, data=None, status_code=200):
    """
    Returns a standardized JSON response format.
    """
    response = {"status": status, "message": message}
    if data is not None:
        response["data"] = data
    return jsonify(response), status_code


@chat_v1_blueprint.route("/direct/start/<int:receiver_id>", methods=["POST"])
@login_required
def start_direct_chat(receiver_id):
    """
    Starts a direct chat between two users or returns the existing chat.
    """
    if receiver_id == current_user.id:
        return create_response(
            "error", "You cannot chat with yourself.", status_code=400
        )

    try:
        # Check if the receiver exists
        receiver = User.query.get(receiver_id)
        if not receiver:
            return create_response("error", "Receiver not found.", status_code=404)

        # Check if a chat already exists between the users
        existing_chat = DirectChat.query.filter(
            (
                (DirectChat.user1_id == current_user.id)
                & (DirectChat.user2_id == receiver_id)
            )
            | (
                (DirectChat.user1_id == receiver_id)
                & (DirectChat.user2_id == current_user.id)
            )
        ).first()

        if existing_chat:
            return create_response(
                "success",
                "Chat already exists.",
                {"chat": existing_chat.to_dict()},
                200,
            )

        # Create a new chat
        new_chat = DirectChat(user1_id=current_user.id, user2_id=receiver_id)
        db.session.add(new_chat)
        db.session.commit()

        logger.info(
            f"New direct chat created: {new_chat.id} between {current_user.id} and {receiver_id}"
        )

        return create_response(
            "success", "Chat created successfully.", {"chat": new_chat.to_dict()}, 201
        )

    except SQLAlchemyError as db_error:
        logger.error(f"Database error while starting chat: {str(db_error)}")
        db.session.rollback()
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        logger.error(f"Unexpected error while starting chat: {str(e)}")
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


@chat_v1_blueprint.route("/direct/send", methods=["POST"])
@login_required
def send_direct_message():
    """
    Sends a message to a user in an existing direct chat and emits a real-time notification.
    """
    try:
        data = request.json
        chat_id = data.get("chat_id")
        content = data.get("content")

        # ✅ Validate input
        if not chat_id or not content:
            return create_response(
                "error", "Chat ID and content are required.", status_code=400
            )

        # ✅ Check if chat exists
        chat = DirectChat.query.get(chat_id)
        if not chat:
            return create_response("error", "Chat not found.", status_code=404)

        # ✅ Ensure the user is a participant in the chat
        if current_user.id not in [chat.user1_id, chat.user2_id]:
            return create_response(
                "error", "You are not a participant in this chat.", status_code=403
            )

        # ✅ Create and save the message
        new_message = DirectMessage(
            chat_id=chat_id, sender_id=current_user.id, content=content
        )
        db.session.add(new_message)
        db.session.commit()

        logger.info(f"New message sent in chat {chat_id} by user {current_user.id}")

        # ✅ Determine the recipient ID
        receiver_id = (
            chat.user1_id if chat.user2_id == current_user.id else chat.user2_id
        )

        # ✅ Emit a real-time notification to the receiver using the reusable function
        notification_data = {
            "message": "New message received.",
            "chat_id": chat_id,
            "sender_id": current_user.id,
            "content": content,
        }
        send_notification(receiver_id, notification_data)  # Use the socket function

        return create_response(
            "success",
            "Message sent successfully.",
            {"message_data": new_message.to_dict()},
            status_code=201,
        )

    except SQLAlchemyError as db_error:
        logger.error(f"Database error while sending message: {str(db_error)}")
        db.session.rollback()
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        logger.error(f"Unexpected error while sending message: {str(e)}")
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


@chat_v1_blueprint.route("/direct/list", methods=["GET"])
@login_required
def fetch_all_chats():
    try:
        page = request.args.get("page", 1, type=int)
        limit = request.args.get("limit", 10, type=int)

        if page < 1 or limit < 1:
            return create_response(
                "error", "Invalid page or limit values.", status_code=400
            )

        # ✅ Get chats involving the current user that have at least one message
        user_chats_query = DirectChat.query \
            .filter(
                (DirectChat.user1_id == current_user.id) | (DirectChat.user2_id == current_user.id)
            ) \
            .join(DirectChat.messages) \
            .options(
                db.joinedload(DirectChat.user1),
                db.joinedload(DirectChat.user2),
                db.joinedload(DirectChat.messages).joinedload(DirectMessage.sender)
            ) \
            .group_by(DirectChat.id) \
            .order_by(db.func.max(DirectMessage.created_at).desc())

        paginated_chats = user_chats_query.paginate(
            page=page, per_page=limit, error_out=False
        )

        # ✅ Build the response list
        chats_data = []
        for chat in paginated_chats.items:
            # Determine receiver
            receiver = chat.user2 if chat.user1_id == current_user.id else chat.user1

            # Get the latest message
            if not chat.messages:
                continue  # skip if no messages
            latest_message = sorted(chat.messages, key=lambda m: m.created_at, reverse=True)[0]

            chat_dict = {
                "chat_id": chat.id,
                "receiver": {
                    "id": receiver.id,
                    "first_name": receiver.first_name,
                    "last_name": receiver.last_name,
                    "username": receiver.username,
                    "email": receiver.email,
                    "profile_picture_url": receiver.profile_picture_url or "",
                },
                "latest_message": latest_message.to_dict(),
                "last_updated": latest_message.created_at.isoformat()
            }

            chats_data.append(chat_dict)

        logger.info(f"User {current_user.id} fetched chats: page {page}, limit {limit}")

        return create_response(
            "success",
            "Chats retrieved successfully.",
            {
                "total_chats": paginated_chats.total,
                "total_pages": paginated_chats.pages,
                "current_page": paginated_chats.page,
                "chats": chats_data,
            },
            status_code=200,
        )

    except SQLAlchemyError as db_error:
        logger.error(f"Database error while fetching chats: {str(db_error)}")
        db.session.rollback()
        return create_response("error", "Database error occurred.", status_code=500)

    except Exception as e:
        logger.error(f"Unexpected error while fetching chats: {str(e)}")
        return create_response("error", "An unexpected error occurred.", status_code=500)

@chat_v1_blueprint.route("/direct/<int:chat_id>/messages", methods=["GET"])
@login_required
def fetch_chat_messages(chat_id):
    try:
        page = request.args.get("page", 1, type=int)
        limit = request.args.get("limit", 20, type=int)

        if page < 1 or limit < 1:
            return create_response("error", "Invalid page or limit values.", 400)

        # ✅ Check chat existence and user access
        chat = DirectChat.query \
            .options(
                db.joinedload(DirectChat.user1),
                db.joinedload(DirectChat.user2)
            ).filter_by(id=chat_id).first()

        if not chat:
            return create_response("error", "Chat not found.", 404)

        if current_user.id not in [chat.user1_id, chat.user2_id]:
            return create_response("error", "Access denied.", 403)

        # ✅ Identify the receiver
        receiver = chat.user2 if chat.user1_id == current_user.id else chat.user1

        # ✅ Paginate messages
        messages_query = DirectMessage.query \
            .filter_by(chat_id=chat_id) \
            .order_by(DirectMessage.created_at.desc())

        paginated_messages = messages_query.paginate(page=page, per_page=limit, error_out=False)

        # ✅ Prepare pagination metadata
        pagination = {
            "current_page": paginated_messages.page,
            "total_pages": paginated_messages.pages,
            "total_items": paginated_messages.total,
            "has_next": paginated_messages.page < paginated_messages.pages,
            "has_prev": paginated_messages.page > 1
        }

        # ✅ Prepare response
        messages_data = [message.to_dict() for message in paginated_messages.items]

        return create_response(
            "success",
            "Messages retrieved successfully.",
            {
                "chat_id": chat.id,
                "receiver": {
                    "id": receiver.id,
                    "first_name": receiver.first_name,
                    "last_name": receiver.last_name,
                    "username": receiver.username,
                    "email": receiver.email,
                    "profile_picture_url": receiver.profile_picture_url or "",
                },
                "messages": messages_data,
                "pagination": pagination
            },
            200
        )

    except SQLAlchemyError as db_error:
        logger.error(f"Database error while fetching messages: {str(db_error)}")
        db.session.rollback()
        return create_response("error", "Database error occurred.", 500)

    except Exception as e:
        logger.error(f"Unexpected error while fetching messages: {str(e)}")
        return create_response("error", "An unexpected error occurred.", 500)


# Define the time limit (e.g., 10 minutes)
DELETE_TIME_LIMIT = timedelta(minutes=10)


@chat_v1_blueprint.route("/direct-chat/delete-message/<int:message_id>", methods=["DELETE"])
@login_required
def delete_direct_message(message_id):
    """
    Deletes a message in a direct chat.
    - Users can delete their own messages within a time limit.
    - Soft delete: message is only deleted for the sender.
    - Full delete: message is removed for both users.
    """
    try:
        # Check if the request is JSON or if the body is empty (for soft delete case)
        data = request.get_json(force=True, silent=True)

        # Default delete_for_all to False if no body is sent
        delete_for_all = data.get("delete_for_all", False) if data else False

        # ✅ Find the message by ID
        message = DirectMessage.query.get(message_id)
        if not message:
            return jsonify({"status": "error", "message": "Message not found."}), 404

        # ✅ Ensure the user is the sender
        if message.sender_id != current_user.id:
            return jsonify({"status": "error", "message": "You are not authorized to delete this message."}), 403

        # ✅ Check the deletion time limit
        time_elapsed = datetime.utcnow() - message.created_at
        if time_elapsed > DELETE_TIME_LIMIT:
            return jsonify({"status": "error", "message": "You can only delete messages within 10 minutes of sending."}), 403

        # ✅ Soft delete for sender only (default)
        if not delete_for_all:
            message.deleted_for_sender = True
            db.session.commit()
            return jsonify({"status": "success", "message": "Message deleted for you."}), 200

        # ✅ Full delete for both users
        if delete_for_all:
            db.session.delete(message)
            db.session.commit()
            return jsonify({"status": "success", "message": "Message deleted for both users."}), 200

        return jsonify({"status": "error", "message": "Invalid operation."}), 400

    except SQLAlchemyError as db_error:
        logger.error(f"Database error while deleting message: {str(db_error)}")
        db.session.rollback()
        return jsonify({"status": "error", "message": "Database error occurred."}), 500

    except Exception as e:
        logger.exception(f"Unexpected error while deleting message: {str(e)}")
        return jsonify({"status": "error", "message": "An unexpected error occurred."}), 500


@chat_v1_blueprint.route("/direct-chat/delete-chat/<int:chat_id>", methods=["DELETE"])
@login_required
def delete_chat(chat_id):
    """
    Delete an entire chat (remove all messages in a chat).
    """
    try:
        # Find the chat by ID
        chat = DirectChat.query.get(chat_id)
        if not chat:
            return jsonify({"status": "error", "message": "Chat not found."}), 404

        # Check if the current user is part of the chat
        if chat.user1_id != current_user.id and chat.user2_id != current_user.id:
            return (
                jsonify(
                    {
                        "status": "error",
                        "message": "You are not authorized to delete this chat.",
                    }
                ),
                403,
            )

        # Delete the chat and all its messages
        db.session.delete(chat)
        db.session.commit()

        return (
            jsonify({"status": "success", "message": "Chat deleted successfully."}),
            200,
        )

    except SQLAlchemyError as db_error:
        db.session.rollback()
        return jsonify({"status": "error", "message": "Database error occurred."}), 500
    except Exception as e:
        return (
            jsonify({"status": "error", "message": "An unexpected error occurred."}),
            500,
        )


@chat_v1_blueprint.route("/direct-chat/edit-message/<int:message_id>", methods=["PUT"])
@login_required
def edit_direct_message(message_id):
    """
    Edits a message in a direct chat.
    - Users can edit their own messages within a time limit.
    """
    try:
        data = request.json
        new_content = data.get("content")

        # ✅ Validate input
        if not new_content:
            return create_response(
                "error", "New content is required to edit the message.", status_code=400
            )

        # ✅ Find the message by ID
        message = DirectMessage.query.get(message_id)
        if not message:
            return create_response("error", "Message not found.", status_code=404)

        # ✅ Ensure the user is the sender
        if message.sender_id != current_user.id:
            return create_response(
                "error", "You are not authorized to edit this message.", status_code=403
            )

        # ✅ Check the editing time limit
        time_elapsed = datetime.utcnow() - message.created_at
        if time_elapsed > DELETE_TIME_LIMIT:
            return create_response(
                "error",
                "You can only edit messages within 10 minutes of sending.",
                status_code=403,
            )

        # ✅ Update the message content
        message.content = new_content
        db.session.commit()

        logger.info(f"Message {message_id} edited by user {current_user.id}")

        return create_response(
            "success",
            "Message edited successfully.",
            {"message_data": message.to_dict()},
            status_code=200,
        )

    except SQLAlchemyError as db_error:
        logger.error(f"Database error while editing message: {str(db_error)}")
        db.session.rollback()
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        logger.error(f"Unexpected error while editing message: {str(e)}")
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )

from sqlalchemy.orm import aliased
from sqlalchemy.sql import func

@chat_v1_blueprint.route("/list/all", methods=["GET"])
@login_required
def fetch_all_chats_combined_sorted():
    try:
        limit = request.args.get("limit", 10, type=int)
        page = request.args.get("page", 1, type=int)
        offset = (page - 1) * limit

        Receiver = aliased(User)

        # ========== Latest Direct Messages ==========
        latest_direct_subquery = (
            db.session.query(
                DirectMessage.chat_id,
                func.max(DirectMessage.created_at).label("latest_created_at")
            )
            .join(DirectChat, DirectMessage.chat_id == DirectChat.id)
            .filter((DirectChat.user1_id == current_user.id) | (DirectChat.user2_id == current_user.id))
            .group_by(DirectMessage.chat_id)
            .subquery()
        )

        latest_direct_messages = (
            db.session.query(
                DirectChat.id.label("chat_id"),
                DirectMessage.content.label("content"),
                DirectMessage.created_at.label("created_at"),
                DirectMessage.sender_id.label("sender_id"),
                Receiver.id.label("receiver_id"),
                Receiver.first_name.label("receiver_first_name"),
                Receiver.last_name.label("receiver_last_name"),
                Receiver.username.label("receiver_username"),
                Receiver.email.label("receiver_email"),
                Receiver.profile_picture_url.label("receiver_profile_picture_url"),
                db.literal("direct").label("chat_type"),
                db.null().label("group_name")
            )
            .join(DirectMessage, DirectChat.id == DirectMessage.chat_id)
            .join(latest_direct_subquery,
                  (DirectMessage.chat_id == latest_direct_subquery.c.chat_id) &
                  (DirectMessage.created_at == latest_direct_subquery.c.latest_created_at)
            )
            .join(
                Receiver,
                db.case(
                    (DirectChat.user1_id == current_user.id, DirectChat.user2_id),
                    else_=DirectChat.user1_id
                ) == Receiver.id
            )
        )

        # ========== Latest Group Messages ==========
        latest_group_subquery = (
            db.session.query(
                GroupMessage.group_chat_id.label("chat_id"),
                func.max(GroupMessage.created_at).label("latest_created_at")
            )
            .join(GroupChatMember, GroupMessage.group_chat_id == GroupChatMember.group_chat_id)
            .filter(GroupChatMember.user_id == current_user.id)
            .group_by(GroupMessage.group_chat_id)
            .subquery()
        )

        latest_group_messages = (
            db.session.query(
                GroupChat.id.label("chat_id"),
                GroupMessage.content.label("content"),
                GroupMessage.created_at.label("created_at"),
                GroupMessage.sender_id.label("sender_id"),
                db.null().label("receiver_id"),
                db.null().label("receiver_first_name"),
                db.null().label("receiver_last_name"),
                db.null().label("receiver_username"),
                db.null().label("receiver_email"),
                db.null().label("receiver_profile_picture_url"),
                db.literal("group").label("chat_type"),
                GroupChat.name.label("group_name")
            )
            .join(GroupMessage, GroupChat.id == GroupMessage.group_chat_id)
            .join(latest_group_subquery,
                  (GroupMessage.group_chat_id == latest_group_subquery.c.chat_id) &
                  (GroupMessage.created_at == latest_group_subquery.c.latest_created_at)
            )
        )

        # ========== Combine ==========
        combined = latest_direct_messages.union_all(latest_group_messages).subquery("combined_chats")

        # ========== Order & Paginate ==========
        ordered_query = db.session.query(combined).order_by(combined.c.created_at.desc())
        paginated_results = ordered_query.offset(offset).limit(limit).all()

        # ========== Format Response ==========
        chats = []
        for row in paginated_results:
            if row.chat_type == "direct":
                name = f"{row.receiver_first_name or ''} {row.receiver_last_name or ''}".strip()
                profile_picture_url = row.receiver_profile_picture_url or ""
                receiver_info = {
                    "id": row.receiver_id,
                    "first_name": row.receiver_first_name,
                    "last_name": row.receiver_last_name,
                    "username": row.receiver_username,
                    "email": row.receiver_email,
                    "profile_picture_url": row.receiver_profile_picture_url or "",
                }
            else:
                name = row.group_name
                profile_picture_url = ""
                receiver_info = None

            chats.append({
                "chat_id": row.chat_id,
                "type": row.chat_type,
                "name": name,
                "profile_picture_url": profile_picture_url,
                "receiver": receiver_info,
                "latest_message": {
                    "sender_id": row.sender_id,
                    "content": row.content,
                    "created_at": row.created_at.isoformat()
                },
                "last_updated": row.created_at.isoformat()
            })

        return create_response(
            "success",
            "Combined chat list retrieved and sorted.",
            {
                "current_page": page,
                "limit": limit,
                "chats": chats
            },
            200
        )

    except Exception as e:
        logger.exception("Failed to fetch sorted chat list")
        return create_response("error", "An error occurred while fetching chats.", 500)
