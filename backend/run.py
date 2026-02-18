# run.py
import eventlet
eventlet.monkey_patch()

import os
import logging
from app import create_app
from app.extensions import socketio

app, celery = create_app()

# Health checking endpoint for ready state
@app.route('/health')
def health_check():
    return "OK", 200


@app.route('/ping')
def ping():
    return "pong", 200

if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG,
                        format="%(asctime)s - %(levelname)s - %(message)s")
    
    app_env = os.getenv("APP_ENV", "local").lower()
    is_debug_mode = app_env != "production"

    logging.info(f"🚀 Starting Flask-SocketIO (Eventlet) on ws://0.0.0.0:5000 with debug={is_debug_mode}")
    
    socketio.run(
        app,
        host="0.0.0.0",
        port=int(os.getenv("PORT", 5000)),
        debug=is_debug_mode
    )
