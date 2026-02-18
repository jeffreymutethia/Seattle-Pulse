from .base_fetcher import DataFetcher
from bs4 import BeautifulSoup
from datetime import datetime
from ..models import db, User, UserContent
from .news_saver import save_parsed_news
from urllib.parse import urljoin
from app.utils import fetch_google_image_url
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
log_prefix = "[CHSFetcher]"

class CHSFetcher(DataFetcher):
    def __init__(self, api_handler):
        self.api_handler = api_handler
        self.site_config = {
            "username": "Capitol Hill Seattle",
            "first_name": "Capitol",
            "last_name": "Hill",
            "email": "contact@capitolhillseattle.com",
            "profile_picture": "https://www.capitolhillseattle.com/wp-content/uploads/2013/05/header1-2.png"
        }

    def parse_data(self, response):
        logger.info(f"{log_prefix} Parsing homepage HTML...")
        soup = BeautifulSoup(response.content, "html.parser")
        articles = soup.select("header.entry-header")[:5]
        parsed = []

        logger.info(f"{log_prefix} Found {len(articles)} articles to process.")

        for i, header in enumerate(articles, 1):
            logger.info(f"{log_prefix} Processing article #{i}")

            # Headline & Link
            title_tag = header.select_one("h1.entry-title a")
            if not title_tag:
                logger.warning(f"{log_prefix} Skipping article #{i} — no title tag.")
                continue
            headline = title_tag.get_text(strip=True)
            link = title_tag["href"]

            # Timestamp
            time_tag = header.select_one("time.entry-date")
            if time_tag and time_tag.has_attr("datetime"):
                timestamp = datetime.fromisoformat(time_tag["datetime"])
            else:
                timestamp = datetime.utcnow()
                logger.warning(f"{log_prefix} No valid timestamp; using current UTC.")

            # Fetch the article detail page for body
            body = ""
            try:
                detail_resp = self.api_handler.get_news_data(link)
                if detail_resp and detail_resp.ok:
                    detail_soup = BeautifulSoup(detail_resp.content, "html.parser")
                    content_div = detail_soup.select_one("div.entry-content")
                    if content_div:
                        p_tags = content_div.find_all("p")
                        text_parts = [p.get_text(strip=True) for p in p_tags if p.get_text(strip=True)]
                        body = " ".join(text_parts)[:280]
            except Exception as e:
                logger.warning(f"{log_prefix} Failed to fetch body for {link}: {e}")
                body = headline  # fallback to headline

            # Image (optional)
            article_parent = header.find_parent("article")
            entry_content = article_parent.select_one("div.entry-content") if article_parent else None
            image_tag = entry_content.find("img") if entry_content else None
            image_url = (
                image_tag["src"]
                if image_tag and image_tag.get("src")
                else fetch_google_image_url(headline) or "https://via.placeholder.com/500x300?text=CHS"
            )

            parsed.append({
                "headline": headline,
                "link": link,
                "image_url": image_url,
                "timestamp": timestamp,
                "body": body
            })

        logger.info(f"{log_prefix} ✅ Parsed {len(parsed)} articles.")
        return parsed

    def save_data(self, parsed_news):
        logger.info(f"{log_prefix} Saving {len(parsed_news)} parsed items")
        saved = save_parsed_news(parsed_news, self.site_config, db, User, UserContent)
        logger.info(f"{log_prefix} ✅ Saved {len(saved)} news items")
        return saved
