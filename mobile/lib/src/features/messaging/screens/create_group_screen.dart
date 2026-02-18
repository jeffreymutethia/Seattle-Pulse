import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../models/chat_user.dart';
import '../repositories/group_chat_repository.dart';
import '../providers/user_provider.dart';
import '../widgets/avatar.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  final List<ChatUser>? initialUsers;

  const CreateGroupScreen({Key? key, this.initialUsers}) : super(key: key);

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<ChatUser> _selectedUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  Chat? _createdGroup;

  @override
  void initState() {
    super.initState();
    if (widget.initialUsers != null && widget.initialUsers!.isNotEmpty) {
      _selectedUsers.addAll(widget.initialUsers!);
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = GroupChatRepository();
      final newGroup =
          await repository.createGroupChat(_groupNameController.text);

      // Store the created group for later use
      setState(() {
        _createdGroup = newGroup;
      });

      // Add selected users to group
      for (final user in _selectedUsers) {
        await repository.addMemberToGroup(newGroup.id, user.id);
      }

      // Navigate back with success
      if (mounted) {
        Navigator.pop(context, newGroup);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create group: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter a name for your group',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedUsers.isNotEmpty) ...[
                const Text(
                  'Selected Members:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                const SizedBox(height: 16),
              ],
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Group'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectUsersScreen(
                              selectedUsers: _selectedUsers,
                            ),
                          ),
                        ).then((selectedUsers) {
                          if (selectedUsers != null) {
                            setState(() {
                              _selectedUsers.clear();
                              _selectedUsers.addAll(selectedUsers);
                            });
                          }
                        });
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add Members'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectUsersScreen extends ConsumerStatefulWidget {
  final List<ChatUser> selectedUsers;

  const SelectUsersScreen({Key? key, required this.selectedUsers})
      : super(key: key);

  @override
  ConsumerState<SelectUsersScreen> createState() => _SelectUsersScreenState();
}

class _SelectUsersScreenState extends ConsumerState<SelectUsersScreen> {
  late List<ChatUser> _selectedUsers;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedUsers = List.from(widget.selectedUsers);

    // Force refresh of users list
    Future.microtask(() {
      ref.read(followingUsersProvider.notifier).fetchFollowingUsers();
    });
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
    final isLoading = fetchState == UserFetchState.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Members'),
        actions: [
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
          if (_selectedUsers.isNotEmpty) ...[
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

                  return ListTile(
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
                    trailing: IconButton(
                      icon: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                        color: isSelected ? Colors.green : null,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isSelected) {
                            _selectedUsers.removeWhere((u) => u.id == user.id);
                          } else {
                            _selectedUsers.add(user);
                          }
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedUsers.removeWhere((u) => u.id == user.id);
                        } else {
                          _selectedUsers.add(user);
                        }
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
