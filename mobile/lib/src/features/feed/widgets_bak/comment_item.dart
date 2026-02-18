import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/core/constants/reaction_constants.dart';
import 'package:seattle_pulse_mobile/src/core/utils/time_ago.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/reaction_popup.dart';
import 'package:seattle_pulse_mobile/src/features/feed/models/comment_model.dart';
import 'package:seattle_pulse_mobile/src/features/feed/widgets/post_action_row.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/comment_reaction_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/feed/widgets/comment_action_row.dart';

class CommentItem extends ConsumerStatefulWidget {
  final Comment comment;
  final VoidCallback onReply;
  final VoidCallback onLoadReplies;
  final VoidCallback onLoadMoreReplies;
  final Function(int, String)? onEditComment;
  final Function(int, String)? onReactToComment;
  final Function(int, String, int)? onReplyToReply;

  const CommentItem({
    Key? key,
    required this.comment,
    required this.onReply,
    required this.onLoadReplies,
    required this.onLoadMoreReplies,
    this.onEditComment,
    this.onReactToComment,
    this.onReplyToReply,
  }) : super(key: key);

  @override
  ConsumerState<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<CommentItem> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _likeButtonKey = GlobalKey();

  @override
  void dispose() {
    _dismissReactionPopup();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize reactions in the provider if not done yet
    final commentReactions = ref.read(commentReactionsProvider);
    if (commentReactions.isEmpty) {
      ref
          .read(commentReactionsProvider.notifier)
          .initializeFromCommentList([widget.comment]);
    }
  }

  void _dismissReactionPopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showReactionPopup() {
    _dismissReactionPopup();

    // Create an overlay with the reaction popup
    final popup = ReactionPopupOverlay(
      context: context,
      anchorKey: _likeButtonKey,
      reactions: kReactions,
      onReactionSelected: (reaction) {
        if (widget.onReactToComment != null) {
          widget.onReactToComment!(widget.comment.id, reaction.name);
        }
      },
    );
    popup.show();
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final hasReplies = widget.comment.replies.isNotEmpty;
    final commentReactions = ref.watch(commentReactionsProvider);
    final userReaction = commentReactions[widget.comment.id];

    return GestureDetector(
      onLongPress: () => _showInteractionOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main comment
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    widget.comment.user.profilePictureUrl ??
                        "https://picsum.photos/40/40",
                  ),
                ),
                const SizedBox(width: 8),

                // Comment content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username and timestamp
                      Row(
                        children: [
                          Text(
                            widget.comment.user.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeAgo(widget.comment.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      // Comment text
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          widget.comment.content,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                      // Reaction count and icons
                      if (widget.comment.reactionCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                          child: Row(
                            children: [
                              for (var reaction
                                  in widget.comment.topReactions.take(2))
                                Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: _buildReactionIcon(reaction),
                                ),
                              Text(
                                widget.comment.reactionCount.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Action buttons
                      CommentActionRow(
                        likeLabel: widget.comment.hasReacted ? "Liked" : "Like",
                        commentLabel: "Reply",
                        onLike: _showReactionPopup,
                        onComment: widget.onReply,
                        hasLiked:
                            widget.comment.hasReacted || userReaction != null,
                        reactionType:
                            userReaction ?? widget.comment.reactionType,
                        reactionColor: _getReactionColor(
                            userReaction ?? widget.comment.reactionType),
                        onMore: () => _showInteractionOptions(context),
                        likeButtonKey: _likeButtonKey,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Show 'View replies' if the comment has replies_count > 0 and replies are not loaded
            if (((widget.comment.repliesCount ?? 0) > 0 ||
                    widget.comment.replies.isNotEmpty) &&
                !widget.comment.showReplies)
              Padding(
                padding: const EdgeInsets.only(left: 40.0, top: 8.0),
                child: InkWell(
                  onTap: widget.onLoadReplies,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.subdirectory_arrow_right,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'View ${widget.comment.repliesCount ?? widget.comment.replies.length} ${(widget.comment.repliesCount ?? widget.comment.replies.length) == 1 ? 'reply' : 'replies'}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Show replies section if showing replies
            if (widget.comment.showReplies)
              Padding(
                padding: const EdgeInsets.only(left: 40.0, top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loading indicator
                    if (widget.comment.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),

                    // Replies list
                    ...widget.comment.replies.map((reply) => ReplyItem(
                          reply: reply,
                          parentId: widget.comment.id,
                          onReply: () {
                            // When replying to a reply, pass the parent comment ID
                            if (widget.onReplyToReply != null) {
                              widget.onReplyToReply!(reply.id,
                                  reply.user.username, widget.comment.id);
                            }
                          },
                          onReactToReply: widget.onReactToComment,
                        )),

                    // Load more button
                    if (widget.comment.hasMoreReplies)
                      TextButton(
                        onPressed: widget.onLoadMoreReplies,
                        child: const Text('Load more replies'),
                      ),

                    // Hide replies button
                    if (!widget.comment.isLoading &&
                        widget.comment.replies.isNotEmpty)
                      TextButton(
                        onPressed: widget.onLoadReplies,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_drop_up, size: 16),
                            SizedBox(width: 2),
                            Text('Hide replies'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getReactionColor(String? reactionType) {
    if (reactionType == null) return Colors.grey;

    final reaction = kReactions.firstWhere(
      (r) => r.name == reactionType,
      orElse: () => kReactions[0],
    );

    return reaction.color;
  }

  void _showInteractionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reactions section
          if (widget.onReactToComment != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reactions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: kReactions.map((reaction) {
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.onReactToComment != null) {
                            widget.onReactToComment!(
                                widget.comment.id, reaction.name);
                          }
                        },
                        child: Column(
                          children: [
                            Text(reaction.emoji,
                                style: const TextStyle(fontSize: 30)),
                            const SizedBox(height: 4),
                            Text(
                              reaction.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: reaction.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Reply option
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () {
              Navigator.pop(context);
              widget.onReply();
            },
          ),

          // Edit option (if authorized)
          if (widget.onEditComment != null)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Comment'),
              onTap: () {
                Navigator.pop(context);
                widget.onEditComment!(
                    widget.comment.id, widget.comment.content);
              },
            ),

          // Report option
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comment reported')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReactionIcon(String reaction) {
    // Find the reaction based on type
    final reactionObj = kReactions.firstWhere(
      (r) => r.name == reaction,
      orElse: () => kReactions[0],
    );

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        shape: BoxShape.circle,
      ),
      child: Text(reactionObj.emoji, style: const TextStyle(fontSize: 12)),
    );
  }
}

class ReplyItem extends ConsumerStatefulWidget {
  final Comment reply;
  final int parentId; // Add parent comment ID
  final VoidCallback onReply;
  final Function(int, String)? onReactToReply;

  const ReplyItem({
    Key? key,
    required this.reply,
    required this.parentId,
    required this.onReply,
    this.onReactToReply,
  }) : super(key: key);

  @override
  ConsumerState<ReplyItem> createState() => _ReplyItemState();
}

class _ReplyItemState extends ConsumerState<ReplyItem> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _likeButtonKey = GlobalKey();

  @override
  void dispose() {
    _dismissReactionPopup();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize reactions in the provider if not done yet
    final commentReactions = ref.read(commentReactionsProvider);
    if (commentReactions.isEmpty ||
        !commentReactions.containsKey(widget.reply.id)) {
      ref
          .read(commentReactionsProvider.notifier)
          .initializeFromCommentList([widget.reply]);
    }
  }

  void _dismissReactionPopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showReactionPopup() {
    _dismissReactionPopup();

    // Create an overlay with the reaction popup
    final popup = ReactionPopupOverlay(
      context: context,
      anchorKey: _likeButtonKey,
      reactions: kReactions,
      onReactionSelected: (reaction) {
        if (widget.onReactToReply != null) {
          widget.onReactToReply!(widget.reply.id, reaction.name);
        }
      },
    );
    popup.show();
  }

  @override
  Widget build(BuildContext context) {
    final reply = widget.reply;
    final replyToUsername =
        reply.repliedTo != null ? (reply.repliedTo?.username ?? "") : "";
    final commentReactions = ref.watch(commentReactionsProvider);
    final userReaction = commentReactions[widget.reply.id];

    return GestureDetector(
      onLongPress: () => _showInteractionOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(
                reply.user.profilePictureUrl ?? "https://picsum.photos/40/40",
              ),
            ),
            const SizedBox(width: 8),

            // Reply content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username and timestamp
                  Row(
                    children: [
                      Text(
                        reply.user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo(reply.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // If replying to someone specific
                  if (reply.repliedTo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'Replying to $replyToUsername',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Reply text
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      reply.content,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  // Reaction count and icons
                  if (reply.reactionCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, bottom: 6.0),
                      child: Row(
                        children: [
                          for (var reaction in reply.topReactions.take(2))
                            Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: _buildReactionIcon(),
                            ),
                          Text(
                            reply.reactionCount.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Action buttons
                  CommentActionRow(
                    likeLabel: reply.hasReacted ? "Liked" : "Like",
                    commentLabel: "Reply",
                    onLike: _showReactionPopup,
                    onComment: widget.onReply,
                    hasLiked: reply.hasReacted || userReaction != null,
                    reactionType: userReaction ?? reply.reactionType,
                    reactionColor:
                        _getReactionColor(userReaction ?? reply.reactionType),
                    likeButtonKey: _likeButtonKey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionIcon() {
    final commentUserReactions = ref.watch(commentReactionsProvider);
    final userReaction = commentUserReactions[widget.reply.id];

    if (userReaction == null) {
      return const Icon(
        Icons.thumb_up_outlined,
        size: 16,
        color: Colors.grey,
      );
    }

    // Find the reaction based on type
    final reactionObj = kReactions.firstWhere(
      (r) => r.name == userReaction,
      orElse: () => kReactions[0],
    );

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        shape: BoxShape.circle,
      ),
      child: Text(reactionObj.emoji, style: const TextStyle(fontSize: 10)),
    );
  }

  Color _getReactionColor(String? reactionType) {
    if (reactionType == null) return Colors.grey;

    final reaction = kReactions.firstWhere(
      (r) => r.name == reactionType,
      orElse: () => kReactions[0],
    );

    return reaction.color;
  }

  void _showInteractionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reactions section
          if (widget.onReactToReply != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reactions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: kReactions.map((reaction) {
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.onReactToReply != null) {
                            widget.onReactToReply!(
                                widget.reply.id, reaction.name);
                          }
                        },
                        child: Column(
                          children: [
                            Text(reaction.emoji,
                                style: const TextStyle(fontSize: 30)),
                            const SizedBox(height: 4),
                            Text(
                              reaction.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: reaction.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Reply option
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () {
              Navigator.pop(context);
              widget.onReply();
            },
          ),

          // Report option
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reply reported')),
              );
            },
          ),
        ],
      ),
    );
  }
}
