import socketio
import logging
import time

# Configure Logger
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - [WEBSOCKET CLIENT] - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()],  # Logs to console
)

logger = logging.getLogger("socketio_client")

# Create a Socket.IO client
sio = socketio.Client()


@sio.event
def connect():
    logger.info("✅ WebSocket Connection Opened")
    subscribe_to_all_notifications()  # Subscribe when connected


@sio.event
def disconnect():
    logger.warning("❌ WebSocket Disconnected. Reconnecting in 5 seconds...")
    time.sleep(5)
    reconnect()


def reconnect():
    """Reconnect to the WebSocket server."""
    while True:
        try:
            logger.info("🔄 Attempting to reconnect...")
            sio.connect("http://127.0.0.1:5001")  # Use HTTP, not ws://
            logger.info("🔗 Reconnected successfully")
            subscribe_to_all_notifications()  # Re-subscribe after reconnecting
            break
        except Exception as e:
            logger.error(f"🚨 Reconnection Error: {e}")
            time.sleep(5)  # Wait before retrying


# Listen for ALL notifications
def subscribe_to_all_notifications():
    """Subscribe to all WebSocket notification events dynamically."""

    @sio.on("*")
    def handle_all_events(event, data):
        if event.startswith("notify_"):  # Only listen to notification events
            logger.info(f"🔔 Notification Received ({event}): {data}")

    logger.info("📡 Subscribed to ALL notifications")


if __name__ == "__main__":
    try:
        sio.connect("http://127.0.0.1:5001")  # Use HTTP
        sio.wait()  # Keep listening indefinitely
    except Exception as e:
        logger.error(f"🚨 Connection Error: {e}")
        reconnect()
