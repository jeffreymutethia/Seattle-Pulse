import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_endpoints.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/service/user_secure_storage.dart';
import '../models/user_model.dart';
import '../models/register_response_model.dart';
import '../models/verify_account_response_model.dart';

class AuthService {
  final ApiClient api;

  AuthService(this.api);

  Future<RegisterResponseModel> registerUser({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) async {
    final response =
        await api.post('${ApiEndpoints.register}?isMobile=true', data: {
      "first_name": firstName,
      "last_name": lastName,
      "username": username,
      "email": email,
      "password": password,
      "accepted_terms_and_conditions": acceptedTerms,
    });
    return RegisterResponseModel.fromJson(response.data);
  }

  // POST /auth/login
  Future<UserModel> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await api.post(ApiEndpoints.login, data: {
      "email": email,
      "password": password,
    });

    final data = response.data["data"] ?? {};
    final user = UserModel.fromJson(data);

    await SecureStorageService.saveUser(user);

    return user;
  }

  Future<void> logoutUser() async {
    await api.post('/auth/logout');

    await SecureStorageService.clearUser();
  }

  Future<void> verifyOtp(int userId, String otp) async {
    await api.post('/auth/verify_otp', data: {
      "user_id": userId,
      "otp": otp,
    });
  }

  // New method for account verification with OTP
  Future<VerifyAccountResponseModel> verifyAccount(
      int userId, String otp) async {
    final response =
        await api.post('${ApiEndpoints.verifyAccount}?isMobile=true', data: {
      "user_id": userId,
      "otp": otp,
    });
    return VerifyAccountResponseModel.fromJson(response.data);
  }

  // New method for resending OTP
  Future<VerifyAccountResponseModel> resendOtp(int userId) async {
    final response = await api.post(ApiEndpoints.resendOtp, data: {
      "user_id": userId,
    });
    return VerifyAccountResponseModel.fromJson(response.data);
  }

  Future<void> requestPasswordReset(String email) async {
    await api.post(
      '/auth/reset_password_request',
      queryParams: {"isMobile": true},
      data: {"email": email},
    );
  }

  Future<String> verifyResetPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final response = await api.post('/auth/verify_reset_password_otp', data: {
      "email": email,
      "otp": otp,
    });
    if (response.data["status"] == "success") {
      return response.data["token"];
    } else {
      throw Exception(response.data["message"] ?? "OTP verification failed");
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    await api.post(
      '/auth/reset_password',
      queryParams: {"token": token},
      data: {
        "password": password,
        "confirm_password": confirmPassword,
      },
    );
  }

  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await api.post('/auth/change_password', data: {
      "user_id": userId,
      "old_password": oldPassword,
      "new_password": newPassword,
      "confirm_new_password": confirmNewPassword,
    });
  }

  // Updated method name and parameter to match the API documentation.
  Future<void> resendVerificationEmail(String email) async {
    await api.post('/auth/resend-email-verification', data: {"email": email});
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await api.get('/auth/is_authenticated');

    if (response.data["status"] == "success" &&
        response.data["data"]?["authenticated"] == true) {
      return response.data; // Returning raw JSON instead of a UserModel
    } else {
      throw Exception("Not authenticated or error fetching user.");
    }
  }
}
