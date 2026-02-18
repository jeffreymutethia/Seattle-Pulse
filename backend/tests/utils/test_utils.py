import pytest
from app.utils import is_valid_email, validate_password


@pytest.mark.parametrize(
    "email, expected_result",
    [
        ("valid.email@example.com", True),  # ✅ Valid email
        ("user+test@domain.co.uk", True),  # ✅ Valid with plus and subdomain
        ("invalid-email.com", False),  # ❌ Missing @
        ("user@.com", False),  # ❌ Missing domain
        ("user@domain..com", False),  # ❌ Double dot in domain
        ("user@domain@domain.com", False),  # ❌ Multiple @ symbols
        ("plainaddress", False),  # ❌ No domain
        ("@missingusername.com", False),  # ❌ Missing username
    ],
)
def test_is_valid_email(email, expected_result):
    """Test the email validation function with different email formats."""
    assert is_valid_email(email) == expected_result, f"Failed for email: {email}"


@pytest.mark.parametrize(
    "password, expected_valid, expected_message",
    [
        ("SecureP@ss123", True, ""),  # ✅ Valid password
        (
            "short",
            False,
            "Password too weak,Password must be at least 8 characters long.",
        ),  # ❌ Too short
        (
            "lowercaseonly123!",
            False,
            "Password must contain at least one uppercase letter.",
        ),  # ❌ Missing uppercase
        (
            "UPPERCASEONLY123!",
            False,
            "Password must contain at least one lowercase letter.",
        ),  # ❌ Missing lowercase
        (
            "NoDigitsOrSpecial!",
            False,
            "Password must contain at least one digit.",
        ),  # ❌ Missing digit
        (
            "NoSpecialChars123",
            False,
            "Password must contain at least one special character.",
        ),  # ❌ Missing special character
        ("Valid@1234", True, ""),  # ✅ Valid password with special character
        (
            "validpassword",
            False,
            "Password must contain at least one uppercase letter.",
        ),  # ❌ No uppercase, digit, or special
    ],
)
def test_validate_password(password, expected_valid, expected_message):
    """Test the password validation function with different password strengths."""
    is_valid, message = validate_password(password)
    assert is_valid == expected_valid, f"Failed for password: {password}"
    assert message == expected_message, f"Expected: {expected_message}, Got: {message}"
