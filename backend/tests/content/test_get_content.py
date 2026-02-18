import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import User, UserContent, Reaction, Comment, Repost, Share
from datetime import datetime, timedelta
from app.api.content import fetch_high_score_content  # Import function
from types import SimpleNamespace


@pytest.fixture
def client(app):
    """Provide a test client."""
    return app.test_client()


@pytest.fixture
def mock_current_user():
    """Mock an authenticated user."""
    mock_user = MagicMock(spec=User)
    mock_user.id = 1
    mock_user.username = "testuser"
    return mock_user


# ✅ 1️⃣ Authentication Tests
@patch("flask_login.utils._get_user")
def test_content_authenticated(mock_get_user, client, mock_current_user):
    """Test `get_content` endpoint with authentication."""
    mock_get_user.return_value = mock_current_user
    response = client.get(url_for("content_v1.get_content"))
    assert response.status_code == 200, f"Unexpected response: {response.get_json()}"


@patch("flask_login.utils._get_user")
def test_content_unauthenticated(mock_get_user, client):
    """Test `get_content` endpoint without authentication (should return 401)."""

    mock_user = MagicMock()
    mock_user.is_authenticated = False
    mock_get_user.return_value = mock_user

    response = client.get(url_for("content_v1.get_content"))

    assert response.status_code == 401, f"Unexpected response: {response.get_json()}"


# ✅ 2️⃣ Location Filtering Tests
@patch("flask_login.utils._get_user")
@patch("app.models.UserContent.query")
def test_content_filter_location(
    mock_content_query, mock_get_user, client, mock_current_user
):
    """Test filtering content by location (Seattle)."""
    mock_get_user.return_value = mock_current_user

    mock_paginate = MagicMock()
    mock_paginate.items = [
        MagicMock(spec=UserContent, location="Seattle") for _ in range(5)
    ]

    mock_content_query.filter.return_value.paginate.return_value = mock_paginate

    response = client.get(url_for("content_v1.get_content", location="Seattle"))
    data = response.get_json()

    assert response.status_code == 200
    assert all(post["location"] == "Seattle" for post in data["data"]["content"])


@patch("flask_login.utils._get_user")
@patch("app.models.UserContent.query")
def test_content_filter_invalid_location(
    mock_content_query, mock_get_user, client, mock_current_user
):
    """Test filtering with an invalid location (should return an empty list)."""
    mock_get_user.return_value = mock_current_user

    mock_paginate = MagicMock()
    mock_paginate.items = []

    mock_content_query.filter.return_value.paginate.return_value = mock_paginate

    response = client.get(url_for("content_v1.get_content", location="InvalidCity"))
    data = response.get_json()

    assert response.status_code == 200
    assert len(data["data"]["content"]) == 0


# ✅ 3️⃣ Database Query Behavior
@patch("flask_login.utils._get_user")
@patch("app.models.UserContent.query")
def test_content_no_content(
    mock_content_query, mock_get_user, client, mock_current_user
):
    """Test case when no content is available (should return an empty response)."""
    mock_get_user.return_value = mock_current_user
    mock_content_query.all.return_value = []  # Simulate empty database

    response = client.get(url_for("content_v1.get_content"))
    data = response.get_json()

    assert response.status_code == 200
    assert len(data["data"]["content"]) == 0


# ✅ 4️⃣ Handling Database Failures
@patch("flask_login.utils._get_user")
@patch("app.models.Reaction.query")
@patch("app.models.Repost.query")
@patch("app.api.content.fetch_high_score_content")
def test_content_database_failure(
    mock_fetch_high_score_content,
    mock_repost_query,
    mock_reaction_query,
    mock_get_user,
    mock_current_user,
    client,
):
    """Test handling of a database failure when fetching content."""

    mock_get_user.return_value = mock_current_user

    # Simulate database failure
    mock_fetch_high_score_content.side_effect = Exception("Database error")

    response = client.get(url_for("content_v1.get_content"))
    data = response.get_json()

    assert response.status_code == 500
    assert data["success"] == "error"
    assert "Failed to fetch content" in data["message"]


@patch("flask_login.utils._get_user")
@patch("app.api.content.fetch_high_score_content")
def test_avoid_consecutive_sources_on_feed(
    mock_fetch_high_score_content,
    mock_get_user,
    client,
    mock_current_user,
):
    """Ensure feed reorders posts to avoid consecutive sources."""
    mock_get_user.return_value = mock_current_user

    now = datetime.utcnow()

    def make_item(id_, user_id):
        return SimpleNamespace(
            id=id_,
            title=f"Post {id_}",
            body="",
            location="Seattle",
            created_at=now,
            updated_at=now,
            thumbnail="",
            user_id=user_id,
            username=f"user{user_id}",
            profile_picture_url="",
            is_seeded=True,
            seed_type="news",
            seeded_likes_count=0,
            seeded_comments_count=0,
            news_link="",
            score=1.0,
        )

    items = [make_item(1, 1), make_item(2, 1), make_item(3, 2)]
    mock_fetch_high_score_content.return_value = (items, len(items))

    resp = client.get(url_for("content_v1.get_content"))
    data = resp.get_json()

    user_ids = [c["user"]["id"] for c in data["data"]["content"]]
    assert resp.status_code == 200
    assert user_ids == [1, 2, 1]


@patch("flask_login.utils._get_user")
@patch("app.api.content.fetch_high_score_content")
def test_latest_post_per_source_only(
    mock_fetch_high_score_content,
    mock_get_user,
    client,
    mock_current_user,
):
    """Ensure feed includes only the most recent post per source."""
    mock_get_user.return_value = mock_current_user

    now = datetime.utcnow()

    def make_item(id_, user_id, minutes):
        t = now - timedelta(minutes=minutes)
        return SimpleNamespace(
            id=id_,
            title=f"Post {id_}",
            body="",
            location="Seattle",
            created_at=t,
            updated_at=t,
            thumbnail="",
            user_id=user_id,
            username=f"user{user_id}",
            profile_picture_url="",
            is_seeded=True,
            seed_type="news",
            seeded_likes_count=0,
            seeded_comments_count=0,
            news_link="",
            score=1.0,
        )

    items = [make_item(1, 1, 10), make_item(2, 1, 5), make_item(3, 2, 8)]
    mock_fetch_high_score_content.return_value = (items, len(items))

    resp = client.get(url_for("content_v1.get_content"))
    data = resp.get_json()

    ids = [c["id"] for c in data["data"]["content"]]
    user_ids = [c["user"]["id"] for c in data["data"]["content"]]

    assert resp.status_code == 200
    assert ids == [2, 3]
    assert user_ids == [1, 2]
