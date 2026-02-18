import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/core/constants/constants.dart';
import 'package:seattle_pulse_mobile/src/core/constants/reaction_constants.dart';
import 'package:seattle_pulse_mobile/src/core/utils/time_ago.dart';

import 'package:seattle_pulse_mobile/src/core/widgets/app_bar.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_input_field.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/reaction_provider.dart';
import 'package:seattle_pulse_mobile/src/features/feed/widgets/comment_bottom_sheet.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/feed_card.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/share_bottom_sheet.dart';
import 'package:seattle_pulse_mobile/src/features/mypulse/providers/mypulse_provider.dart';

import '../../feed/providers/repost_provider.dart';

class MyPulseScreen extends ConsumerStatefulWidget {
  const MyPulseScreen({super.key});

  @override
  ConsumerState<MyPulseScreen> createState() => _MyPulseScreenState();
}

class _MyPulseScreenState extends ConsumerState<MyPulseScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    debugPrint("initState: About to fetch first page...");

    Future.microtask(() {
      ref.read(myPulseNotifierProvider.notifier).fetchFirstPage();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final mypulseState = ref.read(myPulseNotifierProvider);

    debugPrint(
      "_onScroll: extentAfter=${_scrollController.position.extentAfter}, "
      "isLoadingMore=${mypulseState.isLoadingMore}, hasNext=${mypulseState.hasNext}",
    );

    if (!mypulseState.isLoadingMore && mypulseState.hasNext) {
      if (_scrollController.position.extentAfter < 200) {
        ref.read(myPulseNotifierProvider.notifier).fetchNextPage();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mypulseState = ref.watch(myPulseNotifierProvider);
    final userReactions = ref.watch(userReactionsProvider);
    final userReposts = ref.watch(userRepostsProvider);

    return Scaffold(
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          debugPrint("Pull-to-refresh: fetching first page again...");
          await ref.read(myPulseNotifierProvider.notifier).fetchFirstPage();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppInputField(
              hintText: "Search",
              labelText: "Search",
              borderRadius: 50,
              keyboardType: TextInputType.text,
              prefixIcon: const Icon(Icons.search),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Posts from people you follow",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.color0C1024,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: mypulseState.isLoading && mypulseState.contents.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: mypulseState.contents.length + 1,
                      itemBuilder: (context, index) {
                        if (index == mypulseState.contents.length) {
                          if (mypulseState.isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else {
                            return const SizedBox();
                          }
                        }

                        final post = mypulseState.contents[index];
                        final contentId = post.id;
                        final currentReaction = userReactions[contentId];
                        final hasReposted = userReposts[contentId] == true;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: PostCard(
                             contentId: 1,
            isOwner: true,
                            profileImageUrl: post.user.profilePictureUrl ??
                                "https://picsum.photos/640/480?random=1",
                            name: post.user.username,
                            location: post.location,
                            timeAgo: timeAgo(post.createdAt),
                            postImageUrl: post.thumbnail ??
                                "https://picsum.photos/640/480?random=3",
                            headline: post.title ?? "",
                            likeCount: post.reactionsCount,
                            commentCount: post.commentsCount,
                            repostCount: post.repostsCount ?? 0,
                            hasReposted: hasReposted,
                            topReactions: post.topReactions,
                            onLike: () {
                              // If there's no current reaction, add a like
                              if (currentReaction == null) {
                                _handleReaction(post.id, 'like');
                              } else {
                                // Toggle off if already liked
                                _handleReaction(post.id, currentReaction);
                              }
                            },
                            onComment: () {
                              _openCommentBottomSheet(post.id);
                            },
                            onRepost: () {
                              _handleRepost(post.id);
                            },
                            onShare: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => ShareBottomSheet(
                                  publisherName: post.user.username,
                                  location: post.location,
                                  publisherAvatarUrl: post
                                          .user.profilePictureUrl ??
                                      "https://picsum.photos/640/480?random=1",
                                  privateMessageProfiles: [
                                    UserProfile(
                                        name: "John Doe",
                                        avatarUrl:
                                            "https://picsum.photos/seed/1/60"),
                                  ],
                                  shareOptions: [
                                    ShareOption(
                                        label: "My Story", icon: Icons.add),
                                    ShareOption(
                                        label: "Copy Link", icon: Icons.link),
                                    ShareOption(
                                        label: "Group", icon: Icons.group),
                                  ],
                                  onShareNow: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Post shared!")),
                                    );
                                  },
                                ),
                              );
                            },
                            onReaction: (reaction) {
                              _handleReaction(post.id, reaction.name);
                            },
                            currentReaction: currentReaction,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleReaction(int contentId, String reactionName) async {
    try {
      // Find the reaction object by name
      final reaction = kReactions.firstWhere(
        (r) => r.name == reactionName,
        orElse: () => kReactions.first,
      );

      final userReactions = ref.read(userReactionsProvider);
      final currentReaction = userReactions[contentId];
      final isRemovingReaction = currentReaction == reactionName;

      // Call the provider to handle the reaction
      await ref.read(userReactionsProvider.notifier).reactToContent(
            contentId,
            reaction,
          );

      // Show appropriate snackbar message based on action
      if (isRemovingReaction) {
        // Show message for removing reaction
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reaction removed'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Get updated user reaction state after adding/changing
        final updatedReactions = ref.read(userReactionsProvider);
        final updatedReaction = updatedReactions[contentId];

        if (updatedReaction != null) {
          // Show success message for adding/updating reaction
          final selectedReaction = kReactions.firstWhere(
            (r) => r.name == updatedReaction,
          );

          // Different message for adding vs. changing reaction
          final message = currentReaction == null
              ? 'You reacted with ${selectedReaction.label}!'
              : 'Changed to ${selectedReaction.label}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(selectedReaction.emoji),
                  const SizedBox(width: 8),
                  Text(message),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Show error message with better formatting
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Handle repost functionality
  void _handleRepost(int contentId) async {
    try {
      final userReposts = ref.read(userRepostsProvider);
      final hasReposted = userReposts[contentId] == true;

      debugPrint(
          "MYPULSE: Handling repost for content $contentId, currently reposted: $hasReposted");

      if (hasReposted) {
        // User is undoing a repost
        debugPrint("MYPULSE: Undoing repost for content $contentId");
        await ref.read(userRepostsProvider.notifier).undoRepost(contentId);

        // Check if the repost was actually removed
        final updatedReposts = ref.read(userRepostsProvider);
        final wasRemoved = updatedReposts[contentId] != true;

        if (wasRemoved) {
          debugPrint(
              "MYPULSE: Successfully removed repost for content $contentId");
          // Force a state refresh to ensure UI updates
          if (mounted) {
            setState(() {});
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Repost removed'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          debugPrint("MYPULSE: Failed to remove repost for content $contentId");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove repost'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Show bottom sheet to add optional thoughts
        final thoughts = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _RepostBottomSheet(),
        );

        if (thoughts != null) {
          // User confirmed the repost
          debugPrint(
              "MYPULSE: Reposting content $contentId with thoughts: $thoughts");
          await ref
              .read(userRepostsProvider.notifier)
              .repost(contentId, thoughts);

          // Check if the repost was actually added
          final updatedReposts = ref.read(userRepostsProvider);
          final wasAdded = updatedReposts[contentId] == true;

          if (wasAdded) {
            debugPrint("MYPULSE: Successfully reposted content $contentId");
            // Force a state refresh to ensure UI updates
            if (mounted) {
              setState(() {});
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.repeat, color: Colors.blue[400]),
                    const SizedBox(width: 8),
                    const Text('Post reposted successfully'),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            debugPrint("MYPULSE: Failed to repost content $contentId");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to repost'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Show error message
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint("MYPULSE: Error in repost: $errorMessage");

      // Check if this is actually a success message
      final isSuccessMessage =
          errorMessage.toLowerCase().contains('successfully') ||
              errorMessage.toLowerCase().contains('undone') ||
              errorMessage.toLowerCase().contains('removed');

      // Force a UI refresh
      if (mounted) {
        setState(() {});
      }

      if (isSuccessMessage) {
        // This is actually a success message
        final isUndoSuccess = errorMessage.toLowerCase().contains('undone') ||
            errorMessage.toLowerCase().contains('removed');

        if (isUndoSuccess) {
          // It was a successful undo repost
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Repost removed'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // It was a successful repost
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.repeat, color: Colors.blue[400]),
                  const SizedBox(width: 8),
                  const Text('Post reposted successfully'),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // This is a real error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Open comment bottom sheet
  void _openCommentBottomSheet(int contentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
        contentType: "user_content",
        contentId: contentId,
      ),
    );
  }
}

class _RepostBottomSheet extends StatefulWidget {
  @override
  _RepostBottomSheetState createState() => _RepostBottomSheetState();
}

class _RepostBottomSheetState extends State<_RepostBottomSheet> {
  final TextEditingController _thoughtsController = TextEditingController();

  @override
  void dispose() {
    _thoughtsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Repost this content',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add your thoughts (optional):',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _thoughtsController,
            decoration: const InputDecoration(
              hintText: 'What are your thoughts about this?',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _thoughtsController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Repost'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
