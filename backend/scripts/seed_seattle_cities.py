import sys
import os
from datetime import datetime, timezone

# Add the project root directory to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import create_app, db
from app.models import Location

# Initialize the Flask app and Celery (unpack the tuple)
app, _ = create_app()

# Only these three neighborhoods
locations = [
    {"name": "Capitol Hill",         "latitude": 47.6231, "longitude": -122.3207},
    {"name": "University District",  "latitude": 47.6613, "longitude": -122.3134},
    {"name": "Ballard",              "latitude": 47.6686, "longitude": -122.3860},
]

# Seed the locations into the database
with app.app_context():
    try:
        for loc in locations:
            existing_location = Location.query.filter_by(name=loc["name"]).first()
            if not existing_location:
                location = Location(
                    name=loc["name"],
                    latitude=loc["latitude"],
                    longitude=loc["longitude"],
                    created_at=datetime.now(timezone.utc),
                    updated_at=datetime.now(timezone.utc),
                )
                db.session.add(location)
        
        db.session.commit()
        print("Locations seeded successfully!")
    except Exception as e:
        db.session.rollback()
        print(f"Error seeding locations: {e}")
