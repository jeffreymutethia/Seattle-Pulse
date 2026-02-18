from flask import jsonify, request, current_app, Blueprint, url_for
from flask_login import current_user, login_required
from werkzeug.utils import secure_filename
from datetime import datetime
from app.models import (
    UserContent,
    db,
    Reaction,
    Comment,
    News,
    CommentReaction,
    Bookmark,
    UserContent,
    Block,
    User,
    Share,
    Repost,
    ReportReason,
    ContentReport,
    HiddenContent,
    Location,
)
from app.utils import time_since_post, is_placeholder_image
from utils.aws_moderation import moderate_text
import random

from math import exp
from sqlalchemy import func, desc  # Import func and desc from SQLAlchemy
from app.models import ReactionType
import requests
from config import get_share_url, NOMINATIM_BASE_URL

from config import FRONTEND_URL
from sqlalchemy.orm import subqueryload
import uuid
from ..utils import (
    get_neighborhood,
    get_coordinates_from_location,
    is_coordinate_in_seattle,
)
from app.location_service import (
    InvalidLocation,
    apply_location_filter,
    display_location_value,
    format_post_location,
    parse_location_filter,
)
from werkzeug.exceptions import BadRequest
from app.api.upload import upload_thumbnail
from flask_cors import cross_origin
from collections import defaultdict, deque,OrderedDict
from itertools import cycle
from datetime import datetime, timedelta
from config import CORS_ALLOWED_ORIGINS
from typing import List, Dict
from app.api.upload import upload_thumbnail
from flask_cors import cross_origin
from collections import OrderedDict

# Create the content blueprint
content_v1_blueprint = Blueprint("content_v1", __name__, url_prefix="/api/v1/content")

import logging

logger = logging.getLogger(__name__)


def _get_item_user_id(item):
    """Helper to extract user_id from a dict or object."""
    if isinstance(item, dict):
        if "user_id" in item:
            return item.get("user_id")
        if "user" in item and isinstance(item["user"], dict):
            return item["user"].get("id")
    return getattr(item, "user_id", None)


def most_recent_per_source(items):
    """Return only the newest item per user/source."""
    latest = {}

    def get_created_at(obj):
        if isinstance(obj, dict):
            return obj.get("created_at")
        return getattr(obj, "created_at", None)

    for item in items:
        uid = _get_item_user_id(item)
        current = latest.get(uid)
        if current is None or (
            get_created_at(item) and get_created_at(item) > get_created_at(current)
        ):
            latest[uid] = item

    return sorted(latest.values(), key=get_created_at, reverse=True)


def avoid_consecutive_sources(items):
    """Reorder items so consecutive entries from the same user are avoided."""
    result = list(items)
    for i in range(1, len(result)):
        prev_id = _get_item_user_id(result[i - 1])
        curr_id = _get_item_user_id(result[i])
        if prev_id is not None and curr_id == prev_id:
            swap_idx = None
            for j in range(i + 1, len(result)):
                if _get_item_user_id(result[j]) != prev_id:
                    swap_idx = j
                    break
            if swap_idx is not None:
                result[i], result[swap_idx] = result[swap_idx], result[i]
    return result


def distribute_sources(items):
    """Return items in round-robin order grouped by user_id."""
    groups = OrderedDict()
    for item in items:
        uid = _get_item_user_id(item)
        groups.setdefault(uid, []).append(item)

    result = []
    active_keys = list(groups.keys())
    while active_keys:
        finished = []
        for uid in active_keys:
            user_items = groups.get(uid)
            if user_items:
                result.append(user_items.pop(0))
            if not user_items:
                finished.append(uid)
        for uid in finished:
            active_keys.remove(uid)
            groups.pop(uid, None)
    return result


    if spec.kind == "seattle_all":
        return "Seattle"
    if spec.kind == "outside":
        return "Outside Seattle"
    if getattr(spec, "label", None):
        return spec.label
    return normalized or "Seattle"

@content_v1_blueprint.route("/is_in_seattle", methods=["POST"])
@cross_origin()
def is_in_seattle():
    logger.info("Received POST /is_in_seattle")
    raw = request.get_data(as_text=True)
    logger.info("Raw body: %s", raw)

    try:
        data = request.get_json(force=True)
        logger.info("Parsed JSON body: %s", data)
    except Exception as e:
        logger.error("JSON parse error: %s", e)
        raise BadRequest("Invalid JSON payload.")

    if not data or "lat" not in data or "lon" not in data:
        raise BadRequest("Missing required fields 'lat' and 'lon' in request body.")

    try:
        lat = float(data["lat"])
        lon = float(data["lon"])
    except (TypeError, ValueError) as e:
        logger.error("Invalid lat/lon types: %s", e)
        raise BadRequest("Please provide valid numeric values for 'lat' and 'lon'.")

    inside_np = is_coordinate_in_seattle(lat, lon)
    inside = bool(inside_np)
    logger.info("Coordinate (%s, %s) → inside: %s", lat, lon, inside)
    
    neighborhoods_gdf = load_seattle_neighborhoods()
    neighborhood = get_seattle_neighborhood(lat, lon, neighborhoods_gdf)

    return jsonify({
        "latitude": lat,
        "longitude": lon,
        "is_in_seattle": inside,
        "neighborhood": neighborhood 
    })


# Updated API Endpoint
@content_v1_blueprint.route("/add_story", methods=["POST"])
@login_required
def post_add_story():
    try:
        if not current_user.is_authenticated:
            return jsonify(success="error", message="User is not authenticated", data=None), 401

        # Convert FormData to a dictionary and get files
        data = request.form.to_dict()
        files = request.files
        
        # 3) EXTRACT & MODERATE TEXT (ADDED)
        # ADDED: grab title/body and run AWS Comprehend moderation
        title = data.get("title", "").strip()
        body  = data.get("body", "").strip()
        aws_labels = moderate_text(f"{title}\n{body}")
        if aws_labels:
            # ADDED: if any labels exceed threshold, block the post988888888888888
            return jsonify(
                success="error",
                message="Your story was flagged by AWS content moderation",
                data={"aws_labels": aws_labels}
            ), 400

        # Extract location data
        latitude_raw = data.get("latitude")
        longitude_raw = data.get("longitude")
        manual_location = data.get("location")

        latitude = float(latitude_raw) if latitude_raw is not None else None
        longitude = float(longitude_raw) if longitude_raw is not None else None

        if latitude is None and longitude is None and not manual_location:
            return jsonify(success="error", message="Provide either latitude & longitude or a neighborhood name.", data=None), 400

        if (latitude is None) != (longitude is None):
            return jsonify(success="error", message="Both latitude and longitude must be provided together.", data=None), 400

        if latitude is None and longitude is None:
            latitude, longitude = get_coordinates_from_location(manual_location)
            if latitude is None or longitude is None:
                return jsonify(success="error", message=f"Could not find coordinates for '{manual_location}'", data=None), 400

        location_name = get_neighborhood(latitude, longitude)

        # Handle Thumbnail Upload based on environment
        app_env = current_app.config.get("APP_ENV", "local").lower()
        thumbnail_url = None

        if app_env == "local":
            file = files.get("thumbnail")
            if not file:
                return jsonify(success="error", message="Thumbnail file is required in local environment.", data=None), 400
            try:
                filename = secure_filename(
                    f"{current_user.id}_{uuid.uuid4().hex}.{file.filename.rsplit('.', 1)[-1]}"
                )
                thumbnail_result = upload_thumbnail(file, filename)
                thumbnail_url = thumbnail_result.get("file_url")
                current_app.logger.info(f"Thumbnail uploaded locally: {thumbnail_url}")
            except Exception as e:
                current_app.logger.error(f"Local upload error: {e}", exc_info=True)
                return jsonify(success="error", message="Failed to upload thumbnail.", data=None), 400
        else:
            # Use thumbnail_url from presigned upload flow
            thumbnail_url = data.get("thumbnail_url")
            if not thumbnail_url:
                return jsonify(success="error", message="thumbnail_url is required in staging/production.", data=None), 400
            current_app.logger.info(f"Using provided thumbnail URL: {thumbnail_url}")
            
        # Determine if the post is in Seattle using the lat/lon
        is_in_seattle = is_coordinate_in_seattle(latitude, longitude)

        content = UserContent(
            title      = title,     # UPDATED: use moderated title
            body       = body,      # UPDATED: use moderated body
            user_id=current_user.id,
            unique_id=random.randint(1000000000, 2999999999),
            location=location_name,
            latitude=latitude,
            longitude=longitude,
            thumbnail=thumbnail_url,
            is_in_seattle = is_in_seattle,
        )

        db.session.add(content)
        db.session.commit()

        return jsonify(success="success", message="Story added successfully.", data={"post": content.to_dict()}), 201

    except Exception as e:
        current_app.logger.error(f"Error adding story: {str(e)}", exc_info=True)
        return jsonify(success="error", message="Failed to add story", data=None), 500


def fetch_high_score_content(page, per_page, user_id, location_spec=None, seeded_only=False):
    # Define weights for different components of the score
    weights = {
        "reaction_weight": 2,
        "comment_weight": 3,
        "share_weight": 5,
    }
    decay_factor = 86400  # 1 day in seconds

    # Calculate the score expression
    score_expression = (
        (
            weights["reaction_weight"] * func.count(Reaction.id)
            + weights["comment_weight"]  * func.count(Comment.id)
            + weights["share_weight"]   * func.count(Share.id)
        )
        * func.exp(
            -(
                func.extract("epoch", func.now() - UserContent.created_at)
                / decay_factor
            )
        )
    ).label("score")

    # Base query joining to User and aggregating reactions/comments/shares
    q = (
        db.session.query(
            UserContent.id,
            UserContent.title,
            UserContent.body,
            UserContent.location,
            UserContent.created_at,
            UserContent.updated_at,
            UserContent.thumbnail,
            UserContent.user_id,
            User.username,
            User.profile_picture_url,
            UserContent.is_in_seattle,
            UserContent.is_seeded,                 # ✅ Add this
            UserContent.seed_type,                 # ✅ Add this
            UserContent.seeded_likes_count,        # ✅ Add this
            UserContent.seeded_comments_count,     # ✅ Add this
            UserContent.news_link,
            score_expression,
        )
        .join(User, User.id == UserContent.user_id)
        .outerjoin(Reaction, Reaction.content_id == UserContent.id)
        .outerjoin(Comment,  Comment.content_id   == UserContent.id)
        .outerjoin(Share,    Share.content_id     == UserContent.id)
    )

    if seeded_only:
        # Only seeded news posts
        q = q.filter(
            UserContent.is_seeded.is_(True),
            UserContent.seed_type == 'news'
        )
    else:
        # Filter out blocked or hidden content for authenticated user
        q = q.filter(
            ~UserContent.user_id.in_(
                db.session.query(Block.blocked_id)
                          .filter(Block.blocker_id == user_id)
            ),
            ~UserContent.id.in_(
                db.session.query(HiddenContent.content_id)
                          .filter(HiddenContent.user_id == user_id)
            ),
        )

    if location_spec:
        q = apply_location_filter(q, location_spec)

    # Exclude known placeholder thumbnails and require a thumbnail value
    placeholder_prefixes = [
        "via.placeholder.com",
        "placeholder.pagebee.io",
    ]
    q = q.filter(UserContent.thumbnail.is_not(None))
    for prefix in placeholder_prefixes:
        q = q.filter(~UserContent.thumbnail.ilike(prefix + "%"))

    # Grouping for aggregate counts
    grouped = q.group_by(
        UserContent.id,
        UserContent.title,
        UserContent.body,
        UserContent.location,
        UserContent.created_at,
        UserContent.updated_at,
        UserContent.thumbnail,
        UserContent.user_id,
        User.username,
        User.profile_picture_url,
        UserContent.is_in_seattle,
    )

    # Count total items before pagination
    total_items = grouped.count()

    # Apply sorting and pagination
    items = (
        grouped
        .order_by(desc("score"))
        .limit(per_page)
        .offset((page - 1) * per_page)
        .all()
    )

    return items, total_items


from sqlalchemy.orm import joinedload

def fetch_seeded_content_round_robin(page: int, per_page: int, location_spec=None):
    """
    Fetch only seeded content (news) and return it in round robin order.
    No scoring algorithm, just newest first per source.
    Includes joined user info so username/profile_picture_url are available.
    """

    # Only seeded content, with joined User relationship
    query = (
        UserContent.query
        .filter_by(is_seeded=True)
        .options(joinedload(UserContent.user))  # preload related user object
    )

    if location_spec:
        query = apply_location_filter(query, location_spec)

    # Newest first
    query = query.order_by(UserContent.created_at.desc())

    # Fetch all results
    posts = query.all()

    # Apply round robin distribution
    posts = distribute_sources(posts)

    # Pagination AFTER round robin ordering
    total = len(posts)
    start = (page - 1) * per_page
    end = start + per_page
    posts = posts[start:end]

    return posts, total


def fetch_combined_content_round_robin(page: int, per_page: int, location_spec=None):
    """
    Fetch BOTH seeded content (news) AND user content, return in round robin order.
    Combines seeded news with user posts, newest first.
    Includes joined user info so username/profile_picture_url are available.
    """

    # Get BOTH seeded content AND user content
    query = (
        UserContent.query
        .options(joinedload(UserContent.user))  # preload related user object
    )

    # Optional location filter with same behavior as /content endpoint
    if location_spec:
        query = apply_location_filter(query, location_spec)

    # Newest first
    query = query.order_by(UserContent.created_at.desc())

    # Fetch all results
    posts = query.all()

    # Apply round robin distribution
    posts = distribute_sources(posts)

    # Pagination AFTER round robin ordering
    total = len(posts)
    start = (page - 1) * per_page
    end = start + per_page
    posts = posts[start:end]

    return posts, total



@content_v1_blueprint.route("/", methods=["GET", "OPTIONS"])
@cross_origin(origins=CORS_ALLOWED_ORIGINS, supports_credentials=True)
def get_content():
    # 1) Preflight logging
    if request.method == "OPTIONS":
        origin = request.headers.get("Origin")
        allowed_origins = CORS_ALLOWED_ORIGINS

        current_app.logger.info(
            f"CORS preflight for {request.path!r} from Origin={origin}"
        )

        current_app.logger.info(
            f"CORS preflight for {request.path!r} from Origin={origin}"
        )

        if origin not in allowed_origins:
            current_app.logger.warning(
                f"→ Preflight DENIED: {origin!r} not in {allowed_origins!r}"
            )
        else:
            current_app.logger.info(
                f"→ Preflight OK: allowing {origin!r}"
            )


        # flask-cors will still attach the actual headers for us,
        # but we short‐circuit the OPTIONS with a 204.
        return "", 204

    # Query parameters with defaults
    page = request.args.get("page", default=1, type=int)
    per_page = request.args.get("per_page", default=10, type=int)
    raw_location = request.args.get("location")

    try:
        location_spec = parse_location_filter(raw_location)
    except InvalidLocation as exc:
        return (
            jsonify(
                success="error",
                message=str(exc),
                data=None,
                query={"page": page, "per_page": per_page, "location": raw_location},
                pagination={},
            ),
            400,
        )

    response_location = display_location_value(raw_location, location_spec)

    current_app.logger.debug(
        "Received request with params - Page: %s, Per Page: %s, Location: %s",
        page,
        per_page,
        response_location,
    )

    # Check if user is authenticated
    is_authenticated = current_user.is_authenticated
    user_id = current_user.id if is_authenticated else None

    try:
        current_app.logger.debug(
            "Fetching content with page=%s, per_page=%s, location_spec=%s",
            page,
            per_page,
            location_spec,
        )
        paginated_content, total_items = fetch_high_score_content(
            page=page,
            per_page=per_page,
            user_id=user_id,
            location_spec=location_spec,
        )


        # Log the fetched content length
        current_app.logger.debug(f"Fetched {len(paginated_content)} items")

        # Initialize default values for unauthenticated users
        user_reacted_content_ids = set()
        user_reactions_dict = {}
        user_reposted_content_ids = set()

        if is_authenticated:
            # Fetch user reactions
            user_reactions = Reaction.query.filter_by(user_id=user_id).all()
            user_reacted_content_ids = {
                reaction.content_id for reaction in user_reactions
            }
            user_reactions_dict = {
                reaction.content_id: reaction.reaction_type.value
                for reaction in user_reactions
            }

            # Fetch user's reposts
            user_reposts = Repost.query.filter_by(user_id=user_id).all()
            user_reposted_content_ids = {repost.content_id for repost in user_reposts}

        # Format content for response
        content_list = []
        for item in paginated_content:
            thumbnail = getattr(item, "thumbnail", None)
            if thumbnail and is_placeholder_image(thumbnail):
                continue
            if item.is_seeded:
                reactions_count = item.seeded_likes_count
                comments_count = item.seeded_comments_count
            else:
                reactions_count = Reaction.query.filter_by(content_id=item.id).count()
                comments_count = Comment.query.filter_by(content_id=item.id).count()

            # Calculate top 2 reactions
            top_reaction_counts = (
                db.session.query(
                    Reaction.reaction_type, db.func.count(Reaction.reaction_type)
                )
                .filter_by(content_id=item.id)
                .group_by(Reaction.reaction_type)
                .order_by(db.func.count(Reaction.reaction_type).desc())
                .limit(2)
                .all()
            )
            top_reactions = [
                reaction_type.value for reaction_type, count in top_reaction_counts
            ]
            
            # 👇 Prepare link and body_text based on content type
            if item.is_seeded and item.seed_type == 'news':
                link = item.news_link
                body_text = ""  # You can also put item.title or "" as body if you want consistency
            else:
                link = None
                body_text = item.body

            # Build base content structure
            content_item = {
                "id": item.id,
                "title": item.title,
                "location": item.location,
                "location_label": format_post_location(item),
                "created_at": item.created_at.isoformat() if item.created_at else None,
                "updated_at": item.updated_at.isoformat() if item.updated_at else None,
                "time_since_post": (
                    time_since_post(item.created_at) if item.created_at else None
                ),
                "score": item.score,
                "reactions_count": reactions_count,
                "comments_count": comments_count,
                "top_reactions": top_reactions,
                "user": {
                    "id": item.user_id,
                    "username": item.username,
                    "profile_picture_url": item.profile_picture_url,
                },
                "thumbnail": item.thumbnail,
                "body": item.body,
                "is_in_seattle": item.is_in_seattle,
            }
            
            # Add link field ONLY if seeded news
            if item.is_seeded and item.seed_type == 'news':
                content_item["link"] = link

            # Add user-specific fields only if authenticated
            if is_authenticated:
                content_item["user_has_reacted"] = item.id in user_reacted_content_ids
                content_item["user_reaction_type"] = user_reactions_dict.get(
                    item.id, None
                )
                content_item["has_user_reposted"] = item.id in user_reposted_content_ids

            content_list.append(content_item)

        # Pagination Logic
        # Pagination Logic
        total_pages = total_items // per_page + (1 if total_items % per_page > 0 else 0)

        has_next = page < total_pages
        has_prev = page > 1
        current_app.logger.debug(f"Has next: {has_next}, Has prev: {has_prev}")

        # Response structure
        response = {
            "success": "success",
            "message": "Content fetched successfully",
            "data": {"content": content_list},
            "query": {
                "page": page,
                "per_page": per_page,
                "location": response_location,
            },
            "pagination": {
                "current_page": page,
                "total_pages": total_pages,
                "total_items": total_items,
                "has_next": has_next,
                "has_prev": has_prev,
            },
        }

        return jsonify(response), 200

    except Exception as e:
        # Log the error with detailed information
        current_app.logger.error(f"Pagination error: {e}")
        db.session.rollback()
        return (
            jsonify(
                {
                    "success": "error",
                    "message": f"Failed to fetch content: {str(e)}",
                    "data": None,
                    "query": {
                        "page": page,
                        "per_page": per_page,
                        "location": response_location,
                    },
                    "pagination": {},
                }
            ),
            500,
        )


@content_v1_blueprint.route("/<content_type>/<content_id>", methods=["GET"])
def get_content_detail(content_type, content_id):
    """Fetch content details, top-level comments, and their reply counts."""

    is_authenticated = current_user.is_authenticated
    user_id = current_user.id if is_authenticated else None

    try:
        # Fetch the content (news or user_content)
        content = None
        source_url = None
        if content_type == "news":
            content = News.query.filter_by(unique_id=content_id).first()
            source_url = content.link if content else None
        elif content_type == "user_content":
            content = UserContent.query.filter_by(id=content_id).first()
            source_url = None

        if not content:
            return jsonify(success="error", message="Content not found", data=None), 404

        # Default values for guests
        user_has_reacted = False
        user_reaction_type = None
        has_user_reposted = False

        if is_authenticated:
            # Fetch user-specific data only if logged in
            user_reaction = Reaction.query.filter_by(
                user_id=user_id, content_id=content.id
            ).first()
            user_has_reacted = user_reaction is not None
            user_reaction_type = (
                user_reaction.reaction_type.value if user_reaction else None
            )
            has_user_reposted = (
                db.session.query(Repost)
                .filter_by(user_id=user_id, content_id=content.id)
                .first()
                is not None
            )

        # Count total comments
        total_comments = Comment.query.filter_by(
            content_type=content_type, content_id=content_id
        ).count()

        # Count total reactions
        total_reactions = Reaction.query.filter_by(content_id=content.id).count()

        # Calculate top 2 reactions
        top_reaction_counts = (
            db.session.query(
                Reaction.reaction_type, db.func.count(Reaction.reaction_type)
            )
            .filter_by(content_id=content.id)
            .group_by(Reaction.reaction_type)
            .order_by(
                db.func.count(Reaction.reaction_type).desc(), Reaction.reaction_type
            )
            .limit(2)
            .all()
        )
        top_reactions = [
            reaction_type.value for reaction_type, count in top_reaction_counts
        ]

        # Define pagination parameters
        page = request.args.get("page", 1, type=int)
        per_page = request.args.get("per_page", 10, type=int)

        comment_list = []
        pagination_info = {
            "current_page": 1,
            "total_pages": 1,
            "total_items": 0,
            "has_next": False,
            "has_prev": False,
        }

        if total_comments > 0:
            try:
                # Fetch paginated comments only if they exist
                top_level_comments_paginated = (
                    Comment.query.filter_by(
                        content_type=content_type, content_id=content_id, parent_id=None
                    )
                    .options(subqueryload(Comment.user))
                    .order_by(Comment.created_at.asc())
                    .paginate(page=page, per_page=per_page, error_out=False)
                )

                user_comment_reactions = {}
                if is_authenticated:
                    # Fetch user reactions to comments only if authenticated
                    user_comment_reactions = {
                        reaction.content_id: reaction.reaction_type.value
                        for reaction in CommentReaction.query.filter_by(
                            user_id=user_id
                        ).all()
                    }

                # Build the comment list with reply counts and top reactions
                for comment in top_level_comments_paginated.items:
                    # Calculate top 2 reactions for each comment
                    top_comment_reaction_counts = (
                        db.session.query(
                            CommentReaction.reaction_type,
                            db.func.count(CommentReaction.reaction_type),
                        )
                        .filter_by(content_id=comment.id)
                        .group_by(CommentReaction.reaction_type)
                        .order_by(
                            db.func.count(CommentReaction.reaction_type).desc(),
                            CommentReaction.reaction_type,
                        )
                        .limit(2)
                        .all()
                    )
                    top_comment_reactions = [
                        reaction_type.value
                        for reaction_type, count in top_comment_reaction_counts
                    ]

                    # Only include user-specific reaction details for authenticated users
                    comment_data = {
                        "id": comment.id,
                        "content": comment.content,
                        "user_id": comment.user_id,
                        "created_at": (
                            comment.created_at.isoformat()
                            if comment.created_at
                            else None
                        ),
                        "updated_at": (
                            comment.updated_at.isoformat()
                            if comment.updated_at
                            else None
                        ),
                        "user": {
                            "id": comment.user.id,
                            "first_name": comment.user.first_name,
                            "last_name": comment.user.last_name,
                            "username": comment.user.username,
                            "profile_picture_url": comment.user.profile_picture_url
                            or "",
                        },
                        "replies_count": Comment.query.filter_by(
                            parent_id=comment.id
                        ).count(),
                        "top_comment_reactions": top_comment_reactions,
                    }

                    if is_authenticated:
                        comment_data["has_reacted_to_comment"] = (
                            comment.id in user_comment_reactions
                        )
                        comment_data["comment_reaction_type"] = (
                            user_comment_reactions.get(comment.id, None)
                        )

                    comment_list.append(comment_data)

                pagination_info = {
                    "current_page": top_level_comments_paginated.page,
                    "total_pages": top_level_comments_paginated.pages,
                    "total_items": top_level_comments_paginated.total,
                    "has_next": top_level_comments_paginated.has_next,
                    "has_prev": top_level_comments_paginated.has_prev,
                }

            except Exception as e:
                current_app.logger.error(f"Pagination error: {e}")
                return (
                    jsonify(success="error", message="Pagination failed", data=None),
                    500,
                )

        # Build response structure
        content_data = {
            "id": content.id,
            "unique_id": content.unique_id,
            "title": content.title,
            "description": content.body,
            "image_url": content.thumbnail,
            "location": content.location,
            "location_label": format_post_location(content),
            "is_in_seattle": getattr(content, "is_in_seattle", None),
            "source_url": source_url,
            "total_comments": total_comments,
            "total_reactions": total_reactions,
            "top_reactions": top_reactions,
            "comments": comment_list,
            "user": {
                "id": content.user.id,
                "first_name": content.user.first_name,
                "last_name": content.user.last_name,
                "username": content.user.username,
                "profile_picture_url": content.user.profile_picture_url or "",
            },
            "pagination": pagination_info,
        }

        # Only include user-specific data if authenticated
        if is_authenticated:
            content_data["user_has_reacted"] = user_has_reacted
            content_data["user_reaction_type"] = user_reaction_type
            content_data["has_user_reposted"] = has_user_reposted

        return (
            jsonify(
                success="success",
                message="Content details fetched successfully",
                data=content_data,
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Server error: {e}")
        return jsonify(success="error", message="Server error", data=None), 500


@content_v1_blueprint.route("/guest_feed", methods=["GET"])
def get_guest_feed():
    # Query params
    page = request.args.get("page", default=1, type=int)
    per_page = request.args.get("per_page", default=10, type=int)
    raw_location = request.args.get("location")

    try:
        location_spec = parse_location_filter(raw_location)
    except InvalidLocation as exc:
        return (
            jsonify(
                success="error",
                message=str(exc),
                data=None,
                query={"page": page, "per_page": per_page, "location": raw_location},
                pagination={},
            ),
            400,
        )

    response_location = display_location_value(raw_location, location_spec)

    current_app.logger.debug(
        "Guest feed request → page=%s, per_page=%s, location_spec=%s",
        page,
        per_page,
        location_spec,
    )

    try:
        posts, total = fetch_seeded_content_round_robin(
            page=page,
            per_page=per_page,
            location_spec=location_spec,
        )

        content_list = []
        for item in posts:
            thumbnail = getattr(item, "thumbnail", None)
            if thumbnail and is_placeholder_image(thumbnail):
                continue
            content_list.append(
                {
                    "id": item.id,
                    "title": item.title,
                    "body": item.body,
                    "location": item.location,
                    "location_label": format_post_location(item),
                    "created_at": item.created_at.isoformat() if item.created_at else None,
                    "updated_at": item.updated_at.isoformat() if item.updated_at else None,
                    "time_since_post": time_since_post(item.created_at) if item.created_at else None,
                    "user": {
                        "id": item.user_id,
                        "username": item.user.username if item.user else None,
                        "profile_picture_url": item.user.profile_picture_url if item.user else None,
                    },
                    "thumbnail": item.thumbnail,
                    "is_seeded": item.is_seeded,
                    "seed_type": item.seed_type,
                    "reactions_count": item.seeded_likes_count,
                    "comments_count": item.seeded_comments_count,
                    "link": item.news_link,
                    "is_in_seattle": item.is_in_seattle,
                }
            )

        total_pages = total // per_page + (1 if total % per_page else 0)
        response = {
            "success": "success",
            "message": "Guest feed fetched successfully",
            "data": {"content": content_list},
            "query": {"page": page, "per_page": per_page, "location": response_location},
            "pagination": {
                "current_page": page,
                "total_pages": total_pages,
                "total_items": total,
                "has_next": page < total_pages,
                "has_prev": page > 1,
            },
        }
        return jsonify(response), 200

    except Exception as e:
        current_app.logger.error(f"Guest feed error: {e}", exc_info=True)
        return (
            jsonify(
                success="error",
                message=f"Failed to fetch guest feed: {str(e)}",
                data=None,
                query={"page": page, "per_page": per_page, "location": response_location},
                pagination={},
            ),
            500,
        )


@content_v1_blueprint.route("/combined_feed", methods=["GET"])
def get_combined_feed():
    """
    Combined feed endpoint that shows BOTH seeded news AND user content.
    Similar to guest_feed but includes all content types.
    """
    # Query params
    page = request.args.get("page", default=1, type=int)
    per_page = request.args.get("per_page", default=10, type=int)
    raw_location = request.args.get("location")

    try:
        location_spec = parse_location_filter(raw_location)
    except InvalidLocation as exc:
        return (
            jsonify(
                success="error",
                message=str(exc),
                data=None,
                query={"page": page, "per_page": per_page, "location": raw_location},
                pagination={},
            ),
            400,
        )

    response_location = display_location_value(raw_location, location_spec)

    current_app.logger.debug(
        "Combined feed request → page=%s, per_page=%s, location_spec=%s",
        page,
        per_page,
        location_spec,
    )

    try:
        posts, total = fetch_combined_content_round_robin(
            page=page,
            per_page=per_page,
            location_spec=location_spec,
        )

        content_list = []
        for item in posts:
            thumbnail = getattr(item, "thumbnail", None)
            if thumbnail and is_placeholder_image(thumbnail):
                continue
            if item.is_seeded:
                reactions_count = item.seeded_likes_count
                comments_count = item.seeded_comments_count
                link = item.news_link
            else:
                reactions_count = Reaction.query.filter_by(content_id=item.id).count()
                comments_count = Comment.query.filter_by(content_id=item.id).count()
                link = None

            content_list.append(
                {
                    "id": item.id,
                    "title": item.title,
                    "body": item.body,
                    "location": item.location,
                    "location_label": format_post_location(item),
                    "created_at": item.created_at.isoformat() if item.created_at else None,
                    "updated_at": item.updated_at.isoformat() if item.updated_at else None,
                    "time_since_post": time_since_post(item.created_at) if item.created_at else None,
                    "user": {
                        "id": item.user_id,
                        "username": item.user.username if item.user else None,
                        "profile_picture_url": item.user.profile_picture_url if item.user else None,
                    },
                    "thumbnail": item.thumbnail,
                    "is_seeded": item.is_seeded,
                    "seed_type": item.seed_type,
                    "reactions_count": reactions_count,
                    "comments_count": comments_count,
                    "link": link,
                    "is_in_seattle": item.is_in_seattle,
                }
            )

        total_pages = total // per_page + (1 if total % per_page else 0)
        response = {
            "success": "success",
            "message": "Combined feed fetched successfully",
            "data": {"content": content_list},
            "query": {"page": page, "per_page": per_page, "location": response_location},
            "pagination": {
                "current_page": page,
                "total_pages": total_pages,
                "total_items": total,
                "has_next": page < total_pages,
                "has_prev": page > 1,
            },
        }
        return jsonify(response), 200

    except Exception as e:
        current_app.logger.error(f"Combined feed error: {e}", exc_info=True)
        return (
            jsonify(
                success="error",
                message=f"Failed to fetch combined feed: {str(e)}",
                data=None,
                query={"page": page, "per_page": per_page, "location": response_location},
                pagination={},
            ),
            500,
        )


@content_v1_blueprint.route("/hide_content/<int:content_id>", methods=["POST"])
@login_required
def hide_story(content_id):
    """
    Endpoint to hide a story from the user's feed.
    Only works if the content exists and hasn't already been hidden by the user.
    """
    try:
        # Check if the content exists
        content = UserContent.query.get(content_id)
        if not content:
            return jsonify(success="error", message="Content not found", data=None), 404

        # Prevent duplicate hiding
        existing = HiddenContent.query.filter_by(
            user_id=current_user.id, content_id=content_id
        ).first()
        if existing:
            return (
                jsonify(success="error", message="Content already hidden", data=None),
                409,
            )

        # Save the hidden record
        hidden = HiddenContent(user_id=current_user.id, content_id=content_id)
        db.session.add(hidden)
        db.session.commit()

        return (
            jsonify(
                success="success",
                message="Content hidden from feed",
                data={"content_id": content_id},
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Failed to hide content: {e}")
        return jsonify(success="error", message="Server error", data=None), 500


@content_v1_blueprint.route("/unhide_content/<int:content_id>", methods=["DELETE"])
@login_required
def unhide_story(content_id):
    """
    Endpoint to unhide a story (make it appear in the user's feed again).
    Works only if the content was previously hidden.
    """
    try:
        # Find the hidden content record
        hidden = HiddenContent.query.filter_by(
            user_id=current_user.id, content_id=content_id
        ).first()

        if not hidden:
            return (
                jsonify(success="error", message="Content is not hidden", data=None),
                404,
            )

        # Remove from hidden content
        db.session.delete(hidden)
        db.session.commit()

        return (
            jsonify(
                success="success",
                message="Content unhidden successfully",
                data={"content_id": content_id},
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Failed to unhide content: {e}")
        return jsonify(success="error", message="Server error", data=None), 500


@content_v1_blueprint.route("/share/<int:content_id>", methods=["POST"])
@login_required
def create_share(content_id):
    """Creates a shareable link for a specific content."""

    # Fetch the content to be shared
    content = UserContent.query.get(content_id)
    if not content:
        return jsonify({"status": "error", "message": "Content not found"}), 404

    # Validate the platform input
    VALID_PLATFORMS = {"facebook", "twitter", "email", "whatsapp", "link"}
    platform = request.json.get("platform", "link").lower()

    if platform not in VALID_PLATFORMS:
        return (
            jsonify({"status": "error", "message": f"Invalid platform '{platform}'"}),
            400,
        )

    # Check if the user has already shared this content on the same platform
    existing_share = Share.query.filter_by(
        user_id=current_user.id, content_id=content.id, platform=platform
    ).first()

    if existing_share:
        # Return existing share link instead of creating a duplicate
        sharable_link = get_share_url(str(existing_share.id))
        return (
            jsonify(
                {
                    "status": "success",
                    "message": f"Share already exists (Platform: {platform})",
                    "data": {"sharable_link": sharable_link, "platform": platform},
                }
            ),
            200,
        )

    # Log the new share in the Share model
    share = Share(user_id=current_user.id, content_id=content.id, platform=platform)
    db.session.add(share)
    db.session.commit()

    # Generate frontend-accessible shareable link
    sharable_link = get_share_url(str(share.id))

    # Return response
    return (
        jsonify(
            {
                "status": "success",
                "message": f"Sharable link created successfully (Platform: {platform})",
                "data": {
                    "sharable_link": sharable_link,
                    "platform": platform,
                },
            }
        ),
        201,
    )


@content_v1_blueprint.route("/share/content-detail/<int:share_id>", methods=["GET"])
def get_shared_content_detail(share_id):
    """Fetches content details based on share_id, similar to get_content_detail."""

    # Fetch the Share entry
    share = Share.query.get(share_id)
    if not share:
        return jsonify({"success": "error", "message": "Share not found"}), 404

    # Fetch the related content
    content = UserContent.query.get(share.content_id)
    if not content:
        return jsonify({"success": "error", "message": "Content not found"}), 404

    # Prepare user profile information
    profile_picture_url = (
        content.user.profile_picture_url if content.user.profile_picture_url else ""
    )

    # Reaction breakdown and total reactions
    total_reactions = Reaction.query.filter_by(content_id=content.id).count()
    reaction_breakdown = {
        "LIKE": Reaction.query.filter_by(
            content_id=content.id, reaction_type="LIKE"
        ).count(),
        "LOVE": Reaction.query.filter_by(
            content_id=content.id, reaction_type="LOVE"
        ).count(),
        "HAHA": Reaction.query.filter_by(
            content_id=content.id, reaction_type="HAHA"
        ).count(),
        "WOW": Reaction.query.filter_by(
            content_id=content.id, reaction_type="WOW"
        ).count(),
        "SAD": Reaction.query.filter_by(
            content_id=content.id, reaction_type="SAD"
        ).count(),
        "ANGRY": Reaction.query.filter_by(
            content_id=content.id, reaction_type="ANGRY"
        ).count(),
    }

    # Fetch user reaction if available
    user_reaction = Reaction.query.filter_by(
        content_id=content.id, user_id=share.user_id
    ).first()
    user_reaction_type = str(user_reaction.reaction_type) if user_reaction else None

    # Pagination parameters for top-level comments
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 10, type=int)

    # Fetch top-level comments
    top_level_comments_paginated = (
        Comment.query.filter_by(content_id=content.id, parent_id=None)
        .options(subqueryload(Comment.user))
        .order_by(Comment.created_at.asc())
        .paginate(page=page, per_page=per_page)
    )

    # Build the comment list with reply counts
    comment_list = [
        {
            "id": comment.id,
            "content": comment.content,
            "user_id": comment.user_id,
            "created_at": comment.created_at.isoformat(),
            "user": {
                "id": comment.user.id,
                "username": comment.user.username,
                "profile_picture_url": comment.user.profile_picture_url or "",
            },
            "replies_count": Comment.query.filter_by(parent_id=comment.id).count(),
        }
        for comment in top_level_comments_paginated.items
    ]

    return (
        jsonify(
            {
                "success": "success",
                "message": "Shared content details fetched successfully",
                "data": {
                    "id": content.id,
                    "title": content.title,
                    "description": content.body,
                    "image_url": content.thumbnail,
                    "location": content.location,
                    "location_label": format_post_location(content),
                    "is_in_seattle": content.is_in_seattle,
                    "user": {
                        "id": content.user.id,
                        "username": content.user.username,
                        "profile_picture_url": profile_picture_url,
                    },
                    "total_reactions": total_reactions,
                    "reaction_breakdown": reaction_breakdown,
                    "user_reaction": user_reaction_type,
                    "total_comments": top_level_comments_paginated.total,
                    "comments": comment_list,
                    "pagination": {
                        "current_page": top_level_comments_paginated.page,
                        "total_pages": top_level_comments_paginated.pages,
                        "total_items": top_level_comments_paginated.total,
                        "has_next": top_level_comments_paginated.has_next,
                        "has_prev": top_level_comments_paginated.has_prev,
                    },
                },
            }
        ),
        200,
    )


@content_v1_blueprint.route("/track/<int:share_id>", methods=["GET"])
def track_click(share_id):
    """Tracks clicks on sharable links and increments click count."""
    # Fetch the Share entry
    share = Share.query.get(share_id)
    if not share:
        return jsonify({"success": "error", "message": "Share not found"}), 404

    # Increment the click count
    share.click_count += 1
    db.session.commit()

    # Return content details
    content = share.content
    return (
        jsonify(
            {
                "success": "success",
                "message": "Click tracked successfully",
                "data": {
                    "content_id": content.id,
                    "title": content.title,
                    "body": content.body,
                    "thumbnail": content.thumbnail,
                },
            }
        ),
        200,
    )


@content_v1_blueprint.route("/metrics", methods=["GET"])
@login_required
def get_share_metrics():
    """Fetches metrics for shared content, including clicks and platforms."""
    # Retrieve share data with related content
    shares = Share.query.join(UserContent, Share.content_id == UserContent.id).all()

    # Format the metrics
    metrics = [
        {
            "share_id": share.id,
            "content_id": share.content_id,
            "title": share.content.title,
            "shared_by": share.user.username,
            "platform": share.platform,
            "click_count": share.click_count,
            "shared_at": share.shared_at.isoformat(),
        }
        for share in shares
    ]

    # Return the metrics
    return (
        jsonify(
            {
                "success": "success",
                "message": "Share metrics fetched successfully",
                "data": metrics,
            }
        ),
        200,
    )


@content_v1_blueprint.route("/report_content", methods=["POST"])
@login_required
def report_content():
    try:
        data = request.get_json()
        content_id = data.get("content_id")
        reason_str = data.get("reason")
        custom_reason = data.get("custom_reason")

        if not content_id or not reason_str:
            return (
                jsonify(
                    success="error",
                    message="Both 'content_id' and 'reason' are required.",
                    data=None,
                ),
                400,
            )

        # Validate and convert to Enum
        try:
            reason = ReportReason(reason_str)
        except ValueError:
            return (
                jsonify(
                    success="error",
                    message=f"Invalid reason. Valid reasons are: {[r.value for r in ReportReason]}",
                    data=None,
                ),
                400,
            )

        # Require custom_reason if 'Other' is selected
        if reason == ReportReason.OTHER:
            if not custom_reason or not custom_reason.strip():
                return (
                    jsonify(
                        success="error",
                        message="You must provide a custom reason when selecting 'Other'.",
                        data=None,
                    ),
                    400,
                )

        # Check if content exists
        content = UserContent.query.get(content_id)
        if not content:
            return jsonify(success="error", message="Content not found", data=None), 404

        # Prevent self-reporting
        if content.user_id == current_user.id:
            return (
                jsonify(
                    success="error",
                    message="You cannot report your own content.",
                    data=None,
                ),
                400,
            )

        # Prevent duplicate reports
        existing_report = ContentReport.query.filter_by(
            content_id=content_id, reporter_id=current_user.id
        ).first()
        if existing_report:
            return (
                jsonify(
                    success="error",
                    message="You have already reported this content.",
                    data=None,
                ),
                409,
            )

        # Save the report
        report = ContentReport(
            content_id=content_id,
            reporter_id=current_user.id,
            reason=reason,
            custom_reason=custom_reason if reason == ReportReason.OTHER else None,
        )

        db.session.add(report)
        db.session.commit()

        return (
            jsonify(
                success="success",
                message="Content reported successfully.",
                data=report.to_dict(),
            ),
            201,
        )

    except Exception as e:
        current_app.logger.error(f"Error reporting content: {str(e)}")
        return (
            jsonify(
                success="error",
                message="Failed to report content due to a server error.",
                data=None,
            ),
            500,
        )


@content_v1_blueprint.route("/delete_story/<int:content_id>", methods=["DELETE"])
@login_required
def delete_story(content_id):
    """
    Endpoint to delete a story by its ID.
    Only the user who created the story can delete it.
    """
    try:
        # Fetch the content by ID
        content = UserContent.query.get(content_id)

        if not content:
            return jsonify(success="error", message="Content not found", data=None), 404

        # Ensure the current user is the owner of the content
        if content.user_id != current_user.id:
            return (
                jsonify(
                    success="error",
                    message="Unauthorized to delete this content",
                    data=None,
                ),
                403,
            )

        # Optional: Delete thumbnail from S3 if it exists
        if content.thumbnail:
            try:
                # Determine the environment and corresponding bucket
                app_env = current_app.config.get("APP_ENV", "local")

                if app_env == "production":
                    bucket_name = "seattlepulse-production-user-post-images"
                elif app_env == "staging":
                    bucket_name = "seattlepulse-staging-user-post-images"
                else:
                    bucket_name = "seattlepulse-user-post-images"  # local or dev

                # Extract the object key (file name) from the thumbnail URL
                filename = content.thumbnail.split(f"{bucket_name}/")[-1]

                # Delete the object from S3
                s3_client = current_app.s3_client
                s3_client.delete_object(Bucket=bucket_name, Key=filename)

                current_app.logger.info(f"Thumbnail deleted: {filename}")

            except Exception as s3_err:
                current_app.logger.warning(
                    f"Failed to delete thumbnail from S3: {s3_err}"
                )

        # Delete the content from the database
        db.session.delete(content)
        db.session.commit()

        return (
            jsonify(success="success", message="Content deleted successfully"),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Error deleting content: {str(e)}")
        return (
            jsonify(success="error", message="Failed to delete content", data=None),
            500,
        )


@content_v1_blueprint.route("/user-content", methods=["GET"])
def api_user_content():
    try:
        page = request.args.get("page", 1, type=int)
        per_page = 10
        pagination = UserContent.query.order_by(UserContent.created_at.desc()).paginate(
            page=page, per_page=per_page
        )
        items = []
        for content_item in pagination.items:
            items.append(
                {
                    "id": content_item.id,
                    "unique_id": content_item.unique_id,
                    "title": content_item.title,
                    "description": content_item.body,
                    "image_url": content_item.thumbnail,
                    "location": content_item.location,
                    "location_label": format_post_location(content_item),
                    "is_in_seattle": content_item.is_in_seattle,
                    "user": {
                        "username": content_item.user.username,
                        "profile_picture_url": (
                            content_item.user.profile_picture_url
                            if content_item.user.profile_picture_url
                            else ""
                        ),
                    },
                    "total_reactions": Reaction.query.filter_by(
                        content_id=content_item.id, content_type="story"
                    ).count(),
                }
            )
        return jsonify(status="success", content=items, hasMore=pagination.has_next)
    except Exception as e:
        print(f"Error fetching user content: {e}")
        return (
            jsonify(
                status="error", message="An error occurred while fetching user content."
            ),
            500,
        )


@content_v1_blueprint.route("/<content_type>/<content_id>/comments", methods=["POST"])
def add_comment(content_type, content_id):
    data = request.get_json()
    content = None

    if content_type == "news":
        content = News.query.filter_by(unique_id=content_id).first()
    elif content_type == "usercontent":
        content = UserContent.query.filter_by(id=content_id).first()

    if not content:
        return jsonify(status="error", message="UserContent not found"), 404

    if not data or not data.get("content"):
        return jsonify(status="error", message="Comment content is required"), 400

    new_comment = Comment(
        content=data["content"],
        content_id=content_id,
        content_type=content_type,
        created_at=datetime.utcnow(),
        user_id=current_user.id if current_user.is_authenticated else None,
    )
    db.session.add(new_comment)
    db.session.commit()

    return jsonify(status="success", message="Comment added successfully")


@content_v1_blueprint.route("/search_location_for_upload", methods=["GET"])
def search_location_for_upload():
    """
    Search locations worldwide for user location input (e.g., story upload).
    Returns a paginated list of matching locations with Seattle-aware labels.
    """

    query = request.args.get("query", "").strip()
    page = int(request.args.get("page", 1))
    limit = int(request.args.get("limit", 10))

    if not query:
        return jsonify({"error": "query parameter is required"}), 400

    # Step 1: Use OpenStreetMap to search locations
    url = f"{NOMINATIM_BASE_URL}/search?q={query}&format=json&addressdetails=1&limit={limit}&offset={(page - 1) * limit}"
    headers = {"User-Agent": "SeattlePulseApp/1.0"}

    try:
        response = requests.get(url, headers=headers, timeout=5)
        response.raise_for_status()
        results = response.json()

        if not results:
            return jsonify({"error": "No matching locations found."}), 404

        locations = []
        for place in results:
            lat = float(place["lat"])
            lon = float(place["lon"])
            display_name = place.get("display_name", "Unknown")
            address = place.get("address", {})

            # 🌎 Use new Seattle-aware + global label
            location_label = get_location_label(lat, lon, address)

            locations.append(
                {
                    "location_label": location_label,
                    "latitude": lat,
                    "longitude": lon,
                    "raw": {"display_name": display_name, "address": address},
                }
            )

        return jsonify(
            {
                "success": "success",
                "query": query,
                "page": page,
                "limit": limit,
                "results": locations,
                "total_results": len(
                    locations
                ),  # Nominatim does not provide total, so this is per-page
            }
        )

    except requests.RequestException as e:
        print(f"Error fetching locations: {e}")
        return jsonify({"error": "Failed to retrieve locations"}), 500


def calculate_center(locations):
    """Calculate the center of given locations."""
    if not locations:
        return None
    avg_latitude = sum(loc["latitude"] for loc in locations) / len(locations)
    avg_longitude = sum(loc["longitude"] for loc in locations) / len(locations)
    return {"latitude": avg_latitude, "longitude": avg_longitude}


@content_v1_blueprint.route("/user/locations", methods=["GET"])
@login_required
def get_user_locations():
    """Endpoint to get all locations a user has posted in."""
    try:
        # Ensure user is authenticated
        if not current_user.is_authenticated:
            return (
                jsonify(
                    success="error", message="User is not authenticated", data=None
                ),
                401,
            )

        # Query the UserContent table for the current user's posts
        user_contents = UserContent.query.filter_by(user_id=current_user.id).all()

        # Extract content details including locations, latitude, and longitude
        locations = [
            {
                "content_id": content.id,
                "title": content.title,
                "location": content.location,
                "location_label": format_post_location(content),
                "latitude": content.latitude,
                "longitude": content.longitude,
                "is_in_seattle": content.is_in_seattle,
            }
            for content in user_contents
            if content.latitude and content.longitude
        ]

        # Calculate the center of the locations
        center = calculate_center(locations)

        return (
            jsonify(
                success="success",
                message="User locations retrieved successfully",
                data={"locations": locations, "center": center},
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Error fetching user locations: {str(e)}")
        return (
            jsonify(
                success="error", message="Failed to retrieve user locations", data=None
            ),
            500,
        )


@content_v1_blueprint.route("/user/<int:user_id>/locations", methods=["GET"])
@login_required
def get_user_locations_by_id(user_id):
    """Endpoint to get all locations a specific user has posted in."""
    try:
        # Query the UserContent table for the given user's posts
        user_contents = UserContent.query.filter_by(user_id=user_id).all()

        # Extract content details including locations, latitude, and longitude
        locations = [
            {
                "content_id": content.id,
                "title": content.title,
                "location": content.location,
                "location_label": format_post_location(content),
                "latitude": content.latitude,
                "longitude": content.longitude,
                "is_in_seattle": content.is_in_seattle,
            }
            for content in user_contents
            if content.latitude and content.longitude
        ]

        # Calculate the center of the locations
        center = calculate_center(locations)

        return (
            jsonify(
                success="success",
                message="User locations retrieved successfully",
                data={"locations": locations, "center": center},
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Error fetching user locations: {str(e)}")
        return (
            jsonify(
                success="error", message="Failed to retrieve user locations", data=None
            ),
            500,
        )


@content_v1_blueprint.route(
    "/bookmark/<content_type>/<int:content_id>", methods=["POST"]
)
@login_required
def bookmark_content(content_type, content_id):
    """Handle POST requests to bookmark content."""
    if content_type not in ["news", "user_content"]:
        return jsonify(status="error", message="Invalid content type"), 400

    if content_type == "news":
        content = News.query.filter_by(id=content_id).first()
    elif content_type == "user_content":
        content = UserContent.query.filter_by(id=content_id).first()

    if not content:
        return jsonify(status="error", message="UserContent not found"), 404

    # Check if the content is already bookmarked
    if current_user.has_bookmarked(content_id, content_type):
        return jsonify(status="error", message="UserContent already bookmarked"), 400

    current_user.bookmark(content_id, content_type)
    db.session.commit()
    return jsonify(status="success", message="UserContent bookmarked successfully")


@content_v1_blueprint.route(
    "/unbookmark/<content_type>/<int:content_id>", methods=["POST"]
)
@login_required
def unbookmark_content(content_type, content_id):
    """Handle POST requests to unbookmark content."""
    if content_type not in ["news", "user_content"]:
        return jsonify(status="error", message="Invalid content type"), 400

    if content_type == "news":
        content = News.query.filter_by(id=content_id).first()
    elif content_type == "user_content":
        content = UserContent.query.filter_by(id=content_id).first()

    if not content:
        return jsonify(status="error", message="UserContent not found"), 404

    # Check if the content is already unbookmarked
    if not current_user.has_bookmarked(content_id, content_type):
        return jsonify(status="error", message="UserContent already unbookmarked"), 400

    current_user.unbookmark(content_id, content_type)
    db.session.commit()
    return jsonify(status="success", message="UserContent unbookmarked successfully")


@content_v1_blueprint.route("/bookmarked", methods=["GET"])
@login_required
def get_bookmarked_content():
    """Get all bookmarked content for the current user."""
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 10, type=int)

    bookmarks = Bookmark.query.filter_by(user_id=current_user.id).paginate(
        page=page, per_page=per_page, error_out=False
    )
    bookmarked_content = []

    for bookmark in bookmarks.items:
        if bookmark.content_type == "news":
            content = News.query.filter_by(id=bookmark.content_id).first()
        elif bookmark.content_type == "user_content":
            content = UserContent.query.filter_by(id=bookmark.content_id).first()

        if content:
            bookmarked_content.append(
                {
                    "id": content.id,
                    "unique_id": content.unique_id,
                    "title": (
                        content.headline
                        if bookmark.content_type == "news"
                        else content.title
                    ),
                    "description": (
                        content.body
                        if bookmark.content_type == "user_content"
                        else None
                    ),
                    "image_url": (
                        content.image_url
                        if bookmark.content_type == "news"
                        else content.thumbnail
                    ),
                    "location": content.location,
                    "user": {
                        "username": content.user.username,
                        "profile_picture_url": content.user.profile_picture_url,
                    },
                    "content_type": bookmark.content_type,
                    "timestamp": content.created_at,  # Use created_at instead of timestamp
                }
            )

    if not bookmarked_content:
        message = "No bookmarks found. Start bookmarking your favorite content!"
    else:
        message = "Bookmarked content retrieved successfully"

    return jsonify(
        status="success",
        message=message,
        data=bookmarked_content,
        pagination={
            "current_page": bookmarks.page,
            "total_pages": bookmarks.pages,
            "total_items": bookmarks.total,
            "has_next": bookmarks.has_next,
            "has_prev": bookmarks.has_prev,
        },
    )


@content_v1_blueprint.route("/repost/<int:content_id>", methods=["POST"])
@login_required
def repost_content(content_id):
    """Allow users to repost content."""
    try:
        data = request.get_json()
        thoughts = data.get("thoughts")  # Get user's thoughts from the request

        content = UserContent.query.get(content_id)
        if not content:
            return jsonify(success="error", message="Content not found", data=None), 404

        # Check if user already reposted
        if Repost.query.filter_by(
            user_id=current_user.id, content_id=content_id
        ).first():
            return (
                jsonify(success="error", message="Content already reposted", data=None),
                409,
            )

        # Add repost record
        new_repost = Repost(
            user_id=current_user.id, content_id=content_id, thoughts=thoughts
        )
        db.session.add(new_repost)
        db.session.commit()

        return (
            jsonify(
                success="success",
                message="Content reposted successfully",
                data={"content_id": content_id, "thoughts": thoughts},
            ),
            201,
        )

    except Exception as e:
        current_app.logger.error(f"Error reposting content: {str(e)}")
        db.session.rollback()
        return (
            jsonify(success="error", message="Failed to repost content", data=None),
            500,
        )


@content_v1_blueprint.route("/undo_repost/<int:content_id>", methods=["POST"])
@login_required
def undo_repost_content(content_id):
    """Allow users to undo a repost."""
    try:
        content = UserContent.query.get(content_id)
        if not content:
            return jsonify(success="error", message="Content not found", data=None), 404

        # Check if user has reposted
        repost = Repost.query.filter_by(
            user_id=current_user.id, content_id=content_id
        ).first()
        if not repost:
            return (
                jsonify(success="error", message="Repost not found", data=None),
                404,
            )

        # Remove repost record
        db.session.delete(repost)
        db.session.commit()

        return (
            jsonify(
                success="success",
                message="Repost undone successfully",
                data={"content_id": content_id},
            ),
            200,
        )

    except Exception as e:
        current_app.logger.error(f"Error undoing repost: {str(e)}")
        db.session.rollback()
        return (
            jsonify(success="error", message="Failed to undo repost", data=None),
            500,
        )

@content_v1_blueprint.route("/get-seattle-locations", methods=["GET"])
def get_all_seattle_city_locations():
    """
    GET /locations
    Returns a list of all locations including a virtual "All Locations" entry.
    """
    # Query all locations from the database, ordered by name
    locations = Location.query.order_by(Location.name.asc()).all()

    # Convert each location to a dictionary
    location_list = [location.to_dict() for location in locations]

    # Add "All Locations" option at the top
    all_location = {
        "id": 0,
        "name": "Seattle (All)",
        "latitude": None,
        "longitude": None,
    }
    location_list.insert(0, all_location)
    
    # Add "Outside Seattle" option
    outside_seattle = {
        "id": -1,
        "name": "Outside Seattle",
        "latitude": None,
        "longitude": None,
    }
    location_list.insert(1, outside_seattle)

    # Return JSON response
    return (
        jsonify(
            {
                "status": "success",
                "message": "Location list retrieved successfully.",
                "data": location_list,
                "totalResults": len(location_list),
            }
        ),
        200,
    )

@content_v1_blueprint.route("/search_home_location", methods=["GET"])
def search_home_location():
    """
    Search user-inputted home locations with Seattle-aware, country-aware, and dropdown-aware labeling.
    """

    query = request.args.get("query", "").strip()
    page = int(request.args.get("page", 1))
    limit = int(request.args.get("limit", 10))

    if not query:
        return jsonify({"error": "query parameter is required"}), 400

    url = f"{NOMINATIM_BASE_URL}/search?q={query}&format=json&addressdetails=1&limit={limit}&offset={(page - 1) * limit}"
    headers = {"User-Agent": "SeattlePulseApp/1.0"}

    try:
        response = requests.get(url, headers=headers, timeout=5)
        response.raise_for_status()
        results = response.json()

        if not results:
            return jsonify({"error": "No matching locations found."}), 404

        locations = []
        for place in results:
            lat = float(place["lat"])
            lon = float(place["lon"])
            display_name = place.get("display_name", "Unknown")
            address = place.get("address", {})

            # Label the home location
            home_label = label_home_location(address, query)
            dropdown_value = normalize_for_dropdown(home_label)

            locations.append({
                "home_location_label": home_label,
                "latitude": lat,
                "longitude": lon,
                "dropdown_value": dropdown_value,
                "raw": {"display_name": display_name, "address": address},
            })

        # Prioritize Seattle neighborhoods first
        def _priority(item):
            addr = item["raw"].get("address", {})
            city = (addr.get("city") or addr.get("town") or addr.get("village") or "").lower()
            country_code = (addr.get("country_code") or "").lower()
            neighbourhood = (addr.get("neighbourhood") or addr.get("suburb") or "").strip()
            is_seattle = city == "seattle" or country_code == "us" and addr.get("state", "").lower() == "washington" and city == "seattle"
            has_neighborhood = bool(neighbourhood) and neighbourhood.lower() != "seattle"
            # Highest priority: Seattle with a neighborhood
            if is_seattle and has_neighborhood:
                return (0,)
            # Next: Seattle city fallback
            if is_seattle:
                return (1,)
            # Others later
            return (2,)

        locations.sort(key=_priority)

        return jsonify({
            "success": "success",
            "query": query,
            "page": page,
            "limit": limit,
            "results": locations,
            "total_results": len(locations),
        })

    except requests.RequestException as e:
        print(f"Error fetching locations: {e}")
        return jsonify({"error": "Failed to retrieve locations"}), 500


def label_home_location(address, query=""):
    """
    Determine appropriate label for 'Home Location':
    - Neighborhood (if in Seattle)
    - City, State (if in USA, outside Seattle)
    - City, Country (if outside USA)
    """
    city = address.get("city") or address.get("town") or address.get("village") or address.get("hamlet")
    state = address.get("state")
    country = address.get("country")
    country_code = (address.get("country_code") or "").lower()
    neighborhood = address.get("neighbourhood") or address.get("suburb")

    def normalize_city(name: str):
        if not name:
            return name
        # Handle cases like "City of London" → "London"
        lowered = name.lower()
        prefixes = ["city of "]
        for p in prefixes:
            if lowered.startswith(p):
                return name[len(p):]
        return name

    city = normalize_city(city)

    # Fremont-specific logic
    if "fremont" in query.lower():
        if city and city.lower() == "seattle":
            return "Fremont"
        elif state:
            return f"Fremont, {state}"

    # Seattle neighborhood logic
    if city and city.lower() == "seattle" and state and state.lower() == "washington" and (
        country_code == "us" or (country or "").lower().startswith("united states")
    ):
        if neighborhood and neighborhood.lower() != "seattle":
            return neighborhood
        return "Seattle"

    # Inside USA, outside Seattle
    if (country_code == "us") or ((country or "").lower().startswith("united states")):
        if city and state:
            return f"{city}, {state}"
        return city or state or "Unknown US Location"

    # International
    if city and country:
        return f"{city}, {country}"
    return country or "International Location"


def normalize_for_dropdown(home_label):
    """
    Normalize the home location label for dropdown filtering logic.
    """
    primary = ["U-District", "Ballard", "Capitol Hill"]
    if home_label in primary:
        return home_label
    elif "Seattle" in home_label or home_label in ["Fremont", "Greenwood", "Rainier Valley"]:
        return "Seattle"
    return home_label
