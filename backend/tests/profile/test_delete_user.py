import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import User, OTP, UserDeletionLog
from flask_login import AnonymousUserMixin


@pytest.fixture
def client(app):
    """Provide a test client."""
    return app.test_client()


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
def test_delete_user_not_found(mock_user_query, mock_get_user, client):
    """Test deleting a non-existent user."""

    mock_get_user.return_value = MagicMock(spec=User, id=1)

    # ❌ Simulate user not found
    mock_user_query.filter_by.return_value.first.return_value = None

    response = client.delete(
        url_for("profile_v1.delete_user"),
        json={
            "username": "nonexistent",
            "reason": "No longer needed",
        },
    )

    # ✅ Validate response
    assert response.status_code == 404
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "User not found."


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
def test_delete_user_unauthorized(mock_user_query, mock_get_user, client):
    """Test attempting to delete another user's account (Unauthorized)."""

    mock_current_user = MagicMock(spec=User, id=1)
    mock_target_user = MagicMock(spec=User, id=2)

    mock_get_user.return_value = mock_current_user
    mock_user_query.filter_by.return_value.first.return_value = mock_target_user

    response = client.delete(
        url_for("profile_v1.delete_user"),
        json={
            "username": "targetuser",
            "reason": "No longer needed",
        },
    )

    # ✅ Validate response
    assert response.status_code == 403
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "Unauthorized action."


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
@patch("app.models.UserDeletionLog")
@patch("app.db.session.commit")
def test_delete_user_logging_error(
    mock_commit, mock_deletion_log, mock_user_query, mock_get_user, client
):
    """Test failure when logging the user deletion."""

    mock_user = MagicMock(spec=User, id=1)
    mock_get_user.return_value = mock_user
    mock_user_query.filter_by.return_value.first.return_value = mock_user

    # ❌ Simulate log insert failure
    mock_commit.side_effect = Exception("DB commit failed")

    response = client.delete(
        url_for("profile_v1.delete_user"),
        json={
            "username": "testuser",
            "reason": "No longer needed",
        },
    )

    # ✅ Validate response
    assert response.status_code == 500
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "Failed to log user deletion."
