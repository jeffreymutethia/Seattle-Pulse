"use client";

import { useEffect, useState } from "react";
import {
  fetchDirectMessages,
  sendDirectMessage,
  editDirectMessage,
  deleteDirectMessage,
  deleteChat,
  DirectMessage,
} from "../services/chat-service";
import { useNotificationContext } from "../context/notification-context";

function canEditOrDelete(msg: DirectMessage): boolean {
  const userId = sessionStorage.getItem("user_id");
  if (!userId) return false;
  if (String(msg.sender_id) !== userId) return false;

  // 10 min limit
  const msgTime = new Date(msg.created_at).getTime();
  return Date.now() - msgTime < 10 * 60 * 1000;
}

export function useDirectMessages(chatId: number) {
  const [messages, setMessages] = useState<DirectMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [receiver, setReceiver] = useState<any>(null);

  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  // Global socket from NotificationContext
  const { globalSocket } = useNotificationContext();

  // 1) Load initial messages
  useEffect(() => {
    if (!chatId) return;
    loadMessages(1);
  }, [chatId]);

  async function loadMessages(p: number) {
    if (!chatId) return;
    setLoading(true);
    try {
      const response = await fetchDirectMessages(chatId, p, 20);
      const fetched = response.messages;
      // We assume server returns them in ascending order.
      // If the server returns them in descending order, you could reverse them here:
      fetched.reverse();

      if (p === 1) {
        setMessages(fetched);
      } else {
        // If these are older messages, maybe you want to prepend them:
        // setMessages((prev) => [...fetched, ...prev]);
        // or if they're newer, append:
        setMessages((prev) => [...prev, ...fetched]);
      }

      if (fetched.length === 0) setHasMore(false);
      setPage(p);
      
      // Store receiver information
      if (response.receiver) {
        setReceiver(response.receiver);
      }
    } catch (err) {
      console.error("Error fetching messages:", err);
      return null;
    } finally {
      setLoading(false);
    }
  }

  async function loadMore() {
    if (!hasMore || loading) return;
    await loadMessages(page + 1);
  }

  // 2) Send message
  async function send(content: string) {
    if (!chatId || !content.trim()) return;
    try {
      setSending(true);
      const newMsg = await sendDirectMessage({ chat_id: chatId, content });
      // Append at the bottom
      setMessages((prev) => [...prev, newMsg]);
    } catch (err) {
      console.error("Error sending message:", err);
    } finally {
      setSending(false);
    }
  }

  // 3) Edit message
  async function editMessage(messageId: number, newContent: string) {
    try {
      await editDirectMessage(messageId, newContent);
      setMessages((prev) =>
        prev.map((m) =>
          m.id === messageId ? { ...m, content: newContent } : m
        )
      );
    } catch (err) {
      console.error("Error editing message:", err);
    }
  }

  // 4) Remove single message
  async function removeMessage(messageId: number, deleteForAll = false) {
    try {
      await deleteDirectMessage(messageId, deleteForAll);
      setMessages((prev) => prev.filter((m) => m.id !== messageId));
    } catch (err) {
      console.error("Error deleting message:", err);
    }
  }

  // 5) Remove entire chat
  async function removeChat() {
    if (!chatId) return;
    try {
      await deleteChat(chatId);
    } catch (err) {
      console.error("Error deleting entire chat:", err);
    }
  }

  // 6) Listen for incoming messages from socket
  useEffect(() => {
    if (!globalSocket || !chatId) return;
    const userId = sessionStorage.getItem("user_id");
    if (!userId) return;

    function handleIncoming(data: any) {
      // Just create a new object
      const newMsg: DirectMessage = {
        id: Date.now(),
        chat_id: data.chat_id,
        sender_id: data.sender_id,
        content: data.content,
        created_at: new Date().toISOString(),
      };

      // Append at the bottom if it's for the current chat
      if (newMsg.chat_id === chatId) {
        setMessages((prev) => [...prev, newMsg]);
      }
    }

    globalSocket.on(`notify_${userId}`, handleIncoming);
    return () => {
      globalSocket.off(`notify_${userId}`, handleIncoming);
    };
  }, [globalSocket, chatId]);

  return {
    messages,
    setMessages,
    loading,
    sending,
    hasMore,
    loadMore,
    send,
    editMessage,
    removeMessage,
    removeChat,
    canEditOrDelete,
    receiver,
  };
}
