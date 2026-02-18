import 'package:flutter/material.dart';

class PostActionsRow extends StatelessWidget {
  final String likeLabel;
  final String commentLabel;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final bool hasLiked;
  final Color reactionColor;
  final Key? likeButtonKey;

  const PostActionsRow({
    Key? key,
    required this.likeLabel,
    required this.commentLabel,
    required this.onLike,
    required this.onComment,
    this.onShare,
    this.onMore,
    this.hasLiked = false,
    this.reactionColor = Colors.blue,
    this.likeButtonKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.,
      children: [
        // Like button
        GestureDetector(
          key: likeButtonKey,
          onTap: onLike,
          onLongPress: onLike,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Row(
              children: [
                Icon(
                  hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 18,
                  color: hasLiked ? reactionColor : Colors.grey,
                ),
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

        // Comment button
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

        // Share button (optional)
        if (onShare != null)
          GestureDetector(
            onTap: onShare,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Row(
                children: const [
                  Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Share',
                    style: TextStyle(
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
}
