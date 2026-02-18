import 'package:flutter/material.dart';

import 'screens/inbox_screen.dart';
import 'screens/create_group_screen.dart';

/// Entry point for the messaging feature
class MessagingFeature {
  /// Navigates to the messaging inbox screen
  static void navigateToInbox(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InboxScreen(),
      ),
    );
  }

  /// Navigates to the group creation screen
  static void navigateToCreateGroup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      ),
    );
  }

  /// Exports all the screens and components for the messaging feature
  static Widget getInboxScreen() {
    return const InboxScreen();
  }
}
