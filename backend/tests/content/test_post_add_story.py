import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import UserContent, db


# ✅ 1️⃣ Fixture: Mock Authenticated User
@pytest.fixture
def authenticated_user():
    """Fixture to create a mock authenticated user."""
    user = MagicMock(id=1, is_authenticated=True)
    return user


# ✅ 3️⃣ Validation Tests
@patch("flask_login.utils._get_user")
def test_post_add_story_missing_required_fields(mock_get_user, client_authenticated):
    """Test missing required fields (title, body) results in a 400 error."""
    mock_get_user.return_value = MagicMock(is_authenticated=True)

    payload = {"title": "Test Story"}  # Missing "body"

    response = client_authenticated.post(
        url_for("content_v1.post_add_story"), json=payload
    )
    json_data = response.get_json()

    assert response.status_code == 400
    assert json_data["success"] == "error"
    assert "You have missed these fields" in json_data["message"]


@patch("flask_login.utils._get_user")
def test_post_add_story_missing_location(mock_get_user, client_authenticated):
    """Test missing location data results in a 400 error."""
    mock_get_user.return_value = MagicMock(is_authenticated=True)

    payload = {
        "title": "Story Without Location",
        "body": "This story has no location data.",
    }  # Missing latitude, longitude, and location

    response = client_authenticated.post(
        url_for("content_v1.post_add_story"), json=payload
    )
    json_data = response.get_json()

    assert response.status_code == 400
    assert json_data["success"] == "error"
    assert "Location data is required" in json_data["message"]


@patch("flask_login.utils._get_user")
def test_post_add_story_only_latitude(mock_get_user, client_authenticated):
    """Test providing only latitude or only longitude results in a 400 error."""
    mock_get_user.return_value = MagicMock(is_authenticated=True)

    payload = {
        "title": "Invalid Story",
        "body": "Only one coordinate provided.",
        "latitude": 47.6062,  # No longitude
    }

    response = client_authenticated.post(
        url_for("content_v1.post_add_story"), json=payload
    )
    json_data = response.get_json()

    assert response.status_code == 400
    assert (
        "Both latitude and longitude must be provided together" in json_data["message"]
    )


@patch("flask_login.utils._get_user")
@patch("app.api.content.is_location_in_seattle", return_value=False)
def test_post_add_story_invalid_geolocation(
    mock_location_check, mock_get_user, client_authenticated
):
    """Test adding a story with an invalid (outside Seattle) location."""
    mock_get_user.return_value = MagicMock(is_authenticated=True)

    payload = {
        "title": "Outside Seattle",
        "body": "Story from outside Seattle.",
        "latitude": 40.7128,  # New York City coordinates
        "longitude": -74.0060,
    }

    response = client_authenticated.post(
        url_for("content_v1.post_add_story"), json=payload
    )
    json_data = response.get_json()

    assert response.status_code == 400
    assert json_data["success"] == "error"
    assert "The specified location is outside Seattle" in json_data["message"]


# ✅ 5️⃣ Database & Error Handling
@patch("flask_login.utils._get_user")
@patch("app.api.content.db.session.commit", side_effect=Exception("Database error"))
def test_post_add_story_database_failure(
    mock_db_commit, mock_get_user, client_authenticated
):
    """Test handling of database failure when adding a story."""
    mock_get_user.return_value = MagicMock(is_authenticated=True)

    payload = {
        "title": "Database Error Test",
        "body": "This should trigger a database error.",
        "latitude": 47.6062,
        "longitude": -122.3321,
    }

    response = client_authenticated.post(
        url_for("content_v1.post_add_story"), json=payload
    )
    json_data = response.get_json()

    assert response.status_code == 500
    assert json_data["success"] == "error"
    assert "Failed to add story" in json_data["message"]


@patch("flask_login.utils._get_user")
@patch(
    "app.api.content.get_neighborhood", side_effect=Exception("Unexpected API Error")
)
def test_post_add_story_server_error(
    mock_get_neighborhood, mock_get_user, client_authenticated
):
    """Test handling of unexpected server errors."""
    mock_get_user.return_value = MagicMock(is_authenticated=True)

    payload = {
        "title": "Unexpected Error Test",
        "body": "This should trigger a server error.",
        "latitude": 47.6062,
        "longitude": -122.3321,
    }

    response = client_authenticated.post(
        url_for("content_v1.post_add_story"), json=payload
    )
    json_data = response.get_json()

    assert response.status_code == 500
    assert json_data["success"] == "error"
    assert "Failed to add story" in json_data["message"]
