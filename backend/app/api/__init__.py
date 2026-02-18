from flask import Blueprint

# Create the API blueprint
auth_blueprint = Blueprint('api', __name__)

# Import API routes to register them with the blueprint
from . import auth
