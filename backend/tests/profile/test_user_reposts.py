import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import User, UserContent, Repost
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


# @patch("flask_login.utils._get_user")
# @patch("app.models.User.query")
# @patch("app.models.Repost.query")
# @patch("app.models.UserContent.query")
# @patch("app.api.profile.serialize_user_content")
# def test_get_user_reposts_success(
#     mock_serialize_user_content,
#     mock_content_query,
#     mock_repost_query,
#     mock_user_query,
#     mock_get_user,
#     mock_current_user,
#     client,
# ):
#     """Test successfully fetching a user's reposts."""

#     # ✅ 1. Mock an authenticated user
#     mock_get_user.return_value = mock_current_user

#     # ✅ 2. Mock user retrieval
#     mock_user = MagicMock(spec=User)
#     mock_user.id = mock_current_user.id
#     mock_user.username = mock_current_user.username

#     mock_user_query.filter_by.return_value.first_or_404.return_value = mock_user

#     # ✅ 3. Mock reposted content
#     mock_repost_1 = MagicMock(spec=Repost)
#     mock_repost_1.user_id = mock_user.id
#     mock_repost_1.content_id = 101
#     mock_repost_1.thoughts = "Interesting post!"

#     mock_repost_2 = MagicMock(spec=Repost)
#     mock_repost_2.user_id = mock_user.id
#     mock_repost_2.content_id = 102
#     mock_repost_2.thoughts = "Great insights!"

#     # ✅ 4. Mock original content (The actual post being reposted)
#     mock_content_1 = MagicMock(spec=UserContent)
#     mock_content_1.id = 101
#     mock_content_1.title = "Original Post 1"

#     mock_content_2 = MagicMock(spec=UserContent)
#     mock_content_2.id = 102
#     mock_content_2.title = "Original Post 2"

#     # ✅ 5. Mock pagination
#     mock_paginate = MagicMock()
#     mock_paginate.items = [
#         (mock_content_1, mock_repost_1.thoughts),
#         (mock_content_2, mock_repost_2.thoughts),
#     ]
#     mock_paginate.page = 1
#     mock_paginate.pages = 2
#     mock_paginate.total = 10
#     mock_paginate.has_next = True
#     mock_paginate.has_prev = False

#     # ✅ 6. Ensure mock query returns results
#     mock_repost_query.join.return_value.filter.return_value.order_by.return_value.paginate.return_value = (
#         mock_paginate
#     )

#     # ✅ 7. Mock serialization
#     def mock_serialize(content, thoughts):
#         return {
#             "id": content.id,
#             "title": content.title,
#             "thoughts": thoughts,
#         }

#     mock_serialize_user_content.side_effect = mock_serialize

#     # 🔥 8. Send API request
#     response = client.get(url_for("profile_v1.get_user_reposts", username="testuser"))

#     # ✅ 9. Validate response status
#     assert response.status_code == 200, f"Unexpected response: {response.get_json()}"

#     data = response.get_json()

#     # ✅ 10. Validate success message
#     assert data["success"] == "success"
#     assert data["message"] == "User reposts fetched successfully"

#     # ✅ 11. Validate reposts structure
#     assert len(data["data"]["reposts"]) == 2
#     assert data["data"]["reposts"][0]["id"] == 101
#     assert data["data"]["reposts"][1]["id"] == 102
#     assert data["data"]["reposts"][0]["title"] == "Original Post 1"
#     assert data["data"]["reposts"][1]["title"] == "Original Post 2"
#     assert data["data"]["reposts"][0]["thoughts"] == "Interesting post!"
#     assert data["data"]["reposts"][1]["thoughts"] == "Great insights!"

#     # ✅ 12. Validate pagination data
#     assert data["data"]["pagination"]["current_page"] == 1
#     assert data["data"]["pagination"]["total_pages"] == 2
#     assert data["data"]["pagination"]["total_items"] == 10
#     assert data["data"]["pagination"]["has_next"] is True
#     assert data["data"]["pagination"]["has_prev"] is False


@patch("flask_login.utils._get_user")
@patch("app.models.User.query")
@patch("app.models.Repost.query")
def test_get_user_reposts_no_reposts(
    mock_repost_query, mock_user_query, mock_get_user, mock_current_user, client
):
    """Test fetching reposts when the user has no reposts (200 OK but no data)."""

    # ✅ 1. Mock an authenticated user
    mock_get_user.return_value = mock_current_user

    # ✅ 2. Mock user retrieval
    mock_user_query.filter_by.return_value.first_or_404.return_value = mock_current_user

    # ✅ 3. Simulate no reposts
    mock_paginate = MagicMock()
    mock_paginate.items = []
    mock_paginate.page = 1
    mock_paginate.pages = 1
    mock_paginate.total = 0
    mock_paginate.has_next = False
    mock_paginate.has_prev = False

    # ✅ 4. Set up mock query chain
    mock_repost_query.join.return_value.filter.return_value.order_by.return_value.paginate.return_value = (
        mock_paginate
    )

    # 🔥 5. Send API request
    response = client.get(url_for("profile_v1.get_user_reposts", username="testuser"))

    # ✅ 6. Validate response status
    assert response.status_code == 200, f"Unexpected response: {response.get_json()}"

    data = response.get_json()

    # ✅ 7. Validate empty response
    assert data["success"] == "success"
    assert data["message"] == "No reposts found."
    assert data["data"]["reposts"] == []
    assert data["data"]["pagination"]["total_items"] == 0


@patch("flask_login.utils._get_user")
def test_get_user_reposts_unauthenticated(mock_get_user, client):
    """Test trying to access reposts without authentication (should return 401)."""

    # ❌ 1. Simulate an unauthenticated request
    mock_get_user.return_value = (
        AnonymousUserMixin()
    )  # Flask-Login's way of handling unauthenticated users

    # 🔥 2. Send API request without authentication
    response = client.get(url_for("profile_v1.get_user_reposts", username="testuser"))

    # ✅ 3. Validate 401 Unauthorized
    assert response.status_code == 401, f"Unexpected response: {response.get_json()}"

    data = response.get_json()

    # ✅ 4. Validate error message
    assert data["error"] == "Unauthorized"
    assert data["message"] == "You must be logged in to access this resource."


@patch("flask_login.utils._get_user")
@patch("app.models.Repost.query")
def test_get_user_reposts_server_error(
    mock_repost_query, mock_get_user, mock_current_user, client
):
    """Test handling an unexpected server error when fetching reposts."""

    # ✅ 1. Mock an authenticated user
    mock_get_user.return_value = mock_current_user

    # ❌ 2. Simulate a database error
    mock_repost_query.join.return_value.filter.side_effect = Exception("Database error")

    # 🔥 3. Send API request
    response = client.get(url_for("profile_v1.get_user_reposts", username="testuser"))

    # ✅ 4. Validate 500 Internal Server Error
    assert response.status_code == 500, f"Unexpected response: {response.get_json()}"

    data = response.get_json()

    # ✅ 5. Validate error message
    assert data["success"] == "error"
    assert data["message"] == "Failed to fetch user reposts"
