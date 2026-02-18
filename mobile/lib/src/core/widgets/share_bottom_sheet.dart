import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';

/// Simple data model for user profiles in the private message section.
class UserProfile {
  final String name;
  final String avatarUrl;

  UserProfile({
    required this.name,
    required this.avatarUrl,
  });
}

/// Simple data model for share options (icon + label).
class ShareOption {
  final String label;
  final IconData icon;

  ShareOption({
    required this.label,
    required this.icon,
  });
}

/// A bottom sheet widget resembling your provided share design.
class ShareBottomSheet extends StatelessWidget {
  /// Title/avatar for the post owner or publisher.
  final String publisherName;
  final String location;
  final String publisherAvatarUrl;

  /// Placeholder text for the "Say something about this..." field.
  final String hintText;

  /// Text for the "Share Now" button.
  final String shareButtonLabel;

  /// Label for the "Send in Private Message" section.
  final String privateMessageLabel;

  /// Label for the "Share to" section.
  final String shareToLabel;

  /// List of user profiles for the "Send in Private Message" section.
  final List<UserProfile> privateMessageProfiles;

  /// List of share options for the "Share to" section (e.g., My Story, Copy Link).
  final List<ShareOption> shareOptions;

  /// Callback when the "Share Now" button is pressed.
  final VoidCallback? onShareNow;

  /// Whether to show a drag handle at the top.
  final bool showDragHandle;

  /// Maximum height factor relative to the screen size (default 0.9 = 90%).
  final double maxHeightFactor;

  /// Background color of the bottom sheet.
  final Color backgroundColor;

  /// Radius for the top corners.
  final double topBorderRadius;

  const ShareBottomSheet({
    Key? key,
    this.publisherName = "Komo News",
    this.location = "Seattle",
    this.publisherAvatarUrl = "https://picsum.photos/40",
    this.hintText = "Say something about this...",
    this.shareButtonLabel = "Share Now",
    this.privateMessageLabel = "Send in Private Message",
    this.shareToLabel = "Share to",
    this.privateMessageProfiles = const [],
    this.shareOptions = const [],
    this.onShareNow,
    this.showDragHandle = true,
    this.maxHeightFactor = 0.6,
    this.backgroundColor = Colors.white,
    this.topBorderRadius = 32.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topBorderRadius),
          topRight: Radius.circular(topBorderRadius),
        ),
      ),
    
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional drag handle
          if (showDragHandle)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F9),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Publisher avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(publisherAvatarUrl),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Publisher name + location
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                publisherName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    location,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          // const SizedBox(height: 8),

                          TextField(
                            decoration: InputDecoration(
                              hintText: hintText,
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    Align(
                      alignment: Alignment.bottomRight,
                      child: AppButton(
                        borderRadius: 32,
                        text: "Share now",
                        onPressed: () {},
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          if (privateMessageProfiles.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section label
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      privateMessageLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Horizontally scrollable list of user profiles
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: privateMessageProfiles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final profile = privateMessageProfiles[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(profile.avatarUrl),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // "Share to" section
          if (shareOptions.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section label
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      shareToLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Horizontally scrollable share targets
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: shareOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final option = shareOptions[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                option.icon,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              option.label,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
