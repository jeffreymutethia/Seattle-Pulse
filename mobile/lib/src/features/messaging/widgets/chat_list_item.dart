import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../providers/chat_provider.dart';
import 'avatar.dart';

class ChatListItem extends ConsumerWidget {
  final Chat chat;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user ID
    final currentUserId = ref.watch(currentUserIdProvider);

    // Check if participants list is empty to avoid "No element" error
    if (chat.participants.isEmpty) {
      debugPrint('Warning: Chat ${chat.id} has no participants');
    }

    // Find the other user in a private chat (not the current user)
    // Added safe handling for empty participants list
    final otherUser =
        chat.type == ChatType.private && chat.participants.isNotEmpty
            ? chat.participants
                    .where((user) => user.id != currentUserId)
                    .firstOrNull ??
                (chat.participants.isNotEmpty ? chat.participants.first : null)
            : null;

    // Use the other user's online status for private chats
    final isOnline = chat.type == ChatType.private && otherUser != null
        ? otherUser.isOnline
        : false;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Avatar(
              imageUrl: chat.imageUrl,
              isOnline: isOnline,
              size: 56,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  if (chat.lastMessage != null)
                    _buildLastMessageText(chat, currentUserId),
                ],
              ),
            ),
            if (chat.lastMessage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(chat.lastMessage!.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  if (!chat.lastMessage!.isRead &&
                      chat.lastMessage!.senderId != currentUserId)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastMessageText(Chat chat, String currentUserId) {
    final lastMessage = chat.lastMessage!;

    // For group chats, show sender name + message
    if (chat.isGroupChat) {
      String senderName = '';

      // Get sender name from the message
      if (lastMessage.sender != null) {
        // Use first name if available
        senderName = lastMessage.sender!.firstName ??
            (lastMessage.sender!.name.split(' ').first);
      }

      // Check if the sender is the current user
      final isFromCurrentUser = lastMessage.senderId == currentUserId;
      final prefix = isFromCurrentUser ? 'You: ' : '$senderName: ';

      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.0,
          ),
          children: [
            TextSpan(
              text: prefix,
              style: TextStyle(
                fontWeight:
                    isFromCurrentUser ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            TextSpan(text: lastMessage.content),
          ],
        ),
      );
    } else {
      // For direct chats, just show the message
      return Text(
        lastMessage.content,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14.0,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      // Format as HH:MM
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      // Format as MM/DD
      return '${time.month}/${time.day}';
    }
  }
}
