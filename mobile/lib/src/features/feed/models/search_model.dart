class UserModel {
  final int id;
  final String username;
  final String name;
  final String profilePictureUrl;
  final String? location;
  final int totalFollowers;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.profilePictureUrl,
    this.location,
    required this.totalFollowers,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      name: "${json['first_name']} ${json['last_name']}",
      profilePictureUrl: json['profile_picture_url'],
      location: json['location'],
      totalFollowers: json['total_followers'],
    );
  }
}
