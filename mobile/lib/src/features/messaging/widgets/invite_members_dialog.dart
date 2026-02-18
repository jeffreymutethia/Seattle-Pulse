import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_user.dart';
import '../repositories/group_chat_repository.dart';
import '../screens/select_users_screen.dart';

class InviteMembersDialog extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const InviteMembersDialog({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  ConsumerState<InviteMembersDialog> createState() =>
      _InviteMembersDialogState();
}

class _InviteMembersDialogState extends ConsumerState<InviteMembersDialog> {
  final GroupChatRepository _repository = GroupChatRepository();

  // States
  String? _inviteLink;
  String? _errorMessage;
  bool _isLoading = false;
  bool _linkCopied = false;

  @override
  void initState() {
    super.initState();
    // Generate invite link immediately when dialog opens
    _generateInviteLink();
  }

  Future<void> _generateInviteLink() async {
    // Skip if we already have a link
    if (_inviteLink != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Generating invite link for group ${widget.groupId}...');
      final link = await _repository.generateGroupInviteLink(widget.groupId);

      setState(() {
        _inviteLink = link;
        _isLoading = false;
      });

      debugPrint('✅ Successfully generated invite link: $_inviteLink');
    } catch (e) {
      debugPrint('❌ Error generating invite link: $e');
      setState(() {
        _errorMessage = 'Could not generate invite link. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _copyLinkToClipboard() {
    if (_inviteLink == null) return;

    Clipboard.setData(ClipboardData(text: _inviteLink!));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );

    setState(() {
      _linkCopied = true;
    });

    // Reset copy icon after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _linkCopied = false;
        });
      }
    });
  }

  void _openSelectUsersScreen() {
    // Close this dialog first
    Navigator.of(context).pop();

    // Open the user selection screen in invite mode by passing group info
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectUsersScreen(
          groupId: widget.groupId,
          groupName: widget.groupName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Invite to "${widget.groupName}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Loading indicator for initial link generation
            if (_isLoading) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating invite link...'),
                  ],
                ),
              ),
            ] else ...[
              // Invite link section
              if (_inviteLink != null) ...[
                const Text(
                  'Share this link to join the group:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _inviteLink!,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(_linkCopied ? Icons.check : Icons.copy),
                        color: _linkCopied ? Colors.green : null,
                        tooltip: 'Copy to clipboard',
                        onPressed: _copyLinkToClipboard,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
              ],

              // Action buttons
              const Text(
                'Choose how to invite members:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Copy link button
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _inviteLink == null ? null : _copyLinkToClipboard,
              ),

              const SizedBox(height: 8),

              // Select user to invite button
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Send Invite to User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _openSelectUsersScreen,
              ),

              const SizedBox(height: 16),
              Text(
                'Note: Click "Send Invite to User" to select a user and directly send the invite to them.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
