import pytest
import logging
from app.models import User, db
from sqlalchemy.exc import SQLAlchemyError
from tests.conftest import client

logger = logging.getLogger(__name__)


@pytest.fixture(scope="function", autouse=True)
def clear_database():
    """Ensure the database is cleaned before each test."""
    db.session.rollback()
    for table in reversed(db.metadata.sorted_tables):
        db.session.execute(table.delete())
    db.session.commit()


@pytest.fixture
def test_user():
    """Creates a test user for authentication purposes."""
    user = User(
        name="Authenticated User",
        username="auth_user",
        email="auth_user@example.com",
        accepted_terms_and_conditions=True,
    )
    user.set_password("SecureP@ss123")
    db.session.add(user)
    db.session.commit()
    return user


@pytest.fixture
def client_authenticated(client, test_user):
    """Logs in the test user before returning the client."""
    with client.session_transaction() as session:
        session["_user_id"] = test_user.id  # Simulating Flask-Login user session
    return client


@pytest.fixture
def client_unauthenticated(client):
    """Ensures the client does not have a user session."""
    with client.session_transaction() as session:
        session.clear()  # Removes authentication session data
    return client


def test_register_success(client_unauthenticated, mocker):
    """Test successful user registration when unauthenticated."""
    # Mock OTP and email sending
    mocker.patch("app.utils.generate_otp", return_value="123456")
    mocker.patch("app.utils.send_otp_email")

    data = {
        "name": "John Doe",
        "username": "johndoe",
        "email": "john@example.com",
        "password": "SecureP@ss123",
        "accepted_terms_and_conditions": True,
    }

    response = client_unauthenticated.post("/api/v1/auth/register", json=data)
    json_data = response.get_json()

    assert response.status_code == 201
    assert json_data["status"] == "success"
    assert (
        json_data["message"]
        == "User registered successfully. Please verify your email."
    )
    assert "user_id" in json_data["data"]


def test_register_missing_fields(client_unauthenticated):
    """Test registration failure when required fields are missing."""
    data = {"username": "johndoe", "email": "john@example.com"}

    response = client_unauthenticated.post("/api/v1/auth/register", json=data)
    json_data = response.get_json()

    assert response.status_code == 400
    assert json_data["status"] == "error"
    assert "Missing required fields" in json_data["message"]


def test_register_duplicate_username(client_unauthenticated, mocker):
    """Test registration failure when username is already taken."""
    # Create a user first
    user = User(
        name="Existing User",
        username="johndoe",
        email="existing@example.com",
        accepted_terms_and_conditions=True,
    )
    user.set_password("SecureP@ss123")
    db.session.add(user)
    db.session.commit()

    # Try registering with the same username
    data = {
        "name": "New User",
        "username": "johndoe",  # Duplicate username
        "email": "new@example.com",
        "password": "SecureP@ss123",
        "accepted_terms_and_conditions": True,
    }

    response = client_unauthenticated.post("/api/v1/auth/register", json=data)
    json_data = response.get_json()

    assert response.status_code == 409
    assert json_data["status"] == "error"
    assert json_data["message"] == "Username already taken."


def test_register_invalid_email(client_unauthenticated):
    """Test registration failure when email format is invalid."""
    data = {
        "name": "John Doe",
        "username": "johndoe",
        "email": "invalid-email",
        "password": "SecureP@ss123",
        "accepted_terms_and_conditions": True,
    }

    response = client_unauthenticated.post("/api/v1/auth/register", json=data)
    json_data = response.get_json()

    assert response.status_code == 400
    assert json_data["status"] == "error"
    assert json_data["message"] == "Invalid email format."


def test_register_weak_password(client_unauthenticated, mocker):
    """Test registration failure when password is too weak."""
    mocker.patch(
        "app.utils.validate_password", return_value=(False, "Password too weak.")
    )

    data = {
        "name": "John Doe",
        "username": "johndoe",
        "email": "john@example.com",
        "password": "1234",
        "accepted_terms_and_conditions": True,
    }

    response = client_unauthenticated.post("/api/v1/auth/register", json=data)
    json_data = response.get_json()

    assert response.status_code == 400
    assert json_data["status"] == "error"
    assert "Password too weak" in json_data["message"]


