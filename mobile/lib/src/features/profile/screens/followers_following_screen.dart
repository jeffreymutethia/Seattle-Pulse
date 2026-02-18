/// followers_following_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/follower_model.dart';
import 'package:seattle_pulse_mobile/src/features/profile/providers/follow_action_notifier.dart';
import 'package:seattle_pulse_mobile/src/features/profile/providers/follow_state.dart';
import 'package:seattle_pulse_mobile/src/features/profile/widgets/unfollow_dialog.dart';

class FollowersFollowingScreen extends ConsumerStatefulWidget {
  final String username;

  const FollowersFollowingScreen({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  ConsumerState<FollowersFollowingScreen> createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState
    extends ConsumerState<FollowersFollowingScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load followers and following data
    Future.microtask(() {
      ref.read(followersProvider.notifier).fetchFollowers();
      ref.read(followingProvider.notifier).fetchFollowing();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Search followers or following
  void _handleSearch(bool isFollowersTab) {
    final searchQuery = _searchController.text.trim();

    if (isFollowersTab) {
      ref.read(followersProvider.notifier).fetchFollowers(
          searchQuery: searchQuery.isNotEmpty ? searchQuery : null);
    } else {
      ref.read(followingProvider.notifier).fetchFollowing(
          searchQuery: searchQuery.isNotEmpty ? searchQuery : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch followers and following state
    final followersState = ref.watch(followersProvider);
    final followingState = ref.watch(followingProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.white,
          title: Text(
            widget.username,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: TabBar(
            dividerColor: const Color.fromARGB(255, 233, 233, 233),
            labelColor: AppColor.color4C68D5,
            unselectedLabelColor: AppColor.colorABB0B9,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color: AppColor.color4C68D5,
                width: 3,
              ),
            ),
            tabs: [
              Tab(
                child: Text(
                  "${followersState.total} Followers",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  "${followingState.total} Following",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      final isFollowersTab =
                          DefaultTabController.of(context).index == 0;
                      _handleSearch(isFollowersTab);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onSubmitted: (_) {
                  final isFollowersTab =
                      DefaultTabController.of(context).index == 0;
                  _handleSearch(isFollowersTab);
                },
              ),
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  // Followers tab
                  _buildFollowersTab(followersState),
                  // Following tab
                  _buildFollowingTab(followingState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowersTab(FollowersState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text(state.error!));
    }

    final followers = state.followers;
    if (followers == null || followers.isEmpty) {
      return const Center(child: Text("No followers found"));
    }

    return _buildUserListView(followers, isFollowers: true);
  }

  Widget _buildFollowingTab(FollowingState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text(state.error!));
    }

    final following = state.following;
    if (following == null || following.isEmpty) {
      return const Center(child: Text("You are not following anyone yet"));
    }

    return _buildUserListView(following, isFollowers: false);
  }

  Widget _buildUserListView(List<FollowerUser> users,
      {required bool isFollowers}) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundImage: NetworkImage(
                    user.profilePictureUrl ?? "https://picsum.photos/40/40"),
                radius: 26,
              ),
              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColor.color0C1024,
                      ),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty)
                      Text(
                        user.bio!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColor.color838B98,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Follow/Unfollow button
              _buildFollowButton(user),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowButton(FollowerUser user) {
    final followActionState = ref.watch(followActionProvider);
    final isLoading =
        followActionState.isLoading && followActionState.userId == user.id;

    if (isLoading) {
      return const SizedBox(
        width: 100,
        height: 42,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (user.isFollowing) {
      return AppButton(
        text: "Following",
        fontSize: 13,
        paddingVertical: 0,
        paddingHorizontal: 5,
        fontWeight: FontWeight.w600,
        height: 42,
        width: 100,
        buttonType: ButtonType.secondary,
        onPressed: () {
          showUnfollowDialog(context, user.fullName).then((confirmed) {
            if (confirmed == true) {
              ref.read(followActionProvider.notifier).unfollowUser(user.id);
            }
          });
        },
      );
    } else {
      return AppButton(
        text: "Follow",
        fontSize: 13,
        paddingVertical: 0,
        paddingHorizontal: 10,
        fontWeight: FontWeight.w600,
        height: 42,
        width: 100,
        onPressed: () {
          ref.read(followActionProvider.notifier).followUser(user.id);
        },
      );
    }
  }
}
