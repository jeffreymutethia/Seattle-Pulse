import logging
from flask import Blueprint, request, jsonify,current_app
from flask_login import login_required, current_user
from sqlalchemy.exc import SQLAlchemyError
from app.models import db, GroupChat, GroupChatMember, GroupMessage, RoleEnum, User
from app.socket_events import (
    handle_join_group,
    handle_leave_group,
    send_notification,
    broadcast_group_message,
)  # Import the function
from datetime import datetime, timedelta

# Configure Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create Blueprint for Group Chat API
group_chat_blueprint = Blueprint("group_chat", __name__, url_prefix="/api/v1/group")


# ✅ Utility function for standard API responses
def create_response(status, message, data=None, status_code=200):
    response = {"status": status, "message": message}
    if data is not None:
        response["data"] = data
    return jsonify(response), status_code


# ✅ Create a Group Chat
@group_chat_blueprint.route("/create", methods=["POST"])
@login_required
def create_group_chat():
    """
    Creates a new group chat and assigns the creator as an admin.
    """
    logger.info(f"User {current_user.id} initiated a group creation request.")

    try:
        data = request.json
        group_name = data.get("name")
        logger.info(f"Received request with group name: {group_name}")

        if not group_name:
            logger.warning("Group name is missing in the request.")
            return create_response("error", "Group name is required.", status_code=400)

        # Check if a group with the same name exists
        existing_group = GroupChat.query.filter_by(name=group_name).first()
        if existing_group:
            logger.info(f"Group with name '{group_name}' already exists (ID: {existing_group.id}).")
            return create_response("error", "Group name already exists.", status_code=409)

        # Create new group chat
        new_group = GroupChat(name=group_name, created_by=current_user.id)
        db.session.add(new_group)
        db.session.commit()
        logger.info(f"Group '{group_name}' created successfully with ID {new_group.id}.")

        # Assign the creator as an admin in the group
        creator_membership = GroupChatMember(
            group_chat_id=new_group.id,
            user_id=current_user.id,
            role=RoleEnum.OWNER
        )
        db.session.add(creator_membership)
        db.session.commit()
        logger.info(f"User {current_user.id} assigned as admin for group {new_group.id}.")

        return create_response(
            "success",
            "Group created successfully.",
            {"group": new_group.to_dict()},
            201,
        )

    except SQLAlchemyError as db_error:
        db.session.rollback()
        logger.error(f"Database error occurred: {str(db_error)}", exc_info=True)
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        logger.exception(f"An unexpected error occurred: {str(e)}")
        return create_response("error", "An unexpected error occurred.", status_code=500)


@group_chat_blueprint.route("/message/send", methods=["POST"])
@login_required
def send_group_message():
    """
    Sends a message in a group chat. Users must be part of the group.
    Also sends group onboarding notifications.
    """
    logger.info(f"User {current_user.id} initiated sending a group message.")
    try:
        data = request.json
        group_chat_id = data.get("group_chat_id")
        content = data.get("content")
        logger.info(f"Received message send request for group {group_chat_id} with content: {content}")

        if not group_chat_id or not content:
            logger.warning("Group ID or message content is missing from the request.")
            return create_response(
                "error", "Group ID and message content are required.", status_code=400
            )

        # Ensure group exists
        group = GroupChat.query.get(group_chat_id)
        if not group:
            logger.warning(f"Group with ID {group_chat_id} not found.")
            return create_response("error", "Group not found.", status_code=404)
        logger.info(f"Group {group_chat_id} found: {group.name}")

        # Ensure user is a member of the group
        membership = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=current_user.id
        ).first()
        if not membership:
            logger.warning(f"User {current_user.id} is not a member of group {group_chat_id}.")
            return create_response(
                "error", "You are not a member of this group.", status_code=403
            )
        logger.info(f"User {current_user.id} confirmed as member of group {group_chat_id}.")

        # Create and save the message in the DB
        new_message = GroupMessage(
            group_chat_id=group_chat_id,
            sender_id=current_user.id,
            content=content
        )
        db.session.add(new_message)
        db.session.commit()
        logger.info(f"Message created in group {group_chat_id} by user {current_user.id}.")

        message_payload = new_message.to_dict()
        logger.info(f"Message payload: {message_payload}")

        # Send group onboarding notifications to other members
        group_members = GroupChatMember.query.filter_by(group_chat_id=group_chat_id).all()
        logger.info(f"Found {len(group_members)} member(s) in group {group_chat_id}. Sending notifications...")
        for member in group_members:
            if member.user_id != current_user.id:
                notification_data = {
                    "type": "group_onboarding",
                    "group_chat_id": group_chat_id,
                    "message": message_payload,
                    "info": f"{current_user.username} posted a new message in {group.name}."
                }
                send_notification(member.user_id, notification_data)
                logger.info(f"Notification sent to user {member.user_id} for group {group_chat_id}.")

        # Use the shared broadcast function to send the group message in real-time
        broadcast_group_message(group_chat_id, message_payload)
        logger.info(f"Real-time message broadcasted to group {group_chat_id}.")

        return create_response(
            "success",
            "Message sent successfully.",
            {"message": message_payload},
            201,
        )

    except SQLAlchemyError as db_error:
        db.session.rollback()
        logger.error(f"Database error occurred while sending group message: {str(db_error)}", exc_info=True)
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        logger.exception(f"An unexpected error occurred while sending group message: {str(e)}")
        return create_response("error", "An unexpected error occurred.", status_code=500)

@group_chat_blueprint.route("/messages/<int:group_chat_id>", methods=["GET"])
@login_required
def fetch_group_messages(group_chat_id):
    """
    Retrieves all messages in a group chat (paginated).
    """
    try:
        # Ensure the group exists
        group = GroupChat.query.get(group_chat_id)
        if not group:
            return create_response("error", "Group not found.", status_code=404)

        # Ensure the current user is a member of the group
        membership = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=current_user.id
        ).first()
        if not membership:
            return create_response(
                "error", "You are not a member of this group.", status_code=403
            )

        # Get pagination parameters (default page=1, limit=20)
        page = request.args.get("page", 1, type=int)
        limit = request.args.get("limit", 20, type=int)

        if page < 1 or limit < 1:
            return create_response(
                "error", "Invalid page or limit values.", status_code=400
            )

        # Query messages with pagination
        messages_query = GroupMessage.query.filter_by(
            group_chat_id=group_chat_id
        ).order_by(GroupMessage.created_at.desc())
        paginated_messages = messages_query.paginate(
            page=page, per_page=limit, error_out=False
        )

        messages_data = [message.to_dict() for message in paginated_messages.items]

        return create_response(
            "success",
            "Messages retrieved successfully.",
            {
                "total_messages": paginated_messages.total,
                "total_pages": paginated_messages.pages,
                "current_page": paginated_messages.page,
                "messages": messages_data,
            },
            status_code=200,
        )

    except SQLAlchemyError as db_error:
        db.session.rollback()
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


@group_chat_blueprint.route("/list", methods=["GET"])
@login_required
def fetch_user_groups():
    """
    Fetches all groups the current user is a member of.
    """
    try:
        # Get pagination parameters (default page=1, limit=10)
        page = request.args.get("page", 1, type=int)
        limit = request.args.get("limit", 10, type=int)

        if page < 1 or limit < 1:
            return create_response(
                "error", "Invalid page or limit values.", status_code=400
            )

        # Query for all group memberships of the current user
        user_groups_query = (
            db.session.query(GroupChat)
            .join(GroupChatMember)
            .filter(GroupChatMember.user_id == current_user.id)
        )
        paginated_groups = user_groups_query.paginate(
            page=page, per_page=limit, error_out=False
        )

        groups_data = [group.to_dict() for group in paginated_groups.items]

        return create_response(
            "success",
            "Groups retrieved successfully.",
            {
                "total_groups": paginated_groups.total,
                "total_pages": paginated_groups.pages,
                "current_page": paginated_groups.page,
                "groups": groups_data,
            },
            status_code=200,
        )

    except SQLAlchemyError as db_error:
        db.session.rollback()
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


@group_chat_blueprint.route("/member/add", methods=["POST"])
@login_required
def add_group_member():
    """
    Allows an admin or the group owner to add a user to a group.
    """
    logger.info(f"User {current_user.id} initiated a request to add a member.")
    try:
        data = request.json
        group_chat_id = data.get("group_chat_id")
        user_id = data.get("user_id")
        logger.info(f"Received request to add user {user_id} to group {group_chat_id}.")

        if not group_chat_id or not user_id:
            logger.warning("Group ID or user ID is missing in the request.")
            return create_response("error", "Group ID and user ID are required.", status_code=400)

        # Ensure the group exists
        group = GroupChat.query.get(group_chat_id)
        if not group:
            logger.warning(f"Group {group_chat_id} not found.")
            return create_response("error", "Group not found.", status_code=404)
        logger.info(f"Group {group_chat_id} found: {group.to_dict()}")

        # ✅ Allow if user is ADMIN or OWNER
        admin_or_owner_check = GroupChatMember.query.filter(
            GroupChatMember.group_chat_id == group_chat_id,
            GroupChatMember.user_id == current_user.id,
            GroupChatMember.role.in_([RoleEnum.ADMIN, RoleEnum.OWNER])
        ).first()

        if not admin_or_owner_check:
            logger.warning(f"User {current_user.id} is not an admin or owner in group {group_chat_id}.")
            return create_response("error", "Only admins or the owner can add members.", status_code=403)

        logger.info(f"Permission check passed for user {current_user.id} in group {group_chat_id}.")

        # Check if the user is already a member
        existing_member = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=user_id
        ).first()
        if existing_member:
            logger.info(f"User {user_id} is already a member of group {group_chat_id}.")
            return create_response("error", "User is already in the group.", status_code=409)

        # Add the new member with the role set to MEMBER
        new_member = GroupChatMember(
            group_chat_id=group_chat_id,
            user_id=user_id,
            role=RoleEnum.MEMBER
        )
        db.session.add(new_member)
        db.session.commit()
        logger.info(f"User {user_id} successfully added to group {group_chat_id} as a member.")

        # 🔔 Notify the user who was added
        send_notification(
            user_id,
            {
                "type": "group_invite",
                "message": f"You have been added to the group {group_chat_id}.",
            },
        )
        logger.info(f"Notification sent to user {user_id} regarding group invitation.")

        # 🔔 Notify group members via the join event
        handle_join_group({"group_chat_id": group_chat_id, "user_id": user_id})
        logger.info(f"Join group event triggered for user {user_id} in group {group_chat_id}.")

        return create_response(
            "success",
            "User added to group successfully.",
            {"member": new_member.to_dict()},
            status_code=201,
        )

    except SQLAlchemyError as db_error:
        db.session.rollback()
        logger.error(f"Database error while adding group member: {db_error}", exc_info=True)
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        logger.exception("An unexpected error occurred while adding a group member.")
        return create_response("error", "An unexpected error occurred.", status_code=500)


@group_chat_blueprint.route("/member/remove", methods=["DELETE"])
@login_required
def remove_group_member():
    """
    Allows an owner to remove any user.
    Admins can remove only members.
    Admins cannot remove other admins or the owner.
    Owners cannot remove themselves.
    """
    try:
        data = request.json
        required_fields = ["group_chat_id", "user_id"]
        missing_fields = [field for field in required_fields if field not in data]

        if missing_fields:
            return create_response(
                "error",
                f"Missing required fields: {', '.join(missing_fields)}.",
                status_code=400,
            )

        group_chat_id = data["group_chat_id"]
        user_id = data["user_id"]

        # Ensure the group exists
        group = GroupChat.query.get(group_chat_id)
        if not group:
            return create_response("error", "Group not found.", status_code=404)

        # Ensure the target user is a group member
        target_member = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=user_id
        ).first()
        if not target_member:
            return create_response(
                "error", "User is not a member of this group.", status_code=404
            )

        # Get the current user's role
        current_user_role = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=current_user.id
        ).first()

        if not current_user_role:
            return create_response(
                "error", "You are not part of this group.", status_code=403
            )

        # Prevent self-removal
        if user_id == current_user.id:
            return create_response(
                "error",
                "You cannot remove yourself. Please leave the group instead.",
                status_code=400,
            )

        # Role-based removal logic
        if current_user_role.role == RoleEnum.OWNER:
            # Owner can remove anyone (except themselves)
            pass
        elif current_user_role.role == RoleEnum.ADMIN:
            # Admins can only remove members, not other admins or the owner
            if target_member.role in [RoleEnum.ADMIN, RoleEnum.OWNER]:
                return create_response(
                    "error", "Admins can only remove members.", status_code=403
                )
        else:
            return create_response(
                "error", "You do not have permission to remove users.", status_code=403
            )

        # Remove the user from the group
        db.session.delete(target_member)
        db.session.commit()

        # 🔔 Notify the removed user
        send_notification(
            user_id,
            {
                "type": "group_removed",
                "message": f"You have been removed from the group {group_chat_id}.",
            },
        )

        # 🔔 Call the socket function to notify group members
        handle_leave_group({"group_chat_id": group_chat_id, "user_id": user_id})

        return create_response(
            "success",
            "User removed from group successfully.",
            {"removed_user_id": user_id},
            status_code=200,
        )

    except SQLAlchemyError:
        db.session.rollback()
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception:
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


@group_chat_blueprint.route("/group/join", methods=["POST"])
@login_required
def join_group_chat():
    """
    Allows a user to join a group chat voluntarily.
    Calls the existing WebSocket event to notify other members.
    """
    try:
        data = request.json
        group_chat_id = data.get("group_chat_id")

        if not group_chat_id:
            return create_response(
                "error", "Group chat ID is required.", status_code=400
            )

        # ✅ Check if the group exists
        group = GroupChat.query.get(group_chat_id)
        if not group:
            return create_response("error", "Group chat not found.", status_code=404)

        # ✅ Check if the user is already a member
        existing_member = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=current_user.id
        ).first()
        if existing_member:
            return create_response(
                "error", "You are already a member of this group.", status_code=409
            )

        # ✅ Add the user to the group
        new_member = GroupChatMember(
            group_chat_id=group_chat_id, user_id=current_user.id, is_admin=False
        )
        db.session.add(new_member)
        db.session.commit()

        logger.info(f"User {current_user.id} joined group {group_chat_id}")

        # ✅ Send a personal notification to the user
        send_notification(
            current_user.id,
            {
                "type": "group_join",
                "message": f"You have joined the group {group_chat_id}.",
            },
        )

        # ✅ Call the WebSocket function to notify all members
        handle_join_group({"group_chat_id": group_chat_id, "user_id": current_user.id})

        return create_response(
            "success",
            "You have joined the group successfully.",
            {"group_id": group_chat_id},
            status_code=200,
        )

    except SQLAlchemyError as db_error:
        logger.error(f"Database error while joining group: {str(db_error)}")
        db.session.rollback()
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        logger.error(f"Unexpected error while joining group: {str(e)}")
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


@group_chat_blueprint.route("/group/leave", methods=["POST"])
@login_required
def leave_group_chat():
    """
    Allows a user to leave a group chat voluntarily.
    If the user is the owner and the last member, the group is deleted only if delete_group_confirmation is true.
    """
    try:
        data = request.json
        required_fields = ["group_chat_id"]
        missing_fields = [field for field in required_fields if field not in data]

        if missing_fields:
            return create_response(
                "error",
                f"Missing required fields: {', '.join(missing_fields)}.",
                status_code=400,
            )

        group_chat_id = data["group_chat_id"]
        delete_group_confirmation = data.get("delete_group_confirmation", False)

        # ✅ Check if the group exists
        group = GroupChat.query.get(group_chat_id)
        if not group:
            return create_response("error", "Group chat not found.", status_code=404)

        # ✅ Check if the user is a member
        member = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=current_user.id
        ).first()
        if not member:
            return create_response(
                "error", "You are not a member of this group.", status_code=404
            )

        # ✅ Count members in the group
        total_members = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id
        ).count()

        # ✅ Check if the user is the owner
        if member.role == RoleEnum.OWNER:
            if total_members == 1:
                # ✅ If the owner is the last member, check the confirmation flag
                if delete_group_confirmation:
                    db.session.delete(group)
                    db.session.commit()
                    logger.info(
                        f"Owner {current_user.id} deleted group {group_chat_id}"
                    )

                    return create_response(
                        "success",
                        "You were the last member. The group has been deleted.",
                        {"group_id": group_chat_id, "group_deleted": True},
                        status_code=200,
                    )
                else:
                    return create_response(
                        "error",
                        "Leaving will delete the group. Please confirm deletion.",
                        {"delete_required": True},
                        status_code=400,
                    )

            # ✅ Otherwise, owner must transfer ownership first
            return create_response(
                "error",
                "You must assign a new owner before leaving.",
                status_code=400,
            )

        # ✅ If not an owner, allow normal leaving
        db.session.delete(member)
        db.session.commit()

        logger.info(f"User {current_user.id} left group {group_chat_id}")

        return create_response(
            "success",
            "You have left the group successfully.",
            {"group_id": group_chat_id, "group_deleted": False},
            status_code=200,
        )

    except SQLAlchemyError as db_error:
        logger.error(f"Database error while leaving group: {str(db_error)}")
        db.session.rollback()
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        logger.error(f"Unexpected error while leaving group: {str(e)}")
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


@group_chat_blueprint.route("/admin/assign", methods=["PATCH"])
@login_required
def assign_role():
    """
    Allows an owner to promote/demote users.
    - Owner can promote/demote any user (including admins).
    - Admins can promote members to admins but cannot demote other admins or the owner.
    - The last owner cannot demote themselves without transferring ownership first.
    """
    logger.info(f"User {current_user.id} initiated a role assignment request.")
    try:
        data = request.json
        required_fields = ["group_chat_id", "user_id", "role"]
        missing_fields = [field for field in required_fields if field not in data]

        if missing_fields:
            logger.warning(f"Missing fields: {missing_fields}")
            return create_response(
                "error",
                f"Missing required fields: {', '.join(missing_fields)}.",
                status_code=400,
            )

        group_chat_id = data["group_chat_id"]
        user_id = data["user_id"]
        new_role_str = data["role"].lower()

        logger.info(f"Request details: group_chat_id={group_chat_id}, user_id={user_id}, new_role={new_role_str}")

        # Validate role string to RoleEnum
        try:
            new_role = RoleEnum[new_role_str.upper()]
        except KeyError:
            logger.warning(f"Invalid role provided: {new_role_str}")
            return create_response("error", "Invalid role specified.", status_code=400)

        # Check if group exists
        group = GroupChat.query.get(group_chat_id)
        if not group:
            logger.warning(f"Group {group_chat_id} not found.")
            return create_response("error", "Group not found.", status_code=404)

        # Check target membership
        target_member = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=user_id
        ).first()
        if not target_member:
            logger.warning(f"User {user_id} is not a member of group {group_chat_id}.")
            return create_response(
                "error", "User is not a member of this group.", status_code=404
            )

        # Get current user's role
        current_member = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=current_user.id
        ).first()
        if not current_member:
            logger.warning(f"Current user {current_user.id} is not a member of group {group_chat_id}.")
            return create_response(
                "error", "You are not part of this group.", status_code=403
            )

        logger.info(f"Current user role: {current_member.role}, Target user role: {target_member.role}")

        # Owner permissions
        if current_member.role == RoleEnum.OWNER:
            if new_role == RoleEnum.OWNER:
                logger.warning("Attempt to assign second owner.")
                return create_response(
                    "error", "Only one owner is allowed.", status_code=400
                )
            if target_member.role == RoleEnum.OWNER and new_role != RoleEnum.OWNER:
                logger.warning("Attempt to demote the only owner without ownership transfer.")
                return create_response(
                    "error",
                    "Cannot demote the owner without transferring ownership.",
                    status_code=400,
                )

        # Admin permissions
        elif current_member.role == RoleEnum.ADMIN:
            if new_role == RoleEnum.ADMIN and target_member.role == RoleEnum.MEMBER:
                logger.info(f"Admin {current_user.id} is promoting member {user_id} to admin.")
            else:
                logger.warning(f"Admin {current_user.id} attempted unauthorized role change.")
                return create_response(
                    "error",
                    "Admins can only promote members, not demote users.",
                    status_code=403,
                )

        # Member permissions
        else:
            logger.warning(f"Member {current_user.id} attempted unauthorized role change.")
            return create_response(
                "error", "You do not have permission to modify roles.", status_code=403
            )

        # ✅ Role update
        old_role = target_member.role
        target_member.role = new_role
        db.session.commit()

        logger.info(
            f"User {user_id} role changed from {old_role.value} to {new_role.value} "
            f"in group {group_chat_id} by user {current_user.id}."
        )

        return create_response(
            "success",
            f"User role updated to {new_role.value}.",
            {"user_id": user_id, "role": new_role.value},
            status_code=200,
        )

    except SQLAlchemyError as db_error:
        db.session.rollback()
        logger.error(f"Database error: {db_error}", exc_info=True)
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        logger.exception("Unexpected error during role assignment.")
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


# Define the time limit for the ability to delete a message in a timeframe (e.g., 10 minutes)
DELETE_TIME_LIMIT = timedelta(minutes=10)


@group_chat_blueprint.route("/message/delete", methods=["DELETE"])
@login_required
def delete_group_message():
    """
    Deletes a message in a group.
    - Users can delete their own messages within a time limit.
    - Admins can delete messages for all members, but still within a time limit.
    - Soft delete for sender only.
    """
    try:
        data = request.json
        message_id = data.get("message_id")
        delete_for_all = data.get(
            "delete_for_all", False
        )  # Default: Soft delete for sender

        if not message_id:
            return create_response("error", "Message ID is required.", status_code=400)

        # ✅ Ensure the message exists
        message = GroupMessage.query.get(message_id)
        if not message:
            return create_response("error", "Message not found.", status_code=404)

        # ✅ Ensure the group exists
        group = GroupChat.query.get(message.group_chat_id)
        if not group:
            return create_response("error", "Group not found.", status_code=404)

        # ✅ Check if the current user is the sender or an admin
        user_role = GroupChatMember.query.filter_by(
            group_chat_id=group.id, user_id=current_user.id
        ).first()

        if not user_role:
            return create_response(
                "error", "You are not a member of this group.", status_code=403
            )

        is_admin = user_role.role in [RoleEnum.OWNER, RoleEnum.ADMIN]
        is_sender = current_user.id == message.sender_id

        # ✅ Check the message deletion time limit
        time_elapsed = datetime.utcnow() - message.created_at
        if time_elapsed > DELETE_TIME_LIMIT:
            return create_response(
                "error",
                "You can only delete messages within 10 minutes of sending.",
                status_code=403,
            )

        # ✅ If not the sender or admin, deny deletion
        if not is_sender and not is_admin:
            return create_response(
                "error", "You are not allowed to delete this message.", status_code=403
            )

        # ✅ Soft delete for sender only
        if not delete_for_all and is_sender:
            message.content = "[Deleted Message]"  # Hide content for sender only
            db.session.commit()
            return create_response(
                "success", "Message deleted for you.", status_code=200
            )

        # ✅ Full delete (admins & sender)
        if delete_for_all and (is_admin or is_sender):
            db.session.delete(message)
            db.session.commit()
            return create_response(
                "success", "Message deleted for everyone.", status_code=200
            )

        return create_response("error", "Invalid operation.", status_code=400)

    except SQLAlchemyError as db_error:
        db.session.rollback()
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


@group_chat_blueprint.route("/delete", methods=["DELETE"])
@login_required
def delete_group():
    """
    Deletes an entire group. Only admins can do this.
    """
    try:
        data = request.json
        group_chat_id = data.get("group_chat_id")

        if not group_chat_id:
            return create_response("error", "Group ID is required.", status_code=400)

        # Ensure the group exists
        group = GroupChat.query.get(group_chat_id)
        if not group:
            return create_response("error", "Group not found.", status_code=404)

        # Ensure the current user is an admin
        is_admin = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=current_user.id, is_admin=True
        ).first()
        if not is_admin:
            return create_response(
                "error", "Only admins can delete this group.", status_code=403
            )

        # Delete group (cascade removes messages and members)
        db.session.delete(group)
        db.session.commit()

        return create_response(
            "success",
            "Group deleted successfully.",
            {"group_chat_id": group_chat_id},
            status_code=200,
        )

    except SQLAlchemyError:
        db.session.rollback()
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception:
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


@group_chat_blueprint.route("/group/member-count", methods=["GET"])
@login_required
def get_group_member_count():
    """
    Returns the total number of members in a group.
    """
    try:
        group_chat_id = request.args.get("group_chat_id")
        logger.info(f"Request received: Get member count for group {group_chat_id}")

        if not group_chat_id:
            logger.warning("Missing required field: group_chat_id")
            return create_response(
                "error", "Group chat ID is required.", status_code=400
            )

        # ✅ Check if the group exists
        group = GroupChat.query.get(group_chat_id)
        if not group:
            logger.warning(f"Group chat not found: {group_chat_id}")
            return create_response("error", "Group chat not found.", status_code=404)

        # ✅ Count the total members
        total_members = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id
        ).count()

        logger.info(f"Total members in group {group_chat_id}: {total_members}")

        return create_response(
            "success",
            "Group member count retrieved successfully.",
            {"group_id": group_chat_id, "total_members": total_members},
            status_code=200,
        )

    except SQLAlchemyError as db_error:
        logger.error(f"Database error in get_group_member_count: {db_error}")
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        logger.error(f"Unexpected error in get_group_member_count: {e}")
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


@group_chat_blueprint.route("/group/members", methods=["GET"])
@login_required
def get_group_members():
    """
    Returns the total number of members in a group along with their details.
    """
    try:
        group_chat_id = request.args.get("group_chat_id")
        logger.info(f"Request received: Get member details for group {group_chat_id}")

        if not group_chat_id:
            logger.warning("Missing required field: group_chat_id")
            return create_response(
                "error", "Group chat ID is required.", status_code=400
            )

        # ✅ Check if the group exists
        group = GroupChat.query.get(group_chat_id)
        if not group:
            logger.warning(f"Group chat not found: {group_chat_id}")
            return create_response("error", "Group chat not found.", status_code=404)

        # ✅ Get all members of the group
        members = (
            db.session.query(
                User.id,
                User.first_name,
                User.last_name,
                User.username,
                User.email,
                User.profile_picture_url,
                GroupChatMember.role,
            )
            .join(GroupChatMember, User.id == GroupChatMember.user_id)
            .filter(GroupChatMember.group_chat_id == group_chat_id)
            .all()
        )

        if not members:
            logger.warning(f"No members found in group {group_chat_id}")

        # ✅ Format response
        members_list = [
            {
                "id": member.id,
                "first_name": member.first_name,
                "last_name": member.last_name,
                "username": member.username,
                "email": member.email,
                "profile_picture_url": member.profile_picture_url,
                "role": member.role.value,  # Convert Enum to string
            }
            for member in members
        ]

        logger.info(f"Retrieved {len(members_list)} members from group {group_chat_id}")

        return create_response(
            "success",
            "Group members retrieved successfully.",
            {
                "group_id": group_chat_id,
                "total_members": len(members_list),
                "members": members_list,
            },
            status_code=200,
        )

    except SQLAlchemyError as db_error:
        logger.error(f"Database error in get_group_members: {db_error}")
        return create_response("error", "Database error occurred.", status_code=500)
    except Exception as e:
        logger.error(f"Unexpected error in get_group_members: {e}")
        return create_response(
            "error", "An unexpected error occurred.", status_code=500
        )


@group_chat_blueprint.route("/group-chat/edit-message/<int:message_id>", methods=["PUT"])
@login_required
def edit_group_message(message_id):
    """
    Edits a message in a group chat.
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
        message = GroupMessage.query.get(message_id)
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

@group_chat_blueprint.route("/invite/generate", methods=["POST"])
@login_required
def generate_invite_link():
    """
    Allows group owner/admin to generate an invite link.
    """
    try:
        data = request.json
        group_chat_id = data.get("group_chat_id")

        if not group_chat_id:
            return create_response("error", "Group ID is required.", status_code=400)

        group = GroupChat.query.get(group_chat_id)
        if not group:
            return create_response("error", "Group not found.", status_code=404)

        membership = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=current_user.id
        ).first()

        if not membership or membership.role not in [RoleEnum.OWNER, RoleEnum.ADMIN]:
            return create_response("error", "You are not authorized to generate links.", status_code=403)

        # Token creation (optionally add expiration)
        from itsdangerous import URLSafeTimedSerializer
        serializer = URLSafeTimedSerializer(current_app.config["SECRET_KEY"])
        token = serializer.dumps({"group_chat_id": group_chat_id}, salt="group-invite")

        invite_link = f"{request.host_url}api/v1/group/invite/join?token={token}"

        return create_response("success", "Invite link generated.", {"invite_link": invite_link}, 200)

    except Exception as e:
        logger.exception("Failed to generate invite link")
        return create_response("error", "An error occurred.", status_code=500)


@group_chat_blueprint.route("/invite/join/<token>", methods=["GET"])
@login_required
def join_group_via_link(token):
    """
    Allows a user to join a group using an invite token.
    """
    try:
        from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired

        serializer = URLSafeTimedSerializer(current_app.config["SECRET_KEY"])
        data = serializer.loads(token, salt="group-invite", max_age=86400)  # 1 day valid

        group_chat_id = data.get("group_chat_id")
        group = GroupChat.query.get(group_chat_id)
        if not group:
            return create_response("error", "Invalid or expired link.", 404)

        existing_member = GroupChatMember.query.filter_by(
            group_chat_id=group_chat_id, user_id=current_user.id
        ).first()

        if existing_member:
            return create_response("success", "You are already a member of this group.", status_code=200)

        new_member = GroupChatMember(
            group_chat_id=group_chat_id,
            user_id=current_user.id,
            role=RoleEnum.MEMBER
        )
        db.session.add(new_member)
        db.session.commit()

        handle_join_group({"group_chat_id": group_chat_id, "user_id": current_user.id})

        return create_response("success", "You have joined the group successfully.", status_code=200)

    except SignatureExpired:
        return create_response("error", "Invite link has expired.", status_code=400)
    except BadSignature:
        return create_response("error", "Invalid invite link.", status_code=400)
    except Exception:
        logger.exception("Failed to join group via invite")
        return create_response("error", "An unexpected error occurred.", status_code=500)
