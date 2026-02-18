import logging
from flask import request
from .models import Notification
from .extensions import socketio  # Import socketio from extensions

# Setup Logger
socket_logger = logging.getLogger("socketio")
socket_logger.setLevel(logging.DEBUG)
handler = logging.StreamHandler()
formatter = logging.Formatter("%(asctime)s - [SOCKET] - %(levelname)s - %(message)s")
handler.setFormatter(formatter)
socket_logger.addHandler(handler)


@socketio.on("connect")
def handle_connect():
    """Handles a new socket connection."""
    socket_logger.info(f"✅ Client connected: {request.sid}")


@socketio.on("disconnect")
def handle_disconnect():
    """Handles client disconnection."""
    socket_logger.info(f"❌ Client disconnected: {request.sid}")


@socketio.on("message")
def handle_message(data):
    """Handles incoming messages from clients."""
    try:
        socket_logger.info(f"📩 Received message from {request.sid}: {data}")

        # Echo the message back (or modify as per your use case)
        response = {"message": f"Echo: {data}"}
        socketio.emit("response", response, room=request.sid)

        socket_logger.info(f"📤 Sent response to {request.sid}: {response}")

    except Exception as e:
        socket_logger.error(
            f"⚠️ Error processing message from {request.sid}: {e}", exc_info=True
        )


def send_notification(user_id, notification_data):
    """Emit notification event to a specific user."""
    try:
        event_name = f"notify_{user_id}"
        socket_logger.info(f"🔔 Sending notification event: {event_name}")

        socketio.emit(event_name, notification_data)

        socket_logger.info(f"✅ Notification {event_name} sent successfully.")

    except Exception as e:
        socket_logger.error(
            f"⚠️ Error sending notification {event_name}: {e}", exc_info=True
        )


@socketio.on("private_message")
def handle_private_message(data):
    """Handles private messages between users."""
    receiver_id = data["receiver_id"]
    message = data["message"]

    socket_logger.info(
        f"📩 Private message from {request.sid} to {receiver_id}: {message}"
    )
    socketio.emit(
        f"chat_{receiver_id}",
        {"sender_id": request.sid, "message": message},
        room=f"user_{receiver_id}",
    )


@socketio.on("group_message")
def handle_group_message(data):
    """
    Handles messages in group chats.
    Expects: { group_chat_id: str, message: dict }
    """
    group_chat_id = data.get("group_chat_id")
    message = data.get("message")

    if not group_chat_id or not message:
        socket_logger.warning(f"⚠️ Missing data in group_message: {data}")
        return

    socket_logger.info(f"📩 Group message in {group_chat_id}: {message}")

    # Use the shared function to broadcast the message
    broadcast_group_message(group_chat_id, message)


@socketio.on("join_group")
def handle_join_group(data):
    """
    Handles when a user joins a group chat.
    """
    group_chat_id = data["group_chat_id"]
    user_id = data["user_id"]

    socket_logger.info(f"📢 User {user_id} joined group {group_chat_id}")

    # Notify all members in the group that a new user has joined
    socketio.emit(
        f"group_user_joined_{group_chat_id}",
        {"message": f"User {user_id} has joined the group."},
        room=f"group_{group_chat_id}",
    )

    socket_logger.info(f"🔔 Notified group {group_chat_id} of user {user_id} joining")


@socketio.on("leave_group")
def handle_leave_group(data):
    """
    Handles when a user leaves a group chat.
    """
    group_chat_id = data["group_chat_id"]
    user_id = data["user_id"]

    socket_logger.info(f"🚪 User {user_id} left group {group_chat_id}")

    # Notify all members in the group that the user has left
    socketio.emit(
        f"group_user_left_{group_chat_id}",
        {"message": f"User {user_id} has left the group."},
        room=f"group_{group_chat_id}",
    )

    socket_logger.info(f"🔔 Notified group {group_chat_id} of user {user_id} leaving")

def broadcast_group_message(group_chat_id, message):
    """
    Broadcasts a message to the group chat room.
    """
    socketio.emit(
        f"group_chat_{group_chat_id}",
        {"message": message},
        room=f"group_{group_chat_id}",
    )
    socket_logger.info(f"📤 Message broadcasted to room group_chat_{group_chat_id}")
