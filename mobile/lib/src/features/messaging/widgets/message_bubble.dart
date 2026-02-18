import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';

import '../models/message.dart';
import '../providers/message_provider.dart';
import '../providers/chat_provider.dart';
import '../repositories/chat_repository.dart';
import '../repositories/group_chat_repository.dart';
import 'avatar.dart';

// Define a provider for chat list refresh if it doesn't exist
final chatListRefreshProvider = StateProvider<bool>((ref) => false);

class MessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isFromMe;
  final bool showAvatar;
  final bool showTimestamp;
  final String? senderName;
  final String? senderImageUrl;
  final String bubblePosition; // single, top, middle, or bottom
  final bool isGroupChat; // Whether this is a group chat message

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromMe,
    this.showAvatar = false,
    this.showTimestamp = true,
    this.senderName,
    this.senderImageUrl,
    this.bubblePosition = 'single', // Default to single/standalone message
    this.isGroupChat = false,
  });

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  bool _isEditing = false;
  bool _isJoiningGroup = false;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Group invite link detection
  String? _inviteLink;
  bool _hasInviteLink = false;

  @override
  void initState() {
    super.initState();
    _editController.text = widget.message.content;

    // Check if the message contains a group invite link
    _checkForInviteLink();
  }

  void _checkForInviteLink() {
    // Pattern for group invite links
    final RegExp inviteLinkPattern = RegExp(
      r'https?:\/\/[^\s]*\/group\/invite\/join\?token=[^\s]+',
      caseSensitive: false,
    );

    // Find the first match
    final match = inviteLinkPattern.firstMatch(widget.message.content);

    if (match != null) {
      setState(() {
        _inviteLink = match.group(0);
        _hasInviteLink = true;
      });
      debugPrint('Found group invite link: $_inviteLink');
    }
  }

  Future<void> _joinGroup() async {
    if (_inviteLink == null || _isJoiningGroup) return;

    setState(() {
      _isJoiningGroup = true;
    });

    try {
      final repository = GroupChatRepository();

      // Show joining indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text('Joining group...'),
              ),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Try to join the group
      final success = await repository.joinGroupChatViaInviteLink(_inviteLink!);

      // Clear loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Successfully joined the group!'
                : 'Failed to join the group. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      // If successful, trigger a refresh of the chat list to show the new group
      if (success) {
        // Toggle the refresh state to trigger a chat list refresh
        ref.read(chatListRefreshProvider.notifier).state =
            !ref.read(chatListRefreshProvider);

        // Navigate back to the chat list screen after successful join
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('Error joining group: $e');

      // Clear loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isJoiningGroup = false;
      });
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _canEdit() {
    // For testing purposes, allow editing for all your own messages
    return widget.isFromMe;
  }

  bool _canDelete() {
    // For testing purposes, allow deleting for all messages
    return true;
  }

  // Build the message content with clickable link
  Widget _buildMessageContent(bool displayOnRight) {
    if (_hasInviteLink) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Regular text with highlighted link
          RichText(
            text: TextSpan(
              children:
                  _buildLinkTextSpans(widget.message.content, displayOnRight),
            ),
          ),

          // Join button
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: _isJoiningGroup
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.group_add, size: 16),
            label: Text(
              _isJoiningGroup ? 'Joining...' : 'Join Group',
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: displayOnRight ? Colors.white : Colors.blue,
              foregroundColor: displayOnRight ? Colors.blue : Colors.white,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            ),
            onPressed: _isJoiningGroup ? null : _joinGroup,
          ),
        ],
      );
    } else {
      // Regular message without invite link
      return Text(
        widget.message.content,
        style: TextStyle(
          color: displayOnRight ? Colors.white : Colors.black87,
          fontSize: 14.0,
          fontWeight: displayOnRight ? FontWeight.w500 : FontWeight.normal,
        ),
      );
    }
  }

  // Build text spans with clickable link
  List<TextSpan> _buildLinkTextSpans(String text, bool displayOnRight) {
    if (_inviteLink == null) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(
            color: displayOnRight ? Colors.white : Colors.black87,
            fontSize: 14.0,
          ),
        ),
      ];
    }

    // Split the text around the invite link
    final parts = text.split(_inviteLink!);
    final List<TextSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      // Add the text before/after link
      if (parts[i].isNotEmpty) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: TextStyle(
              color: displayOnRight ? Colors.white : Colors.black87,
              fontSize: 14.0,
            ),
          ),
        );
      }

      // Add the link (except after the last part)
      if (i < parts.length - 1) {
        spans.add(
          TextSpan(
            text: _inviteLink,
            style: TextStyle(
              color: displayOnRight ? Colors.white70 : Colors.blue,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(_inviteLink!),
          ),
        );
      }
    }

    return spans;
  }

  // Launch the URL
  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Position bubbles based on who sent the message
    // Messages FROM ME (current user) appear on the RIGHT
    // Messages FROM OTHERS appear on the LEFT
    final displayOnRight = widget.isFromMe;
    final displayOnLeft = !widget.isFromMe;

    // Debug message display
    debugPrint(
        'MessageBubble: ID=${widget.message.id}, senderId=${widget.message.senderId}, '
        'isFromMe=$displayOnRight, position=${displayOnRight ? "right" : "left"}');

    // Determine border radius based on position in group
    BorderRadius borderRadius;

    switch (widget.bubblePosition) {
      case 'top':
        borderRadius = BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: displayOnRight
              ? const Radius.circular(18)
              : const Radius.circular(4),
          bottomRight: displayOnRight
              ? const Radius.circular(4)
              : const Radius.circular(18),
        );
        break;
      case 'middle':
        borderRadius = BorderRadius.only(
          topLeft: displayOnRight
              ? const Radius.circular(18)
              : const Radius.circular(4),
          topRight: displayOnRight
              ? const Radius.circular(4)
              : const Radius.circular(18),
          bottomLeft: displayOnRight
              ? const Radius.circular(18)
              : const Radius.circular(4),
          bottomRight: displayOnRight
              ? const Radius.circular(4)
              : const Radius.circular(18),
        );
        break;
      case 'bottom':
        borderRadius = BorderRadius.only(
          topLeft: displayOnRight
              ? const Radius.circular(18)
              : const Radius.circular(4),
          topRight: displayOnRight
              ? const Radius.circular(4)
              : const Radius.circular(18),
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        );
        break;
      case 'single':
      default:
        borderRadius = BorderRadius.circular(18);
    }

    return GestureDetector(
      // Always show menu on long press regardless of permissions
      onLongPress: _showMessageActions,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
        child: Row(
          mainAxisAlignment:
              displayOnRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for OTHER USERS' messages (on the left)
            if (displayOnLeft && widget.showAvatar)
              Avatar(
                imageUrl:
                    widget.senderImageUrl ?? widget.message.sender?.imageUrl,
                size: 32.0,
                isOnline: false,
              )
            else if (displayOnLeft)
              const SizedBox(width: 32.0), // Placeholder for alignment

            if (displayOnLeft) const SizedBox(width: 8.0),

            // Message content
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: displayOnRight
                      ? const Color(0xFF1976D2) // Blue for my messages (right)
                      : const Color(0xFFF5F5F5), // Gray for others (left)
                  borderRadius: borderRadius,
                  border: displayOnRight
                      ? null
                      : Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: displayOnRight
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Show sender name for group chats
                    if (widget.senderName != null &&
                        widget.showAvatar &&
                        displayOnLeft)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          widget.senderName!,
                          style: TextStyle(
                            color: displayOnRight
                                ? Colors.white70
                                : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                      ),

                    // Message content or edit field
                    if (_isEditing && widget.isFromMe)
                      _buildEditField(displayOnRight)
                    else
                      _buildMessageContent(displayOnRight),

                    // Timestamp and read status
                    if (widget.showTimestamp)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _formatTimestamp(widget.message.timestamp),
                              style: TextStyle(
                                color: displayOnRight
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 10.0,
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            // Show read receipts only for my own messages
                            if (widget.isFromMe)
                              Icon(
                                widget.message.isRead
                                    ? Icons.done_all
                                    : Icons.done,
                                size: 12.0,
                                color: widget.message.isRead
                                    ? Colors.white70
                                    : Colors.white54,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (displayOnRight && widget.showAvatar)
              const SizedBox(width: 40.0),
          ],
        ),
      ),
    );
  }

  // Build the inline editing field
  Widget _buildEditField(bool displayOnRight) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: TextField(
            controller: _editController,
            focusNode: _focusNode,
            autofocus: true,
            style: TextStyle(
              color: displayOnRight ? Colors.white : Colors.black87,
              fontSize: 14.0,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: 'Edit message...',
              hintStyle: TextStyle(
                color: displayOnRight ? Colors.white70 : Colors.grey,
              ),
            ),
            maxLines: null,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveEdit(),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            Icons.check,
            size: 16,
            color: displayOnRight ? Colors.white : Colors.blue,
          ),
          onPressed: _saveEdit,
        ),
      ],
    );
  }

  // Show quick action buttons (edit and delete)
  void _showMessageActions() {
    final items = <PopupMenuEntry<String>>[];

    // Add edit option if user can edit
    if (_canEdit()) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: const Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
      );
    }

    // Always add copy option
    items.add(
      PopupMenuItem(
        value: 'copy',
        child: const Row(
          children: [
            Icon(Icons.copy, size: 18),
            SizedBox(width: 8),
            Text('Copy'),
          ],
        ),
      ),
    );

    // Add delete option if user can delete
    if (_canDelete()) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: const Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    // Show a simple menu at the tap position
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + size.width,
        position.dy + size.height,
      ),
      items: items,
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'edit':
          setState(() {
            _isEditing = true;
          });
          _focusNode.requestFocus();
          break;
        case 'copy':
          Clipboard.setData(ClipboardData(text: widget.message.content));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message copied to clipboard')),
          );
          break;
        case 'delete':
          _showDeleteOptions();
          break;
      }
    });
  }

  void _showDeleteOptions() {
    // Show delete options dialog for all messages
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('How would you like to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(deleteForAll: false);
              },
              child: const Text('Delete for me'),
            ),
            // For testing, allow deleting for everyone on all messages
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(deleteForAll: true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete for everyone'),
            ),
          ],
        );
      },
    );
  }

  // Save edited message
  void _saveEdit() async {
    final newContent = _editController.text.trim();
    if (newContent.isEmpty || newContent == widget.message.content) {
      setState(() {
        _isEditing = false;
      });
      return;
    }

    final chatId = widget.message.chatId ?? '';
    if (chatId.isEmpty) {
      setState(() {
        _isEditing = false;
      });
      return;
    }

    // Immediately update UI
    setState(() {
      _isEditing = false;
    });

    try {
      if (widget.isGroupChat) {
        // Edit group message
        final groupRepository = GroupChatRepository();
        final updatedMessage = await groupRepository.editGroupMessage(
            widget.message.id, newContent);

        // Update message in state
        ref
            .read(messagesProvider.notifier)
            .updateMessage(chatId, updatedMessage);
      } else {
        // Edit direct message
        final chatRepository = ChatRepository();
        final messageData =
            await chatRepository.editMessage(widget.message.id, newContent);
        final updatedMessage = Message.fromApi(messageData);

        // Update message in state
        ref
            .read(messagesProvider.notifier)
            .updateMessage(chatId, updatedMessage);
      }
    } catch (e) {
      debugPrint('Error editing message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit message: $e')),
        );
      }
    }
  }

  // Delete message
  void _deleteMessage({required bool deleteForAll}) async {
    final chatId = widget.message.chatId ?? '';
    if (chatId.isEmpty) return;

    try {
      bool success;

      if (widget.isGroupChat) {
        // Delete group message
        final groupRepository = GroupChatRepository();
        success = await groupRepository.deleteGroupMessage(widget.message.id,
            deleteForAll: deleteForAll);
      } else {
        // Delete direct message
        final chatRepository = ChatRepository();
        success = await chatRepository.deleteMessage(widget.message.id,
            deleteForAll: deleteForAll);
      }

      if (success && mounted) {
        // Remove from local state
        ref
            .read(messagesProvider.notifier)
            .removeMessage(chatId, widget.message.id);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(deleteForAll
                  ? 'Message deleted for everyone'
                  : 'Message deleted for you')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete message: $e')),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Today, show time only
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Other days, show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
