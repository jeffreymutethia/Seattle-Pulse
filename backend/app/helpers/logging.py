import logging

def setup_logging(app):
    # Get logging level from the environment or use DEBUG as default
    log_level = app.config.get("LOGGING_LEVEL", "DEBUG").upper()

    # Configure the log handler
    handler = logging.StreamHandler()
    handler.setLevel(log_level)

    # Set the log format
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    handler.setFormatter(formatter)

    # Attach the handler to the app logger
    app.logger.addHandler(handler)
    app.logger.setLevel(log_level)
