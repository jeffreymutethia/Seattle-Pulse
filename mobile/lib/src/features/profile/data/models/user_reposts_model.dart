// user_reposts_model.dart

import 'package:seattle_pulse_mobile/src/features/profile/data/models/user_posts_model.dart';

class UserRepostsResponse {
  final String success;
  final String message;
  final UserRepostsData data;

  UserRepostsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserRepostsResponse.fromJson(Map<String, dynamic> json) {
    return UserRepostsResponse(
      success: json['success'] ?? '',
      message: json['message'] ?? '',
      data: UserRepostsData.fromJson(json['data']),
    );
  }
}

class UserRepostsData {
  final List<Repost> reposts;
  final Pagination pagination;

  UserRepostsData({
    required this.reposts,
    required this.pagination,
  });

  factory UserRepostsData.fromJson(Map<String, dynamic> json) {
    return UserRepostsData(
      reposts:
          (json['reposts'] as List).map((e) => Repost.fromJson(e)).toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class Repost {
  final int id;
  final String title;
  final String body;
  final String createdAt;
  final String location;
  final String thumbnail; // Expect image URL here

  Repost({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.location,
    required this.thumbnail,
  });

  factory Repost.fromJson(Map<String, dynamic> json) {
    return Repost(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: json['created_at'] ?? '',
      location: json['location'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }
}
