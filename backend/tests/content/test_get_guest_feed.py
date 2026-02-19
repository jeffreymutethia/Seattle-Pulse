from unittest.mock import patch
from flask import url_for
from types import SimpleNamespace
from datetime import datetime


@patch("app.api.content.fetch_seeded_content_round_robin")
def test_distribute_sources_guest_feed(mock_fetch_seeded_content_round_robin, client):
    now = datetime.utcnow()

    def make_item(id_, user_id):
        user = SimpleNamespace(
            id=user_id,
            username=f"user{user_id}",
            profile_picture_url=f"https://example.com/u{user_id}.jpg",
        )
        return SimpleNamespace(
            id=id_,
            title=f"Post {id_}",
            body="",
            location="Seattle",
            created_at=now,
            updated_at=now,
            thumbnail=f"https://example.com/post{id_}.jpg",
            user_id=user_id,
            user=user,
            is_seeded=True,
            seed_type="news",
            seeded_likes_count=0,
            seeded_comments_count=0,
            news_link="",
            is_in_seattle=True,
        )

    # Simulate round-robin ordering returned by the feed fetch helper.
    items = [make_item(1, 1), make_item(3, 2), make_item(2, 1)]
    # Route contract: relies on round-robin content fetch helper.
    mock_fetch_seeded_content_round_robin.return_value = (items, len(items))

    resp = client.get(url_for("content_v1.get_guest_feed"))
    data = resp.get_json()

    user_ids = [c["user"]["id"] for c in data["data"]["content"]]
    assert resp.status_code == 200
    assert data["success"] == "success"
    assert len(data["data"]["content"]) == 3
    assert user_ids == [1, 2, 1]
