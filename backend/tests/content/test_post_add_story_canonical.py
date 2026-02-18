from unittest.mock import patch

import pytest

from app.models import User, UserContent


@pytest.fixture
def posting_client(client, session):
    client.application.config["APP_ENV"] = "staging"

    user = User(
        first_name="Poster",
        last_name="User",
        username="poster",
        email="poster@example.com",
        accepted_terms_and_conditions=True,
        is_email_verified=True,
    )
    user.set_password("Password123!")
    session.add(user)
    session.commit()

    return client, user


@patch("app.api.content.moderate_text", return_value=[])
@patch("flask_login.utils._get_user")
@patch("app.api.content.get_neighborhood", return_value="Queen Anne, Seattle")
@patch("app.api.content.is_coordinate_in_seattle", return_value=True)
def test_add_story_with_coordinates_canonicalizes(
    mock_is_in_seattle, mock_get_neighborhood, mock_get_user, mock_moderate, posting_client, session
):
    client, user = posting_client
    mock_get_user.return_value = user

    payload = {
        "title": "Seattle post",
        "body": "Hello Queen Anne",
        "latitude": "47.6379",
        "longitude": "-122.3560",
        "thumbnail_url": "https://example.com/image.jpg",
    }

    response = client.post("/api/v1/content/add_story", data=payload)
    assert response.status_code == 201
    created = response.get_json()["data"]["post"]

    assert created["location"] == "Queen Anne, Seattle"
    assert created["location_label"] == "Queen Anne, Seattle"
    assert created["is_in_seattle"] is True
    assert float(created["latitude"]) == pytest.approx(47.6379)
    assert float(created["longitude"]) == pytest.approx(-122.3560)

    stored = session.query(UserContent).one()
    assert stored.location == "Queen Anne, Seattle"
    assert stored.is_in_seattle is True


@patch("app.api.content.moderate_text", return_value=[])
@patch("flask_login.utils._get_user")
@patch("app.api.content.get_coordinates_from_location", return_value=(47.6186, -122.3510))
@patch("app.api.content.get_neighborhood", return_value="Seattle")
@patch("app.api.content.is_coordinate_in_seattle", return_value=True)
def test_add_story_resolves_manual_location(
    mock_is_in_seattle,
    mock_get_neighborhood,
    mock_get_coordinates,
    mock_get_user,
    mock_moderate,
    posting_client,
    session,
):
    client, user = posting_client
    mock_get_user.return_value = user

    payload = {
        "title": "Manual location",
        "body": "Downtown",
        "location": "Downtown Seattle",
        "thumbnail_url": "https://example.com/manual.jpg",
    }

    response = client.post("/api/v1/content/add_story", data=payload)
    assert response.status_code == 201
    created = response.get_json()["data"]["post"]

    assert created["location"] == "Seattle"
    assert created["location_label"] == "Seattle"
    assert created["is_in_seattle"] is True
    assert float(created["latitude"]) == pytest.approx(47.6186)
    assert float(created["longitude"]) == pytest.approx(-122.3510)

    stored = session.query(UserContent).one()
    assert stored.latitude == pytest.approx(47.6186)
    assert stored.longitude == pytest.approx(-122.3510)


@patch("app.api.content.moderate_text", return_value=[])
@patch("flask_login.utils._get_user")
@patch("app.api.content.get_neighborhood", return_value="Outside Seattle - Addis Ababa, Ethiopia")
@patch("app.api.content.is_coordinate_in_seattle", return_value=False)
def test_add_story_outside_location(
    mock_is_in_seattle, mock_get_neighborhood, mock_get_user, mock_moderate, posting_client, session
):
    client, user = posting_client
    mock_get_user.return_value = user

    payload = {
        "title": "Travel",
        "body": "Greetings from abroad",
        "latitude": "8.9806",
        "longitude": "38.7578",
        "thumbnail_url": "https://example.com/travel.jpg",
    }

    response = client.post("/api/v1/content/add_story", data=payload)
    assert response.status_code == 201
    created = response.get_json()["data"]["post"]

    assert created["location"] == "Outside Seattle - Addis Ababa, Ethiopia"
    assert created["is_in_seattle"] is False
    assert created["location_label"] == "Outside Seattle - Addis Ababa, Ethiopia"

    stored = session.query(UserContent).one()
    assert stored.is_in_seattle is False
