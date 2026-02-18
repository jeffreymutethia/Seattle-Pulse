from .base_fetcher import DataFetcher
from bs4 import BeautifulSoup
from datetime import datetime
from urllib.parse import urljoin
from ..models import db, User, UserContent
from .news_saver import save_parsed_news
from app.utils import fetch_google_image_url
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
log_prefix = "[StrangerFetcher]"

class StrangerFetcher(DataFetcher):
    BASE_URL = "https://www.thestranger.com"

    def __init__(self, api_handler):
        self.api_handler = api_handler
        self.site_config = {
            "username": "The Stranger",
            "first_name": "The",
            "last_name": "Stranger",
            "email": "editor@thestranger.com",
            "profile_picture": "https://www.thestranger.com/assets/sites/stranger/images/site-logo.png?20220525222143"
        }

    def parse_data(self, response):
        logger.info(f"{log_prefix} Parsing HTML...")
        soup = BeautifulSoup(response.content, "html.parser")
        items = soup.select("div.item")[:5]
        parsed = []

        for i, article in enumerate(items, 1):
            logger.info(f"{log_prefix} Processing article #{i}")

            # headline & link
            title_a = article.select_one("h2.headline a, h3.headline a")
            if not title_a:
                logger.warning(f"{log_prefix} Skipping #{i}: no headline/link")
                continue

            headline = title_a.get_text(strip=True)
            link     = urljoin(self.BASE_URL, title_a["href"])

            # body fallback: fetch detail if needed
            body = ""
            try:
                detail_resp = self.api_handler.get_news_data(link)
                if detail_resp and detail_resp.ok:
                    dsoup = BeautifulSoup(detail_resp.content, "html.parser")
                    body_container = dsoup.select_one("div.component.article-body")
                    if body_container:
                        p_tags = body_container.find_all("p")
                        text_parts = [p.get_text(strip=True) for p in p_tags if p.get_text(strip=True)]
                        body = " ".join(text_parts)[:280]
            except Exception as e:
                logger.warning(f"{log_prefix} Failed to extract body for #{i}: {e}")
                body = headline

            # image
            img = article.select_one("div.item-image img")
            image_url = img["src"] if img and img.get("src") else fetch_google_image_url(headline)

            parsed.append({
                "headline":  headline,
                "link":      link,
                "image_url": image_url,
                "timestamp": datetime.utcnow(),
                "body":      body
            })

            logger.info(f"{log_prefix} Parsed #{i}: {headline!r}")

        logger.info(f"{log_prefix} ✅ Completed parsing. {len(parsed)} items")
        return parsed

    def save_data(self, parsed_news):
        logger.info(f"{log_prefix} Saving parsed items")
        result = save_parsed_news(parsed_news, self.site_config, db, User, UserContent)
        logger.info(f"{log_prefix} ✅ Saved {result['saved']} new items")
        return result
