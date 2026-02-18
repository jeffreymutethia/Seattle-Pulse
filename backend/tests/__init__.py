import pytest
import os
import sys

# Add the project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Provide a fallback database URL for tests
os.environ.setdefault("DATABASE_URL", "sqlite:///test.db")
os.environ.setdefault("APP_ENV", "testing")
os.environ.setdefault("AWS_LAMBDA_FUNCTION_NAME", "tests")
os.makedirs("/tmp", exist_ok=True)
with open("/tmp/client_secret.json", "w") as f:
    f.write("{}")

# Patch Google's OAuth flow to avoid parsing the dummy secrets file
import google_auth_oauthlib.flow
from unittest.mock import MagicMock

google_auth_oauthlib.flow.Flow.from_client_secrets_file = MagicMock(
    return_value=MagicMock(authorization_url=lambda: ("", ""))
)

from app import create_app, db  # Import app factory method


@pytest.fixture
def app():
    """Create and configure a new app instance for each test."""
    app, _ = create_app(config_name="testing")  # Unpack the tuple correctly
    app.config["TESTING"] = True  # Enable test mode
    app.config["SQLALCHEMY_DATABASE_URI"] = (
        "sqlite:///:memory:"  # Use in-memory DB for testing
    )

    with app.app_context():
        db.create_all()  # Create all tables
        yield app  # Provide the app instance for tests
        db.session.remove()
        db.drop_all()  # Clean up DB after tests


@pytest.fixture
def client(app):
    """Create a test client for sending requests."""
    return app.test_client()
