"""Keep the Docker fixtures compatible with the public neighborhood filters."""

import pytest

from app import db
from app.fetchers.news_saver import save_parsed_news
from app.models import User, UserContent
from scripts.seed_demo import DEMO_POSTS, upsert_demo_posts, upsert_demo_user


@pytest.mark.parametrize("label", ["Capitol Hill, Seattle", "Ballard, Seattle"])
def test_reseed_repairs_legacy_demo_locations(client, label):
    user = upsert_demo_user()
    upsert_demo_posts(user)
    db.session.commit()

    # Simulate a volume seeded before labels gained their canonical suffix.
    post = UserContent.query.filter_by(user_id=user.id, location=label).one()
    post.location = label.removesuffix(", Seattle")
    db.session.commit()

    assert upsert_demo_posts(user) == 0
    db.session.commit()

    response = client.get(
        "/api/v1/content/combined_feed", query_string={"location": label}
    )
    assert response.status_code == 200
    stories = response.get_json()["data"]["content"]
    assert len(stories) == 1
    assert stories[0]["title"] == next(
        fixture["title"] for fixture in DEMO_POSTS if fixture["location"] == label
    )
    assert stories[0]["location_label"] == label
    assert UserContent.query.filter_by(user_id=user.id).count() == len(DEMO_POSTS)


@pytest.mark.parametrize(
    ("source", "label"),
    [
        ("My Ballard", "Ballard, Seattle"),
        ("Capitol Hill Seattle", "Capitol Hill, Seattle"),
    ],
)
def test_ingested_story_matches_canonical_neighborhood_filter(client, source, label):
    result = save_parsed_news(
        [
            {
                "headline": f"Fictional fixture from {source}",
                "link": "https://example.invalid/fixture",
                "body": "A fictional story used to verify neighborhood filtering.",
                "image_url": "https://example.invalid/fixture.jpg",
            }
        ],
        {
            "username": source,
            "first_name": "Fictional",
            "last_name": "Publisher",
            "email": "fixture@example.invalid",
            "profile_picture": "https://example.invalid/avatar.jpg",
        },
        db,
        User,
        UserContent,
    )
    assert result["saved"] == 1

    response = client.get(
        "/api/v1/content/combined_feed", query_string={"location": label}
    )
    assert response.status_code == 200
    stories = response.get_json()["data"]["content"]
    assert len(stories) == 1
    assert stories[0]["title"] == f"Fictional fixture from {source}"
    assert stories[0]["location_label"] == label
