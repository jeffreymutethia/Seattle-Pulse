// lib/src/features/feed/data/models/content_model.dart

import 'dart:convert';

class ContentResponse {
  final Data data;
  final String message;
  final Pagination pagination;
  final Query query;
  final String success;

  ContentResponse({
    required this.data,
    required this.message,
    required this.pagination,
    required this.query,
    required this.success,
  });

  factory ContentResponse.fromJson(Map<String, dynamic> json) {
    return ContentResponse(
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
  final String? title;
  final String? body;
  final String location;
  final String? thumbnail; // <-- Make this nullable
  final int commentsCount;
  final int reactionsCount;
  final int repostsCount;
  final String score;
  final String timeSincePost;
  final List<String> topReactions;
  final String createdAt;
  final String updatedAt;
  final User user;
  final bool hasUserReposted;
  final bool userHasReacted;
  final String? userReactionType; // Nullable

  Content({
    required this.id,
    this.title,
    this.body,
    required this.location,
    required this.thumbnail, // Notice now it's nullable
    required this.commentsCount,
    required this.reactionsCount,
    required this.repostsCount,
    required this.score,
    required this.timeSincePost,
    required this.topReactions,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.hasUserReposted,
    required this.userHasReacted,
    this.userReactionType,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id'] as int,
      title: json['title'] as String?,
      body: json['body'] as String?,
      location: json['location'] as String,
      thumbnail: json['thumbnail'] as String?, // Cast as String?
      commentsCount: json['comments_count'] as int,
      reactionsCount: json['reactions_count'] as int,
      repostsCount: json['reposts_count'] as int? ?? 0,
      score: json['score'] as String,
      timeSincePost: json['time_since_post'] as String,
      topReactions: List<String>.from(json['top_reactions']),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      hasUserReposted: json['has_user_reposted'] ?? false,
      userHasReacted: json['user_has_reacted'] ?? false,
      userReactionType: json['user_reaction_type'],
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
      profilePictureUrl: json['profile_picture_url'] ?? '',
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
ContentResponse parseContentResponse(String responseBody) {
  final Map<String, dynamic> parsed = json.decode(responseBody);
  return ContentResponse.fromJson(parsed);
}
