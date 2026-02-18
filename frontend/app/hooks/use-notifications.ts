import { useState, useEffect, useCallback } from "react";
import { io } from "socket.io-client";
import { NotificationItem, NotificationService } from "../services/notification-service";
import { getSocketUrl } from "@/lib/config";

export function useNotifications(userId: number) {
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const fetchNotifications = useCallback(async () => {
    if (!userId) return;
    setLoading(true);
    setError(null);
    try {
      const response = await NotificationService.getAllNotifications(userId);
      setNotifications(response.data);
    } catch (err: any) {
      setError(err.message || "Failed to fetch notifications");
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  useEffect(() => {
    if (!userId) return;
    // Get socket URL from config
    const socketUrl = getSocketUrl();
    
    const socket = io(socketUrl, { transports: ["websocket"] });
    socket.on("connect", () => {
    });
    socket.onAny((event, data) => {
      if (event.startsWith("notify_")) {
        if (data.user_id === userId) {
          setNotifications((prev) => [data, ...prev]);
        }
      }
    });
    return () => {
      socket.disconnect();
    };
  }, [userId]);

  const markAsRead = useCallback(async (notificationId: number) => {
    try {
      await NotificationService.markNotificationAsRead(notificationId);
      setNotifications((prev) =>
        prev.map((n) =>
          n.id === notificationId ? { ...n, is_read: true } : n
        )
      );
    } catch (err: any) {
      console.error("Failed to mark as read:", err);
    }
  }, []);

  const markAllAsRead = useCallback(async () => {
        setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })));
  }, [userId]);

  const deleteNotification = useCallback(async (notificationId: number) => {
    try {
      await NotificationService.deleteNotification(notificationId);
      setNotifications((prev) =>
        prev.filter((n) => n.id !== notificationId)
      );
    } catch (err: any) {
      console.error("Failed to delete notification:", err);
    }
  }, []);

  const deleteAllNotifications = useCallback(async () => {
    try {
      await NotificationService.deleteAllNotifications(userId);
      setNotifications([]);
    } catch (err: any) {
      console.error("Failed to delete all notifications:", err);
    }
  }, [userId]);

  const refetch = useCallback(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  return {
    notifications,
    loading,
    error,
    refetch,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    deleteAllNotifications,
  };
}
