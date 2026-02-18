class ContentDetailsResponse {
  final String success;
  final String message;
  final ContentDetails data;

  ContentDetailsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ContentDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ContentDetailsResponse(
      success: json['success'] ?? '',
      message: json['message'] ?? '',
      data: ContentDetails.fromJson(json['data']),
    );
  }
}

class ContentDetails {
  final int id;
  final int uniqueId;
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final String sourceUrl;
  final User user;
  final int totalComments;
  final int totalReactions;
  final List<String> topReactions;
  final bool userHasReacted;
  final String? userReactionType;
  final bool hasUserReposted;
  final List<Comment> comments;
  final Pagination pagination;
  final createdAt;

  ContentDetails(
      {required this.id,
      required this.uniqueId,
      required this.title,
      required this.description,
      required this.imageUrl,
      required this.location,
      required this.sourceUrl,
      required this.user,
      required this.totalComments,
      required this.totalReactions,
      required this.topReactions,
      required this.userHasReacted,
      this.userReactionType,
      required this.hasUserReposted,
      required this.comments,
      required this.pagination,
      this.createdAt});

  factory ContentDetails.fromJson(Map<String, dynamic> json) {
    return ContentDetails(
      id: json['id'] ?? 0,
      uniqueId: json['unique_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      location: json['location'] ?? '',
      createdAt: json['created_at'] as String?,
      sourceUrl: json['source_url'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      totalComments: json['total_comments'] ?? 0,
      totalReactions: json['total_reactions'] ?? 0,
      topReactions: List<String>.from(json['top_reactions'] ?? []),
      userHasReacted: json['user_has_reacted'] ?? false,
      userReactionType: json['user_reaction_type'], // can be null
      hasUserReposted: json['has_user_reposted'] ?? false,
      comments: (json['comments'] as List? ?? [])
          .map((e) => Comment.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }

  ContentDetails copyWith({
    int? id,
    int? uniqueId,
    String? title,
    String? description,
    String? imageUrl,
    String? location,
    String? sourceUrl,
    User? user,
    int? totalComments,
    int? totalReactions,
    List<String>? topReactions,
    bool? userHasReacted,
    String? userReactionType,
    bool? hasUserReposted,
    String? createdAt,
    List<Comment>? comments,
    Pagination? pagination,
  }) {
    return ContentDetails(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      totalComments: totalComments ?? this.totalComments,
      totalReactions: totalReactions ?? this.totalReactions,
      topReactions: topReactions ?? this.topReactions,
      userHasReacted: userHasReacted ?? this.userHasReacted,
      userReactionType: userReactionType ?? this.userReactionType,
      hasUserReposted: hasUserReposted ?? this.hasUserReposted,
      comments: comments ?? this.comments,
      pagination: pagination ?? this.pagination,
    );
  }
}

class Comment {
  final int id;
  final String content;
  final int userId;
  final String createdAt;
  final User user;
  final int repliesCount;
  final List<String> topCommentReactions;
  final bool hasReactedToComment;
  final String? commentReactionType;

  Comment({
    required this.id,
    required this.content,
    required this.userId,
    required this.createdAt,
    required this.user,
    required this.repliesCount,
    required this.topCommentReactions,
    required this.hasReactedToComment,
    this.commentReactionType,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      repliesCount: json['replies_count'] ?? 0,
      topCommentReactions:
          List<String>.from(json['top_comment_reactions'] ?? []),
      hasReactedToComment: json['has_reacted_to_comment'] ?? false,
      commentReactionType: json['comment_reaction_type'], // nullable
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
    this.profilePictureUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
    );
  }
}

class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNext;
  final bool hasPrev;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalItems: json['total_items'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
    );
  }
}
