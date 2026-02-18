// user_reposts_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/user_reposts_model.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/service/profile_service.dart';


class UserRepostsState {
  final bool isLoading;
  final String? error;
  final UserRepostsData? repostsData;

  UserRepostsState({this.isLoading = false, this.error, this.repostsData});

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

class UserRepostsNotifier extends StateNotifier<UserRepostsState> {
  final UserRepostsService service;
  final String username;

  UserRepostsNotifier(this.service, {required this.username}) : super(UserRepostsState());

  Future<void> fetchUserReposts({int page = 1, int perPage = 10}) async {
    state = state.copyWith(isLoading: true, error: null, repostsData: null);
    try {
      final response = await service.fetchUserReposts(username, page: page, perPage: perPage);
      state = state.copyWith(isLoading: false, repostsData: response.data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
