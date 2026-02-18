import pytest
from unittest.mock import patch, MagicMock
from app.models import User
from flask import json
from tests.conftest import client


@pytest.fixture
def client(app):
    """Provide a test client."""
    return app.test_client()


@patch("app.models.User.verify_reset_token")
@patch("app.models.db.session.commit")
def test_reset_password_success(mock_commit, mock_verify_token, client):
    """Test successful password reset."""
    mock_user = MagicMock(spec=User)
    mock_verify_token.return_value = mock_user

    response = client.post(
        "/api/v1/auth/reset_password?token=valid_token",
        json={"password": "NewPassword123", "confirm_password": "NewPassword123"},
    )

    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "success"
    assert data["message"] == "Password has been reset."
    mock_commit.assert_called_once()


def test_reset_password_missing_token(client):
    """Test reset password request with missing token."""
    response = client.post(
        "/api/v1/auth/reset_password",
        json={"password": "NewPassword123", "confirm_password": "NewPassword123"},
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "Token is required."


def test_reset_password_invalid_json(client):
    """Test reset password request with invalid JSON payload."""
    response = client.post(
        "/api/v1/auth/reset_password?token=valid_token",
        data="invalid json",
        headers={"Content-Type": "application/json"},
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["status"] == "error"
    assert (
        data["message"] == "Malformed JSON. Check your request body."
    ) 


def test_reset_password_missing_fields(client):
    """Test reset password request with missing password fields."""
    response = client.post(
        "/api/v1/auth/reset_password?token=valid_token",
        json={},
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "Password and confirm password are required."


def test_reset_password_mismatched_passwords(client):
    """Test reset password request with mismatched passwords."""
    response = client.post(
        "/api/v1/auth/reset_password?token=valid_token",
        json={"password": "NewPassword123", "confirm_password": "DifferentPassword"},
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "Passwords do not match."


@patch("app.models.User.verify_reset_token")
def test_reset_password_invalid_or_expired_token(mock_verify_token, client):
    """Test reset password request with invalid or expired token."""
    mock_verify_token.return_value = None  # Simulate expired or invalid token

    response = client.post(
        "/api/v1/auth/reset_password?token=invalid_token",
        json={"password": "NewPassword123", "confirm_password": "NewPassword123"},
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["status"] == "error"
    assert data["message"] == "Invalid or expired token."
