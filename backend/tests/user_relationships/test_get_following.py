import pytest
from unittest.mock import patch, MagicMock
from flask import url_for


import pytest
from unittest.mock import patch, MagicMock
from flask import url_for


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
def test_get_following_success(mock_user_query, mock_get_user, client_authenticated):
    """Test retrieving users that the current user is following successfully."""
    mock_user = MagicMock(is_authenticated=True, id=1)
    mock_get_user.return_value = mock_user

    # Mock the returned users list
    mock_following_users = [
        MagicMock(
            id=2,
            username="user_2",
            profile_picture_url="https://example.com/user2.jpg",
            bio="Bio 2",
        ),
        MagicMock(
            id=3,
            username="user_3",
            profile_picture_url="https://example.com/user3.jpg",
            bio="Bio 3",
        ),
    ]

    # Mock database query behavior
    mock_follow_query = MagicMock()
    mock_follow_query.all.return_value = mock_following_users
    mock_user_query.join.return_value.filter.return_value = mock_follow_query

    response = client_authenticated.get(url_for("user_relationships_v1.get_following"))
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["status"] == "success"
    assert json_data["total"] == 2
    assert len(json_data["users"]) == 2
    assert json_data["users"][0]["id"] == 2
    assert json_data["users"][0]["username"] == "user_2"
    assert (
        json_data["users"][0]["profile_picture_url"] == "https://example.com/user2.jpg"
    )
    assert json_data["users"][0]["bio"] == "Bio 2"


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
def test_get_following_empty(mock_user_query, mock_get_user, client_authenticated):
    """Test retrieving an empty following list (user follows no one)."""
    mock_user = MagicMock(is_authenticated=True, id=1)
    mock_get_user.return_value = mock_user

    # Mock empty list return
    mock_follow_query = MagicMock()
    mock_follow_query.all.return_value = []
    mock_user_query.join.return_value.filter.return_value = mock_follow_query

    response = client_authenticated.get(url_for("user_relationships_v1.get_following"))
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["status"] == "success"
    assert json_data["total"] == 0
    assert json_data["users"] == []  # Empty list expected


@patch("flask_login.utils._get_user")
@patch("app.models.User.query.join")  # Mock User query join
def test_get_following_empty(mock_user_query, mock_get_user, client_authenticated):
    """Test retrieving an empty following list (user follows no one)."""
    mock_user = MagicMock(is_authenticated=True, id=1)
    mock_get_user.return_value = mock_user

    # Mock empty list return
    mock_query_filter = MagicMock()
    mock_query_filter.all.return_value = []
    mock_user_query.return_value.filter.return_value = (
        mock_query_filter  # Mock filter query
    )

    response = client_authenticated.get(url_for("user_relationships_v1.get_following"))
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["status"] == "success"
    assert json_data["total"] == 0
    assert json_data["users"] == []  # Empty list expected

 