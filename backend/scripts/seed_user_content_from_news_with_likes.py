from app.models import News, UserContent, Like, User, db
from app.utils import get_top_image
from datetime import datetime
import random

def seed_usercontent_from_news(limit=10):
    komo_user = User.query.filter_by(username="Komo News").first()
    if not komo_user:
        raise ValueError("Komo News user not found")

    recent_news = News.query.order_by(News.timestamp.desc()).limit(limit).all()
    all_users = User.query.all()
    
    if not all_users:
        raise ValueError("No users found to seed likes.")

    seeded_posts = []

    for news_item in recent_news:
        content = UserContent(
            title=news_item.headline[:255],
            body=news_item.headline,  # Can be replaced with a summarizer
            thumbnail=news_item.image_url[:255] if news_item.image_url else get_top_image(news_item.headline)[:255],
            created_at=news_item.timestamp,
            updated_at=news_item.timestamp,
            user_id=komo_user.id,
            unique_id=random.randint(1000000000, 2999999999),
            location=news_item.location,
            latitude=None,
            longitude=None,
            is_seeded=True
        )
        db.session.add(content)
        seeded_posts.append(content)

    db.session.commit()
    print(f"✅ Seeded {len(seeded_posts)} UserContent posts from News.")

    # Now, simulate likes
    for post in seeded_posts:
        like_count = random.randint(15, 60)
        selected_users = random.sample(all_users, min(like_count, len(all_users)))
        for user in selected_users:
            db.session.add(Like(user_id=user.id, post_id=post.id))
    
    db.session.commit()
    print(f"✅ Added random likes to {len(seeded_posts)} posts.")
