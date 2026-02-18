# app/rate_limiting.py
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

# Configure the limiter with a default rate limit
limiter = Limiter(key_func=get_remote_address, default_limits=["5 per 5 minutes"])
