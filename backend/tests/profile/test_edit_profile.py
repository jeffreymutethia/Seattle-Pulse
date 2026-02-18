import pytest
import json
import base64
from unittest.mock import patch, MagicMock
from io import BytesIO
from flask import url_for, current_app
from app.models import User, db
from flask_login import AnonymousUserMixin


@pytest.fixture
def client(app):
    """Provide a test client."""
    return app.test_client()


@pytest.fixture
def mock_current_user():
    """Mock authenticated user."""
    mock_user = MagicMock(spec=User)
    mock_user.id = 1
    mock_user.username = "testuser"
    mock_user.email = "test@example.com"
    mock_user.bio = "This is a bio."
    mock_user.profile_picture_url = "https://example.com/default-profile.jpg"
    return mock_user


@pytest.fixture
def authenticated_client(client, session):
    """Provides an authenticated test client with a mock user."""
    user = User(
        name="Test User",
        username="testuser",
        email="test@example.com",
        accepted_terms_and_conditions=True,
    )
    user.set_password("SecurePass123")
    session.add(user)
    session.commit()

    with client.session_transaction() as sess:
        sess["_user_id"] = str(user.id)  # Simulating login session

    return client, user


@patch("flask.current_app.s3_client.upload_fileobj")  # ✅ Corrected patching
@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
@patch("app.db.session.commit")
def test_edit_profile_success(
    mock_db_commit,
    mock_user_query,
    mock_get_user,
    mock_current_user,  # ✅ Use mock_current_user instead
    client,  # ✅ Use client fixture directly
    app,  # ✅ Inject Flask app fixture
):
    """Test successful profile update."""

    # ✅ Ensure the test runs inside the Flask application context
    with app.app_context():
        mock_get_user.return_value = mock_current_user  # ✅ Use mock instead of DB user
        mock_user_query.filter_by.return_value.first.side_effect = [
            None,
            None,
        ]  # No conflicts

        # ✅ Mock S3 upload inside `current_app` context
        with patch("flask.current_app.s3_client.upload_fileobj", return_value=None):
            # ✅ Simulated Base64 encoded image data
            fake_image = base64.b64encode(b"fake-image-data").decode("utf-8")
            base64_image = f"data:image/png;base64,{fake_image}"

            updated_data = {
                "name": "Updated Name",
                "username": "updateduser",
                "email": "updated@example.com",
                "bio": "Updated bio.",
                "cropped_image": base64_image,
            }

            response = client.post(
                url_for("profile_v1.edit_profile_api"),
                data=json.dumps(updated_data),
                content_type="application/json",
            )

            assert (
                response.status_code == 200
            ), f"Unexpected response: {response.get_json()}"
            assert response.get_json()["status"] == "success"
            assert response.get_json()["message"] == "Your profile has been updated!"


@patch("flask_login.utils._get_user")
def test_edit_profile_unauthenticated(mock_get_user, client):
    """Test profile update when user is not authenticated."""

    # ✅ Simulate an unauthenticated user by returning an AnonymousUserMixin
    mock_get_user.return_value = AnonymousUserMixin()

    # 🔥 Send the request without authentication
    response = client.post(url_for("profile_v1.edit_profile_api"), json={})

    # ✅ Validate the response
    assert response.status_code == 401, f"Unexpected response: {response.get_json()}"

    data = response.get_json()

    # ✅ Check if 'error' and 'message' exist instead of 'status'
    assert "error" in data, f"'error' key not found in response: {data}"
    assert "message" in data, f"'message' key not found in response: {data}"
    assert data["error"] == "Unauthorized"
    assert data["message"] == "You must be logged in to access this resource."


@patch("flask_login.utils._get_user")
def test_edit_profile_missing_fields(mock_get_user, client, mock_current_user):
    """Test profile update with missing required fields."""
    mock_get_user.return_value = mock_current_user

    incomplete_data = {"name": "New Name"}  # Missing username, email, and bio

    response = client.post(
        url_for("profile_v1.edit_profile_api"),
        data=json.dumps(incomplete_data),
        content_type="application/json",
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["status"] == "error"
    assert "username is required." in data["message"]


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
def test_edit_profile_username_conflict(
    mock_user_query, mock_get_user, client, mock_current_user
):
    """Test profile update when username is already taken by another user."""
    mock_get_user.return_value = mock_current_user
    conflicting_user = MagicMock(spec=User)
    conflicting_user.id = 2  # Different user with same username
    mock_user_query.filter_by.return_value.first.return_value = conflicting_user

    update_data = {
        "name": "Updated Name",
        "username": "existinguser",
        "email": "newemail@example.com",
        "bio": "Updated bio.",
    }

    response = client.post(
        url_for("profile_v1.edit_profile_api"),
        data=json.dumps(update_data),
        content_type="application/json",
    )

    assert response.status_code == 409
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "Username already in use."


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
def test_edit_profile_email_conflict(
    mock_user_query, mock_get_user, client, mock_current_user
):
    """Test profile update when email is already taken by another user."""
    mock_get_user.return_value = mock_current_user
    conflicting_user = MagicMock(spec=User)
    conflicting_user.id = 2  # Different user with same email
    mock_user_query.filter_by.return_value.first.side_effect = [None, conflicting_user]

    update_data = {
        "name": "Updated Name",
        "username": "newusername",
        "email": "existing@example.com",
        "bio": "Updated bio.",
    }

    response = client.post(
        url_for("profile_v1.edit_profile_api"),
        data=json.dumps(update_data),
        content_type="application/json",
    )

    assert response.status_code == 409
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "Email already in use."


@patch("flask_login.utils._get_user")
def test_edit_profile_invalid_json(mock_get_user, client, mock_current_user):
    """Test profile update with Invalid JSON payload provided.."""
    mock_get_user.return_value = mock_current_user

    response = client.post(
        url_for("profile_v1.edit_profile_api"),
        data="Invalid JSON",
        content_type="application/json",
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "Malformed JSON. Check your request body."


@patch("flask_login.utils._get_user")
@patch("app.db.session.commit")
def test_edit_profile_database_error(
    mock_db_commit, mock_get_user, client, mock_current_user
):
    """Test profile update failure due to database error."""
    mock_get_user.return_value = mock_current_user
    mock_db_commit.side_effect = Exception("Database error")

    update_data = {
        "name": "Updated Name",
        "username": "newusername",
        "email": "new@example.com",
        "bio": "Updated bio.",
    }

    response = client.post(
        url_for("profile_v1.edit_profile_api"),
        data=json.dumps(update_data),
        content_type="application/json",
    )

    assert response.status_code == 500
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "An error occurred while updating your profile."
