import datetime
import sys
import os

# Add the app directory to the path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def seed_news_users(db_session):
    users = [
        {
            "first_name": "Capitol",
            "last_name": "Hill",
            "username": "Capitol Hill Seattle",
            "email": "contact@capitolhillseattle.com",
            "profile_picture_url": "https://seattlepulse-logos.s3.us-east-1.amazonaws.com/Seattle+Pulse_Logo/news-logos/chs.png",
        },
        {
            "first_name": "Komo",
            "last_name": "News",
            "username": "Komo News",
            "email": "contact@komonews.com",
            "profile_picture_url": "https://seattlepulse-logos.s3.us-east-1.amazonaws.com/Seattle+Pulse_Logo/news-logos/komo_news_ppic.jpeg",
        },
        {
            "first_name": "My",
            "last_name": "Ballard",
            "username": "My Ballard",
            "email": "contact@myballard.com",
            "profile_picture_url": "https://seattlepulse-logos.s3.us-east-1.amazonaws.com/Seattle+Pulse_Logo/news-logos/my%20ballard.png",
        },
        {
            "first_name": "Seattle",
            "last_name": "Times",
            "username": "Seattle Times",
            "email": "editor@seattletimes.com",
            "profile_picture_url": "https://asterprofilepics.s3.us-west-1.amazonaws.com/seattletimes_ppic.jpeg",
        },
        {
            "first_name": "The",
            "last_name": "Needling",
            "username": "The Needling",
            "email": "editor@theneedling.com",
            "profile_picture_url": "https://seattlepulse-logos.s3.us-east-1.amazonaws.com/Seattle+Pulse_Logo/news-logos/Needling_banner_102118.jpg",
        },
        {
            "first_name": "The",
            "last_name": "Stranger",
            "username": "The Stranger",
            "email": "editor@thestranger.com",
            "profile_picture_url": "https://seattlepulse-logos.s3.us-east-1.amazonaws.com/Seattle+Pulse_Logo/news-logos/the%20stranger.png",
        },
    ]

    # Use timezone-aware datetime
    now = datetime.datetime.now(datetime.timezone.utc)

    for user in users:
        try:
            # Check if user exists by username
            existing_user = db_session.execute(
                text("SELECT id FROM users WHERE username = :username"),
                {"username": user["username"]}
            ).fetchone()
            
            if existing_user:
                # Update existing user
                db_session.execute(
                    text("""
                    UPDATE users SET
                        first_name = :first_name,
                        last_name = :last_name,
                        email = :email,
                        profile_picture_url = :profile_picture_url,
                        updated_at = :updated_at
                    WHERE username = :username
                    """),
                    {
                        "first_name": user["first_name"],
                        "last_name": user["last_name"],
                        "email": user["email"],
                        "profile_picture_url": user["profile_picture_url"],
                        "updated_at": now,
                        "username": user["username"],
                    }
                )
                print(f"✅ Updated existing user: {user['username']}")
            else:
                # Create new user
                db_session.execute(
                    text("""
                    INSERT INTO users (
                        first_name, last_name, username, email, profile_picture_url,
                        login_type, is_email_verified, created_at, updated_at, accepted_terms_and_conditions, show_home_location
                    )
                    VALUES (
                        :first_name, :last_name, :username, :email, :profile_picture_url,
                        'normal', false, :created_at, :updated_at, false, false
                    )
                    """),
                    {
                        "first_name": user["first_name"],
                        "last_name": user["last_name"],
                        "username": user["username"],
                        "email": user["email"],
                        "profile_picture_url": user["profile_picture_url"],
                        "created_at": now,
                        "updated_at": now,
                    }
                )
                print(f"✅ Created new user: {user['username']}")
                
        except Exception as e:
            print(f"❌ Failed to upsert user: {user['username']}. Error: {e}")

    try:
        db_session.commit()
        print("✅ Commit successful.")
    except Exception as e:
        print(f"❌ Commit failed. Error: {e}")

# Runner code - executes when script is run directly
if __name__ == "__main__":
    print("🌱 Starting news users seeding...")
    
    try:
        # Import Flask app and database
        from app import create_app
        from app.models import db
        from sqlalchemy import text
        
        # Create Flask app context
        app, _ = create_app()
        
        with app.app_context():
            # Get database session
            db_session = db.session
            
            # Run the seeding function
            seed_news_users(db_session)
            
            print("✅ News users seeding completed successfully!")
            
    except Exception as e:
        print(f"❌ Error during seeding: {e}")
        sys.exit(1)
