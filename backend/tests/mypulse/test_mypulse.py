from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from flask import url_for

from app.location_service import LocationFilterSpec
from app.models import User
@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def mock_current_user():
    user = MagicMock(spec=User)
    user.id = 1
    user.username = "testuser"
    user.followed = []
    return user


@patch("flask_login.utils._get_user")
def test_mypulse_requires_auth(mock_get_user, client):
    mock_user = MagicMock()
    mock_user.is_authenticated = False
    mock_get_user.return_value = mock_user

    response = client.get(url_for("feed_v1.mypulse"))
    assert response.status_code == 401


@patch("flask_login.utils._get_user")
@patch("app.api.feed.fetch_mypulse_content")
@patch("app.models.Reaction.query")
@patch("app.models.Repost.query")
def test_mypulse_location_filter_passed_to_fetch(
    mock_repost_query,
    mock_reaction_query,
    mock_fetch,
    mock_get_user,
    client,
    mock_current_user,
):
    mock_current_user.followed = [SimpleNamespace(followed_id=2)]
    mock_get_user.return_value = mock_current_user

    mock_reaction_query.filter_by.return_value.all.return_value = []
    mock_reaction_query.filter_by.return_value.count.return_value = 0
    mock_repost_query.filter_by.return_value.all.return_value = []

    item = SimpleNamespace(
        id=10,
        title="City update",
        body="",
        location="New York, NY",
        created_at=None,
        updated_at=None,
        thumbnail="https://example.com/thumb.jpg",
        user_id=2,
        username="friend",
        profile_picture_url=None,
        score=1.0,
        is_in_seattle=False,
    )
    mock_fetch.return_value = ([item], 1)

    response = client.get(url_for("feed_v1.mypulse", location="New York, NY"))
    assert response.status_code == 200

    called_spec = mock_fetch.call_args.kwargs["location_spec"]
    assert isinstance(called_spec, LocationFilterSpec)
    assert called_spec.label == "New York, NY"

    payload = response.get_json()
    content = payload["data"]["content"][0]
    assert content["location_label"] == "New York, NY"
    assert content["is_in_seattle"] is False
    assert payload["query"]["location"] == "New York, NY"


@patch("flask_login.utils._get_user")
def test_mypulse_blank_location_returns_400(mock_get_user, client, mock_current_user):
    mock_get_user.return_value = mock_current_user
    response = client.get(url_for("feed_v1.mypulse", location="   "))
    assert response.status_code == 400
    data = response.get_json()
    assert data["success"] == "error"
