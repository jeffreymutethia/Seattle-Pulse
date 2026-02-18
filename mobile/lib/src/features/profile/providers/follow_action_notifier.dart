import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/core/providers/api_providers.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/service/follow_service.dart';
import 'package:seattle_pulse_mobile/src/features/profile/providers/follow_state.dart';
import 'package:seattle_pulse_mobile/src/features/profile/providers/followers_notifier.dart';
import 'package:seattle_pulse_mobile/src/features/profile/providers/following_notifier.dart';

class FollowActionNotifier extends StateNotifier<FollowActionState> {
  final FollowService _followService;
  final StateNotifierProviderRef _ref;

  FollowActionNotifier(this._followService, this._ref)
      : super(FollowActionState());

  // Follow a user
  Future<bool> followUser(int userId) async {
    // Reset any previous errors
    state = state.copyWith(
      isLoading: true,
      error: null,
      isSuccess: false,
      userId: userId,
    );

    try {
      final response = await _followService.followUser(userId);

      if (response['status'] == 'success') {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          error: null,
        );

        // Update followers and following lists
        _updateFollowLists(userId, true);

        return true;
      } else {
        final errorMessage = response['message'] ?? 'Failed to follow user';
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
          isSuccess: false,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error following user: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to follow user. Please try again.',
        isSuccess: false,
      );
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(int userId) async {
    // Reset any previous errors
    state = state.copyWith(
      isLoading: true,
      error: null,
      isSuccess: false,
      userId: userId,
    );

    try {
      final response = await _followService.unfollowUser(userId);

      if (response['status'] == 'success') {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          error: null,
        );

        // Update followers and following lists
        _updateFollowLists(userId, false);

        return true;
      } else {
        final errorMessage = response['message'] ?? 'Failed to unfollow user';
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
          isSuccess: false,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to unfollow user. Please try again.',
        isSuccess: false,
      );
      return false;
    }
  }

  // Update both followers and following lists after follow/unfollow
  void _updateFollowLists(int userId, bool isFollowing) {
    try {
      // Update followers list if available
      try {
        final followersNotifier = _ref.read(followersProvider.notifier);
        followersNotifier.updateFollowerState(userId, isFollowing);
      } catch (e) {
        debugPrint('Error updating followers list: $e');
      }

      // Update following list if available
      try {
        final followingNotifier = _ref.read(followingProvider.notifier);
        if (!isFollowing) {
          // If unfollowing, remove from the list
          followingNotifier.updateFollowingState(userId, false);
        }
      } catch (e) {
        debugPrint('Error updating following list: $e');
      }
    } catch (e) {
      debugPrint('Error updating follow lists: $e');
    }
  }
}

// Define providers
final followServiceProvider = Provider<FollowService>((ref) {
  // Access the ApiClient from your dependency injection setup
  final apiClient = ref.watch(apiClientProvider);
  return FollowService(apiClient);
});

final followersProvider =
    StateNotifierProvider<FollowersNotifier, FollowersState>((ref) {
  final followService = ref.watch(followServiceProvider);
  return FollowersNotifier(followService);
});

final followingProvider =
    StateNotifierProvider<FollowingNotifier, FollowingState>((ref) {
  final followService = ref.watch(followServiceProvider);
  return FollowingNotifier(followService);
});

final followActionProvider =
    StateNotifierProvider<FollowActionNotifier, FollowActionState>((ref) {
  final followService = ref.watch(followServiceProvider);
  return FollowActionNotifier(followService, ref);
});
