// services/notification-service.ts

import { apiClient } from "../api/api-client";


export interface NotificationItem {
  id: number;
  user_id: number;
  content: string;
  is_read: boolean;
  created_at: string;
  post_id: number | null;
  sender_id: number | null;
  type: string;
}




export const NotificationService = {
  async getAllNotifications(userId: number) {
    return apiClient.get<{ status: string; message: string; data: NotificationItem[] }>(
      `/notifications/${userId}`
    );
  },

  async markNotificationAsRead(notificationId: number) {
    return apiClient.put<{ status: string; message: string }>(
      `/notifications/read/${notificationId}`
    );
  },

  async deleteNotification(notificationId: number) {
    return apiClient.delete<{ status: string; message: string }>(
      `/notifications/delete/${notificationId}`
    );
  },

  async deleteAllNotifications(userId: number) {
    return apiClient.delete<{ status: string; message: string }>(
      `/notifications/delete/all/${userId}`
    );
  },

  async markAllNotificationsAsRead(userId: number) {
    return apiClient.put<{ status: string; message: string }>(
      `/notifications/read/all/${userId}`
    );
  },
};
