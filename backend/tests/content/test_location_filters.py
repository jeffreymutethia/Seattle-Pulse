import pytest


@pytest.fixture
def seeded_locations(client):
    response = client.post("/api/v1/test_seed/locations")
    assert response.status_code == 201
    payload = response.get_json()
    user_id = payload["user_id"]
    yield payload
    cleanup = client.delete(f"/api/v1/test_seed/locations/{user_id}")
    assert cleanup.status_code in (200, 404)


def extract_ids(content):
    return [item["id"] for item in content]


def test_feed_filters_seattle_neighborhood(client, seeded_locations):
    response = client.get(
        "/api/v1/content/",
        query_string={"location": "Queen Anne, Seattle", "per_page": 10},
    )
    assert response.status_code == 200
    data = response.get_json()["data"]["content"]
    assert data
    assert {item["location_label"] for item in data} == {"Queen Anne, Seattle"}
    assert all(item["is_in_seattle"] for item in data)


def test_feed_filters_seattle_all(client, seeded_locations):
    response = client.get(
        "/api/v1/content/",
        query_string={"location": "Seattle", "per_page": 10},
    )
    assert response.status_code == 200
    data = response.get_json()["data"]["content"]
    assert data
    assert all(item["is_in_seattle"] for item in data)


def test_feed_filters_outside(client, seeded_locations):
    response = client.get(
        "/api/v1/content/",
        query_string={"location": "Outside Seattle", "per_page": 10},
    )
    assert response.status_code == 200
    data = response.get_json()["data"]["content"]
    assert data
    assert {item["is_in_seattle"] for item in data} == {False}


def test_feed_filters_city_exact(client, seeded_locations):
    response = client.get(
        "/api/v1/content/",
        query_string={"location": "New York, NY", "per_page": 10},
    )
    assert response.status_code == 200
    data = response.get_json()["data"]["content"]
    assert len(data) == 1
    assert data[0]["location_label"] == "New York, NY"
    assert data[0]["is_in_seattle"] is False


def test_combined_feed_matches_primary(client, seeded_locations):
    params = {"location": "Addis Ababa, Ethiopia", "per_page": 10}
    logged_in = client.get("/api/v1/content/", query_string=params)
    guest = client.get("/api/v1/content/combined_feed", query_string=params)

    assert logged_in.status_code == 200
    assert guest.status_code == 200

    primary_content = logged_in.get_json()["data"]["content"]
    combined_content = guest.get_json()["data"]["content"]

    assert extract_ids(primary_content) == extract_ids(combined_content)
    assert {item["location_label"] for item in combined_content} == {
        "Addis Ababa, Ethiopia"
    }


def test_guest_feed_rejects_blank_location(client):
    response = client.get(
        "/api/v1/content/guest_feed",
        query_string={"location": "   "},
    )
    assert response.status_code == 400
    payload = response.get_json()
    assert payload["success"] == "error"


def test_location_labels_consistent_across_views(client, seeded_locations):
    username = seeded_locations["username"]

    feed_resp = client.get(
        "/api/v1/content/",
        query_string={"location": "Queen Anne, Seattle", "per_page": 5},
    )
    assert feed_resp.status_code == 200
    feed_item = feed_resp.get_json()["data"]["content"][0]
    feed_post_id = feed_item["id"]

    profile_posts = client.get(f"/api/v1/profile/{username}/posts")
    assert profile_posts.status_code == 200
    posts_payload = profile_posts.get_json()["data"]["posts"]
    profile_item = next(post["post"] for post in posts_payload if post["post"]["id"] == feed_post_id)

    profile_locations = client.get(f"/api/v1/profile/{username}/location")
    assert profile_locations.status_code == 200
    location_payload = profile_locations.get_json()["data"]["locations"]
    location_entry = next(entry for entry in location_payload if entry["post_id"] == feed_post_id)

    assert feed_item["location_label"] == "Queen Anne, Seattle"
    assert profile_item["location_label"] == "Queen Anne, Seattle"
    assert location_entry["location_label"] == "Queen Anne, Seattle"
