import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import UserContent, Repost


@pytest.fixture
def test_content(session, test_user):
    """Creates test content for reposting."""
    content = UserContent(
        title="Original Post",
        body="This is an original post",
        user_id=test_user.id,
        location="Seattle",
        latitude=47.6062,
        longitude=-122.3321,
    )
    session.add(content)
    session.commit()
    return content


@pytest.fixture
def test_repost(session, test_user, test_content):
    """Creates a repost record."""
    repost = Repost(
        user_id=test_user.id, content_id=test_content.id, thoughts="Reposted!"
    )
    session.add(repost)
    session.commit()
    return repost


@patch("flask_login.utils._get_user")
def test_undo_repost_success(
    mock_get_user, client_authenticated, test_user, test_content, test_repost
):
    """Test successfully undoing a repost."""
    mock_user = MagicMock()
    mock_user.is_authenticated = True
    mock_user.id = test_user.id  # ✅ Use actual user ID instead of MagicMock
    mock_get_user.return_value = mock_user

    response = client_authenticated.post(
        url_for("content_v1.undo_repost_content", content_id=test_content.id)
    )
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["success"] == "success"
    assert json_data["message"] == "Repost undone successfully"
    assert json_data["data"]["content_id"] == test_content.id


def test_undo_repost_unauthenticated(client, test_content):
    """Test undoing a repost while unauthenticated (should fail)."""
    response = client.post(
        url_for("content_v1.undo_repost_content", content_id=test_content.id)
    )
    json_data = response.get_json()

    assert response.status_code == 401
    assert json_data.get("error") == "Unauthorized"
    assert json_data.get("message") == "You must be logged in to access this resource."


@patch("flask_login.utils._get_user")
def test_undo_repost_content_not_found(mock_get_user, client_authenticated, test_user):
    """Test undoing a repost for a content ID that does not exist (should return 404)."""
    mock_user = MagicMock()
    mock_user.is_authenticated = True
    mock_user.id = test_user.id  # ✅ Use actual user ID instead of MagicMock
    mock_get_user.return_value = mock_user

    response = client_authenticated.post(
        url_for(
            "content_v1.undo_repost_content", content_id=9999
        )  # Non-existent content ID
    )
    json_data = response.get_json()

    assert response.status_code == 404
    assert json_data["success"] == "error"
    assert json_data["message"] == "Content not found"


@patch("flask_login.utils._get_user")
def test_undo_repost_not_reposted(
    mock_get_user, client_authenticated, test_user, test_content
):
    """Test undoing a repost when the user has not reposted (should return 404)."""
    mock_user = MagicMock()
    mock_user.is_authenticated = True
    mock_user.id = test_user.id  # ✅ Use actual user ID instead of MagicMock
    mock_get_user.return_value = mock_user

    response = client_authenticated.post(
        url_for(
            "content_v1.undo_repost_content", content_id=test_content.id
        )  # No repost exists
    )
    json_data = response.get_json()

    assert response.status_code == 404
    assert json_data["success"] == "error"
    assert json_data["message"] == "Repost not found"


@patch("flask_login.utils._get_user")
@patch("app.models.Repost.query")
def test_undo_repost_database_failure(
    mock_query, mock_get_user, client_authenticated, test_user, test_content
):
    """Test API handling a database failure (should return 500)."""
    mock_user = MagicMock()
    mock_user.is_authenticated = True
    mock_user.id = test_user.id  # ✅ Use actual user ID instead of MagicMock
    mock_get_user.return_value = mock_user

    mock_query.filter_by.side_effect = Exception(
        "Database error"
    )  # Simulate DB failure

    response = client_authenticated.post(
        url_for("content_v1.undo_repost_content", content_id=test_content.id)
    )
    json_data = response.get_json()

    assert response.status_code == 500
    assert json_data["success"] == "error"
    assert json_data["message"] == "Failed to undo repost"
