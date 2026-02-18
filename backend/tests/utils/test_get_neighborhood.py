from app import utils


def test_get_neighborhood_inside_seattle_prefers_neighborhood(monkeypatch):
    monkeypatch.setattr(utils, "is_coordinate_in_seattle", lambda lat, lon: True)

    def fake_reverse_geocode(lat, lon):
        return {"neighbourhood": "Ballard"}

    monkeypatch.setattr(utils, "_reverse_geocode_with_cache", fake_reverse_geocode)

    assert utils.get_neighborhood(47.6687, -122.3847) == "Ballard, Seattle"


def test_get_neighborhood_inside_seattle_when_reverse_geocode_fails(monkeypatch):
    monkeypatch.setattr(utils, "is_coordinate_in_seattle", lambda lat, lon: True)

    def boom(*args, **kwargs):
        raise RuntimeError("reverse geocode down")

    monkeypatch.setattr(utils, "_reverse_geocode_with_cache", boom)

    assert utils.get_neighborhood(47.6062, -122.3321) == "Seattle"


def test_get_neighborhood_outside_uses_city_when_available(monkeypatch):
    monkeypatch.setattr(utils, "is_coordinate_in_seattle", lambda lat, lon: False)

    def fake_reverse_geocode(lat, lon):
        return {"city": "Portland", "state": "Oregon"}

    monkeypatch.setattr(utils, "_reverse_geocode_with_cache", fake_reverse_geocode)

    assert utils.get_neighborhood(45.5152, -122.6784) == "Outside Seattle - Portland"
