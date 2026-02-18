import 'package:flutter/foundation.dart';

class Comment {
  final int id;
  final String content;
  final String createdAt;
  final String? updatedAt;
  final int contentId;
  final String contentType;
  final int userId;
  final UserComment user;
  final int? parentId;
  final UserComment? repliedTo;
  final int reactionCount;
  final List<String> topReactions;
  final bool hasReacted;
  final String? reactionType;
  final List<Comment> replies;
  final bool showReplies;
  final bool isLoading;
  final bool hasMoreReplies;
  final int currentPage;
  final int? repliesCount;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    required this.contentId,
    required this.contentType,
    required this.userId,
    required this.user,
    this.parentId,
    this.repliedTo,
    this.reactionCount = 0,
    this.topReactions = const [],
    this.hasReacted = false,
    this.reactionType,
    this.replies = const [],
    this.showReplies = false,
    this.isLoading = false,
    this.hasMoreReplies = false,
    this.currentPage = 1,
    this.repliesCount,
  });

  Comment copyWith({
    int? id,
    String? content,
    String? createdAt,
    String? updatedAt,
    int? contentId,
    String? contentType,
    int? userId,
    UserComment? user,
    int? parentId,
    UserComment? repliedTo,
    int? reactionCount,
    List<String>? topReactions,
    bool? hasReacted,
    String? reactionType,
    List<Comment>? replies,
    bool? showReplies,
    bool? isLoading,
    bool? hasMoreReplies,
    int? currentPage,
    int? repliesCount,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      parentId: parentId ?? this.parentId,
      repliedTo: repliedTo ?? this.repliedTo,
      reactionCount: reactionCount ?? this.reactionCount,
      topReactions: topReactions ?? this.topReactions,
      hasReacted: hasReacted ?? this.hasReacted,
      reactionType: reactionType ?? this.reactionType,
      replies: replies ?? this.replies,
      showReplies: showReplies ?? this.showReplies,
      isLoading: isLoading ?? this.isLoading,
      hasMoreReplies: hasMoreReplies ?? this.hasMoreReplies,
      currentPage: currentPage ?? this.currentPage,
      repliesCount: repliesCount ?? this.repliesCount,
    );
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      // Debug the incoming JSON
      debugPrint('Creating Comment from JSON: $json');

      // Handle integer as string case for IDs
      int parseIdSafely(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      return Comment(
        id: parseIdSafely(json['id']),
        content: json['content'] ?? '',
        createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
        updatedAt: json['updated_at'],
        contentId: parseIdSafely(json['content_id']),
        contentType: json['content_type'] ?? 'user_content',
        userId: parseIdSafely(json['user_id']),
        user: json['user'] != null
            ? UserComment.fromJson(json['user'])
            : UserComment(
                id: parseIdSafely(json['user_id']),
                username: 'Unknown User',
              ),
        parentId:
            json['parent_id'] != null ? parseIdSafely(json['parent_id']) : null,
        repliedTo: json['replied_to'] != null
            ? UserComment.fromJson(json['replied_to'])
            : null,
        reactionCount: json['reaction_count'] ?? 0,
        topReactions: json['top_comment_reactions'] != null
            ? List<String>.from(json['top_comment_reactions'])
            : (json['top_reactions'] != null
                ? List<String>.from(json['top_reactions'])
                : []),
        hasReacted: json['has_reacted_to_comment'] ?? false,
        reactionType: json['comment_reaction_type'],
        repliesCount: json['replies_count'],
      );
    } catch (e) {
      debugPrint('Error parsing Comment JSON: $e');
      debugPrint('JSON was: $json');
      rethrow;
    }
  }
}

class UserComment {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;

  UserComment({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
  });

  factory UserComment.fromJson(Map<String, dynamic> json) {
    try {
      // Handle integer or string IDs
      int parseIdSafely(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      return UserComment(
        id: parseIdSafely(json['id']),
        username: json['username'] ?? 'User',
        firstName: json['first_name'],
        lastName: json['last_name'],
        profilePictureUrl: json['profile_picture_url'],
      );
    } catch (e) {
      debugPrint('Error parsing UserComment JSON: $e');
      debugPrint('JSON was: $json');
      return UserComment(
        id: 0,
        username: 'Unknown User',
      );
    }
  }
}
