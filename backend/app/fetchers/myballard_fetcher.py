from .base_fetcher import DataFetcher
from bs4 import BeautifulSoup
from datetime import datetime
from ..models import db, User, UserContent
from .news_saver import save_parsed_news
import logging
from app.utils import fetch_google_image_url

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
log_prefix = "[MyBallardFetcher]"
import requests

class MyBallardFetcher(DataFetcher):
    def __init__(self, api_handler):
        self.api_handler = api_handler
        self.site_config = {
            "username": "My Ballard",
            "first_name": "My",
            "last_name": "Ballard",
            "email": "contact@myballard.com",
            "profile_picture": "https://www.myballard.com/wp-content/uploads/myballardlogo-4.png"
        }


    def fetch_with_headers(self, url):
        """
        Fetch page with a browser-like User-Agent to reduce 403 Forbidden responses.
        """
        headers = {
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/115.0 Safari/537.36"
            )
        }
        try:
            response = requests.get(url, headers=headers, timeout=10)
            if response.status_code != 200:
                logger.error(f"{log_prefix} ❌ Failed to fetch {url} — Status {response.status_code}")
                return None
            return response
        except Exception as e:
            logger.error(f"{log_prefix} ❌ Exception while fetching {url}: {e}")
            return None
        
        
    def parse_data(self, response):
        logger.info(f"{log_prefix} Parsing HTML response...")

        # ✅ Check for valid HTTP response before parsing
        if not response or getattr(response, "status_code", 0) != 200:
            logger.error(
                f"{log_prefix} ❌ Failed to fetch MyBallard. "
                f"Status: {getattr(response, 'status_code', 'No Response')}"
            )
            return []

        try:
            soup = BeautifulSoup(response.content, "html.parser")
        except Exception as e:
            logger.error(f"{log_prefix} ❌ Failed to parse HTML: {e}")
            return []

        # Grab first 5 teasers
        teasers = soup.select("div.blog-item-wrap")[:5]
        parsed = []

        logger.info(f"{log_prefix} Found {len(teasers)} article elements to process.")

        for i, article in enumerate(teasers, 1):
            logger.info(f"{log_prefix} Processing article #{i}")

            # Headline + link
            a = article.select_one("h2.entry-title a")
            if not a:
                logger.warning(f"{log_prefix} Skipping article #{i} — no headline link found")
                continue

            headline = a.get_text(strip=True)
            link = a["href"]

            # Teaser body
            body = ""
            teaser_div = article.select_one("div.entry-content")
            if teaser_div:
                p = teaser_div.find("p")
                if p:
                    body = p.get_text(strip=True)
            if not body:
                body = headline

            # Image
            img_tag = article.select_one("img.single-featured")
            if img_tag and img_tag.get("src"):
                image_url = img_tag["src"]
            else:
                image_url = fetch_google_image_url(headline) or "https://via.placeholder.com/500x300?text=My+Ballard"

            # Timestamp
            ts = datetime.utcnow()
            time_tag = article.select_one("time.entry-date")
            if time_tag and time_tag.has_attr("datetime"):
                try:
                    ts = datetime.fromisoformat(time_tag["datetime"])
                except Exception:
                    logger.warning(f"{log_prefix} Could not parse timestamp, using now")

            parsed.append({
                "headline": headline,
                "link": link,
                "body": body,
                "image_url": image_url,
                "timestamp": ts
            })

        logger.info(f"{log_prefix} ✅ Completed parsing. Total parsed items: {len(parsed)}")
        return parsed


    def save_data(self, parsed_news):
        logger.info(f"{log_prefix} Saving {len(parsed_news)} parsed items to DB")
        saved = save_parsed_news(parsed_news, self.site_config, db, User, UserContent)
        logger.info(f"{log_prefix} ✅ Saved {saved['saved']} new news items to DB")
        return saved
