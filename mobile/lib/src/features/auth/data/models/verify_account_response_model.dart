class VerifyAccountResponseModel {
  final String status;
  final String message;

  VerifyAccountResponseModel({
    required this.status,
    required this.message,
  });

  factory VerifyAccountResponseModel.fromJson(Map<String, dynamic> json) {
    return VerifyAccountResponseModel(
      status: json["status"] ?? "",
      message: json["message"] ?? "",
    );
  }
}
