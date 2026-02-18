from flask import Blueprint, jsonify, request
from flask_login import current_user
from app.models import User, Follow, SearchHistory, Block
from app import db
from sqlalchemy import or_, func

users_v1_blueprint = Blueprint("users_v1", __name__, url_prefix="/api/v1/users")


@users_v1_blueprint.route("/search", methods=["GET"])
def search_users():
    """Search users by username, first name, last name, or full name, with pagination and block filtering."""
    if not current_user.is_authenticated:
        return jsonify({"success": "error", "message": "You must be logged in."}), 401

    search_query = request.args.get("query", "").strip()
    save_to_history = request.args.get("save", "true").lower() == "true"
    page = int(request.args.get("page", 1))
    per_page = int(request.args.get("limit", 10))

    if not search_query:
        return jsonify({"success": "error", "message": "Search query cannot be empty."}), 400

    try:
        if save_to_history:
            new_search = SearchHistory(user_id=current_user.id, query=search_query)
            db.session.add(new_search)
            db.session.commit()

        search_pattern = f"%{search_query}%"

        # Get IDs of users blocked by current_user
        blocked_ids = db.session.query(Block.blocked_id).filter_by(blocker_id=current_user.id)

        # Search users not in blocked list
        query = User.query.filter(
            ~User.id.in_(blocked_ids),
            or_(
                User.username.ilike(search_pattern),
                User.first_name.ilike(search_pattern),
                User.last_name.ilike(search_pattern),
                func.concat(User.first_name, ' ', User.last_name).ilike(search_pattern),
            )
        )

        paginated = query.paginate(page=page, per_page=per_page, error_out=False)

        user_list = [
            {
                "id": user.id,
                "username": user.username,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "profile_picture_url": user.profile_picture_url,
                "location": user.location,
                "total_followers": db.session.query(Follow).filter_by(followed_id=user.id).count(),
            }
            for user in paginated.items
        ]

        return jsonify({
            "success": "success",
            "data": user_list,
            "query": search_query,
            "pagination": {
                "current_page": paginated.page,
                "total_pages": paginated.pages,
                "total_items": paginated.total,
                "has_next": paginated.has_next,
                "has_prev": paginated.has_prev,
            },
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({"success": "error", "message": str(e)}), 500




@users_v1_blueprint.route("/search/history", methods=["GET"])
def get_user_search_history():
    """Retrieve the last 10 search queries of the logged-in user."""
    if not current_user.is_authenticated:
        return jsonify({"success": "error", "message": "You must be logged in."}), 401

    try:
        history = (
            db.session.query(SearchHistory)
            .filter(SearchHistory.user_id == current_user.id)
            .order_by(SearchHistory.timestamp.desc())
            .limit(10)
            .all()
        )

        return jsonify(
            {
                "success": "success",
                "history": [
                    {"query": h.query, "timestamp": h.timestamp.isoformat()}
                    for h in history
                ],
            }
        )

    except Exception as e:
        db.session.rollback()
        return jsonify({"success": "error", "message": str(e)}), 500


@users_v1_blueprint.route("/search/history/clear", methods=["POST"])
def clear_user_search_history():
    """Clear search history of the logged-in user."""
    if not current_user.is_authenticated:
        return jsonify({"success": "error", "message": "You must be logged in."}), 401

    try:
        # Use `.filter()` instead of `.filter_by()`
        db.session.query(SearchHistory).filter(
            SearchHistory.user_id == current_user.id
        ).delete()
        db.session.commit()
        return jsonify({"success": "success", "message": "Search history cleared."})
    except Exception as e:
        db.session.rollback()
        return jsonify({"success": "error", "message": str(e)}), 500
