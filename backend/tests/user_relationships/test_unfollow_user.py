import pytest
from unittest.mock import patch, MagicMock
from flask import url_for


@patch("flask_login.utils._get_user")
@patch("app.models.User.query.get")
def test_unfollow_user_not_found(
    mock_get_user, mock_get_user_session, client_authenticated
):
    """Test trying to unfollow a non-existent user (should return 404)."""
    mock_user = MagicMock(is_authenticated=True, id=1)
    mock_get_user_session.return_value = mock_user  # Ensure logged-in user exists

    mock_get_user.return_value = None  # Simulate user not found

    response = client_authenticated.post(
        url_for("user_relationships_v1.unfollow_user", user_id=999)
    )
    json_data = response.get_json()

    assert response.status_code == 404
    assert json_data["status"] == "error"
    assert json_data["message"] == "User not found"
