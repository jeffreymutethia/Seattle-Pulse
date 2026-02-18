from __future__ import annotations

import uuid

from flask import Blueprint, current_app, jsonify, request
from werkzeug.exceptions import NotFound

from app.models import User, UserContent, db


def _ensure_testing():
    if not current_app.config.get("TESTING"):
        raise NotFound()


def _build_seed_user(username: str, email: str) -> User:
    user = User(
        first_name="Seed",
        last_name="User",
        username=username,
        email=email,
        is_email_verified=True,
        accepted_terms_and_conditions=True,
    )
    user.set_password("TestPassword123!")
    return user


def _create_seed_post(user_id: int, title: str, location: str, *, is_in_seattle: bool, latitude: float, longitude: float) -> UserContent:
    post = UserContent(
        title=title,
        body=f"Seed content for {location}",
        user_id=user_id,
        unique_id=uuid.uuid4().int % 10**10,
        location=location,
        latitude=latitude,
        longitude=longitude,
        thumbnail="https://example.com/seed-thumbnail.jpg",
        is_in_seattle=is_in_seattle,
    )
    return post


test_seed_v1_blueprint = Blueprint("test_seed_v1", __name__, url_prefix="/api/v1/test_seed")


@test_seed_v1_blueprint.route("/locations", methods=["POST"])
def seed_locations():
    _ensure_testing()

    payload = request.get_json(silent=True) or {}
    username = payload.get("username", f"seed_{uuid.uuid4().hex[:8]}")
    email = payload.get("email", f"{uuid.uuid4().hex[:8]}@example.com")

    user = _build_seed_user(username, email)
    db.session.add(user)
    db.session.commit()

    posts = [
        _create_seed_post(
            user.id,
            "Queen Anne fixture",
            "Queen Anne, Seattle",
            is_in_seattle=True,
            latitude=47.6379,
            longitude=-122.3560,
        ),
        _create_seed_post(
            user.id,
            "NYC fixture",
            "New York, NY",
            is_in_seattle=False,
            latitude=40.7128,
            longitude=-74.0060,
        ),
        _create_seed_post(
            user.id,
            "Addis fixture",
            "Addis Ababa, Ethiopia",
            is_in_seattle=False,
            latitude=8.9806,
            longitude=38.7578,
        ),
    ]

    for post in posts:
        db.session.add(post)
    db.session.commit()

    return (
        jsonify(
            {
                "user_id": user.id,
                "username": user.username,
                "posts": [
                    {
                        "id": post.id,
                        "location": post.location,
                        "is_in_seattle": post.is_in_seattle,
                    }
                    for post in posts
                ],
            }
        ),
        201,
    )


@test_seed_v1_blueprint.route("/locations/<int:user_id>", methods=["DELETE"])
def clear_seed_locations(user_id: int):
    _ensure_testing()

    user = User.query.filter_by(id=user_id).first()
    if not user:
        raise NotFound()

    UserContent.query.filter_by(user_id=user.id).delete()
    db.session.delete(user)
    db.session.commit()

    return jsonify({"status": "deleted"}), 200
