import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import User, UserContent, Comment, Reaction
from app.api.profile import serialize_user_content


@pytest.fixture
def client(app):
    """Provide a test client."""
    return app.test_client()


@patch("app.models.User.query")
@patch("app.models.UserContent.query")
@patch("app.models.Comment.query")
@patch("app.models.Reaction.query")
def test_get_user_posts_success(
    mock_reaction_query, mock_comment_query, mock_content_query, mock_user_query, client
):
    """Test fetching a user's posts successfully with pagination."""

    # ✅ Mock user instance
    mock_user = MagicMock(spec=User)
    mock_user.id = 1
    mock_user.username = "testuser"

    # ✅ Ensure `query.filter_by().first_or_404()` returns the mocked user
    mock_user_query.filter_by.return_value.first_or_404.return_value = mock_user

    # ✅ Mock paginated posts
    mock_post_1 = MagicMock(spec=UserContent, id=101)
    mock_post_2 = MagicMock(spec=UserContent, id=102)

    mock_paginate = MagicMock()
    mock_paginate.items = [mock_post_1, mock_post_2]
    mock_paginate.page = 1
    mock_paginate.pages = 2
    mock_paginate.total = 15
    mock_paginate.has_next = True
    mock_paginate.has_prev = False

    mock_content_query.filter_by.return_value.order_by.return_value.paginate.return_value = (
        mock_paginate
    )

    # ✅ Mock comment & reaction counts
    mock_comment_query.filter_by.return_value.count.side_effect = [
        5,
        3,
    ]  # 5 comments for post 1, 3 for post 2
    mock_reaction_query.filter_by.return_value.count.side_effect = [
        20,
        15,
    ]  # 20 likes for post 1, 15 for post 2

    # ✅ Corrected mock path for `serialize_user_content`
    with patch("app.api.profile.serialize_user_content") as mock_serialize:
        mock_serialize.side_effect = lambda post: {
            "id": post.id,
            "content": f"Post {post.id}",
        }

        # 🔥 Send request
        response = client.get(url_for("profile_v1.get_user_posts", username="testuser"))

        # ✅ Validate response
        assert (
            response.status_code == 200
        ), f"Unexpected response: {response.get_json()}"
        data = response.get_json()
        assert data["success"] == "success"
        assert data["message"] == "User posts fetched successfully"

        # ✅ Validate posts structure
        assert len(data["data"]["posts"]) == 2
        assert data["data"]["posts"][0]["post"]["id"] == 101
        assert data["data"]["posts"][1]["post"]["id"] == 102

        # ✅ Validate metadata
        assert data["data"]["posts"][0]["total_comments"] == 5
        assert data["data"]["posts"][1]["total_comments"] == 3
        assert data["data"]["posts"][0]["total_likes"] == 20
        assert data["data"]["posts"][1]["total_likes"] == 15

        # ✅ Validate pagination
        assert data["data"]["pagination"]["current_page"] == 1
        assert data["data"]["pagination"]["total_pages"] == 2
        assert data["data"]["pagination"]["total_items"] == 15
        assert data["data"]["pagination"]["has_next"] is True
        assert data["data"]["pagination"]["has_prev"] is False


@patch("app.models.User.query")
def test_get_user_posts_user_not_found(mock_user_query, client):
    """Test fetching posts of a non-existent user."""

    # ❌ Simulate user not found (raises 404)
    mock_user_query.filter_by.return_value.first_or_404.side_effect = Exception(
        "User not found"
    )

    response = client.get(url_for("profile_v1.get_user_posts", username="unknown"))

    # ✅ Validate response
    assert response.status_code == 500, f"Unexpected response: {response.get_json()}"
    data = response.get_json()
    assert data["success"] == "error"
    assert data["message"] == "Failed to fetch user posts"
