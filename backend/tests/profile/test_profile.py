import pytest
import json
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import User, UserContent


@pytest.fixture
def client(app):
    """Provide a test client."""
    return app.test_client()


@pytest.fixture
def mock_current_user():
    """Mock an authenticated user with real attributes."""
    mock_user = MagicMock(spec=User)
    mock_user.id = 1
    mock_user.username = "testuser"
    mock_user.email = "test@example.com"
    mock_user.bio = "This is a test bio."
    mock_user.profile_picture_url = "https://example.com/test.jpg"
    mock_user.name = "Test User"

    # Mock relationship counts
    mock_user.followers = MagicMock()
    mock_user.followers.count.return_value = 5  # ✅ Returns an integer

    mock_user.followed = MagicMock()
    mock_user.followed.count.return_value = 3  # ✅ Returns an integer

    mock_user.is_following = MagicMock(
        return_value=False
    )  # Ensure proper boolean value
    return mock_user


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
@patch("app.models.UserContent.query")
@patch(
    "app.api.profile.serialize_user",
    return_value={
        "id": 2,
        "username": "profileuser",
        "email": "profile@example.com",
        "bio": "Profile user bio.",
        "profile_picture_url": "https://example.com/profile.jpg",
        "name": "Profile User",
    },
)
def test_get_user_profile_success(
    mock_serialize_user,
    mock_user_content_query,
    mock_user_query,
    mock_get_user,
    mock_current_user,
    client,
    app_context,
):
    """Test successful user profile retrieval."""

    # ✅ Mock user returned from the database
    mock_user = MagicMock(spec=User)
    mock_user.id = 2  # Profile being accessed
    mock_user.username = "profileuser"
    mock_user.email = "profile@example.com"
    mock_user.bio = "Profile user bio."

    # ✅ Ensure followers and following return real integers
    mock_user.followers = MagicMock()
    mock_user.followers.count.return_value = 5  # ✅ Returns an integer

    mock_user.followed = MagicMock()
    mock_user.followed.count.return_value = 3  # ✅ Returns an integer

    # ✅ Ensure total_posts returns an integer
    mock_user_content_query.filter_by.return_value.count.return_value = (
        10  # ✅ Returns 10 posts
    )

    mock_user_query.filter_by.return_value.first_or_404.return_value = mock_user
    mock_get_user.return_value = mock_current_user  # ✅ Ensure current user is returned

    response = client.get(
        url_for("profile_v1.get_user_profile", username="profileuser")
    )

    assert response.status_code == 200
    data = response.get_json()

    assert data["success"] == "success"
    assert data["message"] == "User profile fetched successfully"
    assert "data" in data
    assert data["data"]["user_data"]["username"] == "profileuser"
    assert data["data"]["relationships"]["total_posts"] == 10
    assert data["data"]["relationships"]["followers"] == 5
    assert data["data"]["relationships"]["following"] == 3
    assert data["data"]["is_following"] is False  # Since mock user is different


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
def test_get_user_profile_not_found(
    mock_user_query, mock_get_user, mock_current_user, client, app_context
):
    """Test user profile retrieval when the user does not exist."""

    mock_user_query.filter_by.return_value.first_or_404.side_effect = Exception(
        "User not found"
    )

    # ✅ Mock the current user
    mock_get_user.return_value = mock_current_user

    response = client.get(
        url_for("profile_v1.get_user_profile", username="unknownuser")
    )

    assert response.status_code == 500
    data = response.get_json()
    assert data["success"] == "error"
    assert data["message"] == "Failed to fetch user profile"


def test_get_user_profile_unauthenticated(client):
    """Test user profile retrieval when unauthenticated."""

    response = client.get(
        url_for("profile_v1.get_user_profile", username="profileuser")
    )

    assert response.status_code == 401
    data = response.get_json()
    assert "You must be logged in to access this resource." in data["message"]
