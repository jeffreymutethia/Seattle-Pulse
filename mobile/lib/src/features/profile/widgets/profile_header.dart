import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/constants.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/features/profile/providers/follow_action_notifier.dart';
import 'package:seattle_pulse_mobile/src/features/profile/widgets/unfollow_dialog.dart';

class ProfileHeader extends ConsumerWidget {
  /// Determines whether we display "Edit Profile" (for the current user)
  /// or "Follow" & "Message" (for another user).
  final bool isCurrentUser;

  /// ID of the user (needed for follow/unfollow)
  final int userId;

  /// Basic user info
  final String userName;
  final String userHandle;
  final String userLocation;
  final String userAvatarUrl;
  final String bio;

  /// Stats
  final int postCount;
  final int followersCount;
  final int followingCount;

  /// Callbacks for button taps
  final VoidCallback? onEditProfile;
  final VoidCallback? onMessage;
  final VoidCallback? onFollowerCount;
  final VoidCallback? onFollowingCount;

  /// Styling parameters (optional) for easier customization
  final Color avatarBorderColor;
  final double avatarRadius;
  final TextStyle? nameTextStyle;
  final TextStyle? handleTextStyle;
  final TextStyle? locationTextStyle;
  final TextStyle? statsNumberTextStyle;
  final TextStyle? statsLabelTextStyle;
  final TextStyle? bioTextStyle;
  final ButtonStyle? editProfileButtonStyle;
  final ButtonStyle? followButtonStyle;
  final ButtonStyle? messageButtonStyle;

  final bool isFollowing;

  const ProfileHeader(
      {Key? key,
      required this.isCurrentUser,
      required this.userId,
      required this.userName,
      required this.userHandle,
      required this.userLocation,
      required this.userAvatarUrl,
      required this.bio,
      required this.postCount,
      required this.followersCount,
      required this.followingCount,
      this.onEditProfile,
      this.onMessage,
      this.onFollowerCount,
      this.onFollowingCount,
      // Default styling
      this.avatarBorderColor = Colors.white,
      this.avatarRadius = 40.0,
      this.nameTextStyle,
      this.handleTextStyle,
      this.locationTextStyle,
      this.statsNumberTextStyle,
      this.statsLabelTextStyle,
      this.bioTextStyle,
      this.editProfileButtonStyle,
      this.followButtonStyle,
      this.messageButtonStyle,
      this.isFollowing = false})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const defaultNameStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFF27364B),
    );
    const defaultHandleStyle = TextStyle(
      fontSize: 14,
      color: Color(0xFF5D6778),
    );
    const defaultLocationStyle = TextStyle(
      fontSize: 14,
      color: Color(0xFF5D6778),
    );
    const defaultStatsNumberStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    const defaultStatsLabelStyle = TextStyle(
      fontSize: 13,
      color: Color(0xFF5D6778),
    );
    const defaultBioStyle = TextStyle(
      fontSize: 14,
      color: Color(0xFF5D6778),
    );

    // Watch follow action state
    final followActionState = ref.watch(followActionProvider);
    final isLoadingFollow =
        followActionState.isLoading && followActionState.userId == userId;

    // Determine follow status
    bool isFollowingNow = isFollowing;
    if (followActionState.isSuccess && followActionState.userId == userId) {
      // If the action was successful, toggle the follow status
      isFollowingNow = !isFollowing;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Row(
            children: [
              Container(
                height: 80,
                width: 80,
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: avatarBorderColor,
                  child: CircleAvatar(
                    radius: avatarRadius - 2,
                    backgroundImage: NetworkImage(userAvatarUrl),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        style: nameTextStyle ?? defaultNameStyle,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/',
                        style: nameTextStyle ?? defaultNameStyle,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        userHandle,
                        style: handleTextStyle ?? defaultHandleStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        userLocation,
                        style: locationTextStyle ?? defaultLocationStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Stats row: Posts, Followers, Following
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        count: postCount,
                        label: 'Posts',
                        numberStyle:
                            statsNumberTextStyle ?? defaultStatsNumberStyle,
                        labelStyle:
                            statsLabelTextStyle ?? defaultStatsLabelStyle,
                      ),
                      SizedBox(width: 16),
                      isCurrentUser
                          ? GestureDetector(
                              onTap: onFollowerCount,
                              child: _buildStatItem(
                                count: followersCount,
                                label: 'Followers',
                                numberStyle: statsNumberTextStyle ??
                                    defaultStatsNumberStyle,
                                labelStyle: statsLabelTextStyle ??
                                    defaultStatsLabelStyle,
                              ),
                            )
                          : _buildStatItem(
                              count: followersCount,
                              label: 'Followers',
                              numberStyle: statsNumberTextStyle ??
                                  defaultStatsNumberStyle,
                              labelStyle:
                                  statsLabelTextStyle ?? defaultStatsLabelStyle,
                            ),
                      SizedBox(width: 16),
                      isCurrentUser
                          ? GestureDetector(
                              onTap: onFollowingCount,
                              child: _buildStatItem(
                                count: followingCount,
                                label: 'Following',
                                numberStyle: statsNumberTextStyle ??
                                    defaultStatsNumberStyle,
                                labelStyle: statsLabelTextStyle ??
                                    defaultStatsLabelStyle,
                              ),
                            )
                          : _buildStatItem(
                              count: followingCount,
                              label: 'Following',
                              numberStyle: statsNumberTextStyle ??
                                  defaultStatsNumberStyle,
                              labelStyle:
                                  statsLabelTextStyle ?? defaultStatsLabelStyle,
                            ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bio
          Text(
            bio,
            textAlign: TextAlign.start,
            style: bioTextStyle ?? defaultBioStyle,
          ),
          const SizedBox(height: 16),

          // Button(s) depending on isCurrentUser
          if (isCurrentUser)
            // "Edit Profile" Button
            AppButton(
              text: "Edit Profile",
              borderRadius: 32,
              width: double.infinity,
              onPressed: onEditProfile ?? () {},
              buttonType: ButtonType.secondary,
            )
          else
            // Follow/Following and Message buttons
            Row(
              children: [
                // Follow button (filled)
                Expanded(
                  child: isLoadingFollow
                      ? const Center(child: CircularProgressIndicator())
                      : AppButton(
                          text: isFollowingNow ? "Following" : "Follow",
                          borderRadius: 32,
                          onPressed: () {
                            if (isFollowingNow) {
                              showUnfollowDialog(context, userName)
                                  .then((confirmed) {
                                if (confirmed == true) {
                                  ref
                                      .read(followActionProvider.notifier)
                                      .unfollowUser(userId);
                                }
                              });
                            } else {
                              ref
                                  .read(followActionProvider.notifier)
                                  .followUser(userId);
                            }
                          },
                          buttonType: isFollowingNow
                              ? ButtonType.secondary
                              : ButtonType.primary,
                          backgroundColor: AppColor.color4C68D5,
                        ),
                ),

                const SizedBox(width: 8),

                // Message button
                Expanded(
                  child: AppButton(
                    text: "Message",
                    borderRadius: 32,
                    onPressed: onMessage ?? () {},
                    buttonType: ButtonType.secondary,
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required TextStyle numberStyle,
    required TextStyle labelStyle,
  }) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: numberStyle,
        ),
        Text(
          label,
          style: labelStyle,
        ),
      ],
    );
  }
}
