import '../data/models/user_model.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;
  final UserModel? user;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
    UserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
    );
  }
}
