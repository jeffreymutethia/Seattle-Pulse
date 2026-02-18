import { useEffect } from "react";
import { io } from "socket.io-client";
import { NotificationItem } from "../services/notification-service";
import { getSocketUrl } from "@/lib/config";


export function useSocketNotifications(
  onNewNotification: (notif: NotificationItem) => void
) {
  useEffect(() => {
    // Get socket URL from config
    const socketUrl = getSocketUrl();
    
    const socket = io(socketUrl, {
      transports: ["websocket"],
    });

    socket.on("connect", () => {
    });

    socket.onAny((event, data) => {
      if (event.startsWith("notify_")) {
        onNewNotification(data);
      }
    });

    socket.on("disconnect", () => {
    });

    return () => {
      socket.disconnect();
    };
  }, [onNewNotification]);
}
