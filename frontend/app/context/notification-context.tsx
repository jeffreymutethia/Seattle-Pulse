// /app/context/NotificationContext.tsx
"use client";

import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  ReactNode,
} from "react";
import { io, Socket } from "socket.io-client";
import {
  NotificationItem,
  NotificationService,
} from "../services/notification-service";

import { API_BASE_URL_NOTIFICATION } from "@/lib/config";


interface NotificationContextType {
  notifications: NotificationItem[];
  notificationCount: number;
  loading: boolean;
  error: string | null;
  fetchNotifications: () => Promise<void>;
  markAllAsRead: () => Promise<void>;
  markAsRead: (id: number) => Promise<void>;
  deleteNotification: (id: number) => Promise<void>;
  deleteAllNotifications: () => Promise<void>;
  refetch: () => Promise<void>;
  addNotification: (notif: NotificationItem) => void;
  globalSocket: Socket | null; // expose the socket to use in other hooks if needed
}

const NotificationContext = createContext<NotificationContextType | undefined>(
  undefined
);

let globalSocket: Socket | null = null;

export function NotificationProvider({ children }: { children: ReactNode }) {
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [userId, setUserId] = useState<number | null>(null);

  useEffect(() => {
    const storedUserId = sessionStorage.getItem("user_id");
    if (storedUserId) {
      setUserId(parseInt(storedUserId, 10));
    }
  }, []);

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
    if (userId) {
      fetchNotifications();
    }
  }, [userId, fetchNotifications]);

  useEffect(() => {
    if (!userId) return;
    if (!globalSocket) {
      globalSocket = io(API_BASE_URL_NOTIFICATION, { transports: ["websocket"] });
    }

    globalSocket.on("connect", () => {
    });

    globalSocket.onAny((event, data) => {

      // If event looks like "notify_xxx", check the data
      if (event.startsWith("notify_")) {
        // If it's a chat message => data.chat_id might exist
        if (data.chat_id) {
          // We'll handle new chat messages in the chat hook (useDirectMessages),
          // so no direct action needed here. But we could do something if we want
          // to update chat list or something else.
        }
        // If it's a normal notification
        else if (data.user_id === userId) {
          setNotifications((prev) => [data, ...prev]);
        }
      }
    });

    globalSocket.on("disconnect", () => {
    });

    return () => {
      globalSocket?.disconnect();
      globalSocket = null;
    };
  }, [userId]);

  // 3) Notification actions
  const markAsRead = useCallback(async (id: number) => {
    try {
      await NotificationService.markNotificationAsRead(id);
      setNotifications((prev) =>
        prev.map((n) => (n.id === id ? { ...n, is_read: true } : n))
      );
    } catch (err: any) {
      console.error("Error marking notification as read:", err);
    }
  }, []);

  const markAllAsRead = useCallback(async () => {
    if (!userId) return;
    try {
      await NotificationService.markAllNotificationsAsRead(userId);
      setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })));
    } catch (err: any) {
      console.error("Error marking all as read:", err);
    }
  }, [userId]);

  const deleteNotification = useCallback(async (id: number) => {
    try {
      await NotificationService.deleteNotification(id);
      setNotifications((prev) => prev.filter((n) => n.id !== id));
    } catch (err: any) {
      console.error("Error deleting notification:", err);
    }
  }, []);

  const deleteAllNotifications = useCallback(async () => {
    if (!userId) return;
    try {
      await NotificationService.deleteAllNotifications(userId);
      setNotifications([]);
    } catch (err: any) {
      console.error("Error deleting all notifications:", err);
    }
  }, [userId]);

  const refetch = useCallback(async () => {
    await fetchNotifications();
  }, [fetchNotifications]);

  const addNotification = useCallback((notif: NotificationItem) => {
    setNotifications((prev) => [notif, ...prev]);
  }, []);

  const notificationCount = notifications.filter((n) => !n.is_read).length;

  return (
    <NotificationContext.Provider
      value={{
        notifications,
        notificationCount,
        loading,
        error,
        fetchNotifications,
        markAllAsRead,
        markAsRead,
        deleteNotification,
        deleteAllNotifications,
        refetch,
        addNotification,
        globalSocket,
      }}
    >
      {children}
    </NotificationContext.Provider>
  );
}

export function useNotificationContext() {
  const ctx = useContext(NotificationContext);
  if (!ctx) {
    throw new Error(
      "useNotificationContext must be used within a NotificationProvider"
    );
  }
  return ctx;
}
