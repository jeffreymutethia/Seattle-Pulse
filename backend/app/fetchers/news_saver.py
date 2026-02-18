import random
import logging
import re
from datetime import datetime
from difflib import SequenceMatcher
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app import create_app
import os
from urllib.parse import urlparse

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

LOCATION_MAP = {
    "My Ballard":       "Ballard",
    "Capitol Hill Seattle": "Capitol Hill",
    "The Stranger":     "Seattle",
    "The Needling":     "Seattle",
    "Komo News":        "Seattle",
    "Seattle Times":    "Seattle",
}

def normalize_text(text):
    """Normalize text for comparison by removing extra spaces, converting to lowercase, and removing punctuation."""
    if not text:
        return ""
    # Remove extra spaces, convert to lowercase, remove punctuation except apostrophes
    normalized = re.sub(r'[^\w\s\']', '', text.lower().strip())
    # Remove extra whitespace
    normalized = re.sub(r'\s+', ' ', normalized)
    return normalized.strip()

def get_domain_from_url(url):
    """Extract domain from URL for comparison."""
    try:
        parsed = urlparse(url)
        return parsed.netloc.lower()
    except:
        return ""

def calculate_similarity(text1, text2):
    """Calculate similarity ratio between two texts."""
    if not text1 or not text2:
        return 0.0
    return SequenceMatcher(None, normalize_text(text1), normalize_text(text2)).ratio()

def is_similar_title(title1, title2, threshold=0.85):
    """Check if two titles are similar enough to be considered duplicates."""
    return calculate_similarity(title1, title2) >= threshold

def check_for_duplicates(headline, link, existing_news_data):
    """
    Comprehensive duplicate checking function.
    Returns (is_duplicate, reason) tuple.
    """
    normalized_headline = normalize_text(headline)
    current_domain = get_domain_from_url(link)
    
    for existing_uc in existing_news_data:
        if not existing_uc.title or not existing_uc.news_link:
            continue
            
        existing_title = existing_uc.title.strip()
        existing_link = existing_uc.news_link.strip()
        existing_domain = get_domain_from_url(existing_link)
        
        # 1. Exact title match
        if headline.lower() == existing_title.lower():
            return True, "exact_title_match"
            
        # 2. Exact link match
        if link.lower() == existing_link.lower():
            return True, "exact_link_match"
            
        # 3. Normalized title match (removes punctuation, extra spaces)
        if normalized_headline == normalize_text(existing_title):
            return True, "normalized_title_match"
            
        # 4. Same domain with similar title
        if current_domain and current_domain == existing_domain:
            if is_similar_title(headline, existing_title, threshold=0.8):
                return True, "similar_title_same_domain"
                
        # 5. Very high content similarity (90%+)
        similarity = calculate_similarity(headline, existing_title)
        if similarity >= 0.9:
            return True, f"high_similarity_{similarity:.2f}"
    
    return False, None

def get_alternate_db_url():
    """Get the alternate database URL based on the current environment"""
    current_env = os.getenv('APP_ENV', '').lower()
    
    if current_env == 'staging':
        return os.getenv('PROD_DATABASE_URL')
    elif current_env == 'production':
        return os.getenv('STAGING_DATABASE_URL')
    return None

def save_to_alternate_db(db_url, links, site_config, User, UserContent, parsed_news):
    """Save news items to an alternate database
    
    Args:
        db_url: Database URL to connect to
        links: List of news item links to save
        site_config: Configuration for the news source
        User: User model class
        UserContent: UserContent model class
        parsed_news: List of parsed news items with full details
    """
    try:
        # Create a new engine and session for the alternate database
        engine = create_engine(db_url)
        Session = sessionmaker(bind=engine)
        alt_db = Session()
        
        # Get existing items from the alternate database to check for duplicates
        existing_links = {r[0] for r in alt_db.query(UserContent.news_link).filter(
            UserContent.news_link.in_(links)
        ).all()}
        
        # Only save items that don't exist in the alternate database
        new_items = [link for link in links if link not in existing_links]
        
        if not new_items:
            logger.info("[save_to_alternate_db] No new items to save to alternate database.")
            return
            
        # Save each new item
        for link in new_items:
            uc = UserContent(
                content_type='news',
                title=next((item['title'] for item in parsed_news if item['link'] == link), ''),
                description=next((item.get('description', '') for item in parsed_news if item['link'] == link), ''),
                news_link=link,
                source=site_config['name'],
                user_id=1,  # System user or appropriate user ID
                location=LOCATION_MAP.get(site_config["username"], None),
                seeded_likes_count=random.randint(15, 60),
                seeded_comments_count=0,
                unique_id=random.randint(1_000_000_000, 9_999_999_999),
            )
            alt_db.add(uc)
        
        alt_db.commit()
        logger.info(f"[save_to_alternate_db] ✅ Committed {len(new_items)} new news items to alternate database.")
        
    except Exception as e:
        logger.error(f"[save_to_alternate_db] Error: {str(e)}")
        if 'alt_db' in locals():
            alt_db.rollback()
        raise
    finally:
        if 'alt_db' in locals():
            alt_db.close()

def save_parsed_news(parsed_news, site_config, db, User, UserContent):
    logger.info(f"[save_parsed_news] Starting save for: {site_config['username']}")
    logger.info(f"[save_parsed_news] Parsed news count: {len(parsed_news)}")

    # Get or create user
    user = User.query.filter_by(username=site_config["username"]).first()
    if not user:
        logger.info(f"[save_parsed_news] Creating new user: {site_config['username']}")
        user = User(
            first_name=site_config["first_name"],
            last_name=site_config["last_name"],
            username=site_config["username"],
            email=site_config["email"],
            profile_picture_url=site_config["profile_picture"],
            login_type="normal",
            is_email_verified=False,
            accepted_terms_and_conditions=False,
        )
        db.session.add(user)
        db.session.flush()
    else:
        logger.info(f"[save_parsed_news] Found existing user: {site_config['username']}")

    # ✅ Get ALL existing seeded news for comprehensive duplicate checking
    existing_news_data = UserContent.query.filter_by(is_seeded=True, seed_type="news").all()
    logger.info(f"[save_parsed_news] Existing seeded post count: {len(existing_news_data)}")

    skipped_invalid = 0
    skipped_duplicates = 0
    duplicate_reasons = {}
    new_items = []

    for news in parsed_news:
        headline = news.get("headline", "").strip()
        link = news.get("link", "").strip()

        if not headline or not link:
            logger.warning(f"[save_parsed_news] Skipping invalid news item (missing headline or link)")
            skipped_invalid += 1
            continue

        # ✅ Explicit duplicate checking
        is_duplicate, reason = check_for_duplicates(headline, link, existing_news_data)
        
        if is_duplicate:
            logger.info(f"[save_parsed_news] Skipping duplicate ({reason}): {headline[:60]}")
            skipped_duplicates += 1
            duplicate_reasons[reason] = duplicate_reasons.get(reason, 0) + 1
            continue

        # ✅ All checks passed - save the news item
        logger.info(f"[save_parsed_news] Saving new headline: {headline[:60]}")
        uc = UserContent(
            title=headline,
            body=news.get("body", news["headline"]),
            news_link=link,
            thumbnail=news.get("image_url"),
            created_at=news.get("timestamp") or datetime.utcnow(),
            user_id=user.id,
            is_seeded=True,
            seed_type="news",
            is_in_seattle=True,
            location=LOCATION_MAP.get(site_config["username"], None),
            seeded_likes_count=random.randint(15, 60),
            seeded_comments_count=0,
            unique_id=random.randint(1_000_000_000, 9_999_999_999),
        )
        db.session.add(uc)
        new_items.append((headline, link))
        
        # Add to existing data for this batch to prevent duplicates within the same run
        existing_news_data.append(uc)

    # Save to primary database
    db.session.commit()
    logger.info(f"[save_parsed_news] ✅ Committed {len(new_items)} new news items to primary database.")
    
    # Save to alternate database if in production or staging
   
    
    # Log detailed duplicate statistics
    if duplicate_reasons:
        logger.info(f"[save_parsed_news] Duplicate breakdown:")
        for reason, count in duplicate_reasons.items():
            logger.info(f"[save_parsed_news]   - {reason}: {count}")

    return {
        "saved": len(new_items),
        "skipped_duplicates": skipped_duplicates,
        "duplicate_reasons": duplicate_reasons,
        "skipped_invalid": skipped_invalid
    }
