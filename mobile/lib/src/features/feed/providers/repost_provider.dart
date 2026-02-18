import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/feed/repositories/repost_repository.dart';

// Provider for the repost repository
final repostRepositoryProvider = Provider<RepostRepository>((ref) {
  return RepostRepository();
});

// Provider to track user's reposts for different content items
final userRepostsProvider =
    StateNotifierProvider<UserRepostsNotifier, Map<int, bool>>(
  (ref) => UserRepostsNotifier(ref.watch(repostRepositoryProvider)),
);

class UserRepostsNotifier extends StateNotifier<Map<int, bool>> {
  final RepostRepository _repository;

  UserRepostsNotifier(this._repository) : super({});

  // Initialize reposts from content list
  void initializeFromContentList(List<dynamic> contents) {
    final Map<int, bool> initialReposts = {};

    for (final content in contents) {
      if (content.hasUserReposted == true) {
        initialReposts[content.id] = true;
        debugPrint("Initialized repost for content ${content.id}");
      }
    }

    if (initialReposts.isNotEmpty) {
      state = {...state, ...initialReposts};
      debugPrint("Initialized with ${initialReposts.length} reposts");
    }
  }

  // Repost content
  Future<void> repost(int contentId, String thoughts) async {
    try {
      debugPrint("REPOST: Attempting to repost content $contentId");

      // Optimistically update UI
      final newState = Map<int, bool>.from(state);
      newState[contentId] = true;
      state = newState;

      debugPrint(
          "REPOST: State updated, contentId=$contentId is now marked as reposted");

      // Make API call
      final response = await _repository.repostContent(
        contentId: contentId,
        thoughts: thoughts,
      );

      // Check server response - key change here to correctly identify success
      final isSuccessStatus =
          response['status'] == 'success' || response['success'] == 'success';
      final isSuccessMessage = response['message'] != null &&
          response['message'].toString().contains('successfully');
      final isSuccessful = isSuccessStatus || isSuccessMessage;

      if (isSuccessful) {
        debugPrint(
            "REPOST: Server confirmed successful repost for content $contentId");

        // Double-check our state is correct
        if (state[contentId] != true) {
          final newState = Map<int, bool>.from(state);
          newState[contentId] = true;
          state = newState;
          debugPrint(
              "REPOST: Fixed state after API success for content $contentId");
        }
      } else {
        // Revert state if API call failed
        final updatedState = Map<int, bool>.from(state);
        updatedState.remove(contentId);
        state = updatedState;
        debugPrint(
            "REPOST: Reverted state due to API failure for content $contentId");
        throw Exception(response['message'] ?? 'Failed to repost content');
      }
    } catch (e) {
      // Don't throw error if it contains "successfully" since that's actually a success
      if (e.toString().contains('successfully')) {
        debugPrint(
            "REPOST: Received successful response with unexpected format for content $contentId: $e");

        // Ensure state is properly set for success
        final newState = Map<int, bool>.from(state);
        newState[contentId] = true;
        state = newState;
        return; // Return normally, don't propagate "error"
      }

      // Revert state on actual error
      final updatedState = Map<int, bool>.from(state);
      updatedState.remove(contentId);
      state = updatedState;
      debugPrint(
          "REPOST: Error occurred during repost of content $contentId: $e");
      rethrow;
    }
  }

  // Undo repost
  Future<void> undoRepost(int contentId) async {
    try {
      debugPrint("REPOST: Attempting to undo repost for content $contentId");

      // Optimistically update UI - remove the repost status
      final newState = Map<int, bool>.from(state);
      newState.remove(contentId);
      state = newState;

      debugPrint(
          "REPOST: State updated, contentId=$contentId is now removed from reposts");

      // Make API call
      final response = await _repository.undoRepost(
        contentId: contentId,
      );

      // Check response - key change here to correctly identify success
      final isSuccessStatus =
          response['status'] == 'success' || response['success'] == 'success';
      final isSuccessMessage = response['message'] != null &&
          (response['message'].toString().toLowerCase().contains('removed') ||
              response['message'].toString().toLowerCase().contains('undone') ||
              response['message']
                  .toString()
                  .toLowerCase()
                  .contains('successfully'));

      final isSuccessful = isSuccessStatus || isSuccessMessage;

      if (isSuccessful) {
        // API call was successful, keep state as is (without the repost)
        debugPrint(
            "REPOST: Server confirmed successful undo repost for content $contentId");

        // Make sure our state doesn't have this content anymore
        if (state[contentId] == true) {
          final fixedState = Map<int, bool>.from(state);
          fixedState.remove(contentId);
          state = fixedState;
          debugPrint(
              "REPOST: Fixed state after API success for undo repost content $contentId");
        }
      } else {
        // API call failed, revert to previous state
        final revertState = Map<int, bool>.from(state);
        revertState[contentId] = true;
        state = revertState;
        debugPrint(
            "REPOST: Reverted state due to API failure for undo repost content $contentId");
        throw Exception(response['message'] ?? 'Failed to undo repost');
      }
    } catch (e) {
      // Don't throw error if it contains "successfully" since that's actually a success
      if (e.toString().contains('successfully') ||
          e.toString().contains('undone') ||
          e.toString().contains('removed')) {
        debugPrint(
            "REPOST: Received successful response with unexpected format for undo repost content $contentId: $e");

        // Ensure state is properly set for success (remove the repost)
        final newState = Map<int, bool>.from(state);
        newState.remove(contentId);
        state = newState;
        return; // Return normally, don't propagate "error"
      }

      // Revert state on actual error
      final revertState = Map<int, bool>.from(state);
      revertState[contentId] = true;
      state = revertState;
      debugPrint(
          "REPOST: Error occurred during undo repost of content $contentId: $e");
      rethrow;
    }
  }
}
