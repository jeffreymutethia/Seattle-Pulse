import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_user.dart';
import '../providers/user_provider.dart';
import '../widgets/avatar.dart';
import '../repositories/group_chat_repository.dart';

class SelectUsersScreen extends ConsumerStatefulWidget {
  final List<ChatUser>? initialSelectedUsers;
  final String? groupId;
  final String? groupName;

  const SelectUsersScreen({
    Key? key,
    this.initialSelectedUsers,
    this.groupId,
    this.groupName,
  }) : super(key: key);

  @override
  ConsumerState<SelectUsersScreen> createState() => _SelectUsersScreenState();
}

class _SelectUsersScreenState extends ConsumerState<SelectUsersScreen> {
  late List<ChatUser> _selectedUsers;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _inviteLink;
  bool _isSending = false;
  String? _errorMessage;
  final Map<String, bool> _sentInviteStatus = {};

  @override
  void initState() {
    super.initState();
    _selectedUsers = widget.initialSelectedUsers != null
        ? List.from(widget.initialSelectedUsers!)
        : [];

    // Force refresh of users list
    setState(() {
      _isLoading = true;
    });

    Future.microtask(() async {
      // First load the users
      await ref.read(followingUsersProvider.notifier).fetchFollowingUsers();

      // Then generate invite link if this is for inviting to a group
      if (widget.groupId != null) {
        await _generateInviteLink();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _generateInviteLink() async {
    if (widget.groupId == null) return;

    try {
      final repository = GroupChatRepository();
      final link = await repository.generateGroupInviteLink(widget.groupId!);

      if (mounted) {
        setState(() {
          _inviteLink = link;
        });
      }

      debugPrint('Generated invite link: $_inviteLink');
    } catch (e) {
      debugPrint('Error generating invite link: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not generate invite link: $e';
        });
      }
    }
  }

  Future<void> _sendInviteToSelectedUser(ChatUser user) async {
    // Already sending
    if (_isSending) return;

    // Check if we're in invite mode
    if (widget.groupId == null || widget.groupName == null) {
      Navigator.pop(context, [user]);
      return;
    }

    // Make sure we have an invite link
    if (_inviteLink == null) {
      await _generateInviteLink();
      if (_inviteLink == null) {
        setState(() {
          _errorMessage = 'Failed to generate invite link. Please try again.';
        });
        return;
      }
    }

    setState(() {
      _isSending = true;
    });

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Sending invite to ${user.name}...'),
            ),
          ],
        ),
        duration:
            const Duration(seconds: 30), // Long duration as it might take time
      ),
    );

    try {
      final repository = GroupChatRepository();

      // Create personalized message
      final message =
          'Hey! Join our group "${widget.groupName}" with this link: $_inviteLink';

      // Send the invite
      debugPrint('Sending invite to ${user.name} (${user.id})');
      final success = await repository.sendGroupInviteToUser(
        user.id,
        widget.groupId!,
        message: message,
      );

      // Clear loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Update state
      if (mounted) {
        setState(() {
          _isSending = false;
          _sentInviteStatus[user.id] = success;
        });
      }

      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Successfully sent invite to ${user.name}'
                : 'Failed to send invite to ${user.name}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
          action: success
              ? null
              : SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _sendInviteToSelectedUser(user),
                ),
        ),
      );
    } catch (e) {
      // Clear loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      debugPrint('Error sending invite: $e');

      if (mounted) {
        setState(() {
          _isSending = false;
          _sentInviteStatus[user.id] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _sendInviteToSelectedUser(user),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the API-backed providers
    final filteredUsers = ref.watch(filteredUsersProvider);
    final fetchState = ref.watch(userFetchStateProvider);
    final isApiLoading = fetchState == UserFetchState.loading;

    // Combined loading state
    final isLoading = _isLoading || isApiLoading;

    // Set screen title based on whether we're inviting or selecting
    final isInviteMode = widget.groupId != null;
    final screenTitle = isInviteMode ? 'Select User to Invite' : 'Select Users';

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        actions: [
          if (!isInviteMode)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedUsers);
              },
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
              onChanged: (value) {
                ref.read(userSearchQueryProvider.notifier).state = value;
                if (value.isNotEmpty) {
                  // Search with API
                  ref.read(followingUsersProvider.notifier).searchUsers(value);
                }
              },
            ),
          ),
          if (!isInviteMode && _selectedUsers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _selectedUsers.map((user) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundImage: user.imageUrl != null
                              ? NetworkImage(user.imageUrl!)
                              : null,
                          child: user.imageUrl == null
                              ? Text(user.name[0].toUpperCase())
                              : null,
                        ),
                        label: Text(user.name),
                        onDeleted: () {
                          setState(() {
                            _selectedUsers.remove(user);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (filteredUsers.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No users found'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final isSelected = _selectedUsers.any((u) => u.id == user.id);

                  // Check if we already sent an invite to this user
                  final hasSentInvite = _sentInviteStatus.containsKey(user.id);
                  final inviteSuccess = _sentInviteStatus[user.id] ?? false;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Avatar(
                          imageUrl: user.imageUrl,
                          size: 40.0,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: user.username != null
                            ? Text('@${user.username}')
                            : null,
                        trailing: isInviteMode
                            ? ElevatedButton.icon(
                                icon: hasSentInvite
                                    ? Icon(
                                        inviteSuccess
                                            ? Icons.check
                                            : Icons.error,
                                        color: inviteSuccess
                                            ? Colors.green
                                            : Colors.red,
                                      )
                                    : const Icon(Icons.send),
                                label: Text(
                                  hasSentInvite
                                      ? (inviteSuccess ? 'Sent' : 'Failed')
                                      : 'Send Invite',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasSentInvite
                                      ? (inviteSuccess
                                          ? Colors.green
                                          : Colors.red)
                                      : Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isSending ||
                                        (hasSentInvite && inviteSuccess)
                                    ? null
                                    : () => _sendInviteToSelectedUser(user),
                              )
                            : IconButton(
                                icon: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.add_circle_outline,
                                  color: isSelected ? Colors.green : null,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedUsers
                                          .removeWhere((u) => u.id == user.id);
                                    } else {
                                      _selectedUsers.add(user);
                                    }
                                  });
                                },
                              ),
                        onTap: isInviteMode
                            ? () => _sendInviteToSelectedUser(user)
                            : () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedUsers
                                        .removeWhere((u) => u.id == user.id);
                                  } else {
                                    _selectedUsers.add(user);
                                  }
                                });
                              },
                      ),
                      if (hasSentInvite)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 72.0, right: 16.0, bottom: 8.0),
                          child: Text(
                            inviteSuccess
                                ? 'Successfully sent invite!'
                                : 'Failed to send invite. Try again.',
                            style: TextStyle(
                              color: inviteSuccess
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      const Divider(height: 1),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
