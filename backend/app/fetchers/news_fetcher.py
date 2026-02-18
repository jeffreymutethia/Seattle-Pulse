from fileinput import filename
import json
import logging
from .base_fetcher import DataFetcher
from .api_handler import APIHandler
from app import create_app
from app import celery
from ..models import News, User,UserContent
from ..models import db
from ..utils import clear_news
from datetime import datetime
from bs4 import BeautifulSoup
import time
import random
import config as config
from app.fetchers.myballard_fetcher import MyBallardFetcher
from .news_saver import save_parsed_news

FETCHER_MAP = {
    "myballard.com": MyBallardFetcher,
    # Add more mappings here
}

def get_fetcher(source_url):
    for domain, fetcher_cls in FETCHER_MAP.items():
        if domain in source_url:
            return fetcher_cls(APIHandler())
    raise ValueError(f"No fetcher registered for source: {source_url}")

# Configure logger for this module
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

@celery.task(bind=True, max_retries=3, default_retry_delay=60)
def fetch_data(self, source):
    start_time = time.time()
    task_id = self.request.id
    logger.info(f"Starting news fetch task {task_id} at {datetime.now()}")
    
    try:
        # Create a Flask application context instead of using celery.app
        app, _ = create_app()
        with app.app_context():
            logger.info(f"Task {task_id}: Initializing API handler")
            api_handler_instance = APIHandler()
            news_fetcher = NewsFetcher(api_handler_instance)
            
            logger.info(f"Task {task_id}: Fetching news data from {source}")
            fetch_start = time.time()
            news_data = news_fetcher.api_handler.get_news_data(source)
            fetch_duration = time.time() - fetch_start
            logger.info(f"Task {task_id}: News data fetch completed in {fetch_duration:.2f} seconds")
            
            if news_data:
                logger.info(f"Task {task_id}: Parsing fetched news data")
                parse_start = time.time()
                parsed_news = news_fetcher.parse_data(news_data)
                parse_duration = time.time() - parse_start
                logger.info(f"Task {task_id}: Parsed {len(parsed_news)} news items in {parse_duration:.2f} seconds")
                
                logger.info(f"Task {task_id}: Saving parsed news to database")
                save_start = time.time()
                news_fetcher.save_data(parsed_news)
                save_duration = time.time() - save_start
                logger.info(f"Task {task_id}: News items saved to database in {save_duration:.2f} seconds")
            else:
                logger.error(f"Task {task_id}: No data fetched from API")
                raise self.retry(exc=Exception("No data fetched from API"))
            
            total_duration = time.time() - start_time
            logger.info(f"Task {task_id}: Completed successfully in {total_duration:.2f} seconds")
            
    except Exception as exc:
        logger.error(f"Task {task_id}: Error during execution: {str(exc)}")
        raise self.retry(exc=exc)

        
class NewsFetcher(DataFetcher):
    def __init__(self, api_handler):
        self.api_handler = api_handler
                
    def parse_data(self, data):
        soup = BeautifulSoup(data.content, 'html.parser')
        parsed_news = []

        main_headline_item = soup.select_one("ul[class^='heroLayout-module_heroPrimary'] li")
        if main_headline_item:
            main_headline = self.extract_news_item(main_headline_item)
            if main_headline:
                parsed_news.append(main_headline)

        mini_headline_items = soup.select("ul[class^='heroLayout-module_heroSecondary'] li")[:2]
        for item in mini_headline_items:
            mini_headline = self.extract_news_item(item)
            if mini_headline:
                parsed_news.append(mini_headline)

        other_story_items = soup.select("ul[class^='heroLayout-module_heroTertiary'] li")[:7]
        for item in other_story_items:
            other_story = self.extract_news_item(item)
            if other_story:
                parsed_news.append(other_story)
        
        with open('/tmp/parsed_news.json', 'w', encoding='utf-8') as file:
            json.dump(parsed_news, file, indent=4, ensure_ascii=False, default=str)
               
        return parsed_news

    def extract_news_item(self, item):
        headline_link = item.find("a", href=True)
        if not headline_link:
            return None

        headline = headline_link.get("title", "").strip()
        if not headline:
            headline = headline_link.get_text(strip=True)

        link = headline_link['href']
        full_link = "https://komonews.com" + link if link.startswith('/') else link

        # Default placeholder
        image_url = "https://placeholder.pagebee.io/api/plain/500/300?text=Image+Unavailable&bg=cccccc&color=333333"
        body = ""

        try:
            detail_response = self.api_handler.get_news_data(full_link)
            if detail_response and detail_response.ok:
                detail_soup = BeautifulSoup(detail_response.content, 'html.parser')

                # ✅ Corrected body container selector
                body_div = detail_soup.select_one("div.StoryText-module_storyText__FWhP")
                if body_div:
                    paragraphs = body_div.find_all("p")
                    body = " ".join(p.get_text(strip=True) for p in paragraphs if p.get_text(strip=True))[:280]

                # ✅ Image extraction from article
                img_tag = detail_soup.select_one("img.index-module_mainImage__Y04z")
                if img_tag and img_tag.get("src"):
                    raw_src = img_tag["src"]
                    image_url = raw_src if raw_src.startswith("http") else "https://komonews.com" + raw_src

        except Exception as e:
            logger.warning(f"[KOMO] Failed to extract detail body or image for {full_link}: {e}")

        return {
            'headline': headline,
            'link': full_link,
            'image_url': image_url,
            'timestamp': datetime.now(),
            'body': body
        }



    def save_data(self, parsed_news):
        logger.info("Starting save_data operation")
        
        # Use the improved save_parsed_news function for consistent deduplication
        site_config = {
            "username": "Komo News",
            "first_name": "Komo",
            "last_name": "News",
            "email": "contact@komonews.com",
            "profile_picture": "https://avatar.iran.liara.run/username?username=KomoNews"
        }
        
        saved = save_parsed_news(parsed_news, site_config, db, User, UserContent)
        logger.info(f"✅ News fetcher saved {saved['saved']} new items, skipped {saved['skipped_duplicates']} duplicates")
        
        return saved