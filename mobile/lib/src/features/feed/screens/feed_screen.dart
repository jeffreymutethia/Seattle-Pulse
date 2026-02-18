import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/reaction_constants.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_bar.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_input_field.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/feed_card.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/share_bottom_sheet.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/service/user_secure_storage.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_provider.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/reaction_provider.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/repost_provider.dart';
import 'package:seattle_pulse_mobile/src/features/feed/screens/user_search_screen.dart';
import 'package:seattle_pulse_mobile/src/features/feed/widgets/comment_bottom_sheet.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';

// Location model
class Location {
  final int id;
  final String name;
  final double? latitude;
  final double? longitude;

  Location({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    try {
      return Location(
        id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        name: json['name'] as String? ?? "Unknown Location",
        latitude: json['latitude'] != null
            ? (json['latitude'] is double
                ? json['latitude']
                : double.tryParse(json['latitude'].toString()))
            : null,
        longitude: json['longitude'] != null
            ? (json['longitude'] is double
                ? json['longitude']
                : double.tryParse(json['longitude'].toString()))
            : null,
      );
    } catch (e) {
      debugPrint("Error creating Location from JSON: $e, data: $json");
      // Return a fallback location
      return Location(id: 0, name: "All Seattle");
    }
  }
}

// Location provider - lazy loaded only when dropdown is clicked
final locationsProvider =
    FutureProvider.autoDispose<List<Location>>((ref) async {
  final apiClient = ApiClient();
  try {
    final response = await apiClient.get('/content/get-seattle-locations');
    debugPrint("Locations API response statusCode: ${response.statusCode}");

    // Check if response data exists
    if (response.data != null) {
      // Directly try to extract the data array
      if (response.data['data'] != null) {
        final List<dynamic> locationsData = response.data['data'];
        debugPrint("Found ${locationsData.length} locations in response");

        final locations = locationsData
            .map((json) {
              try {
                return Location.fromJson(json);
              } catch (e) {
                debugPrint("Error parsing location: $e, raw data: $json");
                return null;
              }
            })
            .whereType<Location>()
            .toList();

        debugPrint("Successfully parsed ${locations.length} locations");
        return locations;
      } else {
        debugPrint("Response data has no 'data' field: ${response.data}");
      }
    } else {
      debugPrint("Response data is null");
    }

    // Return a default list if we couldn't parse the API response
    return [Location(id: 0, name: "All Seattle")];
  } catch (e) {
    debugPrint("Error fetching locations: $e");
    // Return a default list if the API fails
    return [Location(id: 0, name: "All Seattle")];
  }
});

// Selected location provider
final selectedLocationProvider = StateProvider<Location>((ref) {
  // Default to "All Seattle" with id 0
  return Location(id: 0, name: "All Seattle");
});

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isFirstLoad = true;
  int? _currentUserId;

  // Debug flag - set to true to show delete button for all posts (for testing)
  final bool _debugForceOwnership = false;

  @override
  void initState() {
    super.initState();

    // Debug auth state
    Future.microtask(() {
      // final authState = ref.read(authNotifierProvider);
      // debugPrint(
      //     "Auth state: isLoggedIn=${authState.isLoggedIn}, user=${authState.user != null ? 'present' : 'null'}");
      // if (authState.user != null) {
      //   debugPrint(
      //       "Current user: ID=${authState.user!.userId}, username=${authState.user!.username}");
      // }

      ref.read(contentNotifierProvider.notifier).fetchFirstPage();

      // Prefetch the locations so they're ready when the dropdown is used
      ref.refresh(locationsProvider);
    });
    _loadCurrentUser();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final contentState = ref.read(contentNotifierProvider);

    // debugPrint(
    //   "_onScroll: extentAfter=${_scrollController.position.extentAfter}, "
    //   "isLoadingMore=${contentState.isLoadingMore}, hasNext=${contentState.hasNext}",
    // );

    if (!contentState.isLoadingMore && contentState.hasNext) {
      if (_scrollController.position.extentAfter < 200) {
        ref.read(contentNotifierProvider.notifier).fetchNextPage();
      }
    }
  }

  void _loadCurrentUser() async {
    final user = await SecureStorageService.getUser();
    setState(() {
      _currentUserId = user?.userId;
    });

    debugPrint("Loaded user ID from storage: $_currentUserId");

    // Optionally also trigger content fetch here if needed
    ref.read(contentNotifierProvider.notifier).fetchFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(contentNotifierProvider);
    final userReactions = ref.watch(userReactionsProvider);
    final userReposts = ref.watch(userRepostsProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);

    // Initialize reactions and reposts when content is first loaded
    if (_isFirstLoad &&
        contentState.contents.isNotEmpty &&
        !contentState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Initialize reactions from content
        ref
            .read(userReactionsProvider.notifier)
            .initializeFromContentList(contentState.contents);

        // Initialize reposts from content
        ref
            .read(userRepostsProvider.notifier)
            .initializeFromContentList(contentState.contents);

        // Log all content that has been reposted by the user for debugging
        // debugPrint("FEED: Content with user reposts:");
        for (final content in contentState.contents) {
          if (content.hasUserReposted) {
            // debugPrint(
            //     "FEED: Content ${content.id} has been reposted by the user");
          }
        }

        _isFirstLoad = false;
        // debugPrint("FEED: Initialized reactions and reposts from content");

        // Debug repost state
        final reposts = ref.read(userRepostsProvider);
        // debugPrint("FEED: Current repost state: $reposts");
      });
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          // debugPrint("Pull-to-refresh: fetching first page again...");
          await ref.read(contentNotifierProvider.notifier).fetchFirstPage();
          // Reset first load flag to reinitialize reactions on refresh
          setState(() => _isFirstLoad = true);
        },
        child: Column(
          children: [
            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: AppInputField(
                hintText: "Search",
                labelText: "Search",
                borderRadius: 50,
                keyboardType: TextInputType.text,
                prefixIcon: const Icon(Icons.search),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserSearchScreen()),
                  );
                },
                // onChanged: (value) {
                //   if (value.trim().isNotEmpty) {
                //     ref.read(userSearchProvider.notifier).search(value.trim());
                //   }
                // },
              ),
            ),

            // Location title and dropdown section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  const Text(
                    "Happening in",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final selectedLocation =
                          ref.watch(selectedLocationProvider);
                      final locationsAsync = ref.watch(locationsProvider);

                      return locationsAsync.when(
                        data: (locations) {
                          return Container(
                            // decoration: BoxDecoration(
                            //   color: Colors.white,
                            //   borderRadius: BorderRadius.circular(20),
                            //   border: Border.all(color: Colors.grey.shade300),
                            //   boxShadow: [
                            //     BoxShadow(
                            //       color: Colors.grey.withOpacity(0.1),
                            //       spreadRadius: 1,
                            //       blurRadius: 2,
                            //       offset: const Offset(0, 1),
                            //     ),
                            //   ],
                            // ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            child: DropdownButton<int>(
                              value: selectedLocation.id,
                              underline:
                                  const SizedBox(), // Remove the default underline
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Color.fromARGB(255, 29, 29, 29)),
                              borderRadius: BorderRadius.circular(15),
                              elevation: 4,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  final selectedLoc = locations.firstWhere(
                                      (loc) => loc.id == newValue,
                                      orElse: () =>
                                          Location(id: 0, name: "All Seattle"));

                                  ref
                                      .read(selectedLocationProvider.notifier)
                                      .state = selectedLoc;

                                  // Fetch content based on selected location
                                  ref
                                      .read(contentNotifierProvider.notifier)
                                      .fetchFirstPage(
                                        locationId: selectedLoc.id == 0
                                            ? null
                                            : selectedLoc.id,
                                      );
                                }
                              },
                              items: locations.map<DropdownMenuItem<int>>(
                                  (Location location) {
                                return DropdownMenuItem<int>(
                                  value: location.id,
                                  child: Text(
                                    location.name,
                                    style: TextStyle(
                                      fontWeight:
                                          location.id == selectedLocation.id
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                        loading: () => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text("Loading...",
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        error: (error, _) => TextButton.icon(
                          icon: const Icon(Icons.refresh, color: Colors.red),
                          label: const Text("Retry",
                              style: TextStyle(color: Colors.red)),
                          onPressed: () => ref.refresh(locationsProvider),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Feed Content
            Expanded(
              child: contentState.isLoading && contentState.contents.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : contentState.contents.isEmpty
                      ? const Center(
                          child: Text("No content found. Pull to refresh."))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: contentState.contents.length + 1,
                          itemBuilder: (context, index) {
                            if (index == contentState.contents.length) {
                              if (contentState.isLoadingMore) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              } else {
                                return const SizedBox();
                              }
                            }

                            final post = contentState.contents[index];
                            final contentId = post.id;
                            final currentReaction = userReactions[contentId];
                            final hasReposted = userReposts[contentId] == true;

                            final isPostOwner = _debugForceOwnership ||
                                (_currentUserId != null &&
                                    post.user.id == _currentUserId);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: PostCard(
                                profileImageUrl: post.user.profilePictureUrl ??
                                    "https://picsum.photos/640/480?random=1",
                                name: post.user.username,
                                location: post.location,
                                timeAgo: post.timeSincePost,
                                postImageUrl: post.thumbnail ??
                                    "https://picsum.photos/640/480?random=3",
                                headline: post.title ?? "",
                                likeCount: post.reactionsCount,
                                commentCount: post.commentsCount,
                                repostCount: post.repostsCount,
                                hasReposted: hasReposted,
                                topReactions: post.topReactions,
                                contentId: post.id,
                                isOwner: isPostOwner,
                                // onVerifyOwnership: verifyOwnership,
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
                                            label: "Copy Link",
                                            icon: Icons.link),
                                        ShareOption(
                                            label: "Group", icon: Icons.group),
                                      ],
                                      onShareNow: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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

  // Handle reaction with API integration and improved error handling
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

      // debugPrint(
      //     "FEED: Handling repost for content $contentId, currently reposted: $hasReposted");

      if (hasReposted) {
        // User is undoing a repost
        // debugPrint("FEED: Undoing repost for content $contentId");
        await ref.read(userRepostsProvider.notifier).undoRepost(contentId);

        // Check if the repost was actually removed
        final updatedReposts = ref.read(userRepostsProvider);
        final wasRemoved = updatedReposts[contentId] != true;

        if (wasRemoved) {
          // debugPrint(
          // "FEED: Successfully removed repost for content $contentId");
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
          // debugPrint("FEED: Failed to remove repost for content $contentId");
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
          // debugPrint(
          //     "FEED: Reposting content $contentId with thoughts: $thoughts");
          await ref
              .read(userRepostsProvider.notifier)
              .repost(contentId, thoughts);

          // Check if the repost was actually added
          final updatedReposts = ref.read(userRepostsProvider);
          final wasAdded = updatedReposts[contentId] == true;

          if (wasAdded) {
            // debugPrint("FEED: Successfully reposted content $contentId");
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
            // debugPrint("FEED: Failed to repost content $contentId");
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
      // debugPrint("FEED: Error in repost: $errorMessage");

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

  // Show location dropdown - simplified version to just refresh locations
  void _showLocationDropdown(BuildContext context) {
    // Just refresh the locations provider when needed
    ref.refresh(locationsProvider);
  }
}

// Repost bottom sheet for adding thoughts
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
