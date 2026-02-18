import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/group_chat_repository.dart';
import '../screens/chat_screen.dart';
import '../models/chat.dart';

class DeepLinkHandler {
  // Singleton instance
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final GroupChatRepository _groupRepository = GroupChatRepository();

  // Process a deep link
  Future<void> processDeepLink(
      String link, BuildContext context, WidgetRef ref) async {
    debugPrint("Processing deep link: $link");

    try {
      // Check if it's a group invite link
      if (link.contains('group/invite') || link.contains('token=')) {
        await _handleGroupInvite(link, context);
        return;
      }

      // Other deep link types can be handled here
      debugPrint("Unknown deep link format: $link");
    } catch (e) {
      debugPrint("Error processing deep link: $e");
      // Show error dialog/snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Extract token from URL
  String? _extractToken(String url) {
    // Check if the URL contains a token parameter
    final tokenParam = RegExp(r'token=([^&]+)').firstMatch(url);
    if (tokenParam != null && tokenParam.groupCount >= 1) {
      return tokenParam.group(1);
    }

    // No token found in URL
    return null;
  }

  // Handle group invitation link
  Future<void> _handleGroupInvite(String link, BuildContext context) async {
    // Extract token from URL
    final token = _extractToken(link);
    if (token == null) {
      throw Exception('Invalid invitation link');
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Joining group...'),
          ],
        ),
      ),
    );

    try {
      // Join the group
      final groupData = await _groupRepository.joinGroupViaInviteToken(token);

      // Close the loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined the group!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the group chat if we have enough data
      if (groupData['group_chat_id'] != null) {
        final groupId = groupData['group_chat_id'].toString();
        final groupName = groupData['group_name'] as String? ?? 'Group Chat';

        // Create a simple Chat object with the available data
        final groupChat = Chat(
          id: groupId,
          name: groupName,
          type: ChatType.group,
          participants: [],
        );

        // Navigate to the chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: groupId,
              chat: groupChat,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error Joining Group'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

// Provider for the deep link handler
final deepLinkHandlerProvider = Provider<DeepLinkHandler>((ref) {
  return DeepLinkHandler();
});
