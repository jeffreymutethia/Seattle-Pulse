from flask import Blueprint, jsonify, request
from app import db
from app.models import News, Reaction
import logging
from app.location_service import format_post_location

# Set up logging
logger = logging.getLogger(__name__)

# Create a blueprint for news-related endpoints
news_v1_blueprint = Blueprint("news_v1", __name__, url_prefix="/api/v1/news")


# A Helper function to paginate query results
def get_paginated_items(query, page, per_page):
    """
    Paginate query results.

    Returns:
        A tuple containing the list of items and a boolean indicating if there are more items.
    """
    pagination = query.paginate(page=page, per_page=per_page)
    items = []
    for item in pagination.items:
        items.append(
            {
                "id": item.id,
                "unique_id": item.unique_id,
                "title": item.headline,
                "image_url": item.image_url,
                "location": item.location,
                "location_label": format_post_location(item),
                "is_in_seattle": getattr(item, "is_in_seattle", None),
                "user": {
                    "username": item.user.username,
                    "profile_picture_url": (
                        item.user.profile_picture_url
                        if item.user.profile_picture_url
                        else ""
                    ),
                },
                "total_reactions": Reaction.query.filter_by(
                    content_id=item.unique_id, content_type="story"
                ).count(),
            }
        )
    return items, pagination.has_next


# Define the endpoint to get news items
@news_v1_blueprint.route("/", methods=["GET"])
def api_news():
    """
    Endpoint to get news items with pagination metadata.

    Returns:
        A JSON response containing the news items, pagination details, and a status message.
    """
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 10, type=int)
    try:
        # Query all news items ordered by timestamp
        news_query = News.query.order_by(News.timestamp.desc())

        # Total items BEFORE pagination
        total_items = news_query.count()

        # Apply pagination AFTER counting
        pagination = news_query.paginate(page=page, per_page=per_page, error_out=False)
        items = [
            {
                "id": item.id,
                "unique_id": item.unique_id,
                "title": item.headline,
                "image_url": item.image_url,
                "location": item.location,
                "location_label": format_post_location(item),
                "is_in_seattle": getattr(item, "is_in_seattle", None),
                "user": {
                    "username": item.user.username,
                    "profile_picture_url": (
                        item.user.profile_picture_url
                        if item.user.profile_picture_url
                        else ""
                    ),
                },
                "total_reactions": Reaction.query.filter_by(
                    content_id=item.unique_id, content_type="story"
                ).count(),
            }
            for item in pagination.items
        ]

        # Pagination Logic
        total_pages = total_items // per_page + (1 if total_items % per_page > 0 else 0)
        has_next = page < total_pages
        has_prev = page > 1

        # Log pagination details
        logger.debug(f"Pagination - Page: {page}, Total Pages: {total_pages}, Total Items: {total_items}")

        # Return response with pagination metadata
        return jsonify(
            data={"content": items},
            pagination={
                "current_page": page,
                "total_pages": total_pages,
                "total_items": total_items,
                "has_next": has_next,
                "has_prev": has_prev,
            },
            message="News items fetched successfully",
            status="success",
        ), 200

    except Exception as e:
        db.session.rollback()
        logger.error(f"Error in api_news endpoint: {str(e)}")
        return jsonify(data=None, message="Internal server error", status="error"), 500
    
    
@news_v1_blueprint.route("/trigger-fetch", methods=["POST"])
def trigger_news_fetch():
    from app.fetchers.news_fetcher import fetch_data
    from config import NEWS_SOURCE_KOMO
    source_url = NEWS_SOURCE_KOMO
    task = fetch_data.delay(source_url)
    return jsonify({"message": "News fetch task triggered", "task_id": task.id}), 202
