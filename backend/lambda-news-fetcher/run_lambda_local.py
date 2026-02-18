import importlib.util
import os

# Path to the actual file
handler_path = os.path.join("lambda-news-fetcher", "lambda_handler.py")

spec = importlib.util.spec_from_file_location("lambda_handler", handler_path)
lambda_handler = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lambda_handler)

# Now use the handler
print("\n--- Running KOMO-only (default) ---")
response_komo = lambda_handler.handler({}, None)
print("Response:", response_komo)

print("\n--- Running Multi-source ---")
response_multi = lambda_handler.handler({"multi": True}, None)
print("Response:", response_multi)
