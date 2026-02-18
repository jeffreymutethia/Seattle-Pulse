/// user_model.dart
class User {
  final String name;
  final String location;
  final String avatarUrl;

  bool isFollowing;

  bool canFollowBack;

  User({
    required this.name,
    required this.location,
    required this.avatarUrl,
    this.isFollowing = false,
    this.canFollowBack = false,
  });
}
