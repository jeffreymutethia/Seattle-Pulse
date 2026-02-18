import pytest
from flask import url_for
from app.models import UserContent, Comment


@pytest.fixture
def content(session, test_user):
    """Creates a test content for MyPulse detail tests."""
    content = UserContent(
        user_id=test_user.id, title="Test Content", body="This is a test content body."
    )
    session.add(content)
    session.commit()
    return content


@pytest.fixture
def comments(session, test_user, content):
    """Creates multiple test comments for pagination testing."""
    comments = []
    for i in range(15):  # ✅ Ensure content_type is not NULL
        comment = Comment(
            content_id=content.id,
            user_id=test_user.id,
            content=f"Comment {i}",
            content_type="text",  # ✅ Ensure this field is set
        )
        session.add(comment)
        comments.append(comment)
    session.commit()
    return comments


def test_mypulse_detail_content_not_found(client_authenticated):
    """Test MyPulse detail when content does not exist."""
    response = client_authenticated.get(
        url_for("feed_v1.mypulse_detail", content_id=999)
    )
    json_data = response.get_json()

    assert response.status_code == 404
    assert json_data["success"] == "error"
    assert json_data["message"] == "Content not found"


def test_mypulse_detail_no_comments(client_authenticated, content):
    """Test MyPulse detail when content has no comments."""
    response = client_authenticated.get(
        url_for("feed_v1.mypulse_detail", content_id=content.id)
    )
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["success"] == "success"
    assert json_data["data"]["total_comments"] == 0
    assert json_data["data"]["comments"] == []


def test_mypulse_detail_pagination(client_authenticated, comments, content):
    """Test pagination when there are multiple comments."""
    response = client_authenticated.get(
        url_for("feed_v1.mypulse_detail", content_id=content.id, page=1, per_page=10)
    )
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["success"] == "success"
    assert json_data["data"]["pagination"]["total_items"] == 15
    assert json_data["data"]["pagination"]["total_pages"] >= 2
    assert json_data["data"]["pagination"]["has_next"] is True
    assert json_data["data"]["pagination"]["has_prev"] is False


def test_mypulse_detail_blocked_user(client_authenticated, content, session, test_user):
    """Test MyPulse detail when user is blocked by the content owner."""
    from app.models import Block

    blocked = Block(blocker_id=content.user_id, blocked_id=test_user.id)
    session.add(blocked)
    session.commit()

    response = client_authenticated.get(
        url_for("feed_v1.mypulse_detail", content_id=content.id)
    )
    json_data = response.get_json()

    assert response.status_code == 403
    assert json_data["success"] == "error"
    assert json_data["message"] == "You are not authorized to view this content"


def test_mypulse_detail_success(client_authenticated, comments, content):
    """Test MyPulse detail success response."""
    response = client_authenticated.get(
        url_for("feed_v1.mypulse_detail", content_id=content.id)
    )
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["success"] == "success"
    assert json_data["message"] == "Content details fetched successfully"
    assert json_data["data"]["id"] == content.id
    assert json_data["data"]["total_comments"] == len(comments)
