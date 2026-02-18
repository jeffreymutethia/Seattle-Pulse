from flask import Blueprint, jsonify, request
from flask_login import current_user, login_required
from app.models import (
    Comment,
    UserContent,
    Reaction,
    Share,
    User,
    Block,
    db,
    CommentReaction,
    Repost,
    Follow,
)
from app.location_service import (
    InvalidLocation,
    apply_location_filter,
    display_location_value,
    format_post_location,
    parse_location_filter,
)
import logging
from sqlalchemy.sql import func, desc
from sqlalchemy.orm import subqueryload

logger = logging.getLogger(__name__)

feed_v1_blueprint = Blueprint("feed_v1", __name__, url_prefix="/api/v1/feed")


# Scoring function based on reactions, comments, and shares with time decay
def get_mypulse_score():
    weights = {
        "reaction_weight": 2,
        "comment_weight": 3,
        "share_weight": 5,
    }
    decay_factor = 86400  # 1 day in seconds

    score_expression = (
        (
            weights["reaction_weight"] * func.count(Reaction.id)
            + weights["comment_weight"] * func.count(Comment.id)
            + weights["share_weight"] * func.count(Share.id)
        )
        * func.exp(
            -(func.extract("epoch", func.now() - UserContent.created_at) / decay_factor)
        )
    ).label("score")

    return score_expression


# Function to fetch ranked mypulse content, excluding blocked users
def fetch_mypulse_content(page, per_page, user_id, location_spec=None):
    score_expression = get_mypulse_score()
    followed_users_ids = [follow.followed_id for follow in current_user.followed]

    if not followed_users_ids:
        return [], 0  # Return empty list and zero count

    blocked_users_subquery = db.session.query(Block.blocked_id).filter(
        Block.blocker_id == user_id
    )
    blocked_by_users_subquery = db.session.query(Block.blocker_id).filter(
        Block.blocked_id == user_id
    )

    base_query = (
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
            score_expression,
        )
        .join(User, User.id == UserContent.user_id)
        .outerjoin(Reaction, Reaction.content_id == UserContent.id)
        .outerjoin(Comment, Comment.content_id == UserContent.id)
        .outerjoin(Share, Share.content_id == UserContent.id)
        .filter(
            UserContent.user_id.in_(followed_users_ids),
            ~UserContent.user_id.in_(blocked_users_subquery),
            ~UserContent.user_id.in_(blocked_by_users_subquery),
        )
    )

    if location_spec:
        base_query = apply_location_filter(base_query, location_spec)

    grouped_query = base_query.group_by(
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

    # Total count before pagination
    total_items = grouped_query.count()

    # Paginated result
    content = (
        grouped_query
        .order_by(desc("score"))
        .limit(per_page)
        .offset((page - 1) * per_page)
        .all()
    )

    return content, total_items


@feed_v1_blueprint.route("/mypulse", methods=["GET"])
@login_required
def mypulse():
    raw_location = request.args.get("location")
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 10, type=int)

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

    try:
        paginated_content, total_items = fetch_mypulse_content(
            page=page,
            per_page=per_page,
            user_id=current_user.id,
            location_spec=location_spec,
        )

        # Fetch user reactions
        user_reactions = Reaction.query.filter_by(user_id=current_user.id).all()

        # Fetch user's reposts
        user_reposts = Repost.query.filter_by(user_id=current_user.id).all()

        # Create a set of content_ids the user has reacted to
        user_reacted_content_ids = {reaction.content_id for reaction in user_reactions}

        # Store reaction details in a dictionary for quick lookup
        user_reactions_dict = {
            reaction.content_id: reaction.reaction_type.value
            for reaction in user_reactions
        }

        # Create a set of content_ids the user has reposted
        user_reposted_content_ids = {repost.content_id for repost in user_reposts}

        content_list = []
        for item in paginated_content:
            reactions_count = Reaction.query.filter_by(content_id=item.id).count()
            comments_count = Comment.query.filter_by(content_id=item.id).count()

            # Check if the user has reacted to this post
            user_has_reacted = item.id in user_reacted_content_ids
            user_reaction_type = user_reactions_dict.get(item.id, None)

            # Check if the user has reposted this post
            has_user_reposted = item.id in user_reposted_content_ids

            # Calculate top 2 reactions for content
            top_reaction_counts = (
                db.session.query(
                    Reaction.reaction_type, db.func.count(Reaction.reaction_type)
                )
                .filter_by(content_id=item.id)
                .group_by(Reaction.reaction_type)
                .order_by(
                    db.func.count(Reaction.reaction_type).desc(), Reaction.reaction_type
                )  # Secondary ordering by reaction type
                .limit(2)
                .all()
            )
            top_reactions = [
                reaction_type.value for reaction_type, count in top_reaction_counts
            ]

            # Fetch comments for the content
            comments = Comment.query.filter_by(content_id=item.id).all()
            for comment in comments:
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
                    )  # Secondary ordering by reaction type
                    .limit(2)
                    .all()
                )

            content_list.append(
                {
                    "id": item.id,
                    "title": item.title,
                    "location": item.location,
                    "location_label": format_post_location(item),
                    "created_at": (
                        item.created_at.isoformat() if item.created_at else None
                    ),
                    "updated_at": (
                        item.updated_at.isoformat() if item.updated_at else None
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
                    "user_has_reacted": user_has_reacted,  # Indicates if the user has reacted
                    "user_reaction_type": user_reaction_type,  # Shows the type of reaction user gave
                    "has_user_reposted": has_user_reposted,  # Indicates if the user has reposted
                    "is_in_seattle": item.is_in_seattle,
                }
            )
            
        total_pages = total_items // per_page + (1 if total_items % per_page > 0 else 0)
        has_next = page < total_pages
        has_prev = page > 1
        
        response = {
            "success": "success",
            "message": "My Pulse content fetched successfully",
            "data": {
                "content": content_list,
                "reactions": [
                    {
                        "content_id": reaction.content_id,
                        "content_type": reaction.content_type,
                        "reaction_type": reaction.reaction_type.value,
                        "timestamp": reaction.created_at.isoformat(),
                    }
                    for reaction in user_reactions
                ],
            },
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
        db.session.rollback()
        logger.error(f"Error fetching my pulse content: {str(e)}")
        return (
            jsonify(
                {
                    "success": "error",
                    "message": f"Failed to fetch my pulse content: {str(e)}",
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


@feed_v1_blueprint.route("/mypulse/<int:content_id>", methods=["GET"])
@login_required
def mypulse_detail(content_id):
    """Fetch content details, top-level comments, and their reply counts."""

    # Step 1: Fetch the content and handle the case where it doesn't exist
    content = UserContent.query.filter_by(id=content_id).first()
    if not content:
        return jsonify(success="error", message="Content not found", data=None), 404

    # Step 2: Check if the user is blocked or has blocked the content owner
    blocked_users_subquery = db.session.query(Block.blocked_id).filter(
        Block.blocker_id == current_user.id
    )
    blocked_by_users_subquery = db.session.query(Block.blocker_id).filter(
        Block.blocked_id == current_user.id
    )
    if (
        content.user_id in blocked_users_subquery
        or content.user_id in blocked_by_users_subquery
    ):
        return (
            jsonify(
                success="error",
                message="You are not authorized to view this content",
                data=None,
            ),
            403,
        )

    # Step 3: Fetch total reactions and breakdown of reactions by type
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

    # Step 4: Check if the current user has reposted the content
    has_user_reposted = (
        db.session.query(Repost)
        .filter_by(user_id=current_user.id, content_id=content.id)
        .first()
        is not None
    )

    # Step 5: Check if the current user has reacted to the content
    user_reaction = Reaction.query.filter_by(
        content_id=content.id, user_id=current_user.id
    ).first()
    user_has_reacted = user_reaction is not None
    user_reaction_type = user_reaction.reaction_type.value if user_reaction else None

    # Calculate top 2 reactions
    top_reaction_counts = (
        db.session.query(Reaction.reaction_type, db.func.count(Reaction.reaction_type))
        .filter_by(content_id=content.id)
        .group_by(Reaction.reaction_type)
        .order_by(db.func.count(Reaction.reaction_type).desc(), Reaction.reaction_type)
        .limit(2)
        .all()
    )
    top_reactions = [
        reaction_type.value for reaction_type, count in top_reaction_counts
    ]

    # Step 6: Pagination for top-level comments
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 10, type=int)

    # Count total comments before paginating
    total_comments = Comment.query.filter_by(content_id=content.id).count()

    # Fetch user reactions to comments for optimized lookup
    user_comment_reactions = {
        reaction.content_id: reaction.reaction_type.value
        for reaction in CommentReaction.query.filter_by(user_id=current_user.id).all()
    }

    # Fetch top-level comments with pagination
    try:
        top_level_comments_paginated = (
            Comment.query.filter_by(content_id=content.id, parent_id=None)
            .options(subqueryload(Comment.user))
            .order_by(Comment.created_at.asc())
            .paginate(page=page, per_page=per_page, error_out=False)
        )
    except Exception as e:
        return jsonify(success="error", message="Pagination failed", data=None), 500

    # Build the comment list
    comment_list = []
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
            reaction_type.value for reaction_type, count in top_comment_reaction_counts
        ]

        # Check if the user has reacted to the comment
        has_reacted_to_comment = comment.id in user_comment_reactions
        comment_reaction_type = user_comment_reactions.get(comment.id, None)

        comment_list.append(
            {
                "id": comment.id,
                "content": comment.content,
                "user_id": comment.user_id,
                "created_at": (
                    comment.created_at.isoformat() if comment.created_at else None
                ),
                "updated_at": (
                    comment.updated_at.isoformat() if comment.updated_at else None
                ),
                "user": {
                    "id": comment.user.id,
                    "username": comment.user.username,
                    "profile_picture_url": comment.user.profile_picture_url
                    or "https://default-profile.png",
                },
                "replies_count": Comment.query.filter_by(parent_id=comment.id).count(),
                "reactions_count": Reaction.query.filter_by(
                    content_id=comment.id
                ).count(),
                "top_comment_reactions": top_comment_reactions,
                "has_reacted_to_comment": has_reacted_to_comment,  # Indicates if the user reacted
                "comment_reaction_type": comment_reaction_type,  # Specifies the reaction type
            }
        )

    # Step 7: Build the response data structure
    content_data = {
        "id": content.id,
        "title": content.title,
        "body": content.body,
        "created_at": content.created_at.isoformat() if content.created_at else None,
        "updated_at": content.updated_at.isoformat() if content.updated_at else None,
        "user": {
            "id": content.user.id,
            "username": content.user.username,
            "profile_picture_url": content.user.profile_picture_url
            or "https://default-profile.png",
        },
        "total_reactions": total_reactions,
        "reaction_breakdown": reaction_breakdown,
        "top_reactions": top_reactions,
        "user_has_reacted": user_has_reacted,  # Indicates if the user has reacted
        "user_reaction_type": user_reaction_type,  # Shows the type of reaction user gave
        "has_user_reposted": has_user_reposted,  # Indicates if the user has reposted the content
        "total_comments": total_comments,
        "comments": comment_list,
        "pagination": {
            "current_page": top_level_comments_paginated.page,
            "total_pages": top_level_comments_paginated.pages,
            "total_items": top_level_comments_paginated.total,
            "has_next": top_level_comments_paginated.has_next,
            "has_prev": top_level_comments_paginated.has_prev,
        },
    }

    # Step 8: Return the response
    return (
        jsonify(
            success="success",
            message="Content details fetched successfully",
            data=content_data,
        ),
        200,
    )


@feed_v1_blueprint.route("/suggestions", methods=["GET"])
@login_required
def friend_suggestions():
    try:
        current_user_id = current_user.id

        # Subquery: Find all users followed by the current user
        following_subquery = db.session.query(Follow.followed_id).filter(
            Follow.follower_id == current_user_id
        )

        # Subquery: Find all users who follow the current user
        followers_subquery = db.session.query(Follow.follower_id).filter(
            Follow.followed_id == current_user_id
        )

        # Find mutual connections
        mutual_connections = (
            db.session.query(User)
            .join(Follow, Follow.followed_id == User.id)
            .filter(Follow.follower_id.in_(following_subquery))
        )

        # Find users who reacted to content created by the current user
        reacted_users = (
            db.session.query(User)
            .join(Reaction, Reaction.user_id == User.id)
            .filter(
                Reaction.content_id.in_(
                    db.session.query(UserContent.id).filter(
                        UserContent.user_id == current_user_id
                    )
                )
            )
        )

        # Find news accounts (users with seeded news content) - these should always be suggested
        news_accounts = (
            db.session.query(User)
            .join(UserContent, UserContent.user_id == User.id)
            .filter(
                UserContent.is_seeded == True,
                UserContent.seed_type == "news"
            )
            .distinct()
        )

        # Combine all queries: mutual connections, reacted users, followers, and news accounts
        suggestions_query = mutual_connections.union(reacted_users).union(
            db.session.query(User).filter(User.id.in_(followers_subquery))
        ).union(news_accounts)

        # Apply filters
        suggestions_query = (
            suggestions_query.filter(~User.id.in_(following_subquery))
            .filter(
                ~User.id.in_(
                    db.session.query(Block.blocked_id).filter(
                        Block.blocker_id == current_user_id
                    )
                )
            )
            .filter(
                ~User.id.in_(
                    db.session.query(Block.blocker_id).filter(
                        Block.blocked_id == current_user_id
                    )
                )
            )
            .filter(User.id != current_user_id)
        )

        # Prioritization metrics
        # 1) News-seeded posts count per user (treat any user with seeded 'news' posts as a news account)
        news_posts_count_sq = (
            db.session.query(
                UserContent.user_id.label("user_id"),
                func.count(UserContent.id).label("news_posts_count"),
            )
            .filter(UserContent.is_seeded == True, UserContent.seed_type == "news")
            .group_by(UserContent.user_id)
            .subquery()
        )

        # 2) Total posts count per user
        posts_count_sq = (
            db.session.query(
                UserContent.user_id.label("user_id"),
                func.count(UserContent.id).label("posts_count"),
            )
            .group_by(UserContent.user_id)
            .subquery()
        )

        # Order suggestions: news accounts first, then by total posts
        suggestions_query = (
            suggestions_query
            .outerjoin(
                news_posts_count_sq, news_posts_count_sq.c.user_id == User.id
            )
            .outerjoin(posts_count_sq, posts_count_sq.c.user_id == User.id)
            .order_by(
                desc(func.coalesce(news_posts_count_sq.c.news_posts_count, 0)),
                desc(func.coalesce(posts_count_sq.c.posts_count, 0)),
                desc(User.id),
            )
        )

        # Pagination
        page = request.args.get("page", 1, type=int)
        per_page = request.args.get("per_page", 10, type=int)
        suggestions = suggestions_query.paginate(
            page=page, per_page=per_page, error_out=False
        )

        # Format response
        data = []
        page_users = suggestions.items

        # Batch fetch follower counts for page users to avoid N+1
        if page_users:
            page_user_ids = [u.id for u in page_users]
            follower_counts = (
                db.session.query(
                    Follow.followed_id.label("user_id"),
                    func.count(Follow.follower_id).label("followers_count"),
                )
                .filter(Follow.followed_id.in_(page_user_ids))
                .group_by(Follow.followed_id)
                .all()
            )
            follower_count_map = {row.user_id: row.followers_count for row in follower_counts}
        else:
            follower_count_map = {}

        # Batch fetch news flag and post counts for page users
        news_counts_page = (
            db.session.query(
                UserContent.user_id.label("user_id"),
                func.count(UserContent.id).label("news_posts_count"),
            )
            .filter(
                UserContent.user_id.in_(page_user_ids) if page_users else False,
                UserContent.is_seeded == True,
                UserContent.seed_type == "news",
            )
            .group_by(UserContent.user_id)
            .all()
        )
        news_count_map = {row.user_id: row.news_posts_count for row in news_counts_page}

        posts_counts_page = (
            db.session.query(
                UserContent.user_id.label("user_id"),
                func.count(UserContent.id).label("posts_count"),
            )
            .filter(UserContent.user_id.in_(page_user_ids) if page_users else False)
            .group_by(UserContent.user_id)
            .all()
        )
        posts_count_map = {row.user_id: row.posts_count for row in posts_counts_page}

        for user in page_users:
            total_followers = follower_count_map.get(user.id, 0)
            news_posts_count = news_count_map.get(user.id, 0)
            posts_count = posts_count_map.get(user.id, 0)

            data.append(
                {
                    "id": user.id,
                    "username": user.username,
                    "first_name": user.first_name,
                    "last_name": user.last_name,
                    "profile_picture_url": user.profile_picture_url,
                    "bio": user.bio,
                    "total_followers": total_followers,
                    "location": user.location,
                    "is_news_account": news_posts_count > 0,
                    "posts_count": posts_count,
                }
            )

        return jsonify(
            {
                "success": True,
                "data": data,
                "pagination": {
                    "total": suggestions.total,
                    "pages": suggestions.pages,
                    "current_page": suggestions.page,
                },
            }
        )

    except Exception as e:
        logger.error(
            f"Error fetching friend suggestions for user_id {current_user_id}: {str(e)}"
        )
        return jsonify({"success": False, "error": "Unable to fetch suggestions"}), 500