import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import User, Repost
from flask_login import AnonymousUserMixin


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
    mock_user.email = "test@example.com"
    mock_user.is_authenticated = True  # Ensure authentication
    return mock_user


@patch("flask_login.utils._get_user")
@patch("app.models.Repost.query")
@patch("app.db.session.commit")  # Mock database commit
@patch("app.db.session.delete")  # Mock database delete
def test_undo_repost_success(
    mock_db_delete,
    mock_db_commit,
    mock_repost_query,
    mock_get_user,
    mock_current_user,
    client,
    app_context,
):
    """Test successfully undoing a repost."""

    # ✅ 1. Mock authenticated user
    mock_get_user.return_value = mock_current_user

    # ✅ 2. Mock an existing repost
    mock_repost = MagicMock(spec=Repost)
    mock_repost.user_id = mock_current_user.id
    mock_repost.content_id = 101  # Content being reposted

    mock_repost_query.filter_by.return_value.first.return_value = mock_repost

    # 🔥 3. Send DELETE request
    response = client.delete(url_for("profile_v1.undo_repost", content_id=101))

    # ✅ 4. Validate response status
    assert response.status_code == 200, f"Unexpected response: {response.get_json()}"

    data = response.get_json()

    # ✅ 5. Validate success message
    assert data["success"] == "success"
    assert data["message"] == "Repost removed successfully"

    # ✅ 6. Ensure database delete & commit were called
    mock_db_delete.assert_called_once_with(mock_repost)
    mock_db_commit.assert_called_once()


@patch("flask_login.utils._get_user")
@patch("app.models.Repost.query")
def test_undo_repost_not_found(
    mock_repost_query, mock_get_user, mock_current_user, client
):
    """Test attempting to undo a repost that does not exist (404)."""

    # ✅ 1. Mock authenticated user
    mock_get_user.return_value = mock_current_user

    # ✅ 2. Simulate no repost found
    mock_repost_query.filter_by.return_value.first.return_value = None

    # 🔥 3. Send DELETE request
    response = client.delete(url_for("profile_v1.undo_repost", content_id=101))

    # ✅ 4. Validate 404 Not Found
    assert response.status_code == 404, f"Unexpected response: {response.get_json()}"

    data = response.get_json()

    # ✅ 5. Validate error message
    assert data["success"] == "error"
    assert data["message"] == "Repost not found"


@patch("flask_login.utils._get_user")
def test_undo_repost_unauthenticated(mock_get_user, client):
    """Test accessing the endpoint without authentication (should return 401)."""

    # ❌ 1. Simulate an unauthenticated request
    mock_get_user.return_value = (
        AnonymousUserMixin()
    )  # Flask-Login's way of handling unauthenticated users

    # 🔥 2. Send DELETE request without authentication
    response = client.delete(url_for("profile_v1.undo_repost", content_id=101))

    # ✅ 3. Validate 401 Unauthorized
    assert response.status_code == 401, f"Unexpected response: {response.get_json()}"

    data = response.get_json()

    # ✅ 4. Validate error message
    assert data["error"] == "Unauthorized"
    assert data["message"] == "You must be logged in to access this resource."


@patch("flask_login.utils._get_user")
@patch("app.models.Repost.query")
@patch("app.db.session.commit")
@patch("app.db.session.delete")
def test_undo_repost_server_error(
    mock_db_delete,
    mock_db_commit,
    mock_repost_query,
    mock_get_user,
    mock_current_user,
    client,
):
    """Test handling an unexpected server error when undoing a repost."""

    # ✅ 1. Mock authenticated user
    mock_get_user.return_value = mock_current_user

    # ✅ 2. Mock an existing repost
    mock_repost = MagicMock(spec=Repost)
    mock_repost.user_id = mock_current_user.id
    mock_repost.content_id = 101

    mock_repost_query.filter_by.return_value.first.return_value = mock_repost

    # ❌ 3. Simulate a database error
    mock_db_commit.side_effect = Exception("Database error")

    # 🔥 4. Send DELETE request
    response = client.delete(url_for("profile_v1.undo_repost", content_id=101))

    # ✅ 5. Validate 500 Internal Server Error
    assert response.status_code == 500, f"Unexpected response: {response.get_json()}"

    data = response.get_json()

    # ✅ 6. Validate error message
    assert data["success"] == "error"
    assert data["message"] == "Failed to remove repost"
