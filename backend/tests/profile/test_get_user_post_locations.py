import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import User, UserContent
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
    mock_user.bio = "This is a test bio."
    mock_user.is_authenticated = True  # Ensure authentication
    return mock_user


@patch("flask_login.utils._get_user")  # Ensures authentication is required
@patch("app.models.User.query")
@patch("app.models.UserContent.query")
def test_get_user_location_success(
    mock_content_query,
    mock_user_query,
    mock_get_user,
    mock_current_user,
    client,
    app_context,
):
    """Test fetching a user's post locations successfully with authentication."""

    # ✅ 1. Mock an authenticated user
    mock_get_user.return_value = mock_current_user  # Simulates an authenticated session

    # ✅ 2. Mock user retrieval
    mock_user = MagicMock(spec=User)
    mock_user.id = mock_current_user.id  # Accessing own profile
    mock_user.username = mock_current_user.username
    mock_user.is_authenticated = True

    mock_user_query.filter_by.return_value.first_or_404.return_value = mock_user

    # ✅ 3. Mock user content (posts with locations)
    mock_post_1 = MagicMock(spec=UserContent)
    mock_post_1.id = 101
    mock_post_1.title = "Post with Location 1"
    mock_post_1.location = "New York, USA"

    mock_post_2 = MagicMock(spec=UserContent)
    mock_post_2.id = 102
    mock_post_2.title = "Post with Location 2"
    mock_post_2.location = "Paris, France"

    # ✅ 4. Mock pagination setup
    mock_paginate = MagicMock()
    mock_paginate.items = [mock_post_1, mock_post_2]
    mock_paginate.page = 1
    mock_paginate.pages = 2
    mock_paginate.total = 10
    mock_paginate.has_next = True
    mock_paginate.has_prev = False

    # ✅ 5. Set up mock query chain
    mock_content_query.filter.return_value.paginate.return_value = mock_paginate

    # 🔥 6. Send API request (Ensuring Authentication)
    with client:
        client.environ_base["HTTP_AUTHORIZATION"] = "Bearer testtoken"
        response = client.get(
            url_for("profile_v1.get_user_location", username="testuser")
        )

    # ✅ 7. Validate response status
    assert response.status_code == 200, f"Unexpected response: {response.get_json()}"

    data = response.get_json()

    # ✅ 8. Validate success message
    assert data["success"] == "success"
    assert data["message"] == "User locations fetched successfully"

    # ✅ 9. Validate locations structure
    assert len(data["data"]["locations"]) == 2
    assert data["data"]["locations"][0]["post_id"] == 101
    assert data["data"]["locations"][0]["title"] == "Post with Location 1"
    assert data["data"]["locations"][0]["location"] == "New York, USA"
    assert data["data"]["locations"][1]["post_id"] == 102
    assert data["data"]["locations"][1]["title"] == "Post with Location 2"
    assert data["data"]["locations"][1]["location"] == "Paris, France"

    # ✅ 10. Validate pagination data
    assert data["data"]["pagination"]["current_page"] == 1
    assert data["data"]["pagination"]["total_pages"] == 2
    assert data["data"]["pagination"]["total_items"] == 10
    assert data["data"]["pagination"]["has_next"] is True
    assert data["data"]["pagination"]["has_prev"] is False


@patch("flask_login.utils._get_user")
def test_get_user_location_unauthenticated(mock_get_user, client):
    """Test access to the location endpoint without authentication (should return 401)."""

    # ❌ 1. Simulate an unauthenticated request using `AnonymousUserMixin`
    mock_get_user.return_value = (
        AnonymousUserMixin()
    )  # Flask-Login's way of handling unauthenticated users

    # 🔥 2. Send API request without authentication
    response = client.get(url_for("profile_v1.get_user_location", username="testuser"))

    # ✅ 3. Validate 401 Unauthorized status
    assert response.status_code == 401, f"Unexpected response: {response.get_json()}"

    data = response.get_json()

    # ✅ 4. Validate error message
    assert data["error"] == "Unauthorized"
    assert data["message"] == "You must be logged in to access this resource."
