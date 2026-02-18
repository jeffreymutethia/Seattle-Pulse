import pytest
from unittest.mock import patch
from flask import url_for
from types import SimpleNamespace
from datetime import datetime

@patch("app.api.content.fetch_high_score_content")
def test_distribute_sources_guest_feed(mock_fetch_high_score_content, client):
    now = datetime.utcnow()

    def make_item(id_, user_id):
        return SimpleNamespace(
            id=id_,
            title=f"Post {id_}",
            body="",
            location="Seattle",
            created_at=now,
            updated_at=now,
            thumbnail="",
            user_id=user_id,
            username=f"user{user_id}",
            profile_picture_url="",
            is_seeded=True,
            seed_type="news",
            seeded_likes_count=0,
            seeded_comments_count=0,
            news_link="",
            score=1.0,
        )

    items = [make_item(1, 1), make_item(2, 1), make_item(3, 2)]
    mock_fetch_high_score_content.return_value = (items, len(items))

    resp = client.get(url_for("content_v1.get_guest_feed"))
    data = resp.get_json()

    user_ids = [c["user"]["id"] for c in data["data"]["content"]]
    assert resp.status_code == 200
    assert user_ids == [1, 2, 1]
