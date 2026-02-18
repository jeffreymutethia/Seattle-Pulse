import 'package:flutter/material.dart';
import 'dart:math';
import 'package:seattle_pulse_mobile/src/core/constants/reaction_constants.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/reaction_popup.dart';

class InteractionRow extends StatefulWidget {
  final int? likeCount;
  final int commentCount;
  final int? repostCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onRepost;
  final VoidCallback onShare;
  final Function(Reaction)? onReaction;
  final String? currentReaction;
  final bool hasReposted;

  const InteractionRow({
    Key? key,
    this.likeCount,
    required this.commentCount,
    this.repostCount,
    required this.onLike,
    required this.onComment,
    required this.onRepost,
    required this.onShare,
    this.onReaction,
    this.currentReaction,
    this.hasReposted = false,
  }) : super(key: key);

  @override
  State<InteractionRow> createState() => _InteractionRowState();
}

class _InteractionRowState extends State<InteractionRow> {
  OverlayEntry? _overlayEntry;
  bool _isReactionVisible = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isReactionVisible = false;
  }

  void _showReactionOverlay(BuildContext context, Offset position) {
    // Close any existing overlay first
    _removeOverlay();

    // Create a new overlay
    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Full-screen dismissible area
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _removeOverlay,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // Reaction popup
            Positioned(
              top: position.dy - 80,
              left: max(0, position.dx - 120),
              child: ReactionPopup(
                reactions: kReactions,
                onReactionSelected: (reaction) {
                  if (widget.onReaction != null) {
                    widget.onReaction!(reaction);
                  }
                  _removeOverlay();
                },
                onDismiss: _removeOverlay,
              ),
            ),
          ],
        ),
      ),
    );

    // Insert the overlay
    Overlay.of(context).insert(_overlayEntry!);
    _isReactionVisible = true;
  }

  @override
  Widget build(BuildContext context) {
    // Debug output to verify if hasReposted is being passed correctly
    debugPrint(
        "INTERACTIONS: Building InteractionRow with hasReposted=${widget.hasReposted}, repostCount=${widget.repostCount}");

    return Row(
      children: [
        _buildInteractionButton(
          icon: "assets/icons/like.png",
          count: widget.likeCount,
          onPressed: widget.onLike,
          onLongPress: (position) {
            if (widget.onReaction != null) {
              _showReactionOverlay(context, position);
            }
          },
          currentReaction: widget.currentReaction,
        ),
        SizedBox(width: 20),
        _buildInteractionButton(
          icon: "assets/icons/comment.png",
          count: widget.commentCount,
          onPressed: widget.onComment,
        ),
        SizedBox(width: 20),
        _buildInteractionButton(
          icon: "assets/icons/repost.png",
          count: widget.repostCount,
          onPressed: widget.onRepost,
          isReposted: widget.hasReposted,
        ),
        Spacer(),
        GestureDetector(
          onTap: widget.onShare,
          child: Image.asset(
            "assets/icons/share.png",
            width: 24,
            height: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required String icon,
    int? count,
    required VoidCallback onPressed,
    Function(Offset position)? onLongPress,
    String? currentReaction,
    bool isReposted = false,
  }) {
    // Find reaction emoji if we have a current reaction
    String? emojiToShow;
    Color? colorToUse;

    if (currentReaction != null) {
      final reaction = kReactions.firstWhere(
        (r) => r.name == currentReaction,
        orElse: () => kReactions.first,
      );
      emojiToShow = reaction.emoji;
      colorToUse = reaction.color;
    }

    // Debug output for repost button
    if (icon.contains('repost')) {
      debugPrint(
          "INTERACTIONS: Building repost button with isReposted=$isReposted");
    }

    // Set repost color if this is a repost button and user has reposted
    if (icon.contains('repost') && isReposted) {
      colorToUse = Colors.blue;
      debugPrint("INTERACTIONS: Setting blue color for repost button");
    }

    return Row(
      children: [
        GestureDetector(
          onTap: onPressed,
          onLongPressStart: onLongPress != null
              ? (details) => onLongPress(details.globalPosition)
              : null,
          child: emojiToShow != null
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorToUse?.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    emojiToShow,
                    style: const TextStyle(fontSize: 28),
                  ),
                )
              : icon.contains('repost') && isReposted
                  ? Container(
                      padding: const EdgeInsets.all(
                          8), // Slightly larger padding for visibility
                      decoration: BoxDecoration(
                        color: Colors.blue
                            .withOpacity(0.15), // Slightly more opacity
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        icon,
                        width: 28, // Slightly larger icon
                        height: 28, // Slightly larger icon
                        color: Colors.blue,
                      ),
                    )
                  : Image.asset(
                      icon,
                      width: 24,
                      height: 24,
                    ),
        ),
        const SizedBox(width: 9),
        if (count != null)
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700, // Make text bolder
              color: colorToUse ?? (isReposted ? Colors.blue : Colors.black),
            ),
          ),
      ],
    );
  }
}
