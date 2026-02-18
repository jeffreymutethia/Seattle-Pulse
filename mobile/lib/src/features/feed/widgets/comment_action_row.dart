import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/core/constants/reaction_constants.dart';

class CommentActionRow extends StatelessWidget {
  final String likeLabel;
  final String commentLabel;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final bool hasLiked;
  final String? reactionType;
  final Color reactionColor;
  final Key? likeButtonKey;
  final VoidCallback? onMore;

  const CommentActionRow({
    Key? key,
    required this.likeLabel,
    required this.commentLabel,
    required this.onLike,
    required this.onComment,
    this.hasLiked = false,
    this.reactionType,
    this.reactionColor = Colors.blue,
    this.likeButtonKey,
    this.onMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Reaction button with emoji
        GestureDetector(
          key: likeButtonKey,
          onTap: onLike,
          onLongPress: onLike,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Row(
              children: [
                _buildReactionEmoji(),
                const SizedBox(width: 4),
                Text(
                  likeLabel,
                  style: TextStyle(
                    color: hasLiked ? reactionColor : Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Comment/Reply button
        GestureDetector(
          onTap: onComment,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  commentLabel,
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

        // More options button (optional)
        if (onMore != null)
          IconButton(
            onPressed: onMore,
            icon: const Icon(Icons.more_horiz, color: Colors.grey),
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Widget _buildReactionEmoji() {
    if (!hasLiked) {
      return const Icon(
        Icons.thumb_up_outlined,
        size: 18,
        color: Colors.grey,
      );
    }

    // Find the reaction based on type
    final reaction = kReactions.firstWhere(
      (r) => r.name == reactionType,
      orElse: () => kReactions[0], // Default to "like" if not found
    );

    return Text(
      reaction.emoji,
      style: const TextStyle(fontSize: 18),
    );
  }
}
