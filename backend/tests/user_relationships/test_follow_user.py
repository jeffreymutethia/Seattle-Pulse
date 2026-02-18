import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.api.user_relationships import follow_user


@pytest.fixture
def target_user():
    """Fixture to create a mock target user for testing follow actions."""
    user = MagicMock()
    user.id = 2  # Ensure it has an ID
    user.username = "target_user"
    return user


"""
============================== TEST FOLLOW USER ==============================
"""


@patch("flask_login.utils._get_user")
@patch("app.models.User.query.get", return_value=None)  # Simulate user not found
def test_follow_user_not_found(
    mock_get_user_query, mock_get_user, client_authenticated
):
    """Test trying to follow a non-existent user."""
    mock_get_user.return_value = MagicMock(is_authenticated=True, id=1)

    response = client_authenticated.post(
        url_for("user_relationships_v1.follow_user", user_id=9999)
    )
    json_data = response.get_json()

    assert response.status_code == 404
    assert json_data["status"] == "error"
    assert json_data["message"] == "User not found"


@patch("flask_login.utils._get_user")
@patch("app.models.User.query.get")
def test_follow_user_self_follow(
    mock_get_user_query, mock_get_user, client_authenticated, test_user
):
    """Test trying to follow oneself."""
    mock_user = MagicMock(is_authenticated=True, id=test_user.id)
    mock_get_user.return_value = mock_user
    mock_get_user_query.return_value = test_user

    response = client_authenticated.post(
        url_for("user_relationships_v1.follow_user", user_id=test_user.id)
    )
    json_data = response.get_json()

    assert response.status_code == 400
    assert json_data["status"] == "error"
    assert json_data["message"] == "You cannot follow yourself"
