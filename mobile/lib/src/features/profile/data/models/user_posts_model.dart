// user_posts_model.dart
// pagination_model.dart
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

// user_posts_model.dart

class UserPostsResponse {
  final String success;
  final String message;
  final UserPostsData data;

  UserPostsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserPostsResponse.fromJson(Map<String, dynamic> json) {
    return UserPostsResponse(
      success: json['success'] ?? '',
      message: json['message'] ?? '',
      data: UserPostsData.fromJson(json['data']),
    );
  }
}

class UserPostsData {
  final List<UserPost> posts;
  final Pagination pagination;

  UserPostsData({
    required this.posts,
    required this.pagination,
  });

  factory UserPostsData.fromJson(Map<String, dynamic> json) {
    return UserPostsData(
      posts: (json['posts'] as List).map((e) => UserPost.fromJson(e)).toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class UserPost {
  final Post post;
  final int totalComments;
  final int totalLikes;

  UserPost({
    required this.post,
    required this.totalComments,
    required this.totalLikes,
  });

  factory UserPost.fromJson(Map<String, dynamic> json) {
    return UserPost(
      post: Post.fromJson(json['post']),
      totalComments: json['total_comments'] ?? 0,
      totalLikes: json['total_likes'] ?? 0,
    );
  }
}

class Post {
  final int id;
  final String title;
  final String body;
  final String createdAt;
  final String location;
  final String thumbnail; // Expect the API to return an image URL

  Post({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.location,
    required this.thumbnail,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: json['created_at'] ?? '',
      location: json['location'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }
}
