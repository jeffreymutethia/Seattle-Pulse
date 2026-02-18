import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import UserContent


@pytest.fixture
def test_user_content_with_locations(session, test_user):
    """Creates user content with different locations for the test user."""
    contents = [
        UserContent(
            title=f"Post {i}",
            body=f"Content for post {i}",
            user_id=test_user.id,
            location=f"Location {i}",
            latitude=47.60 + i * 0.01,  # Slight variations in lat/lon
            longitude=-122.33 - i * 0.01,
        )
        for i in range(5)  # Create 5 test posts with locations
    ]
    session.add_all(contents)
    session.commit()
    return contents


@patch(
    "app.api.content.calculate_center",
    return_value={"latitude": 47.61, "longitude": -122.32},
)
def test_get_user_locations_authenticated(
    mock_center, client_authenticated, test_user_content_with_locations
):
    """Test retrieving user locations when authenticated."""
    response = client_authenticated.get(url_for("content_v1.get_user_locations"))
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data.get("success") == "success"
    assert "data" in json_data
    assert isinstance(json_data["data"]["locations"], list)
    assert len(json_data["data"]["locations"]) == 5  # Expect 5 locations
    assert "center" in json_data["data"]
    assert json_data["data"]["center"] == {"latitude": 47.61, "longitude": -122.32}


def test_get_user_locations_unauthenticated(client):
    """Test unauthenticated user trying to retrieve locations."""
    response = client.get(url_for("content_v1.get_user_locations"))
    json_data = response.get_json()

    assert response.status_code == 401  # ✅ Ensure correct status code
    assert (
        json_data.get("error") == "Unauthorized"
    )  # ✅ Check for correct error message
    assert json_data.get("message") == "You must be logged in to access this resource."


@patch("app.models.UserContent.query")
def test_get_user_locations_empty(mock_query, client_authenticated):
    """Test retrieving user locations when no posts exist."""
    mock_query.filter_by.return_value.all.return_value = []  # Simulate no posts

    response = client_authenticated.get(url_for("content_v1.get_user_locations"))
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data.get("success") == "success"
    assert json_data["data"]["locations"] == []  # Expect an empty list
    assert json_data["data"].get("center") is None  # ✅ Correct check for None


@patch("app.models.UserContent.query")
def test_get_user_locations_database_error(mock_query, client_authenticated):
    """Test handling of database errors while fetching locations."""
    mock_query.filter_by.side_effect = Exception("Database error")

    response = client_authenticated.get(url_for("content_v1.get_user_locations"))
    json_data = response.get_json()

    assert response.status_code == 500
    assert json_data.get("success") == "error"  # ✅ Use .get() to avoid KeyError
    assert json_data.get("message") == "Failed to retrieve user locations"
