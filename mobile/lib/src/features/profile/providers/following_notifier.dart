import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/follower_model.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/service/follow_service.dart';
import 'package:seattle_pulse_mobile/src/features/profile/providers/follow_state.dart';

class FollowingNotifier extends StateNotifier<FollowingState> {
  final FollowService _followService;

  FollowingNotifier(this._followService) : super(FollowingState());

  // Fetch following list
  Future<void> fetchFollowing({String? searchQuery}) async {
    // Reset any previous errors
    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: searchQuery,
    );

    try {
      final response = await _followService.getFollowing(query: searchQuery);

      state = state.copyWith(
        isLoading: false,
        following: response.users,
        total: response.total,
        error: null,
      );
    } catch (e) {
      debugPrint('Error fetching following list: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load following list. Please try again.',
      );
    }
  }

  // Update following state after follow/unfollow action
  void updateFollowingState(int userId, bool isFollowing) {
    final currentFollowing = state.following;
    if (currentFollowing == null) return;

    // If unfollowing, remove from the list
    if (!isFollowing) {
      final updatedFollowing =
          currentFollowing.where((user) => user.id != userId).toList();
      state = state.copyWith(
        following: updatedFollowing,
        total: state.total - 1,
      );
    } else {
      // If following, update the status
      final updatedFollowing = currentFollowing.map((user) {
        if (user.id == userId) {
          return FollowerUser(
            id: user.id,
            username: user.username,
            profilePictureUrl: user.profilePictureUrl,
            bio: user.bio,
            firstName: user.firstName,
            lastName: user.lastName,
            isFollowing: true,
          );
        }
        return user;
      }).toList();

      state = state.copyWith(following: updatedFollowing);
    }
  }
}
