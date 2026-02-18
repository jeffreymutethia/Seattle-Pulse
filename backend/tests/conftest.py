import pytest
import logging
from app import create_app, db
from flask_login import login_user
from app.models import User
from flask import g
from unittest.mock import MagicMock

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


@pytest.fixture(scope="session")
def app():
    """Create and configure a new app instance for testing."""
    app, _ = create_app()  # No need to pass "testing"

    app.config["SERVER_NAME"] = "localhost:5000"
    app.config["APPLICATION_ROOT"] = "/"
    app.config["PREFERRED_URL_SCHEME"] = "http"
    app.config["TESTING"] = True  # Ensures test mode is enabled

    with app.app_context():
        db.create_all()
        yield app
        db.session.remove()
        db.drop_all()


@pytest.fixture
def test_user(session):
    """Create a test user in the database."""
    existing_user = session.query(User).filter_by(email="auth_user@example.com").first()
    if existing_user:
        return existing_user  # ✅ Return existing user to avoid duplicates

    user = User(
        name="Authenticated User",
        username="auth_user",
        email="auth_user@example.com",
        accepted_terms_and_conditions=True,
        is_email_verified=True,  # ✅ Ensure the email is verified for login tests
    )
    user.set_password("SecureP@ss123")
    session.add(user)
    session.commit()
    return user


@pytest.fixture(scope="function")
def client(app):
    """Creates a test client for making requests."""
    return app.test_client()


@pytest.fixture(scope="function")
def app_context(app):
    """Provides an active Flask application context for each test."""
    with app.app_context():
        yield


@pytest.fixture
def runner(app):
    """A test runner for the app's Click commands.

    This fixture provides a test runner for the Flask application's Click commands,
    allowing you to test command-line interface (CLI) commands.
    """
    return app.test_cli_runner()


@pytest.fixture
def session(app):
    """Create a new database session for a test."""
    with app.app_context():
        connection = db.engine.connect()
        transaction = connection.begin()
        session = db.session  # ✅ Use db.session directly

        yield session

        transaction.rollback()
        connection.close()
        session.remove()


@pytest.fixture
def users(session):
    """Creates test users with valid names."""
    users = [
        User(
            name=f"User {i}",  # ✅ Ensure the name is not NULL
            username=f"user_{i}",
            email=f"user_{i}@test.com",
            is_email_verified=True,
        )
        for i in range(5)
    ]
    for user in users:
        user.set_password("SecureP@ss123")
        session.add(user)
    session.commit()
    return users


@pytest.fixture
def client_authenticated(client, test_user):
    """Simulate an authenticated user session properly."""
    with client.application.app_context():
        with client.application.test_request_context():  # ✅ Ensure request context
            login_user(test_user)  # ✅ Log in the user within a request
            g._flask_login_user = (
                test_user  # ✅ Store user in global context for Flask-Login
            )

    with client.session_transaction() as session:
        session["_user_id"] = str(test_user.id)  # ✅ Store user ID in session
        session["_fresh"] = True  # ✅ Mark session as fresh

    return client


@pytest.fixture(scope="function", autouse=True)
def clear_database(session):
    """Ensure the database is cleaned before each test."""
    session.rollback()
    for table in reversed(db.metadata.sorted_tables):
        session.execute(table.delete())  # Clear all tables
    session.commit()


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Log test failures with detailed error messages.

    This hook implementation logs detailed error messages for test failures,
    including the exception type and error message. It helps in debugging
    test failures by providing more context in the logs.
    """
    outcome = yield
    report = outcome.get_result()

    if report.failed:
        logger.error(f"\n🔴 TEST FAILED: {item.name}")
        if call.excinfo:
            logger.error(f"\nException Type: {call.excinfo.type}")
            logger.error(f"Error Message: {call.excinfo.value}")
            if hasattr(call.excinfo.value, "orig"):
                logger.error(f"Original Database Error: {call.excinfo.value.orig}")
        logger.error("🔥 Check the logs above for more details.\n")


@pytest.fixture
def mock_user():
    """Create a mock user object."""
    user = MagicMock()
    user.id = 2
    return user


@pytest.fixture
def mock_current_user():
    """Create a mock current user object."""
    current_user = MagicMock()
    current_user.id = 1
    current_user.is_following.return_value = True
    return current_user
