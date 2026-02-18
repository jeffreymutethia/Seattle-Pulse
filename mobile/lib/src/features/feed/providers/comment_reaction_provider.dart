import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/reaction_popup.dart';
import 'package:seattle_pulse_mobile/src/features/feed/repositories/comment_reaction_repository.dart';

// Provider for the comment reaction repository
final commentReactionRepositoryProvider =
    Provider<CommentReactionRepository>((ref) {
  return CommentReactionRepository();
});

// Provider to track user's reactions to different comments
final commentReactionsProvider =
    StateNotifierProvider<CommentReactionsNotifier, Map<int, String>>(
  (ref) =>
      CommentReactionsNotifier(ref.watch(commentReactionRepositoryProvider)),
);

class CommentReactionsNotifier extends StateNotifier<Map<int, String>> {
  final CommentReactionRepository _repository;

  CommentReactionsNotifier(this._repository) : super({});

  // Initialize reactions from comment list
  void initializeFromCommentList(List<dynamic> comments) {
    final Map<int, String> initialReactions = {};

    for (final comment in comments) {
      if (comment.hasReacted && comment.reactionType != null) {
        initialReactions[comment.id] = comment.reactionType;
        debugPrint(
            "Initialized reaction for comment ${comment.id}: ${comment.reactionType}");
      }

      // Also check for replies
      if (comment.replies != null && comment.replies.isNotEmpty) {
        for (final reply in comment.replies) {
          if (reply.hasReacted && reply.reactionType != null) {
            initialReactions[reply.id] = reply.reactionType;
            debugPrint(
                "Initialized reaction for reply ${reply.id}: ${reply.reactionType}");
          }
        }
      }
    }

    if (initialReactions.isNotEmpty) {
      state = {...state, ...initialReactions};
      debugPrint(
          "Initialized with ${initialReactions.length} comment reactions");
    }
  }

  Future<void> reactToComment(int commentId, Reaction reaction) async {
    try {
      final reactionType = _repository.mapReactionToApiType(reaction);

      // Get current state for this comment
      final previousReaction = state[commentId];
      final isRemovingReaction = previousReaction == reaction.name;

      // Optimistically update UI
      if (isRemovingReaction) {
        // User is removing the reaction (toggling off)
        state = {...state}..remove(commentId);
        debugPrint(
            "COMMENT_REACTION_PROVIDER: Removing reaction for comment $commentId");
      } else {
        // User is adding or changing reaction
        final newState = Map<int, String>.from(state);
        newState[commentId] = reaction.name;
        state = newState;
        debugPrint(
            "COMMENT_REACTION_PROVIDER: Setting reaction for comment $commentId to ${reaction.name}");
      }

      // Make API call
      final response = await _repository.reactToComment(
        commentId: commentId,
        reactionType: reactionType,
      );

      // Check if the response contains a success message for reaction removal
      final isRemovalSuccessMessage = response['message'] != null &&
          response['message'].toString().toLowerCase().contains('removed');

      // Check if the response indicates success
      final isSuccessStatus =
          response['status'] == 'success' || response['success'] == 'success';

      // If we're removing a reaction
      if (isRemovingReaction) {
        // If the server confirms removal via message (even if it inconsistently returns a user_reaction)
        if (isRemovalSuccessMessage || isSuccessStatus) {
          // Consider this a successful removal regardless of other fields
          // Keep state with reaction removed (already done in optimistic update)
          debugPrint(
              "COMMENT_REACTION_PROVIDER: Server confirmed reaction removal for comment $commentId");
        }
        // Check response data only if no success message found
        else if (response['data'] != null) {
          if (response['data']['user_reaction'] == null) {
            // Reaction was successfully removed, already updated state
            debugPrint(
                "COMMENT_REACTION_PROVIDER: Server confirmed reaction removed for comment $commentId");
          } else {
            // No removal success message, and server sent back a reaction, so it wasn't actually removed
            final userReaction = response['data']['user_reaction'];
            final mappedReaction = _mapApiReactionTypeToReaction(userReaction);
            final newState = Map<int, String>.from(state);
            newState[commentId] = mappedReaction;
            state = newState;
            debugPrint(
                "COMMENT_REACTION_PROVIDER: Server returned reaction $mappedReaction for comment $commentId (removal failed)");
          }
        }
      } else {
        // Handle adding/changing reaction response
        if (response['data'] != null &&
            response['data']['user_reaction'] != null) {
          final userReaction = response['data']['user_reaction'];
          // Map API reaction type back to our model
          final mappedReaction = _mapApiReactionTypeToReaction(userReaction);
          final newState = Map<int, String>.from(state);
          newState[commentId] = mappedReaction;
          state = newState;
          debugPrint(
              "COMMENT_REACTION_PROVIDER: Server confirmed reaction $mappedReaction for comment $commentId");
        }
      }
    } catch (e) {
      // Don't throw error if it contains "successfully" since that's actually a success
      if (e.toString().contains('successfully') ||
          e.toString().contains('removed')) {
        debugPrint(
            "COMMENT_REACTION_PROVIDER: Received successful response with unexpected format for comment $commentId: $e");
        return; // Return normally, don't propagate "error"
      }

      debugPrint(
          "COMMENT_REACTION_PROVIDER: Error reacting to comment $commentId: $e");
      // Revert to previous state on error
      if (state.containsKey(commentId)) {
        state = {...state};
      }
      rethrow;
    }
  }

  // Convert API reaction type to our model's reaction name
  String _mapApiReactionTypeToReaction(String apiReactionType) {
    switch (apiReactionType.toUpperCase()) {
      case 'LIKE':
        return 'like';
      case 'HEART':
        return 'love';
      case 'HAHA':
        return 'haha';
      case 'WOW':
        return 'wow';
      case 'SAD':
        return 'sad';
      case 'ANGRY':
        return 'angry';
      default:
        return 'like';
    }
  }
}
