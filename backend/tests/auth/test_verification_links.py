import importlib
import os
from unittest import mock

# Ensure the config module can load during tests
os.environ.setdefault("DATABASE_URL", "sqlite:////tmp/seattlepulse-test.db")
import config as config_module


def _reload_config(app_env: str):
    """Reload config with a specific APP_ENV while keeping required env vars."""
    baseline_env = {
        "APP_ENV": app_env,
        # Provide a dummy database URL so config import doesn't fail during tests
        "DATABASE_URL": os.getenv("DATABASE_URL", "sqlite:///instance/site.db"),
    }
    with mock.patch.dict(os.environ, baseline_env, clear=False):
        return importlib.reload(config_module)


def test_verification_link_uses_production_base_url():
    original_env = os.getenv("APP_ENV")
    try:
        cfg = _reload_config("production")
        link = cfg.get_auth_verification_url("token123")
        assert link.startswith("https://seattlepulse.net/auth/verify-email?token=token123")
    finally:
        with mock.patch.dict(os.environ, {"APP_ENV": original_env or ""}, clear=False):
            importlib.reload(config_module)


def test_verification_link_uses_staging_base_url():
    original_env = os.getenv("APP_ENV")
    try:
        cfg = _reload_config("staging")
        link = cfg.get_auth_verification_url("token456")
        assert link.startswith("https://staging.seattlepulse.net/auth/verify-email?token=token456")
    finally:
        with mock.patch.dict(os.environ, {"APP_ENV": original_env or ""}, clear=False):
            importlib.reload(config_module)
