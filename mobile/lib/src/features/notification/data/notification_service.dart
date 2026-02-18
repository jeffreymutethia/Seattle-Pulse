import 'package:dio/dio.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/notification/data/notification_model.dart';

class NotificationService {
  final ApiClient _client = ApiClient();

  Future<List<NotificationItem>> getAllNotifications(int userId) async {
    Response response = await _client.get('/notifications/$userId');
    final data = response.data['data'] as List;
    print("data $data");
    return data.map((json) => NotificationItem.fromJson(json)).toList();
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    await _client.put('/notifications/read/$notificationId');
  }

  Future<void> markAllNotificationsAsRead(int userId) async {
    await _client.put('/notifications/read/all/$userId');
  }

  Future<void> deleteNotification(int notificationId) async {
    await _client.delete('/notifications/delete/$notificationId');
  }

  Future<void> deleteAllNotifications(int userId) async {
    await _client.delete('/notifications/delete/all/$userId');
  }
}
