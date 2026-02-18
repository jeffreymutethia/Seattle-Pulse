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
log_prefix = "[TheNeedlingFetcher]"

class TheNeedlingFetcher(DataFetcher):
    BASE_URL = "https://theneedling.com"

    def __init__(self, api_handler):
        self.api_handler = api_handler
        self.site_config = {
            "username": "The Needling",
            "first_name": "The",
            "last_name": "Needling",
            "email": "editor@theneedling.com",
            "profile_picture": "https://theneedling.com/wp-content/uploads/2018/10/Needling_banner_102118.jpg"
        }

    def parse_data(self, response):
        logger.info(f"{log_prefix} Parsing HTML...")
        soup = BeautifulSoup(response.content, "html.parser")
        articles = soup.select("div.td_module_flex")[:5]
        logger.info(f"{log_prefix} Found {len(articles)} article blocks")
        parsed = []

        for i, article in enumerate(articles, 1):
            logger.info(f"{log_prefix} Processing article #{i}")

            # 1) Headline & Link
            title_tag = article.select_one("h3.entry-title.td-module-title a")
            if not title_tag:
                logger.warning(f"{log_prefix} Article #{i} missing title tag; skipping.")
                continue

            headline = title_tag.get_text(strip=True)
            href     = title_tag["href"]
            link     = href if href.startswith("http") else urljoin(self.BASE_URL, href)
            logger.info(f"{log_prefix} Headline: {headline}")
            logger.info(f"{log_prefix} Link: {link}")

            # 2) Image
            thumb = article.select_one("span.entry-thumb")
            if thumb and thumb.get("data-img-url"):
                image_url = thumb["data-img-url"]
            else:
                image_url = fetch_google_image_url(headline) or "https://via.placeholder.com/500x300?text=The+Needling"
            logger.info(f"{log_prefix} Image URL: {image_url}")

            # 3) Fetch detail page for body
            body = ""
            try:
                detail_resp = self.api_handler.get_news_data(link)
                if detail_resp:
                    dsoup = BeautifulSoup(detail_resp.content, "html.parser")
                    content_div = dsoup.select_one("div.td-post-content.tagdiv-type")
                    if content_div:
                        p = content_div.find("p")
                        if p:
                            text = p.get_text(strip=True)
                            body = text[:280]  # truncate to 280 chars
                            logger.info(f"{log_prefix} Fetched body (first 280 chars): {body!r}")
            except Exception as e:
                logger.error(f"{log_prefix} Error fetching detail page for #{i}: {e}")

            # 4) Timestamp
            timestamp = datetime.utcnow()

            parsed.append({
                "headline":  headline,
                "link":      link,
                "image_url": image_url,
                "timestamp": timestamp,
                "body":      body
            })

        logger.info(f"{log_prefix} ✅ Completed parsing. Total parsed items: {len(parsed)}")
        return parsed

    def save_data(self, parsed_news):
        logger.info(f"{log_prefix} Saving {len(parsed_news)} parsed items")
        result = save_parsed_news(parsed_news, self.site_config, db, User, UserContent)
        logger.info(f"{log_prefix} ✅ Saved {result['saved']} new news items")
        return result
