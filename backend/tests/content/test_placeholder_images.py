import pytest
from unittest.mock import patch, MagicMock
from flask import url_for
from datetime import datetime
from types import SimpleNamespace


@patch("flask_login.utils._get_user")
@patch("app.api.content.fetch_high_score_content")
def test_get_content_skips_placeholder_thumbnails(mock_fetch, mock_get_user, client, mock_current_user):
    mock_get_user.return_value = mock_current_user
    now = datetime.utcnow()

    def make_item(id_, thumb):
        return SimpleNamespace(
            id=id_,
            title=f"Post {id_}",
            body="", 
            location="Seattle",
            created_at=now,
            updated_at=now,
            thumbnail=thumb,
            user_id=id_,
            username=f"user{id_}",
            profile_picture_url="",
            is_seeded=True,
            seed_type="news",
            seeded_likes_count=0,
            seeded_comments_count=0,
            news_link="",
            score=1.0,
        )

    items = [
        make_item(1, "https://via.placeholder.com/123"),
        make_item(2, "https://real.com/image.jpg"),
        make_item(3, "https://placeholder.pagebee.io/img"),
    ]
    mock_fetch.return_value = (items, len(items))

    resp = client.get(url_for("content_v1.get_content"))
    data = resp.get_json()
    returned_ids = [c["id"] for c in data["data"]["content"]]
    assert resp.status_code == 200
    assert returned_ids == [2]


@patch("app.api.content.fetch_high_score_content")
def test_get_guest_feed_skips_placeholder_thumbnails(mock_fetch, client):
    now = datetime.utcnow()

    def make_item(id_, thumb):
        return SimpleNamespace(
            id=id_,
            title=f"Post {id_}",
            body="",
            location="Seattle",
            created_at=now,
            updated_at=now,
            thumbnail=thumb,
            user_id=id_,
            username=f"user{id_}",
            profile_picture_url="",
            is_seeded=True,
            seed_type="news",
            seeded_likes_count=0,
            seeded_comments_count=0,
            news_link="",
            score=1.0,
        )

    items = [
        make_item(1, "https://via.placeholder.com/123"),
        make_item(2, "https://real.com/image.jpg"),
        make_item(3, "https://placeholder.pagebee.io/img"),
    ]
    mock_fetch.return_value = (items, len(items))

    resp = client.get(url_for("content_v1.get_guest_feed"))
    data = resp.get_json()
    returned_ids = [c["id"] for c in data["data"]["content"]]
    assert resp.status_code == 200
    assert returned_ids == [2]
