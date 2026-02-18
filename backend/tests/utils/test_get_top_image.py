import pytest
from unittest.mock import patch

import importlib.util
import pathlib
import types
import sys
import os

os.environ.setdefault("DISABLE_AUTO_CREATE_APP", "1")
os.environ.setdefault("AWS_LAMBDA_FUNCTION_NAME", "tests")
os.environ.setdefault("DATABASE_URL", "postgresql://user:pass@localhost/test")

ROOT = pathlib.Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

UTILS_PATH = pathlib.Path(__file__).resolve().parents[2] / "app" / "utils.py"

# Create a minimal fake app package to satisfy relative imports in utils
app_pkg = types.ModuleType("app")
models_mod = types.ModuleType("app.models")
class Dummy:
    pass
models_mod.News = Dummy
models_mod.db = Dummy
extensions_mod = types.ModuleType("app.extensions")
extensions_mod.mail = Dummy
app_pkg.models = models_mod
app_pkg.extensions = extensions_mod
fetchers_pkg = types.ModuleType("app.fetchers")
search_path = pathlib.Path(__file__).resolve().parents[2] / "app" / "fetchers" / "search_providers.py"
spec_fetch = importlib.util.spec_from_file_location("app.fetchers.search_providers", search_path)
search_module = importlib.util.module_from_spec(spec_fetch)
spec_fetch.loader.exec_module(search_module)
fetchers_pkg.search_providers = search_module
sys.modules.setdefault("app", app_pkg)
sys.modules.setdefault("app.models", models_mod)
sys.modules.setdefault("app.extensions", extensions_mod)
sys.modules.setdefault("app.fetchers", fetchers_pkg)
sys.modules.setdefault("app.fetchers.search_providers", search_module)

spec = importlib.util.spec_from_file_location("app.utils", UTILS_PATH)
utils = importlib.util.module_from_spec(spec)
sys.modules.setdefault("app.utils", utils)
spec.loader.exec_module(utils)

get_top_image = utils.get_top_image
DEFAULT_IMAGE_PLACEHOLDER = utils.DEFAULT_IMAGE_PLACEHOLDER


@patch("app.utils.GoogleImageSearchProvider.search")
def test_get_top_image_success(mock_search):
    mock_search.return_value = "http://example.com/cat.jpg"
    assert get_top_image("cats") == "http://example.com/cat.jpg"


@patch("app.utils.GoogleImageSearchProvider.search")
def test_get_top_image_failure(mock_search):
    mock_search.side_effect = Exception("fail")
    assert get_top_image("dogs") == DEFAULT_IMAGE_PLACEHOLDER



