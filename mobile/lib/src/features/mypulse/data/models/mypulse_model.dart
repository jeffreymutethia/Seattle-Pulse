import 'dart:convert';

class MypulseResponse {
  final Data data;
  final String message;
  final Pagination pagination;
  final Query query;
  final String success;

  MypulseResponse({
    required this.data,
    required this.message,
    required this.pagination,
    required this.query,
    required this.success,
  });

  factory MypulseResponse.fromJson(Map<String, dynamic> json) {
    return MypulseResponse(
      data: Data.fromJson(json['data']),
      message: json['message'] as String,
      pagination: Pagination.fromJson(json['pagination']),
      query: Query.fromJson(json['query']),
      success: json['success'] as String,
    );
  }
}

class Data {
  final List<Content> content;

  Data({required this.content});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      content: (json['content'] as List)
          .map((item) => Content.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Content {
  final int id;
  final String title;
  final String body;
  final String location;
  final String? thumbnail;
  final int commentsCount;
  final int reactionsCount;
  final int? totalComments;
  final int? sharesCount;
  final String score;
  final String? timeSincePost;
  final List<String> topReactions;
  final Map<String, int>? reactionBreakdown;
  final String createdAt;
  final String updatedAt;
  final User user;
  final bool hasUserReposted;
  final bool userHasReacted;
  final String? userReactionType;
  final List<Comment>? comments;
  final int repostsCount;

  Content({
    required this.id,
    required this.title,
    required this.body,
    required this.location,
    required this.thumbnail,
    required this.commentsCount,
    required this.reactionsCount,
    this.totalComments,
    this.sharesCount,
    required this.score,
    this.timeSincePost,
    required this.topReactions,
    this.reactionBreakdown,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.hasUserReposted,
    required this.userHasReacted,
    this.userReactionType,
    this.comments,
    required this.repostsCount,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      location: json['location'] as String,
      thumbnail: json['thumbnail'] as String?,
      commentsCount: json['comments_count'] as int,
      reactionsCount: json['reactions_count'] as int,
      totalComments: json['total_comments'] as int?,
      sharesCount: json['shares_count'] as int?,
      repostsCount: (json['reposts_count'] as int?) ?? 0,
      score: json['score'].toString(),
      timeSincePost: json['time_since_post'] as String?,
      topReactions: List<String>.from(json['top_reactions'] ?? []),
      reactionBreakdown: json['reaction_breakdown'] != null
          ? Map<String, int>.from(json['reaction_breakdown'])
          : null,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      hasUserReposted: json['has_user_reposted'] ?? false,
      userHasReacted: json['user_has_reacted'] ?? false,
      userReactionType: json['user_reaction_type'],
      comments: json['comments'] != null
          ? (json['comments'] as List).map((e) => Comment.fromJson(e)).toList()
          : null,
    );
  }
}

class User {
  final int id;
  final String username;
  final String? profilePictureUrl;

  User({
    required this.id,
    required this.username,
    required this.profilePictureUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );
  }
}

class Comment {
  final int id;
  final int userId;
  final int contentId;
  final String contentType;
  final String body;
  final String createdAt;
  final String updatedAt;
  final List<String> topCommentReactions;
  final int repliesCount;
  final int reactionsCount;

  Comment({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.contentType,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.topCommentReactions,
    required this.repliesCount,
    required this.reactionsCount,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      contentId: json['content_id'] as int,
      contentType: json['content_type'] as String,
      body: json['body'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      topCommentReactions:
          List<String>.from(json['top_comment_reactions'] ?? []),
      repliesCount: json['replies_count'] as int,
      reactionsCount: json['reactions_count'] as int,
    );
  }
}

class Pagination {
  final int currentPage;
  final bool hasNext;
  final bool hasPrev;
  final int totalItems;
  final int totalPages;

  Pagination({
    required this.currentPage,
    required this.hasNext,
    required this.hasPrev,
    required this.totalItems,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] as int,
      hasNext: json['has_next'] as bool,
      hasPrev: json['has_prev'] as bool,
      totalItems: json['total_items'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}

class Query {
  final String location;
  final int page;
  final int perPage;

  Query({
    required this.location,
    required this.page,
    required this.perPage,
  });

  factory Query.fromJson(Map<String, dynamic> json) {
    return Query(
      location: json['location'] as String,
      page: json['page'] as int,
      perPage: json['per_page'] as int,
    );
  }
}

// Helper function to parse JSON response if you need it:
MypulseResponse parseMypulseResponse(String responseBody) {
  final Map<String, dynamic> parsed = json.decode(responseBody);
  return MypulseResponse.fromJson(parsed);
}
