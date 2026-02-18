import 'package:seattle_pulse_mobile/src/features/profile/data/models/user_reposts_model.dart';

class UserRepostsState {
  final bool isLoading;
  final String? error;
  final UserRepostsData? repostsData;

  UserRepostsState({
    this.isLoading = false,
    this.error,
    this.repostsData,
  });

  UserRepostsState copyWith({
    bool? isLoading,
    String? error,
    UserRepostsData? repostsData,
  }) {
    return UserRepostsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      repostsData: repostsData ?? this.repostsData,
    );
  }
}
