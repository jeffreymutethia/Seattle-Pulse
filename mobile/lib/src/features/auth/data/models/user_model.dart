import 'dart:convert';

class UserModel {
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String loginType;
  final String profilePictureUrl;
  final String? bio;
  final String? location;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.loginType,
    required this.profilePictureUrl,
    this.bio,
    this.location,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json["user_id"] ?? json['id'],
      username: json["username"],
      email: json["email"],
      firstName: json["first_name"],
      lastName: json["last_name"],
      loginType: json["login_type"] ?? '',
      bio: json["bio"],
      location: json["home_location"] ?? json['location'],
      profilePictureUrl: json["profile_picture_url"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "user_id": userId,
      "username": username,
      "email": email,
      "first_name": firstName,
      "last_name": lastName,
      "login_type": loginType,
      "bio": bio,
      "location": location,
      "profile_picture_url": profilePictureUrl,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJsonString(String source) =>
      UserModel.fromJson(jsonDecode(source));
}
