import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/follower_model.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/service/follow_service.dart';
import 'package:seattle_pulse_mobile/src/features/profile/providers/follow_state.dart';

class FollowersNotifier extends StateNotifier<FollowersState> {
  final FollowService _followService;

  FollowersNotifier(this._followService) : super(FollowersState());

  // Fetch followers list
  Future<void> fetchFollowers({String? searchQuery}) async {
    // Reset any previous errors
    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: searchQuery,
    );

    try {
      final response = await _followService.getFollowers(query: searchQuery);

      state = state.copyWith(
        isLoading: false,
        followers: response.users,
        total: response.total,
        error: null,
      );
    } catch (e) {
      debugPrint('Error fetching followers: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load followers. Please try again.',
      );
    }
  }

  // Update follower state after follow/unfollow action
  void updateFollowerState(int userId, bool isFollowing) {
    final currentFollowers = state.followers;
    if (currentFollowers == null) return;

    final updatedFollowers = currentFollowers.map((user) {
      if (user.id == userId) {
        return FollowerUser(
          id: user.id,
          username: user.username,
          profilePictureUrl: user.profilePictureUrl,
          bio: user.bio,
          firstName: user.firstName,
          lastName: user.lastName,
          isFollowing: isFollowing,
        );
      }
      return user;
    }).toList();

    state = state.copyWith(followers: updatedFollowers);
  }
}
