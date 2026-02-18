import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/core/utils/time_ago.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/interactions.dart';
import 'package:seattle_pulse_mobile/src/features/feed/models/comment_model.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/comment_provider.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_details_provider.dart';
import 'package:seattle_pulse_mobile/src/features/feed/widgets/comment_item.dart';
import 'package:seattle_pulse_mobile/src/features/feed/widgets/post_action_row.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/comment_reaction_provider.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/reaction_popup.dart';
import 'package:seattle_pulse_mobile/src/core/constants/reaction_constants.dart';

class CommentBottomSheet extends ConsumerStatefulWidget {
  final String contentType;
  final int contentId;

  const CommentBottomSheet({
    Key? key,
    required this.contentType,
    required this.contentId,
  }) : super(key: key);

  @override
  ConsumerState<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends ConsumerState<CommentBottomSheet> {
  late final Map<String, dynamic> _contentKey;
  final TextEditingController _commentController = TextEditingController();
  int? _replyToCommentId;
  String _replyToUsername = '';
  int? _editingCommentId;
  int?
      _replyToParentId; // This tracks the top-level comment ID when replying to a nested reply

  @override
  void initState() {
    super.initState();
    _contentKey = {
      'contentType': widget.contentType,
      'contentId': widget.contentId,
    };

    debugPrint(
        'Initializing comment bottom sheet for contentId: ${widget.contentId}, contentType: ${widget.contentType}');

    Future.microtask(() {
      // Fetch content details
      ref
          .read(contentDetailsNotifierProvider(_contentKey).notifier)
          .fetchInitialContentDetails();

      // Initialize comments
      ref
          .read(commentStateProvider(_contentKey).notifier)
          .fetchInitialComments();

      debugPrint('Comment providers initialized');
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Set up to reply to a comment
  void _setupReplyTo({
    required int commentId,
    required String username,
    int? parentId,
  }) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUsername = username;
      _replyToParentId = parentId; // This could be null for top-level comments
      _editingCommentId = null;
      _commentController.text = '';
    });
    // Focus the comment field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  // Cancel reply mode
  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = '';
      _replyToParentId = null;
    });
  }

  // Set up to edit a comment
  void _setupEditComment(int commentId, String content) {
    setState(() {
      _editingCommentId = commentId;
      _replyToCommentId = null;
      _replyToUsername = '';
      _replyToParentId = null;
      _commentController.text = content;
    });
    // Focus the comment field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  // Cancel edit mode
  void _cancelEdit() {
    setState(() {
      _editingCommentId = null;
      _commentController.text = '';
    });
  }

  // Post a comment or reply, or update an existing comment
  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final content = _commentController.text.trim();

    try {
      if (_editingCommentId != null) {
        // Update an existing comment
        debugPrint(
            'Updating comment: $_editingCommentId with content: $content');
        await ref
            .read(commentStateProvider(_contentKey).notifier)
            .updateComment(
              commentId: _editingCommentId!,
              content: content,
            );

        // Clear input and reset edit state
        _commentController.clear();
        setState(() {
          _editingCommentId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment updated successfully')),
        );
      } else if (_replyToCommentId != null) {
        // Post a reply
        debugPrint('Posting reply to comment $_replyToCommentId: $content');
        final targetId = _replyToParentId ?? _replyToCommentId!;

        await ref.read(commentStateProvider(_contentKey).notifier).postReply(
              parentId:
                  targetId, // Always use the top-level comment or parent ID
              content: content,
              repliedToUsername: _replyToUsername,
            );

        // Clear input and reset reply state
        _commentController.clear();
        setState(() {
          _replyToCommentId = null;
          _replyToUsername = '';
          _replyToParentId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply posted successfully')),
        );
      } else {
        // Post a top-level comment
        debugPrint('Posting top-level comment: $content');
        await ref
            .read(commentStateProvider(_contentKey).notifier)
            .postComment(content);

        // Clear input
        _commentController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error handling comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  // Handle reaction to comment
  void _reactToComment(int commentId, String reactionType) async {
    debugPrint('Reacting to comment $commentId with $reactionType');

    try {
      // Find the reaction based on type
      final reaction = kReactions.firstWhere(
        (r) => r.name == reactionType,
        orElse: () => kReactions[0], // Default to "like" if not found
      );

      // Use the comment reaction provider
      await ref
          .read(commentReactionsProvider.notifier)
          .reactToComment(commentId, reaction);

      // Also ensure UI is updated through comment provider
      await ref.read(commentStateProvider(_contentKey).notifier).reactToComment(
            commentId: commentId,
            reactionType: reactionType,
          );

      // Initialize reactions in the provider if not done yet
      final comments = ref.read(commentStateProvider(_contentKey)).comments;
      if (comments.isNotEmpty) {
        ref
            .read(commentReactionsProvider.notifier)
            .initializeFromCommentList(comments);
      }
    } catch (e) {
      debugPrint('Error reacting to comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error reacting to comment: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  // Load more comments
  void _loadMoreComments() {
    debugPrint('Loading more comments');
    ref.read(commentStateProvider(_contentKey).notifier).loadMoreComments();
  }

  // Handle replying to a nested reply
  void _handleReplyToReply(int replyId, String username, int parentId) {
    _setupReplyTo(
      commentId: replyId,
      username: username,
      parentId: parentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentDetailsState =
        ref.watch(contentDetailsNotifierProvider(_contentKey));
    final details = contentDetailsState.contentDetails;
    final commentState = ref.watch(commentStateProvider(_contentKey));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: contentDetailsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : contentDetailsState.error != null
              ? Center(child: Text("Error: ${contentDetailsState.error}"))
              : details == null
                  ? const Center(child: Text("No content details found."))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header image
                        SizedBox(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              details.imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Center(child: Text("Image not found")),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(
                                  details.user.profilePictureUrl ??
                                      "https://picsum.photos/40/40",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    details.user.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "• ${details.createdAt}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_pin,
                                    color: AppColor.color838B98,
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      details.location,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColor.color838B98,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  const Icon(Icons.more_horiz_outlined)
                                ],
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            details.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: AppColor.color0C1024,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 20),
                              InteractionRow(
                                likeCount: details.totalReactions,
                                commentCount: details.totalComments,
                                repostCount: 0,
                                onLike: () {},
                                onComment: () {},
                                onRepost: () {},
                                onShare: () {},
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: commentState.isLoading &&
                                  commentState.comments.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : commentState.comments.isEmpty
                                  ? const Center(
                                      child: Text("No comments yet."))
                                  : ListView.builder(
                                      itemCount: commentState.comments.length +
                                          (commentState.hasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        // Load more indicator at the end
                                        if (commentState.hasMore &&
                                            index ==
                                                commentState.comments.length) {
                                          return Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Center(
                                              child: commentState.isLoading
                                                  ? const CircularProgressIndicator()
                                                  : TextButton(
                                                      onPressed:
                                                          _loadMoreComments,
                                                      child: const Text(
                                                          'Load more comments'),
                                                    ),
                                            ),
                                          );
                                        }

                                        // Show comments
                                        final comment =
                                            commentState.comments[index];

                                        // Determine if we need to load replies for this comment (if it has replies from the API)
                                        final hasReplies =
                                            (comment.repliesCount ?? 0) > 0 ||
                                                comment.replies.isNotEmpty;

                                        return CommentItem(
                                          comment: comment,
                                          onReply: () => _setupReplyTo(
                                            commentId: comment.id,
                                            username: comment.user.username,
                                          ),
                                          onLoadReplies: () {
                                            if (hasReplies) {
                                              ref
                                                  .read(commentStateProvider(
                                                          _contentKey)
                                                      .notifier)
                                                  .loadReplies(comment.id);
                                            }
                                          },
                                          onLoadMoreReplies: () => ref
                                              .read(commentStateProvider(
                                                      _contentKey)
                                                  .notifier)
                                              .loadMoreReplies(comment.id),
                                          onEditComment: _setupEditComment,
                                          onReactToComment: _reactToComment,
                                          onReplyToReply: _handleReplyToReply,
                                        );
                                      },
                                    ),
                        ),

                        // Edit indicator (when editing a comment)
                        if (_editingCommentId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: Colors.amber[50],
                            child: Row(
                              children: [
                                const Icon(Icons.edit,
                                    size: 16, color: Colors.amber),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Editing comment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: _cancelEdit,
                                ),
                              ],
                            ),
                          ),

                        // Reply indicator (when replying)
                        if (_replyToCommentId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: Colors.grey[100],
                            child: Row(
                              children: [
                                const Icon(Icons.reply,
                                    size: 16, color: Colors.black),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Replying to $_replyToUsername',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: _cancelReply,
                                ),
                              ],
                            ),
                          ),

                        // Comment Input
                        SafeArea(
                          top: false,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            color: Colors.white,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      hintText: _editingCommentId != null
                                          ? "Edit your comment..."
                                          : _replyToCommentId != null
                                              ? "Reply to $_replyToUsername..."
                                              : "Share your thoughts here...",
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: const BorderSide(
                                            color: Colors.grey),
                                      ),
                                    ),
                                    maxLines: null,
                                    textInputAction: TextInputAction.newline,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: commentState.isPostingComment
                                      ? null
                                      : _postComment,
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.black,
                                    child: commentState.isPostingComment
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.send,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
