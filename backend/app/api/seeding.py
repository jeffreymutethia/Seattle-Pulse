from flask import Blueprint, jsonify, current_app
from app.models import (
    db,
    User,
    DirectChat,
    DirectMessage,
    GroupChat,
    GroupChatMember,
    GroupMessage,
)
from faker import Faker
import random
import logging

seeding_blueprint = Blueprint("seeding", __name__, url_prefix="/api/v1/seeding")

fake = Faker()

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def create_random_user():
    try:
        email = fake.email()
        username = fake.user_name()

        existing_user = User.query.filter(
            (User.email == email) | (User.username == username)
        ).first()
        if existing_user:
            return existing_user

        user = User(
            first_name=fake.first_name(),
            last_name=fake.last_name(),
            username=username,
            email=email,
            profile_picture_url=f"https://picsum.photos/640/480?random={random.randint(1, 10000)}",
            bio=fake.sentence(),
            is_email_verified=True,
            accepted_terms_and_conditions=True,
        )
        user.set_password("Strong1!")
        db.session.add(user)
        db.session.commit()
        logger.info(f"Created user: {username}")
        return user
    except Exception as e:
        logger.error(f"Error creating user: {str(e)}")
        return None


def create_direct_chat(user1, user2):
    try:
        existing_chat = DirectChat.query.filter(
            ((DirectChat.user1_id == user1.id) & (DirectChat.user2_id == user2.id))
            | ((DirectChat.user1_id == user2.id) & (DirectChat.user2_id == user1.id))
        ).first()

        if existing_chat:
            return existing_chat

        chat = DirectChat(user1_id=user1.id, user2_id=user2.id)
        db.session.add(chat)
        db.session.commit()
        logger.info(
            f"Created direct chat between {user1.username} and {user2.username}"
        )
        return chat
    except Exception as e:
        logger.error(f"Error creating direct chat: {str(e)}")
        return None


def create_direct_message(chat, sender):
    try:
        message = DirectMessage(
            chat_id=chat.id, sender_id=sender.id, content=fake.text()
        )
        db.session.add(message)
        db.session.commit()
        logger.info(f"Message sent by {sender.username} in chat {chat.id}")
    except Exception as e:
        logger.error(f"Error sending direct message: {str(e)}")


def add_user_to_group_chat(group_chat, user, is_admin=False):
    try:
        membership = GroupChatMember(
            group_chat_id=group_chat.id, user_id=user.id, is_admin=is_admin
        )
        db.session.add(membership)
        db.session.commit()
        logger.info(f"Added {user.username} to group chat {group_chat.name}")
    except Exception as e:
        logger.error(f"Error adding user to group chat: {str(e)}")


def seed_users(count=10):
    users = [create_random_user() for _ in range(count)]
    return jsonify({"message": f"Seeded {count} users successfully"})


def seed_chats(count=5):
    users = User.query.all()
    for _ in range(count):
        user1, user2 = random.sample(users, 2)
        create_direct_chat(user1, user2)
    return jsonify({"message": f"Seeded {count} direct chats successfully"})


def seed_messages(count=10):
    chats = DirectChat.query.all()
    for _ in range(count):
        chat = random.choice(chats)
        sender = random.choice([chat.user1, chat.user2])
        create_direct_message(chat, sender)
    return jsonify({"message": f"Seeded {count} direct messages successfully"})


def seed_group_chat():
    users = User.query.all()
    group_chat = GroupChat(name=fake.company(), created_by=random.choice(users).id)
    db.session.add(group_chat)
    db.session.commit()
    for user in users:
        add_user_to_group_chat(group_chat, user)
    return jsonify({"message": f"Created group chat {group_chat.name} successfully"})


@seeding_blueprint.route("/init", methods=["POST"])
def seed_all():
    seed_users()
    seed_chats()
    seed_messages()
    seed_group_chat()
    return jsonify({"message": "Database fully seeded successfully"})


@seeding_blueprint.route("/users/<int:count>", methods=["POST"])
def api_seed_users(count):
    return seed_users(count)


@seeding_blueprint.route("/chats/<int:count>", methods=["POST"])
def api_seed_chats(count):
    return seed_chats(count)


@seeding_blueprint.route("/messages/<int:count>", methods=["POST"])
def api_seed_messages(count):
    return seed_messages(count)


@seeding_blueprint.route("/group-chat", methods=["POST"])
def api_seed_group_chat():
    return seed_group_chat()
