// lib/features/auth/data/models/register_response_model.dart

class RegisterResponseModel {
  final String status;
  final String message;
  final UserData? user;

  RegisterResponseModel({
    required this.status,
    required this.message,
    this.user,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json["data"];
    return RegisterResponseModel(
      status: json["status"] ?? "",
      message: json["message"] ?? "",
      user: data != null ? UserData.fromJson(data) : null,
    );
  }
}

class UserData {
  final String email;
  final int userId;
  final String username;

  UserData({
    required this.email,
    required this.userId,
    required this.username,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      email: json["email"] ?? "",
      userId: json["user_id"] ?? 0,
      username: json["username"] ?? "",
    );
  }
}
