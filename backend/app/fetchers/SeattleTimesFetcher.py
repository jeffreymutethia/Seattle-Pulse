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
log_prefix = "[SeattleTimesFetcher]"

class SeattleTimesFetcher(DataFetcher):
    BASE_URL = "https://www.seattletimes.com"

    def __init__(self, api_handler):
        self.api_handler = api_handler
        self.site_config = {
            "username": "Seattle Times",
            "first_name": "Seattle",
            "last_name": "Times",
            "email": "editor@seattletimes.com",
            "profile_picture": "https://avatar.iran.liara.run/username?username=SeattleTimes"
        }

    def parse_data(self, response):
        logger.info(f"{log_prefix} Parsing HTML response...")
        soup = BeautifulSoup(response.content, "html.parser")
        parsed = []

        # 1) Locate the Local News block
        block = soup.select_one("div.storyBlock.Local-News")
        if not block:
            logger.warning(f"{log_prefix} Couldn't find Local-News block")
            return parsed

        # 2) Grab up to 5 story links
        anchors = block.select("ul.jVUVllsLYRVpiPaEcmvR li a.NZUc3l6EBaSxtympQiak")[:5]
        logger.info(f"{log_prefix} Found {len(anchors)} Local News links")

        for i, a in enumerate(anchors, 1):
            try:
                # — headline
                span = a.select_one("span[data-mrf-layout-title]")
                headline = span.get_text(strip=True) if span else None
                if not headline:
                    logger.warning(f"{log_prefix} Skipping #{i}: no headline text")
                    continue

                # — link (absolute)
                href = a.get("href", "")
                link = href if href.startswith("http") else urljoin(self.BASE_URL, href)

                # — image
                img_tag = a.select_one("img[src]")
                if img_tag and img_tag.get("src"):
                    image_url = img_tag["src"]
                else:
                    image_url = fetch_google_image_url(headline)

                # — body: attempt to fetch the detail page and grab first paragraph
                body = ""
                resp2 = self.api_handler.get_news_data(link)
                if resp2:
                    detail_soup = BeautifulSoup(resp2.content, "html.parser")
                    p = detail_soup.select_one("div#article-content.entry-content p")
                    if p:
                        # truncate to 280 chars
                        body = p.get_text(strip=True)[:280]

                # — timestamp (no reliable homepage time, so use now)
                timestamp = datetime.utcnow()

                parsed.append({
                    "headline":  headline,
                    "link":      link,
                    "image_url": image_url,
                    "timestamp": timestamp,
                    "body":      body
                })
                logger.info(f"{log_prefix} Parsed #{i}: {headline!r}")

            except Exception as e:
                logger.error(f"{log_prefix} Error parsing Local-News #{i}: {e}")

        logger.info(f"{log_prefix} ✅ Completed parsing. Total parsed items: {len(parsed)}")
        return parsed

    def save_data(self, parsed_news):
        logger.info(f"{log_prefix} Saving {len(parsed_news)} parsed items to DB")
        saved = save_parsed_news(parsed_news, self.site_config, db, User, UserContent)
        logger.info(f"{log_prefix} ✅ Saved {saved['saved']} new news items to DB")
        return saved
