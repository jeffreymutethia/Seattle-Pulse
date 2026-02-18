import pytest
from unittest.mock import patch, MagicMock
from app.models import User
from tests.conftest import client


@pytest.fixture
def client(app):
    """Provide a test client."""
    return app.test_client()


@patch("app.models.User.query")  # Change from filter_by to query
@patch("app.api.auth.send_reset_email")  # Mock email function
def test_reset_password_request_success(mock_send_email, mock_query, client):
    """Test successful password reset request."""

    # ✅ Mock user instance
    mock_user = MagicMock(spec=User)
    mock_user.email = "test@example.com"
    mock_user.get_reset_token.return_value = "mocked_token"

    # ✅ Ensure `query.filter_by().first()` returns the mocked user
    mock_query.filter_by.return_value.first.return_value = mock_user
    mock_send_email.return_value = None  # Mock email function to prevent sending

    # ✅ Make the request
    response = client.post(
        "/api/v1/auth/reset_password_request",
        json={"email": "test@example.com"},
    )

    # ✅ Validate response
    assert response.status_code == 200, f"Unexpected response: {response.get_json()}"
    data = response.get_json()
    assert data["status"] == "success"
    assert data["message"] == "Password reset email sent."


def test_reset_password_request_missing_email(client):
    """Test password reset request with missing email."""
    response = client.post(
        "/api/v1/auth/reset_password_request",
        json={"email": ""},  # ✅ Explicitly provide an empty email field
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "Email is required."


def test_reset_password_request_invalid_json(client):
    """Test password reset request with invalid JSON payload."""
    response = client.post(
        "/api/v1/auth/reset_password_request",
        data="invalid json",  # Malformed JSON
        headers={"Content-Type": "application/json"},  # ✅ Set correct Content-Type
    )

    assert response.status_code == 400  # Now it should correctly return 400
    data = response.get_json()
    assert data["status"] == "error"
    assert (
        data["message"] == "Malformed JSON. Check your request body."
    )  # Updated expected message


@patch("app.models.User.query.filter_by")
def test_reset_password_request_user_not_found(mock_query, client):
    """Test password reset request for non-existent user."""

    mock_query.return_value.first.return_value = None  # No user found

    response = client.post(
        "/api/v1/auth/reset_password_request",
        json={"email": "notfound@example.com"},
    )

    assert response.status_code == 404
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "No user found with this email address."
