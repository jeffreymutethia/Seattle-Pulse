// user_profile_model.dart

class UserProfileResponse {
  final String success;
  final String message;
  final UserProfileData data;

  UserProfileResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'] ?? '',
      message: json['message'] ?? '',
      data: UserProfileData.fromJson(json['data']),
    );
  }
}

class UserProfileData {
  final bool isFollowing;
  final Relationships relationships;
  final UserData userData;

  UserProfileData({
    required this.isFollowing,
    required this.relationships,
    required this.userData,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      isFollowing: json['is_following'] ?? false,
      relationships: Relationships.fromJson(json['relationships'] ?? {}),
      userData: UserData.fromJson(json['user_data'] ?? {}),
    );
  }
}

class Relationships {
  final int followers;
  final int following;
  final int totalPosts;

  Relationships({
    required this.followers,
    required this.following,
    required this.totalPosts,
  });

  factory Relationships.fromJson(Map<String, dynamic> json) {
    return Relationships(
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      totalPosts: json['total_posts'] ?? 0,
    );
  }
}

class UserData {
  final int id;
  final String username;
  final String email;
  final String profilePictureUrl;
  final String firstName;
  final String lastName;
  final String bio;
  final String? location;

  UserData({
    required this.id,
    required this.username,
    required this.email,
    required this.profilePictureUrl,
    required this.firstName,
    required this.lastName,
    required this.bio,
    this.location,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profilePictureUrl: json['profile_picture_url'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      bio: json['bio'] ?? '',
      location: json['location'],
    );
  }
}
