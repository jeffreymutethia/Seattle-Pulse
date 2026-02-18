# app/extensions.py
# app/extensions.py
from flask_sqlalchemy import SQLAlchemy
from flask_mail import Mail
from flask_socketio import SocketIO
from config import CORS_ALLOWED_ORIGINS

db = SQLAlchemy()
mail = Mail()

# explicitly choose eventlet async mode and allow CORS
socketio = SocketIO(
    cors_allowed_origins=CORS_ALLOWED_ORIGINS,
    async_mode="eventlet", 
    logger=True, 
    engineio_logger=True,
)
