import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/feed/models/comment_model.dart';
import 'package:seattle_pulse_mobile/src/features/feed/repositories/comment_repository.dart';

// Provider for the comment repository
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository();
});

// State class for managing comments and related UI state
class CommentState {
  final List<Comment> comments;
  final bool isLoading;
  final bool isPostingComment;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final bool isReacting;

  CommentState({
    this.comments = const [],
    this.isLoading = false,
    this.isPostingComment = false,
    this.error,
    this.hasMore = false,
    this.currentPage = 1,
    this.isReacting = false,
  });

  CommentState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    bool? isPostingComment,
    String? error,
    bool? hasMore,
    int? currentPage,
    bool? isReacting,
  }) {
    return CommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isPostingComment: isPostingComment ?? this.isPostingComment,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isReacting: isReacting ?? this.isReacting,
    );
  }
}

// Provider for managing comments for a specific content
final commentStateProvider = StateNotifierProvider.family<CommentNotifier,
    CommentState, Map<String, dynamic>>(
  (ref, contentKey) => CommentNotifier(
    ref.watch(commentRepositoryProvider),
    contentKey,
  ),
);

class CommentNotifier extends StateNotifier<CommentState> {
  final CommentRepository _repository;
  final Map<String, dynamic> _contentKey;

  CommentNotifier(this._repository, this._contentKey) : super(CommentState());

  // Fetch initial comments for this content
  Future<void> fetchInitialComments() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final contentId = int.parse(_contentKey['contentId'].toString());
      final contentType = _contentKey['contentType'] as String;

      debugPrint(
          'Fetching initial comments for contentId: $contentId, contentType: $contentType');

      final response = await _repository.getContentDetails(
        contentId: contentId,
        contentType: contentType,
        page: 1,
        perPage: 10,
      );

      if (response['success'] == 'success' && response['data'] != null) {
        final contentData = response['data'];
        final commentsData = contentData['comments'] as List<dynamic>? ?? [];

        debugPrint('Processing ${commentsData.length} initial comments');

        final comments = commentsData
            .map((commentData) {
              try {
                return Comment.fromJson(commentData);
              } catch (e) {
                debugPrint('Error parsing comment: $e');
                return null;
              }
            })
            .whereType<Comment>()
            .toList();

        final hasMore = contentData['pagination']?['has_next'] ?? false;
        final totalPages = contentData['pagination']?['total_pages'] ?? 1;

        state = state.copyWith(
          isLoading: false,
          comments: comments,
          hasMore: hasMore,
          currentPage: 1,
          error: null,
        );

        debugPrint('Initial comments loaded: ${comments.length} comments');
      } else {
        final errorMessage = response['message'] ?? 'Failed to load comments';
        debugPrint('API Error: $errorMessage');
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      debugPrint('Error fetching initial comments: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Load more comments
  Future<void> loadMoreComments() async {
    if (state.isLoading || !state.hasMore) return;

    try {
      state = state.copyWith(isLoading: true);

      final contentId = int.parse(_contentKey['contentId'].toString());
      final contentType = _contentKey['contentType'] as String;
      final nextPage = state.currentPage + 1;

      final response = await _repository.getContentDetails(
        contentId: contentId,
        contentType: contentType,
        page: nextPage,
        perPage: 10,
      );

      if (response['success'] == 'success' && response['data'] != null) {
        final contentData = response['data'];
        final commentsData = contentData['comments'] as List<dynamic>? ?? [];

        final newComments = commentsData
            .map((commentData) {
              try {
                return Comment.fromJson(commentData);
              } catch (e) {
                debugPrint('Error parsing comment: $e');
                return null;
              }
            })
            .whereType<Comment>()
            .toList();

        final hasMore = contentData['pagination']?['has_next'] ?? false;

        state = state.copyWith(
          isLoading: false,
          comments: [...state.comments, ...newComments],
          hasMore: hasMore,
          currentPage: nextPage,
          error: null,
        );
      } else {
        final errorMessage =
            response['message'] ?? 'Failed to load more comments';
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Post a new comment
  Future<void> postComment(String content) async {
    try {
      debugPrint('Posting comment: $content');
      state = state.copyWith(isPostingComment: true, error: null);

      final contentId = int.parse(_contentKey['contentId'].toString());
      final contentType = _contentKey['contentType'] as String;

      final response = await _repository.postComment(
        contentId: contentId,
        content: content,
        contentType: contentType,
      );

      debugPrint('Post comment response: $response');

      // Check for success response - adapt to your API's actual response format
      if (response['status'] == 'success') {
        // Extract data from the response
        final commentData = response['data'];
        debugPrint('Creating new comment from data: $commentData');

        try {
          final newComment = Comment.fromJson(commentData);
          debugPrint('New comment created: ${newComment.content}');

          state = state.copyWith(
            comments: [newComment, ...state.comments],
            isPostingComment: false,
          );
          debugPrint('State updated with new comment');
        } catch (parseError) {
          debugPrint('Error parsing comment data: $parseError');
          throw Exception('Error parsing server response: $parseError');
        }
      } else {
        final message = response['message'] ?? 'Unknown error posting comment';
        debugPrint('API error: $message');
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('Error in postComment: $e');
      state = state.copyWith(
        isPostingComment: false,
        error: e.toString(),
      );
      rethrow; // Rethrow to allow UI to show error
    }
  }

  // Post a reply to a comment
  Future<void> postReply({
    required int parentId,
    required String content,
    String? repliedToUsername,
  }) async {
    try {
      debugPrint('Posting reply to comment $parentId: $content');
      state = state.copyWith(isPostingComment: true, error: null);

      final contentId = int.parse(_contentKey['contentId'].toString());
      final contentType = _contentKey['contentType'] as String;

      final response = await _repository.postComment(
        contentId: contentId,
        content: content,
        contentType: contentType,
        parentId: parentId,
      );

      debugPrint('Post reply response: $response');

      // Check for success response based on API
      if (response['status'] == 'success') {
        // Extract data from the response
        final replyData = response['data'];
        debugPrint('Creating new reply from data: $replyData');

        try {
          final newReply = Comment.fromJson(replyData);
          debugPrint('New reply created: ${newReply.content}');

          // Find the parent comment in our state
          final commentIndex =
              state.comments.indexWhere((comment) => comment.id == parentId);

          if (commentIndex != -1) {
            // The parent is a top-level comment in our state
            final updatedComments = List<Comment>.from(state.comments);
            final parentComment = updatedComments[commentIndex];

            // Update the parent comment to add this reply and update reply count
            updatedComments[commentIndex] = parentComment.copyWith(
              replies: [...parentComment.replies, newReply],
              showReplies: true, // Auto-show replies when adding a new one
            );

            state = state.copyWith(
              comments: updatedComments,
              isPostingComment: false,
            );
          } else {
            // Parent might be a reply or not found at all - refresh comments to ensure we're up to date
            fetchInitialComments();
          }

          debugPrint('State updated with new reply');
        } catch (parseError) {
          debugPrint('Error parsing reply data: $parseError');
          throw Exception('Error parsing server response: $parseError');
        }
      } else {
        final message = response['message'] ?? 'Unknown error posting reply';
        debugPrint('API error: $message');
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('Error in postReply: $e');
      state = state.copyWith(
        isPostingComment: false,
        error: e.toString(),
      );
      rethrow; // Rethrow to allow UI to show error
    }
  }

  // Update an existing comment
  Future<void> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      state = state.copyWith(isPostingComment: true, error: null);

      final response = await _repository.updateComment(
        commentId: commentId,
        content: content,
      );

      if (response['status'] == 'success' && response['data'] != null) {
        final commentData = response['data']['comment'];
        final updatedComment = Comment.fromJson(commentData);

        // Find and update the comment in state
        bool commentFound = false;
        final updatedComments = state.comments.map((comment) {
          // Check if this is the comment we're looking for
          if (comment.id == commentId) {
            commentFound = true;
            return updatedComment.copyWith(
              replies: comment.replies,
              showReplies: comment.showReplies,
              hasMoreReplies: comment.hasMoreReplies,
              currentPage: comment.currentPage,
              isLoading: comment.isLoading,
            );
          }

          // Check if the comment is in replies
          final updatedReplies = comment.replies.map((reply) {
            if (reply.id == commentId) {
              commentFound = true;
              return updatedComment;
            }
            return reply;
          }).toList();

          if (updatedReplies.any((reply) => reply.id == commentId)) {
            return comment.copyWith(replies: updatedReplies);
          }

          return comment;
        }).toList();

        if (commentFound) {
          state = state.copyWith(
            comments: updatedComments,
            isPostingComment: false,
            error: null,
          );
        } else {
          // If not found in our state, refresh comments
          fetchInitialComments();
        }
      } else {
        final message = response['message'] ?? 'Failed to update comment';
        state = state.copyWith(
          isPostingComment: false,
          error: message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isPostingComment: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Toggle showing/hiding replies for a comment
  void toggleReplies(int commentId) {
    final updatedComments = state.comments.map((comment) {
      if (comment.id == commentId) {
        final shouldShowReplies = !comment.showReplies;

        // If toggling to show replies and none are loaded yet, but we know there are replies,
        // load them instead of just showing an empty state
        if (shouldShowReplies &&
            comment.replies.isEmpty &&
            (comment.repliesCount ?? 0) > 0 &&
            !comment.isLoading) {
          loadReplies(commentId);
          return comment.copyWith(
            showReplies: true,
            isLoading: true,
          );
        }

        return comment.copyWith(
          showReplies: shouldShowReplies,
        );
      }
      return comment;
    }).toList();

    state = state.copyWith(comments: updatedComments);
  }

  // Load replies for a comment
  Future<void> loadReplies(int commentId) async {
    debugPrint('Loading replies for comment: $commentId');

    // Find the comment in the state
    final commentIndex = state.comments.indexWhere((c) => c.id == commentId);
    if (commentIndex == -1) {
      debugPrint('Comment not found in state: $commentId');
      return;
    }

    final comment = state.comments[commentIndex];
    debugPrint('Found comment: ${comment.content}');

    // If replies are already loaded and we're just toggling visibility
    if (comment.replies.isNotEmpty) {
      debugPrint(
          'Comment already has ${comment.replies.length} replies, toggling visibility');
      toggleReplies(commentId);
      return;
    }

    // If we know there are no replies, just toggle to show empty state
    if ((comment.repliesCount ?? 0) == 0) {
      debugPrint('Comment has no replies, toggling visibility only');
      final updatedComments = List<Comment>.from(state.comments);
      updatedComments[commentIndex] = comment.copyWith(
        showReplies: !comment.showReplies,
      );
      state = state.copyWith(comments: updatedComments);
      return;
    }

    try {
      // Mark the comment as loading
      debugPrint('Setting comment as loading');
      var updatedComments = List<Comment>.from(state.comments);
      updatedComments[commentIndex] =
          comment.copyWith(isLoading: true, showReplies: true);
      state = state.copyWith(comments: updatedComments);

      final response = await _repository.getCommentReplies(
        commentId: commentId,
        page: 1,
        perPage: 10,
      );

      debugPrint('Reply API response: $response');

      // Check for success based on API format
      if (response['success'] == 'success') {
        // Parse replies from the response
        final repliesData = response['data'] as List<dynamic>;
        debugPrint('Received ${repliesData.length} replies');

        try {
          final replies =
              repliesData.map((reply) => Comment.fromJson(reply)).toList();
          debugPrint('Parsed ${replies.length} replies');

          // Get pagination info if available
          final paginationData =
              response['pagination'] as Map<String, dynamic>?;
          final hasMore = paginationData != null
              ? (paginationData['has_next'] ?? false)
              : false;
          debugPrint('Has more replies: $hasMore');

          // Update the comment with replies
          updatedComments = List<Comment>.from(state.comments);
          updatedComments[commentIndex] = comment.copyWith(
            replies: replies,
            isLoading: false,
            showReplies: true,
            hasMoreReplies: hasMore,
            currentPage: 1,
          );

          state = state.copyWith(comments: updatedComments);
          debugPrint('State updated with replies');
        } catch (parseError) {
          debugPrint('Error parsing replies: $parseError');
          throw Exception('Error parsing replies: $parseError');
        }
      } else {
        final message = response['message'] ?? 'Failed to load replies';
        debugPrint('API error: $message');
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('Error loading replies: $e');
      // Mark the comment as not loading and show error
      final updatedComments = List<Comment>.from(state.comments);
      updatedComments[commentIndex] = comment.copyWith(isLoading: false);

      state = state.copyWith(
        comments: updatedComments,
        error: e.toString(),
      );
    }
  }

  // Load more replies for a comment
  Future<void> loadMoreReplies(int commentId) async {
    // Find the comment in the state
    final commentIndex = state.comments.indexWhere((c) => c.id == commentId);
    if (commentIndex == -1) return;

    final comment = state.comments[commentIndex];

    // If there are no more replies to load, return
    if (!comment.hasMoreReplies) return;

    try {
      // Mark the comment as loading more
      var updatedComments = List<Comment>.from(state.comments);
      updatedComments[commentIndex] = comment.copyWith(isLoading: true);
      state = state.copyWith(comments: updatedComments);

      final nextPage = comment.currentPage + 1;
      final response = await _repository.getCommentReplies(
        commentId: commentId,
        page: nextPage,
        perPage: 10,
      );

      if (response['success'] == 'success' && response['data'] != null) {
        // Parse new replies
        final repliesData = response['data'] as List<dynamic>;
        final newReplies =
            repliesData.map((reply) => Comment.fromJson(reply)).toList();

        // Get pagination info
        final paginationData = response['pagination'] as Map<String, dynamic>;
        final hasMore = paginationData['has_next'] ?? false;

        // Update the comment with combined replies
        updatedComments = List<Comment>.from(state.comments);
        updatedComments[commentIndex] = comment.copyWith(
          replies: [...comment.replies, ...newReplies],
          isLoading: false,
          hasMoreReplies: hasMore,
          currentPage: nextPage,
        );

        state = state.copyWith(comments: updatedComments);
      }
    } catch (e) {
      // Mark the comment as not loading and show error
      final updatedComments = List<Comment>.from(state.comments);
      updatedComments[commentIndex] = comment.copyWith(isLoading: false);

      state = state.copyWith(
        comments: updatedComments,
        error: e.toString(),
      );
    }
  }

  // React to a comment (like, love, etc.)
  Future<void> reactToComment({
    required int commentId,
    required String reactionType,
  }) async {
    // This would require an API endpoint for adding reactions
    // For now, just update the UI state optimistically
    try {
      state = state.copyWith(isReacting: true);

      // Find the comment in state
      final commentIndex = state.comments.indexWhere((c) => c.id == commentId);

      if (commentIndex != -1) {
        // It's a top-level comment
        final comment = state.comments[commentIndex];
        final updatedComments = List<Comment>.from(state.comments);

        // Toggle reaction if same type, otherwise change to new type
        final hasReacted =
            comment.hasReacted && comment.reactionType == reactionType;
        final newReactionCount =
            hasReacted ? comment.reactionCount - 1 : comment.reactionCount + 1;

        updatedComments[commentIndex] = comment.copyWith(
          hasReacted: !hasReacted,
          reactionType: hasReacted ? null : reactionType,
          reactionCount: newReactionCount,
        );

        state = state.copyWith(
          comments: updatedComments,
          isReacting: false,
        );
      } else {
        // Check if it's a reply to any comment
        bool found = false;
        final updatedComments = state.comments.map((comment) {
          final replyIndex =
              comment.replies.indexWhere((r) => r.id == commentId);

          if (replyIndex != -1) {
            found = true;
            final reply = comment.replies[replyIndex];
            final hasReacted =
                reply.hasReacted && reply.reactionType == reactionType;
            final newReactionCount =
                hasReacted ? reply.reactionCount - 1 : reply.reactionCount + 1;

            final updatedReplies = List<Comment>.from(comment.replies);
            updatedReplies[replyIndex] = reply.copyWith(
              hasReacted: !hasReacted,
              reactionType: hasReacted ? null : reactionType,
              reactionCount: newReactionCount,
            );

            return comment.copyWith(replies: updatedReplies);
          }

          return comment;
        }).toList();

        if (found) {
          state = state.copyWith(
            comments: updatedComments,
            isReacting: false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error reacting to comment: $e');
      state = state.copyWith(
        isReacting: false,
        error: e.toString(),
      );
    }
  }
}
