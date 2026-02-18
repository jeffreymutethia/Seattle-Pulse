import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import '../data/service/auth_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState());

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Register user
  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.registerUser(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
        acceptedTerms: acceptedTerms,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      String errorMsg = e is DioError
          ? e.response?.data['message'] ?? e.toString()
          : e.toString();
      print("Register Error: $errorMsg");
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  // Login
  Future<void> loginUser(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    print("🔄 Logging in... (Loading State: ${state.isLoading})");

    try {
      final user =
          await _authService.loginUser(email: email, password: password);

      state = state.copyWith(isLoading: false, isLoggedIn: true, user: user);
      print("✅ Login Successful! isLoggedIn: ${state.isLoggedIn}");
    } catch (e) {
      String errorMsg = e is DioError
          ? e.response?.data['message'] ?? e.toString()
          : e.toString();

      print("❌ Login Error: $errorMsg");

      state =
          state.copyWith(isLoading: false, error: errorMsg, isLoggedIn: false);
    }
  }

  Future<String?> verifyResetPasswordOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token =
          await _authService.verifyResetPasswordOtp(email: email, otp: otp);
      state = state.copyWith(isLoading: false);
      return token;
    } catch (e) {
      String errorMsg = e is DioError
          ? e.response?.data['message'] ?? e.toString()
          : e.toString();
      print("Verify Reset OTP Error: $errorMsg");
      state = state.copyWith(isLoading: false, error: errorMsg);
      return null;
    }
  }

  // Logout
  Future<void> logoutUser() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.logoutUser();
      state = AuthState();
    } catch (e) {
      String errorMsg = e is DioError
          ? e.response?.data['message'] ?? e.toString()
          : e.toString();
      print("Logout Error: $errorMsg");
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  // Verify OTP
  Future<void> verifyOtp(int userId, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.verifyOtp(userId, otp);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      String errorMsg = e is DioError
          ? e.response?.data['message'] ?? e.toString()
          : e.toString();
      print("Verify OTP Error: $errorMsg");
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  // Verify Account with OTP
  Future<bool> verifyAccountWithOtp(
      {required int userId, required String otp}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.verifyAccount(userId, otp);
      state = state.copyWith(isLoading: false);

      if (response.status == "success") {
        return true;
      } else {
        state = state.copyWith(error: response.message);
        return false;
      }
    } catch (e) {
      String errorMsg = e is DioError
          ? e.response?.data['message'] ?? e.toString()
          : e.toString();
      print("Verify Account OTP Error: $errorMsg");
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  // Resend OTP
  Future<bool> resendOtp(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.resendOtp(userId);
      state = state.copyWith(isLoading: false);

      if (response.status == "success") {
        return true;
      } else {
        state = state.copyWith(error: response.message);
        return false;
      }
    } catch (e) {
      String errorMsg = e is DioError
          ? e.response?.data['message'] ?? e.toString()
          : e.toString();
      print("Resend OTP Error: $errorMsg");
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<void> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.requestPasswordReset(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      String errorMsg = e is DioError
          ? e.response?.data['message'] ?? e.toString()
          : e.toString();
      print("Reset Request Error: $errorMsg");
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  // Reset Password
  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.resetPassword(
        token: token,
        password: password,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      String errorMsg = e is DioError
          ? e.response?.data['message'] ?? e.toString()
          : e.toString();
      print("Reset Password Error: $errorMsg");
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  // Change Password
  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.changePassword(
        userId: userId,
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      String errorMsg = e is DioError
          ? e.response?.data['message'] ?? e.toString()
          : e.toString();
      print("Change Password Error: $errorMsg");
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.resendVerificationEmail(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      String errorMsg = e is DioError
          ? e.response?.data['message'] ?? e.toString()
          : e.toString();
      print("Resend Verification Email Error: $errorMsg");
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  // Check Current User
  Future<void> fetchCurrentUser() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.getCurrentUser();

      if (response["status"] == "success") {
        final userData = response["data"];

        // Update state with user details
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: userData["authenticated"] == true,
        );

        print("✅ User Fetched Successfully: ${userData["username"]}");
      } else {
        throw Exception("Failed to fetch user.");
      }
    } catch (e) {
      print("❌ Fetch Current User Error: ${e.toString()}");

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        error: "Failed to fetch user",
      );
    }
  }
}
