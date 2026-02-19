import os
import sys
from datetime import datetime, timedelta, timezone

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import create_app, db
from app.models import User, UserContent

DEMO_EMAIL = "demo@seattlepulse.local"
DEMO_USERNAME = "demo_user"
DEMO_PASSWORD = "DemoPass123!"

DEMO_POSTS = [
    {
        "unique_id": 910000000001,
        "title": "DEMO: Capitol Hill street mural showcase",
        "body": "Local artists are presenting new murals with live music in Capitol Hill.",
        "location": "Capitol Hill",
        "latitude": 47.6254,
        "longitude": -122.3219,
        "is_in_seattle": True,
        "thumbnail": "https://picsum.photos/seed/sp-demo-1/800/450",
    },
    {
        "unique_id": 910000000002,
        "title": "DEMO: Ballard market weekend highlights",
        "body": "Vendors and food trucks are live at the Ballard market this weekend.",
        "location": "Ballard",
        "latitude": 47.6687,
        "longitude": -122.3831,
        "is_in_seattle": True,
        "thumbnail": "https://picsum.photos/seed/sp-demo-2/800/450",
    },
    {
        "unique_id": 910000000003,
        "title": "DEMO: Bellevue waterfront cleanup event",
        "body": "Community volunteers are hosting a waterfront cleanup in Bellevue.",
        "location": "Bellevue",
        "latitude": 47.6101,
        "longitude": -122.2015,
        "is_in_seattle": False,
        "thumbnail": "https://picsum.photos/seed/sp-demo-3/800/450",
    },
]


def upsert_demo_user() -> User:
    user = User.query.filter_by(email=DEMO_EMAIL).first()
    if user is None:
        user = User(
            first_name="Demo",
            last_name="User",
            username=DEMO_USERNAME,
            email=DEMO_EMAIL,
            accepted_terms_and_conditions=True,
            is_email_verified=True,
            login_type="normal",
            bio="Deterministic demo account for local portfolio walkthroughs.",
        )
    else:
        user.first_name = "Demo"
        user.last_name = "User"
        user.username = DEMO_USERNAME
        user.accepted_terms_and_conditions = True
        user.is_email_verified = True
        user.login_type = "normal"

    user.set_password(DEMO_PASSWORD)
    db.session.add(user)
    db.session.flush()
    return user


def upsert_demo_posts(user: User) -> int:
    now = datetime.now(timezone.utc)
    created = 0

    for offset, payload in enumerate(DEMO_POSTS):
        post = UserContent.query.filter_by(user_id=user.id, title=payload["title"]).first()
        created_at = now - timedelta(minutes=(offset + 1))

        if post is None:
            post = UserContent(
                user_id=user.id,
                unique_id=payload["unique_id"],
                title=payload["title"],
                body=payload["body"],
                location=payload["location"],
                latitude=payload["latitude"],
                longitude=payload["longitude"],
                is_in_seattle=payload["is_in_seattle"],
                thumbnail=payload["thumbnail"],
                is_seeded=True,
                seed_type="demo",
                seeded_likes_count=12 + offset,
                seeded_comments_count=3 + offset,
                created_at=created_at,
                updated_at=created_at,
            )
            db.session.add(post)
            created += 1
            continue

        post.body = payload["body"]
        post.location = payload["location"]
        post.latitude = payload["latitude"]
        post.longitude = payload["longitude"]
        post.is_in_seattle = payload["is_in_seattle"]
        post.thumbnail = payload["thumbnail"]
        post.is_seeded = True
        post.seed_type = "demo"
        post.seeded_likes_count = 12 + offset
        post.seeded_comments_count = 3 + offset
        post.updated_at = now

    return created


def main() -> None:
    app, _ = create_app()
    with app.app_context():
        user = upsert_demo_user()
        created = upsert_demo_posts(user)
        db.session.commit()
        print("Demo seed complete.")
        print(f"Demo user: {DEMO_EMAIL}")
        print(f"Password: {DEMO_PASSWORD}")
        print(f"Posts added this run: {created}")
        print(f"Total demo posts: {len(DEMO_POSTS)}")


if __name__ == "__main__":
    main()
