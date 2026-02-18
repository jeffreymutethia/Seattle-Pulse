import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import UserContent, News, Comment, Reaction, Repost, CommentReaction


@pytest.fixture
def content(session, test_user):
    """Creates a test user content for detail tests."""
    content = UserContent(
        user_id=test_user.id,
        title="Test Content",
        body="This is a test content body.",
        unique_id="12345",
    )
    session.add(content)
    session.commit()
    return content


@pytest.fixture
def news_content(session):
    """Creates a test news content."""
    news = News(
        unique_id="news_001",
        title="Test News",
        body="This is a test news article.",
        link="https://example.com",
    )
    session.add(news)
    session.commit()
    return news


@pytest.fixture
def comments(session, test_user, content):
    """Creates multiple test comments for pagination testing."""
    comments = []
    for i in range(15):  # ✅ Ensure content_type is not NULL
        comment = Comment(
            content_id=content.id,
            user_id=test_user.id,
            content=f"Comment {i}",
            content_type="text",
        )
        session.add(comment)
        comments.append(comment)
    session.commit()
    return comments


@patch("flask_login.utils._get_user")
def test_content_detail_unauthenticated(mock_get_user, client, content):
    """Test content detail when user is not authenticated (should return 401)."""

    mock_user = MagicMock()
    mock_user.is_authenticated = False
    mock_get_user.return_value = mock_user

    response = client.get(
        url_for(
            "content_v1.get_content_detail",
            content_type="user_content",
            content_id=content.id,
        )
    )
    assert response.status_code == 401, f"Unexpected response: {response.get_json()}"


# ✅ 2️⃣ Content Retrieval Tests
def test_content_detail_not_found(client_authenticated):
    """Test content detail when content does not exist."""
    response = client_authenticated.get(
        url_for(
            "content_v1.get_content_detail", content_type="user_content", content_id=999
        )
    )
    json_data = response.get_json()

    assert response.status_code == 404
    assert json_data["success"] == "error"
    assert json_data["message"] == "Content not found"


# ✅ 3️⃣ Pagination & Comments
def test_content_detail_no_comments(client_authenticated, content):
    """Test content detail when there are no comments."""
    response = client_authenticated.get(
        url_for(
            "content_v1.get_content_detail",
            content_type="user_content",
            content_id=content.id,
        )
    )
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["success"] == "success"
    assert json_data["data"]["total_comments"] == 0
    assert json_data["data"]["comments"] == []


def test_content_detail_with_repost(client_authenticated, content, session, test_user):
    """Test content detail when user has reposted content."""
    repost = Repost(user_id=test_user.id, content_id=content.id)
    session.add(repost)
    session.commit()

    response = client_authenticated.get(
        url_for(
            "content_v1.get_content_detail",
            content_type="user_content",
            content_id=content.id,
        )
    )
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["data"]["has_user_reposted"] is True
