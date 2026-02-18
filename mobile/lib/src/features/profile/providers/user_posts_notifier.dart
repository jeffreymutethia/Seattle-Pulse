// user_posts_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/user_posts_model.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/service/profile_service.dart';


class UserPostsState {
  final bool isLoading;
  final String? error;
  final UserPostsData? postsData;

  UserPostsState({this.isLoading = false, this.error, this.postsData});

  UserPostsState copyWith({
    bool? isLoading,
    String? error,
    UserPostsData? postsData,
  }) {
    return UserPostsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      postsData: postsData ?? this.postsData,
    );
  }
}

class UserPostsNotifier extends StateNotifier<UserPostsState> {
  final UserPostsService service;
  final String username;

  UserPostsNotifier(this.service, {required this.username}) : super(UserPostsState());

  Future<void> fetchUserPosts({int page = 1, int perPage = 10}) async {
    state = state.copyWith(isLoading: true, error: null, postsData: null);
    try {
      final response = await service.fetchUserPosts(username, page: page, perPage: perPage);
      state = state.copyWith(isLoading: false, postsData: response.data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
