import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from app.models import UserContent, User, Reaction


@pytest.fixture
def test_user_content(session, users):
    """Creates test user content for pagination tests."""
    contents = []
    for i in range(15):  # Create 15 user content entries
        content = UserContent(
            title=f"Story {i}",
            body=f"This is the content of story {i}.",
            user_id=users[i % len(users)].id,  # Assign content to available users
            unique_id=1000000000 + i,
            location="Seattle",
        )
        session.add(content)
        contents.append(content)

    session.commit()
    return contents


def test_fetch_user_content_success(client, test_user_content):
    """Test fetching paginated user content successfully."""
    response = client.get(url_for("content_v1.fetch_user_content", page=1))
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["status"] == "success"
    assert "content" in json_data
    assert isinstance(json_data["content"], list)
    assert len(json_data["content"]) > 0  # Ensure content is returned
    assert "hasMore" in json_data


def test_fetch_user_content_pagination(client, test_user_content):
    """Test fetching paginated user content with multiple pages."""
    response_page_1 = client.get(url_for("content_v1.fetch_user_content", page=1))
    response_page_2 = client.get(url_for("content_v1.fetch_user_content", page=2))

    json_data_page_1 = response_page_1.get_json()
    json_data_page_2 = response_page_2.get_json()

    assert response_page_1.status_code == 200
    assert response_page_2.status_code == 200
    assert json_data_page_1["hasMore"] is True  # ✅ Expect more pages
    assert json_data_page_2["hasMore"] is False  # ✅ Last page should return False
    assert len(json_data_page_1["content"]) == 10  # ✅ First page should have 10 items
    assert len(json_data_page_2["content"]) == 5  # ✅ Second page should have 5 items


@patch("app.models.UserContent.query")
def test_fetch_user_content_empty(mock_query, client):
    """Test API returns an empty list when no user content exists."""
    mock_paginate = MagicMock()
    mock_paginate.items = []
    mock_paginate.has_next = False

    mock_query.order_by.return_value.paginate.return_value = mock_paginate

    response = client.get(url_for("content_v1.fetch_user_content", page=1))
    json_data = response.get_json()

    assert response.status_code == 200
    assert json_data["status"] == "success"
    assert json_data["content"] == []  # ✅ No content should be returned
    assert json_data["hasMore"] is False


@patch("app.models.UserContent.query")
def test_fetch_user_content_database_error(mock_query, client):
    """Test API handles database failure gracefully."""
    mock_query.order_by.side_effect = Exception("Database error")

    response = client.get(url_for("content_v1.fetch_user_content", page=1))
    json_data = response.get_json()

    assert response.status_code == 500
    assert json_data["status"] == "error"
    assert json_data["message"] == "An error occurred while fetching user content."
