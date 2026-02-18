import 'package:seattle_pulse_mobile/src/features/profile/data/models/follower_model.dart';

// State for followers
class FollowersState {
  final bool isLoading;
  final String? error;
  final List<FollowerUser>? followers;
  final int total;
  final String? searchQuery;

  FollowersState({
    this.isLoading = false,
    this.error,
    this.followers,
    this.total = 0,
    this.searchQuery,
  });

  FollowersState copyWith({
    bool? isLoading,
    String? error,
    List<FollowerUser>? followers,
    int? total,
    String? searchQuery,
  }) {
    return FollowersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      followers: followers ?? this.followers,
      total: total ?? this.total,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// State for following
class FollowingState {
  final bool isLoading;
  final String? error;
  final List<FollowerUser>? following;
  final int total;
  final String? searchQuery;

  FollowingState({
    this.isLoading = false,
    this.error,
    this.following,
    this.total = 0,
    this.searchQuery,
  });

  FollowingState copyWith({
    bool? isLoading,
    String? error,
    List<FollowerUser>? following,
    int? total,
    String? searchQuery,
  }) {
    return FollowingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      following: following ?? this.following,
      total: total ?? this.total,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// Combined state for follow actions (loading, error)
class FollowActionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final int? userId;

  FollowActionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.userId,
  });

  FollowActionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    int? userId,
  }) {
    return FollowActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      userId: userId ?? this.userId,
    );
  }
}
