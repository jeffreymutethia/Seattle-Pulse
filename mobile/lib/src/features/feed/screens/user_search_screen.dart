// lib/src/features/users/screens/user_search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/profile/screens/profile_screen.dart';
import '../models/search_model.dart';
import '../providers/search_provider.dart';

class UserSearchScreen extends ConsumerWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(userSearchProvider);

    return Scaffold(
      appBar: AppBar(
          leading: Icon(Icons.arrow_back_ios_new_rounded),
          title: const Text("Search")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (query) {
                if (query.isNotEmpty) {
                  ref.read(userSearchProvider.notifier).search(query);
                }
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
              ),
            ),
          ),
          if (users.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("No results found",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500)),
                    Text("Try something else"),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.profilePictureUrl),
                    ),
                    title: Text(user.name),
                    subtitle: Text(
                        "${user.location ?? 'Unknown'} · ${user.totalFollowers} followers"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            username: user.username,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}
