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
def test_repost_content_success(
    mock_get_user, client_authenticated, test_user, test_content
):
    """Test successful reposting of content."""
    mock_user = MagicMock()
    mock_user.is_authenticated = True
    mock_user.id = test_user.id  # ✅ Use actual user ID instead of MagicMock
    mock_get_user.return_value = mock_user

    response = client_authenticated.post(
        url_for("content_v1.repost_content", content_id=test_content.id),
        json={"thoughts": "Excited to share this!"},
    )
    json_data = response.get_json()

    assert response.status_code == 201
    assert json_data["success"] == "success"
    assert json_data["message"] == "Content reposted successfully"
    assert json_data["data"]["content_id"] == test_content.id
    assert json_data["data"]["thoughts"] == "Excited to share this!"


def test_repost_content_unauthenticated(client, test_content):
    """Test reposting content while unauthenticated (should fail)."""
    response = client.post(
        url_for("content_v1.repost_content", content_id=test_content.id),
        json={"thoughts": "Great post!"},
    )
    json_data = response.get_json()

    assert response.status_code == 401
    assert json_data.get("error") == "Unauthorized"
    assert json_data.get("message") == "You must be logged in to access this resource."


@patch("flask_login.utils._get_user")
def test_repost_content_not_found(mock_get_user, client_authenticated, test_user):
    """Test reposting content that does not exist (should return 404)."""
    mock_user = MagicMock()
    mock_user.is_authenticated = True
    mock_user.id = test_user.id  # ✅ Use actual user ID instead of MagicMock
    mock_get_user.return_value = mock_user

    response = client_authenticated.post(
        url_for(
            "content_v1.repost_content", content_id=9999
        ),  # Non-existent content ID
        json={"thoughts": "Sharing this!"},
    )
    json_data = response.get_json()

    assert response.status_code == 404
    assert json_data["success"] == "error"
    assert json_data["message"] == "Content not found"


@patch("flask_login.utils._get_user")
def test_repost_content_already_reposted(
    mock_get_user, client_authenticated, test_user, test_content, test_repost
):
    """Test reposting already reposted content (should return 409 conflict)."""
    mock_user = MagicMock()
    mock_user.is_authenticated = True
    mock_user.id = test_user.id  # ✅ Use actual user ID instead of MagicMock
    mock_get_user.return_value = mock_user

    response = client_authenticated.post(
        url_for("content_v1.repost_content", content_id=test_content.id),
        json={"thoughts": "Reposting again!"},
    )
    json_data = response.get_json()

    assert response.status_code == 409
    assert json_data["success"] == "error"
    assert json_data["message"] == "Content already reposted"


@patch("flask_login.utils._get_user")
@patch("app.models.Repost.query")
def test_repost_content_database_failure(
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
        url_for("content_v1.repost_content", content_id=test_content.id),
        json={"thoughts": "Database might fail!"},
    )
    json_data = response.get_json()

    assert response.status_code == 500
    assert json_data["success"] == "error"
    assert json_data["message"] == "Failed to repost content"
