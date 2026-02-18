import pytest
import logging
from sqlalchemy.exc import SQLAlchemyError
from app.models import db
from tests.conftest import client, test_user, client_authenticated

logger = logging.getLogger(__name__)


def test_login_success(client, test_user):
    """Test successful login with logging."""
    response = client.post(
        "/api/v1/auth/login",
        json={"email": test_user.email, "password": "SecureP@ss123"},
    )
    assert response.status_code == 200, f"Unexpected Response: {response.get_json()}"
    data = response.get_json()
    assert data["status"] == "success", f"Response Data: {data}"
    assert "user_id" in data["data"], "Missing `user_id` in response"


def test_login_unverified_email(client, session, test_user):
    """Test login with an unverified email with logging."""
    try:
        test_user.is_email_verified = False  # ✅ Modify user correctly
        session.commit()
    except SQLAlchemyError as e:
        session.rollback()
        logger.error("❌ Failed to update user as unverified.")
        logger.error(f"Exception Type: {type(e).__name__}")
        logger.error(f"Error Details: {e}")
        raise

    response = client.post(
        "/api/v1/auth/login",
        json={"email": test_user.email, "password": "SecureP@ss123"},  # ✅ Use the fixture properly
    )
    assert response.status_code == 403, f"Unexpected Response: {response.get_json()}"
    data = response.get_json()
    assert data["status"] == "error"
    assert "Email is not verified" in data["message"]


def test_login_missing_fields(client):
    """Test login with missing fields."""
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "test@example.com"},
    )
    assert response.status_code == 400
    data = response.get_json()
    assert data["status"] == "error"
    assert "Missing required fields" in data["message"]


def test_login_invalid_credentials(client):
    """Test login with invalid credentials."""
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "test@example.com", "password": "WrongPassword"},
    )
    assert response.status_code == 401
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "Invalid email or password."


def test_login_already_authenticated(client_authenticated, test_user):
    """Test login when already authenticated."""
    response = client_authenticated.post(
        "/api/v1/auth/login",
        json={"email": test_user.email, "password": "SecureP@ss123"},
    )
    assert response.status_code == 400
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "User already authenticated."
