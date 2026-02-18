from flask import Blueprint, jsonify, request
from app.models import News, Reaction
from app import db
import logging
from app.location_service import format_post_location

# Set up logging
logger = logging.getLogger(__name__)

events_v1_blueprint = Blueprint("events_v1", __name__, url_prefix="/api/v1/events")


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
                "title": item.title,
                "description": item.description,
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


@events_v1_blueprint.route("/", methods=["GET"])
def api_events():
    """
    Endpoint to get event items.

    Returns:
        A JSON response containing the event items and a status message.
    """
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 10, type=int)
    try:
        events_query = News.query.filter(News.is_event == True).order_by(
            News.timestamp.desc()
        )
        items, has_more = get_paginated_items(events_query, page, per_page)
        return jsonify(
            data={"content": items, "hasMore": has_more},
            message="Event items fetched successfully",
            status="success",
        )
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error in api_events endpoint: {str(e)}")
        return jsonify(data=None, message="Internal server error", status="error"), 500
