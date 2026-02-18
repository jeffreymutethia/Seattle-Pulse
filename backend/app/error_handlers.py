import socket
from flask import current_app, jsonify
from requests.exceptions import RequestException
from werkzeug.exceptions import HTTPException


# Function to register error handlers for the Flask app
def register_error_handlers(app):

    # 500 - Internal Server Error
    # Handles general server-side errors that aren't caught by specific handlers
    @app.errorhandler(500)
    def internal_server_error(e):
        # Log the error with stack trace for debugging
        current_app.logger.error(f"Server Error: {e}", exc_info=True)
        # Return a standardized JSON error response with a 500 status code
        return (
            jsonify(
                {
                    "status": "error",
                    "error": {
                        "code": 500,
                        "message": "An internal server error occurred. Please try again later.",
                    },
                }
            ),
            500,
        )

    # Catch-all handler for unhandled exceptions
    @app.errorhandler(Exception)
    def handle_exception(e):
        # Log the exception to help with debugging
        current_app.logger.error(f"Unhandled Exception: {e}", exc_info=True)
        # Return a generic error response for unexpected exceptions
        return (
            jsonify(
                {
                    "status": "error",
                    "error": {
                        "code": 500,
                        "message": "An unexpected error occurred. Please contact support.",
                    },
                }
            ),
            500,
        )

    # 503 - Service Unavailable (Network-related errors)
    # Catches errors from external API requests or network issues
    @app.errorhandler(RequestException)
    def handle_request_exception(e):
        # Log the network error
        current_app.logger.error(f"Network Error: {e}", exc_info=True)
        # Return a 503 error indicating a network problem
        return (
            jsonify(
                {
                    "status": "error",
                    "error": {
                        "code": 503,
                        "message": "A network error occurred. Please check your connection and try again.",
                    },
                }
            ),
            503,
        )

    # 504 - Gateway Timeout (Socket timeout errors)
    @app.errorhandler(socket.timeout)
    def handle_timeout_exception(e):
        # Log the timeout error
        current_app.logger.error(f"Timeout Error: {e}", exc_info=True)
        # Return a 504 error to inform the client that the request timed out
        return (
            jsonify(
                {
                    "status": "error",
                    "error": {
                        "code": 504,
                        "message": "The request timed out. Please try again later.",
                    },
                }
            ),
            504,
        )

    # 501 - Not Implemented
    # Handles cases where a feature is not yet implemented
    @app.errorhandler(501)
    def not_implemented_error(e):
        # Log the not implemented error for awareness
        current_app.logger.error(f"Not Implemented Error: {e}", exc_info=True)
        # Return a 501 response with a clear message
        return (
            jsonify(
                {
                    "status": "error",
                    "error": {
                        "code": 501,
                        "message": "This feature is not implemented yet. Please try again later.",
                    },
                }
            ),
            501,
        )

    # 502 - Bad Gateway
    # Handles communication issues between servers (proxy or upstream server issues)
    @app.errorhandler(502)
    def bad_gateway_error(e):
        # Log the error to indicate server-to-server communication issues
        current_app.logger.error(f"Bad Gateway Error: {e}", exc_info=True)
        # Return a 502 response to inform about the issue
        return (
            jsonify(
                {
                    "status": "error",
                    "error": {
                        "code": 502,
                        "message": "Bad gateway. There is a communication issue between servers.",
                    },
                }
            ),
            502,
        )

    # 503 - Service Unavailable
    # Catches general service unavailability due to overload or maintenance
    @app.errorhandler(503)
    def service_unavailable_error(e):
        # Log the error for server overload or maintenance issues
        current_app.logger.error(f"Service Unavailable Error: {e}", exc_info=True)
        # Return a 503 response indicating service unavailability
        return (
            jsonify(
                {
                    "status": "error",
                    "error": {
                        "code": 503,
                        "message": "Service unavailable. The server is temporarily overloaded or under maintenance.",
                    },
                }
            ),
            503,
        )

    # Catch-all handler for general HTTP exceptions (404, 405, etc.)
    @app.errorhandler(HTTPException)
    def handle_http_exception(e):
        # Log the HTTP error (e.g., 404 - Not Found, 405 - Method Not Allowed)
        current_app.logger.error(f"HTTP Exception: {e}", exc_info=True)
        # Return the appropriate status code and message from the exception
        return (
            jsonify(
                {
                    "status": "error",
                    "error": {
                        "code": e.code,  # Dynamic status code (404, 405, etc.)
                        "message": e.description,  # Pre-defined error message
                    },
                }
            ),
            e.code,
        )
