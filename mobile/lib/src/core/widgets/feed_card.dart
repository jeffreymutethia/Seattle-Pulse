import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/core/constants/reaction_constants.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/interactions.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/reaction_popup.dart';
import 'package:seattle_pulse_mobile/src/features/feed/widgets/post_options_menu.dart';
import 'package:seattle_pulse_mobile/src/features/profile/screens/profile_screen.dart';

class PostCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final String profileImageUrl;
  final String name;
  final String location;
  final String timeAgo;
  final String postImageUrl;
  final String headline;
  final int likeCount;
  final int commentCount;
  final int repostCount;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final VoidCallback? onShare;
  final VoidCallback? onProfile;
  final bool? isFollowing;
  final Function(Reaction)? onReaction;
  final String? currentReaction;
  final List<String>? topReactions;
  final bool hasReposted;
  final int? contentId;
  final bool? isOwner;
  final VoidCallback? onVerifyOwnership;

  const PostCard({
    Key? key,
    this.height = 570,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE2E8F0),
    this.borderRadius = 24,
    required this.profileImageUrl,
    required this.name,
    required this.location,
    required this.timeAgo,
    required this.postImageUrl,
    required this.headline,
    required this.likeCount,
    required this.commentCount,
    required this.repostCount,
    this.onLike,
    this.onComment,
    this.onRepost,
    this.onShare,
    this.isFollowing,
    this.onProfile,
    this.onReaction,
    this.currentReaction,
    this.topReactions,
    this.hasReposted = false,
    this.contentId,
    this.isOwner,
    this.onVerifyOwnership,
  }) : super(key: key);

  // Helper method to display top reactions
  Widget _buildTopReactionsRow() {
    if (topReactions == null || topReactions!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Map the top reactions to emojis
    List<Widget> reactionWidgets = [];

    // Add the reaction emojis (maximum 3)
    for (int i = 0; i < topReactions!.length && i < 3; i++) {
      final reactionName = topReactions![i].toLowerCase();
      // Find the reaction
      final reaction = kReactions.firstWhere(
        (r) => r.name.toLowerCase() == reactionName,
        orElse: () => kReactions.first, // Default to "like" if not found
      );

      reactionWidgets.add(
        Text(
          reaction.emoji,
          style: const TextStyle(fontSize: 8),
        ),
      );

      // Add a small gap between emojis
      if (i < topReactions!.length - 1 && i < 2) {
        reactionWidgets.add(const SizedBox(width: 2));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          ...reactionWidgets,
          const SizedBox(width: 4),
          Text(
            '$likeCount',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Show bottom sheet with post options
  void _showPostOptions(BuildContext context) {
    // Skip if contentId is null
    if (contentId == null) return;

    // Call verification callback if provided
    if (onVerifyOwnership != null) {
      onVerifyOwnership!();
    }

   

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => PostOptionsMenu(
        contentId: contentId!,
        isOwner: isOwner ?? false,
        onCopyLink: () {
          _copyContentLink(context);
        },
        onSuccess: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }

  // Copy content link to clipboard
  void _copyContentLink(BuildContext context) {
    // Skip if contentId is null
    if (contentId == null) return;

    // In a real app, you'd construct a proper sharable URL
    final link = "https://seattlepulse.app/content/$contentId";
    Clipboard.setData(ClipboardData(text: link));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        username: name,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColor.colorE2E8F0,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          profileImageUrl,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 10),
                            if (isFollowing ?? false)
                              Text(
                                'Following',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColor.color838B98,
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                location,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeAgo,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // More options icon
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () => _showPostOptions(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Main image content
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: borderColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.network(
                postImageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Headline text
          Text(
            headline,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Top reactions row
          _buildTopReactionsRow(),
          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          InteractionRow(
            // likeCount: likeCount,
            commentCount: commentCount,
            // repostCount: repostCount,
            onLike: onLike ?? () {},
            onComment: onComment ?? () {},
            onRepost: onRepost ?? () {},
            onShare: onShare ?? () {},
            onReaction: onReaction,
            currentReaction: currentReaction,
            hasReposted: hasReposted,
          ),
        ],
      ),
    );
  }
}
