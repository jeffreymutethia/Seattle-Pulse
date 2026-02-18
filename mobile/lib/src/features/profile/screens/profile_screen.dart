import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_bar.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/service/user_secure_storage.dart';
import 'package:seattle_pulse_mobile/src/features/profile/screens/followers_following_screen.dart';
import 'package:seattle_pulse_mobile/src/features/profile/widgets/profile_header.dart';
import 'package:seattle_pulse_mobile/src/features/profile/widgets/profile_tabs.dart';
import 'package:seattle_pulse_mobile/src/features/setting/screens/setting_screen.dart';
import '../providers/user_profile_provider.dart';
import '../providers/user_posts_provider.dart';
import '../providers/user_reposts_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isCurrentUser = false;
  bool _checkedUser = false;

  @override
  void initState() {
    super.initState();

    // Fetch all profile-related data
    Future.microtask(() async {
      ref
          .read(userProfileNotifierProvider(widget.username).notifier)
          .fetchUserProfile();
      ref
          .read(userPostsNotifierProvider(widget.username).notifier)
          .fetchUserPosts();
      ref
          .read(userRepostsNotifierProvider(widget.username).notifier)
          .fetchUserReposts();

      final user = await SecureStorageService.getUser();
      if (user != null && user.username == widget.username) {
        setState(() {
          _isCurrentUser = true;
        });
      }

      setState(() {
        _checkedUser = true;
      });
    });
  }

  void _navigateToFollowersFollowing({bool followersTab = true}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersFollowingScreen(
          username: widget.username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState =
        ref.watch(userProfileNotifierProvider(widget.username));
    final postsState = ref.watch(userPostsNotifierProvider(widget.username));
    final repostsState =
        ref.watch(userRepostsNotifierProvider(widget.username));

    final isLoading = profileState.isLoading ||
        postsState.isLoading ||
        repostsState.isLoading;

    final hasError = profileState.error != null ||
        postsState.error != null ||
        repostsState.error != null;

    final profileData = profileState.profileData;
    final postImages =
        postsState.postsData?.posts.map((e) => e.post.thumbnail).toList() ?? [];
    final repostImages =
        repostsState.repostsData?.reposts.map((e) => e.thumbnail).toList() ??
            [];

    return Scaffold(
      appBar: const CustomAppBar(title: "Profile"),
      body: SafeArea(
        child: !_checkedUser
            ? const Center(child: CircularProgressIndicator())
            : isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError || profileData == null
                    ? const Center(child: Text("Something went wrong"))
                    : Column(
                        children: [
                          ProfileHeader(
                            isCurrentUser: _isCurrentUser,
                            userId: profileData.userData.id,
                            userName:
                                "${profileData.userData.firstName} ${profileData.userData.lastName}",
                            userHandle: "@${profileData.userData.username}",
                            userLocation:
                                profileData.userData.location ?? "Seattle",
                            userAvatarUrl:
                                profileData.userData.profilePictureUrl,
                            bio: profileData.userData.bio,
                            postCount: profileData.relationships.totalPosts,
                            followersCount: profileData.relationships.followers,
                            followingCount: profileData.relationships.following,
                            isFollowing: profileData.isFollowing,
                            onFollowerCount: () =>
                                _navigateToFollowersFollowing(
                                    followersTab: true),
                            onFollowingCount: () =>
                                _navigateToFollowersFollowing(
                                    followersTab: false),
                            onEditProfile: _isCurrentUser
                                ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SettingScreen(),
                                      ),
                                    )
                                : null,
                            onMessage: !_isCurrentUser
                                ? () => debugPrint("Message user tapped")
                                : null,
                          ),
                          Expanded(
                            child: ProfileTabsWidget(
                              postImages: postImages,
                              repostImages: repostImages,
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}
