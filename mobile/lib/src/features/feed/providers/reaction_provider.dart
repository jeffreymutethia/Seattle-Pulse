import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/reaction_popup.dart';
import 'package:seattle_pulse_mobile/src/features/feed/repositories/reaction_repository.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/models/content_model.dart';

// Provider for the reaction repository
final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  return ReactionRepository();
});

// Provider to track user's reactions to different content items
final userReactionsProvider =
    StateNotifierProvider<UserReactionsNotifier, Map<int, String>>(
  (ref) => UserReactionsNotifier(ref.watch(reactionRepositoryProvider)),
);

class UserReactionsNotifier extends StateNotifier<Map<int, String>> {
  final ReactionRepository _repository;

  UserReactionsNotifier(this._repository) : super({});

  // Initialize reactions from feed content
  void initializeFromContentList(List<Content> contents) {
    final Map<int, String> initialReactions = {};

    for (final content in contents) {
      if (content.userHasReacted && content.userReactionType != null) {
        // Convert API reaction type to our format
        final reactionName =
            _mapApiReactionTypeToReaction(content.userReactionType!);
        initialReactions[content.id] = reactionName;
        debugPrint(
            "Initialized reaction for content ${content.id}: $reactionName (from ${content.userReactionType})");
      }
    }

    if (initialReactions.isNotEmpty) {
      state = {...state, ...initialReactions};
      debugPrint("Initialized with ${initialReactions.length} reactions");
    }
  }

  Future<void> reactToContent(int contentId, Reaction reaction) async {
    try {
      final reactionType = _repository.mapReactionToApiType(reaction);

      // Get current state for this content
      final previousReaction = state[contentId];
      final isRemovingReaction = previousReaction == reaction.name;

      // Optimistically update UI
      if (isRemovingReaction) {
        // User is removing the reaction (toggling off)
        state = {...state}..remove(contentId);
        debugPrint(
            "REACTION_PROVIDER: Removing reaction for content $contentId");
      } else {
        // User is adding or changing reaction
        final newState = Map<int, String>.from(state);
        newState[contentId] = reaction.name;
        state = newState;
        debugPrint(
            "REACTION_PROVIDER: Setting reaction for content $contentId to ${reaction.name}");
      }

      // Make API call
      final response = await _repository.reactToContent(
        contentId: contentId,
        reactionType: reactionType,
      );

      // Check if the response contains a success message for reaction removal
      final isRemovalSuccessMessage = response['message'] != null &&
          response['message'].toString().toLowerCase().contains('removed');

      // If we're removing a reaction
      if (isRemovingReaction) {
        // If the server confirms removal via message (even if it inconsistently returns a user_reaction)
        if (isRemovalSuccessMessage) {
          // Consider this a successful removal regardless of other fields
          // Keep state with reaction removed (already done in optimistic update)
          debugPrint(
              "REACTION_PROVIDER: Server confirmed reaction removal for content $contentId via success message");
        }
        // Check response data only if no success message found
        else if (response['data'] != null) {
          if (response['data']['user_reaction'] == null) {
            // Reaction was successfully removed, already updated state
            debugPrint(
                "REACTION_PROVIDER: Server confirmed reaction removed for content $contentId");
          } else {
            // No removal success message, and server sent back a reaction, so it wasn't actually removed
            final userReaction = response['data']['user_reaction'];
            final mappedReaction = _mapApiReactionTypeToReaction(userReaction);
            final newState = Map<int, String>.from(state);
            newState[contentId] = mappedReaction;
            state = newState;
            debugPrint(
                "REACTION_PROVIDER: Server returned reaction $mappedReaction for content $contentId (removal failed)");
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
          newState[contentId] = mappedReaction;
          state = newState;
          debugPrint(
              "REACTION_PROVIDER: Server confirmed reaction $mappedReaction for content $contentId");
        }
      }
    } catch (e) {
      debugPrint("REACTION_PROVIDER: Error reacting to content $contentId: $e");
      // Revert to previous state on error
      if (state.containsKey(contentId)) {
        state = {...state};
      }
      rethrow;
    }
  }

  Future<void> reactToComment(
      int contentId, int commentId, Reaction reaction) async {
    try {
      final reactionType = _repository.mapReactionToApiType(reaction);

      // Comment reactions use a different key format to differentiate from content reactions
      final key = _getCommentKey(contentId, commentId);

      // Get current state for this comment
      final previousReaction = state[key];
      final isRemovingReaction = previousReaction == reaction.name;

      // Optimistically update UI
      if (isRemovingReaction) {
        // User is removing the reaction (toggling off)
        state = {...state}..remove(key);
        debugPrint(
            "REACTION_PROVIDER: Removing reaction for comment $commentId on content $contentId");
      } else {
        // User is adding or changing reaction
        final newState = Map<int, String>.from(state);
        newState[key] = reaction.name;
        state = newState;
        debugPrint(
            "REACTION_PROVIDER: Setting reaction for comment $commentId to ${reaction.name}");
      }

      // Make API call
      final response = await _repository.reactToComment(
        contentId: contentId,
        commentId: commentId,
        reactionType: reactionType,
      );

      // Check if the response contains a success message for reaction removal
      final isRemovalSuccessMessage = response['message'] != null &&
          response['message'].toString().toLowerCase().contains('removed');

      // If we're removing a reaction
      if (isRemovingReaction) {
        // If the server confirms removal via message (even if it inconsistently returns a user_reaction)
        if (isRemovalSuccessMessage) {
          // Consider this a successful removal regardless of other fields
          // Keep state with reaction removed (already done in optimistic update)
          debugPrint(
              "REACTION_PROVIDER: Server confirmed reaction removal for comment $commentId via success message");
        }
        // Check response data only if no success message found
        else if (response['data'] != null) {
          if (response['data']['user_reaction'] == null) {
            // Reaction was successfully removed, already updated state
            debugPrint(
                "REACTION_PROVIDER: Server confirmed reaction removed for comment $commentId");
          } else {
            // No removal success message, and server sent back a reaction, so it wasn't actually removed
            final userReaction = response['data']['user_reaction'];
            final mappedReaction = _mapApiReactionTypeToReaction(userReaction);
            final newState = Map<int, String>.from(state);
            newState[key] = mappedReaction;
            state = newState;
            debugPrint(
                "REACTION_PROVIDER: Server returned reaction $mappedReaction for comment $commentId (removal failed)");
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
          newState[key] = mappedReaction;
          state = newState;
          debugPrint(
              "REACTION_PROVIDER: Server confirmed reaction $mappedReaction for comment $commentId");
        }
      }
    } catch (e) {
      debugPrint("REACTION_PROVIDER: Error reacting to comment $commentId: $e");
      // Revert to previous state on error
      rethrow;
    }
  }

  // Helper to get a unique key for comment reactions
  int _getCommentKey(int contentId, int commentId) {
    // Use a combination of content and comment IDs for uniqueness
    // This is a simple hash function that should work for most cases
    return contentId * 10000 + commentId;
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
