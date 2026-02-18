"use client";

import { useEffect } from "react";
import { ScrollArea } from "@/components/ui/scroll-area";
import { useRouter } from "next/navigation";

import React from "react";
import NavBar from "@/components/nav-bar";
import { useNotificationContext } from "../context/notification-context";
import { useTimeAgo } from "../hooks/use-time-ago";
import { useAuth } from "../context/auth-context";
import { AvatarWithFallback } from "@/components/ui/avatar-with-fallback";

export default function NotificationsPage() {
  const router = useRouter();
  const { isAuthenticated } = useAuth();
  const {
    notifications,
    loading,
    error,
    markAsRead,
    markAllAsRead,
    deleteNotification,
  } = useNotificationContext();

  useEffect(() => {
    markAllAsRead();
  }, [markAllAsRead]);

  // Sort notifications by created_at descending
  const sortedNotifications = [...notifications].sort(
    (a, b) =>
      new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  );

  return (
    <div className="w-full mx-auto p-4">
      <NavBar title="Notifications" showLocationSelector={false}
      showNotification={isAuthenticated}
      showMessage={isAuthenticated}
      isAuthenticated={isAuthenticated}
      />
      <div className="max-w-screen-xl bg-white mx-auto rounded-3xl border mt-4">
        {/* Top Actions */}

        <ScrollArea className="w-full px-4 pb-4">
          <div className="py-4">
            {loading ? (
              <div className="text-center">Loading notifications...</div>
            ) : error ? (
              <div className="text-center text-red-500">Error: {error}</div>
            ) : notifications.length === 0 ? (
              <div className="text-center text-gray-500">No notifications.</div>
            ) : (
              <div className="space-y-4">
                {sortedNotifications.map((notification) => (
                  <NotificationItem
                    key={notification.id}
                    {...notification}
                    onDelete={() => deleteNotification(notification.id)}
                    onItemClick={() => {
                      if (notification.post_id) {
                        markAsRead(notification.id);
                        router.push(
                          `/?notification=true&post_id=${notification.post_id}&type=user_content`
                        );
                      }
                    }}
                  />
                ))}
              </div>
            )}
          </div>
        </ScrollArea>
      </div>
    </div>
  );
}

interface NotificationItemProps {
  id: number;
  user_id: number;
  content: string;
  is_read: boolean;
  created_at: string;
  post_id: number | null;
  type?: string | null;
  sender_id?: number | null;
  onDelete: () => void;
  onItemClick: () => void;
}

function NotificationItem({
  user_id,
  content,
  is_read,
  created_at,
  post_id,
  
  onItemClick,
}: NotificationItemProps) {
  const userName = `User #${user_id}`;
  const timeLabel = useTimeAgo().timeAgo(created_at);
  const backgroundClass = !is_read ? "bg-gray-200" : "bg-white";
  const clickable = Boolean(post_id);
  const containerClasses = clickable
    ? `flex justify-between p-4 items-center gap-3 py-4 border-b hover:bg-gray-100 transition-colors cursor-pointer ${backgroundClass}`
    : `flex justify-between  p-4  items-center gap-3 py-4 border-b ${backgroundClass}`;

  return (
    <div
      className={containerClasses}
      onClick={clickable ? onItemClick : undefined}
    >
      <div className="flex items-center gap-3 ">
        <AvatarWithFallback
          src={undefined}
          alt={userName}
          fallbackText={userName.charAt(0)}
          size="md"
        />
        <div className="text-sm">
          <span className="font-medium text-base text-[#0C1024]">
            {userName}
          </span>{" "}
          <span className="text-[#4B5669] text-sm font-normal">{content}</span>
          <div className="text-xs text-gray-400">{timeLabel}</div>
        </div>
      </div>
      <div
        className="flex items-center gap-2 shrink-0"
        onClick={(e) => e.stopPropagation()}
      ></div>
    </div>
  );
}

