import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/notification/data/notification_model.dart';
import 'package:seattle_pulse_mobile/src/features/notification/data/notification_service.dart';


class NotificationState {
  final List<NotificationItem> notifications;
  final bool loading;
  final String? error;

  NotificationState({required this.notifications, this.loading = false, this.error});

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? loading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;
  final int userId;

  NotificationNotifier({required this.userId})
      : _service = NotificationService(),
        super(NotificationState(notifications: [], loading: true)) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      state = state.copyWith(loading: true, error: null);
      final notifications = await _service.getAllNotifications(userId);
      state = state.copyWith(notifications: notifications, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _service.markNotificationAsRead(notificationId);
      state = state.copyWith(
          notifications: state.notifications.map((n) {
        if (n.id == notificationId) {
          return NotificationItem(
            id: n.id,
            userId: n.userId,
            content: n.content,
            isRead: true,
            createdAt: n.createdAt,
            postId: n.postId,
            senderId: n.senderId,
            type: n.type,
          );
        }
        return n;
      }).toList());
    } catch (e) {
      // handle error if needed
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllNotificationsAsRead(userId);
      state = state.copyWith(
          notifications: state.notifications
              .map((n) => NotificationItem(
                    id: n.id,
                    userId: n.userId,
                    content: n.content,
                    isRead: true,
                    createdAt: n.createdAt,
                    postId: n.postId,
                    senderId: n.senderId,
                    type: n.type,
                  ))
              .toList());
    } catch (e) {
      // handle error
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      await _service.deleteNotification(notificationId);
      state = state.copyWith(
          notifications:
              state.notifications.where((n) => n.id != notificationId).toList());
    } catch (e) {
      // handle error
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      await _service.deleteAllNotifications(userId);
      state = state.copyWith(notifications: []);
    } catch (e) {
      // handle error
    }
  }

  Future<void> refetch() async {
    await fetchNotifications();
  }
}

final notificationProvider = StateNotifierProvider.family<NotificationNotifier, NotificationState, int>(
  (ref, userId) => NotificationNotifier(userId: userId),
);
