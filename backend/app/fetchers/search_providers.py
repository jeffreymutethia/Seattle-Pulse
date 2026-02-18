import requests
from config import GOOGLE_API_KEY, GOOGLE_SEARCH_ENGINE_ID


class GoogleImageSearchProvider:
    """Search for images using Google Custom Search API."""

    API_URL = "https://www.googleapis.com/customsearch/v1"

    def __init__(self, api_key=GOOGLE_API_KEY, cx=GOOGLE_SEARCH_ENGINE_ID):
        self.api_key = api_key
        self.cx = cx

    def search(self, query):
        if not self.api_key or not self.cx:
            raise ValueError("Google API credentials not configured")

        params = {
            "key": self.api_key,
            "cx": self.cx,
            "searchType": "image",
            "num": 1,
            "q": query,
        }
        resp = requests.get(self.API_URL, params=params, timeout=5)
        resp.raise_for_status()
        data = resp.json()
        items = data.get("items")
        return items[0]["link"] if items else None

