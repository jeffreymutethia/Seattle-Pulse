import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/utils/time_ago.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/service/user_secure_storage.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  Future<int?> getUserId() async {
    final user = await SecureStorageService.getUser();
    return user?.userId;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<int?>(
      future: getUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('User not found.')),
          );
        }

        final userId = snapshot.data!;
        final state = ref.watch(notificationProvider(userId));
        final notifier = ref.read(notificationProvider(userId).notifier);

        final sortedNotifications = [...state.notifications]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: state.loading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(child: Text('Error: ${state.error}'))
                  : state.notifications.isEmpty
                      ? const Center(child: Text('No notifications.'))
                      : RefreshIndicator(
                          onRefresh: () async {
                            await notifier.refetch();
                          },
                          child: ListView(
                            children: [
                              // Padding(
                              //   padding: const EdgeInsets.all(16.0),
                              //   child: Row(
                              //     mainAxisAlignment: MainAxisAlignment.center,
                              //     children: [
                              //       if (state.notifications.isNotEmpty)
                              //         AppButton(
                              //           text: "Mark All as Read",
                              //           onPressed: () async {
                              //             await notifier.markAllAsRead();
                              //           },
                              //         ),
                              //       const SizedBox(width: 16),
                              //       if (state.notifications.isNotEmpty)
                              //         AppButton(
                              //           text: "Delete All",
                              //           onPressed: () async {
                              //             await notifier
                              //                 .deleteAllNotifications();
                              //           },
                              //         ),
                              //     ],
                              //   ),
                              // ),
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'New',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black),
                                ),
                              ),
                              ...sortedNotifications
                                  .where((n) => !n.isRead)
                                  .map(
                                    (notification) => Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F4F9),
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Color(0xFFE2E8F0),
                                              width: 2),
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          radius: 24,
                                          backgroundImage: NetworkImage(notification
                                                      .postId !=
                                                  null
                                              ? 'https://picsum.photos/id/1/200'
                                              : 'https://picsum.photos/id/1/200'),
                                        ),
                                        title: Text(
                                          notification.content,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Text(
                                            timeAgo(notification.createdAt
                                                .toIso8601String()),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF4B5669)),
                                          ),
                                        ),
                                        onTap: () async {
                                          await notifier
                                              .markAsRead(notification.id);
                                        },
                                      ),
                                    ),
                                  ),
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Earlier',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black),
                                ),
                              ),
                              ...sortedNotifications.where((n) => n.isRead).map(
                                    (notification) => ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(notification
                                                    .postId !=
                                                null
                                            ? 'https://picsum.photos/id/1/200'
                                            : 'https://picsum.photos/id/1/200'),
                                      ),
                                      title: Text(
                                        notification.content,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: Text(
                                          timeAgo(notification.createdAt
                                              .toIso8601String()),
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF4B5669)),
                                        ),
                                      ),
                                      onTap: () {},
                                    ),
                                  ),
                            ],
                          ),
                        ),
        );
      },
    );
  }
}
