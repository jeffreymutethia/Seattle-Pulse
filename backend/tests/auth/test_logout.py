import pytest
import flask_login
import logging
from app.models import User, db
from tests.conftest import client

logger = logging.getLogger(__name__)


def log_response(response):
    """Log detailed information about the response."""
    logger.info(f"Status Code: {response.status_code}")
    logger.info(f"Response JSON: {response.json}")


@pytest.fixture
def new_user():
    """Fixture to create a new user for testing with logging."""
    try:
        user = User(
            name="Test User",
            username="testuser",
            email="test@example.com",
            is_email_verified=True,
            accepted_terms_and_conditions=True,  # ✅ Ensure required field
        )
        user.set_password("TestPassword123")  # ✅ Ensure valid password
        db.session.add(user)
        db.session.commit()
        return user
    except Exception as e:
        db.session.rollback()
        logger.error("❌ Failed to create test user.")
        logger.error(f"Exception Type: {type(e).__name__}")
        logger.error(f"Error Details: {e}")
        raise


def test_login_success(client, new_user):
    """Test successful login with logging."""
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "test@example.com", "password": "TestPassword123"},
    )

    # 🛠️ Log response for debugging
    log_response(response)

    # ✅ Ensure successful login response
    assert response.status_code == 200, f"Unexpected Response: {response.get_json()}"
    data = response.get_json()
    assert data["status"] == "success", f"Response Data: {data}"
    assert "user_id" in data["data"], "Missing `user_id` in response"
