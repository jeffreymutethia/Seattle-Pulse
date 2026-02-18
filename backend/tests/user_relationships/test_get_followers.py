import pytest
from unittest.mock import patch, MagicMock
from flask import url_for


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
def test_get_followers_success(mock_user_query, mock_get_user, client_authenticated):
    """Test retrieving users that follow the current user successfully."""
    mock_user = MagicMock(is_authenticated=True, id=1)
    mock_get_user.return_value = mock_user

    # Mock the returned followers list
    mock_followers = [
        MagicMock(
            id=2,
            username="follower_2",
            profile_picture_url="https://example.com/follower2.jpg",
            bio="Follower Bio 2",
        ),
        MagicMock(
            id=3,
            username="follower_3",
            profile_picture_url="https://example.com/follower3.jpg",
            bio="Follower Bio 3",
        ),
    ]

    # Corrected: Use mock_user.followers.all() to return the mock followers
    mock_user.followers.all.return_value = mock_followers

    response = client_authenticated.get(url_for("user_relationships_v1.get_followers"))
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["status"] == "success"
    assert json_data["total"] == 2
    assert len(json_data["users"]) == 2
    assert json_data["users"][0]["id"] == 2
    assert json_data["users"][0]["username"] == "follower_2"
    assert (
        json_data["users"][0]["profile_picture_url"]
        == "https://example.com/follower2.jpg"
    )
    assert json_data["users"][0]["bio"] == "Follower Bio 2"


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
def test_get_followers_empty(mock_user_query, mock_get_user, client_authenticated):
    """Test retrieving an empty followers list (user has no followers)."""
    mock_user = MagicMock(is_authenticated=True, id=1)
    mock_get_user.return_value = mock_user

    # Corrected: Use mock_user.followers.all() to return an empty list
    mock_user.followers.all.return_value = []

    response = client_authenticated.get(url_for("user_relationships_v1.get_followers"))
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["status"] == "success"
    assert json_data["total"] == 0
    assert json_data["users"] == []  # Empty list expected
