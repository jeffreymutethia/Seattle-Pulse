// follower_model.dart

class FollowersResponse {
  final String status;
  final int total;
  final List<FollowerUser> users;

  FollowersResponse({
    required this.status,
    required this.total,
    required this.users,
  });

  factory FollowersResponse.fromJson(Map<String, dynamic> json) {
    return FollowersResponse(
      status: json['status'] ?? 'error',
      total: json['total'] ?? 0,
      users: (json['users'] as List<dynamic>?)
              ?.map((user) => FollowerUser.fromJson(user))
              .toList() ??
          [],
    );
  }
}

class FollowerUser {
  final int id;
  final String username;
  final String? profilePictureUrl;
  final String? bio;
  final String? firstName;
  final String? lastName;
  bool isFollowing;

  FollowerUser({
    required this.id,
    required this.username,
    this.profilePictureUrl,
    this.bio,
    this.firstName,
    this.lastName,
    this.isFollowing = false,
  });

  factory FollowerUser.fromJson(Map<String, dynamic> json) {
    return FollowerUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
      bio: json['bio'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      isFollowing: json['is_following'] ?? false,
    );
  }

  // Get full name if available, otherwise use username
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else {
      return username;
    }
  }
}
