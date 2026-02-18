import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import UserContent


@pytest.fixture
def test_user_locations(session, test_user):
    """Creates test user content with locations."""
    contents = [
        UserContent(
            title="Test Post 1",
            body="Test content 1",  # ✅ Ensure body is not None
            location="Seattle",
            latitude=47.6062,
            longitude=-122.3321,
            user_id=test_user.id,
        ),
        UserContent(
            title="Test Post 2",
            body="Test content 2",  # ✅ Ensure body is not None
            location="Bellevue",
            latitude=47.6101,
            longitude=-122.2015,
            user_id=test_user.id,
        ),
    ]
    session.add_all(contents)
    session.commit()
    return contents


@patch("flask_login.utils._get_user")
def test_get_user_locations_by_id_authenticated(
    mock_get_user, client_authenticated, test_user, test_user_locations
):
    """Test retrieving locations for a specific user (authenticated)."""
    mock_get_user.return_value = MagicMock(is_authenticated=True)

    response = client_authenticated.get(
        url_for("content_v1.get_user_locations_by_id", user_id=test_user.id)
    )
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["success"] == "success"
    assert len(json_data["data"]["locations"]) == len(test_user_locations)
    assert isinstance(
        json_data["data"]["center"], (dict, type(None))
    )  # ✅ Accept None or dict


@patch("flask_login.utils._get_user")
@patch("app.models.UserContent.query")
def test_get_user_locations_by_id_empty(
    mock_query, mock_get_user, client_authenticated, test_user
):
    """Test retrieving locations for a user with no posts."""
    mock_get_user.return_value = MagicMock(is_authenticated=True)
    mock_query.filter_by.return_value.all.return_value = []  # Simulate no posts

    response = client_authenticated.get(
        url_for("content_v1.get_user_locations_by_id", user_id=test_user.id)
    )
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["success"] == "success"
    assert json_data["data"]["locations"] == []
    assert json_data["data"]["center"] in [None, {}]  # ✅ Handle both cases


def test_get_user_locations_by_id_unauthenticated(client, test_user):
    """Test retrieving locations while unauthenticated (should fail)."""
    response = client.get(
        url_for("content_v1.get_user_locations_by_id", user_id=test_user.id)
    )
    json_data = response.get_json()

    assert response.status_code == 401
    assert json_data.get("error") == "Unauthorized"
    assert json_data.get("message") == "You must be logged in to access this resource."


@patch("flask_login.utils._get_user")
@patch("app.models.UserContent.query")
def test_get_user_locations_by_id_database_failure(
    mock_query, mock_get_user, client_authenticated, test_user
):
    """Test API handling a database error."""
    mock_get_user.return_value = MagicMock(is_authenticated=True)
    mock_query.filter_by.side_effect = Exception(
        "Database error"
    )  # Simulate DB failure

    response = client_authenticated.get(
        url_for("content_v1.get_user_locations_by_id", user_id=test_user.id)
    )
    json_data = response.get_json()

    assert response.status_code == 500
    assert json_data["success"] == "error"
    assert json_data["message"] == "Failed to retrieve user locations"
