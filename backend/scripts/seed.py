import sys
import os
import random
import logging
from datetime import datetime, timezone
from sqlalchemy import text

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import create_app, db
from app.models import (
    User,
    Follow,
    Reaction,
    Block,
    UserContent,
    ReactionType,
    DirectChat,
    DirectMessage,
    GroupChat,
    GroupChatMember,
    GroupMessage,
    RoleEnum,
)
from sqlalchemy.exc import IntegrityError

# Configure Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app, _ = create_app()

# ---------------------------------------------------------------------------- #
# Database clearing function (optional)
# ---------------------------------------------------------------------------- #

def clear_database():
    """Clear all data from the database and reset sequences."""
    try:
        db.session.execute(text("TRUNCATE TABLE reaction RESTART IDENTITY CASCADE;"))
        db.session.execute(text("TRUNCATE TABLE block RESTART IDENTITY CASCADE;"))
        db.session.execute(text("TRUNCATE TABLE follow RESTART IDENTITY CASCADE;"))
        db.session.execute(text("TRUNCATE TABLE user_content RESTART IDENTITY CASCADE;"))
        db.session.execute(text("TRUNCATE TABLE users RESTART IDENTITY CASCADE;"))
        db.session.commit()
        print("🧹 Database cleared successfully.")
    except Exception as e:
        db.session.rollback()
        print(f"❌ Failed to clear database: {e}")

# ---------------------------------------------------------------------------- #
# Enhanced content generator
# ---------------------------------------------------------------------------- #

SEATTLE_NEIGHBORHOOD_HEADLINES = {
    "Capitol Hill": [
        "Art Walk Returns to Capitol Hill this Weekend",
        "New Vegan Café Opens on Pike Street",
        "Outdoor Movie Nights Begin at Volunteer Park"
    ],
    "Ballard": [
        "Ballard Farmers Market Welcomes Summer Harvest",
        "Historic Ship Canal Bridge Undergoes Renovation",
        "Ballard Locks Fish Ladder Viewing Season Starts"
    ],
    "U District": [
        "U District Street Fair Draws Thousands",
        "Campus Bookstore Hosts Poetry Reading",
        "New Bike Lane Installed on 45th Street"
    ]
}

OUTSIDE_HEADLINES = {
    "Bellevue": [
        "Bellevue City Council Approves New Park",
        "Tech Conference Kicks Off Downtown Bellevue",
        "Bellevue Botanical Garden Spring Blooms Tour"
    ],
    "Shoreline": [
        "Shoreline Waterfront Trail Extension Completed",
        "Community Cleanup Day in Richmond Beach",
        "Shoreline Farmers Market Opens for Season"
    ]
}


def random_body(title, location):
    return (f"Details on '{title}' happening in {location}. Join neighbors and visitors for a fun, community-driven "
            f"event. Stay tuned for more updates and share your experience!")


def random_image_url(query):
    # Uses Unsplash Source for random images by keyword
    tag = query.replace(' ', '+')
    return f"https://source.unsplash.com/random/640x480?{tag}"  # random legit photo


def seed_test_content():
    """Seed realistic posts in Seattle and outside"""
    # Select test users: user100 - user104
    test_users = [User.query.filter_by(email=f"user{100 + i}@example.com").first() for i in range(5)]

    # Seattle neighborhoods
    seattle_coords = {
        "Capitol Hill": (47.6254, -122.3219),
        "Ballard": (47.6687, -122.3831),
        "U District": (47.6638, -122.3135),
    }

    # Create 3 posts per Seattle neighborhood
    for neighborhood, (lat, lon) in seattle_coords.items():
        headlines = SEATTLE_NEIGHBORHOOD_HEADLINES[neighborhood]
        for title in headlines:
            user = random.choice(test_users)
            jitter_lat = lat + random.uniform(-0.0005, 0.0005)
            jitter_lon = lon + random.uniform(-0.0005, 0.0005)
            body = random_body(title, neighborhood)
            thumb_url = random_image_url(neighborhood)
            content = UserContent(
                title=title,
                body=body,
                user_id=user.id,
                unique_id=random.randint(100000, 999999),
                location=neighborhood,
                latitude=jitter_lat,
                longitude=jitter_lon,
                thumbnail=thumb_url,
                is_in_seattle=True
            )
            db.session.add(content)
    
    # Outside Seattle locations
    outside_coords = {
        "Bellevue": (47.6101, -122.2015),
        "Shoreline": (47.7557, -122.3415),
    }

    # Create 5 posts in each outside location
    for loc, (lat, lon) in outside_coords.items():
        headlines = OUTSIDE_HEADLINES[loc]
        for title in headlines:
            user = random.choice(test_users)
            jitter_lat = lat + random.uniform(-0.0005, 0.0005)
            jitter_lon = lon + random.uniform(-0.0005, 0.0005)
            body = random_body(title, loc)
            thumb_url = random_image_url(loc)
            content = UserContent(
                title=title,
                body=body,
                user_id=user.id,
                unique_id=random.randint(100000, 999999),
                location=loc,
                latitude=jitter_lat,
                longitude=jitter_lon,
                thumbnail=thumb_url,
                is_in_seattle=False
            )
            db.session.add(content)

    db.session.commit()
    logger.info("✅ Test-specific content seeded.")


# ---------------------------------------------------------------------------- #
# Main seeding orchestration
# ---------------------------------------------------------------------------- #

def seed_data(clear_db=False):
    if clear_db:
        clear_database()

    # ensure base users and relationships are seeded here (omitted for brevity)
    # ... existing seeding logic for users, follows, reactions, chats ...

    # Seed generic user content
    # ... preserve your existing generic content seeding ...

    # Now seed test content for feed filtering
    seed_test_content()

    logger.info("✅ Complete seeding including realistic test posts.")


if __name__ == "__main__":
    with app.app_context():
        seed_data()
