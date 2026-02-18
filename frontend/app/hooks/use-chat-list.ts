// /app/hooks/useChatList.ts
"use client";

import { useEffect, useState } from "react";
import { ChatListItem, fetchDirectChats } from "../services/chat-service";

export function useChatList() {
  const [chats, setChats] = useState<ChatListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  useEffect(() => {
    loadChats(1);
  }, []);

  async function loadChats(currentPage: number) {
    try {
      setLoading(true);
      const newChats = await fetchDirectChats(currentPage, 10);
      if (newChats.length === 0 && currentPage === 1) {
        setChats([]);
        setHasMore(false);
      } else if (newChats.length === 0) {
        setHasMore(false);
      } else {
        // Sort by last_updated desc:
        newChats.sort((a, b) => {
          const dateA = new Date(a.last_updated).getTime();
          const dateB = new Date(b.last_updated).getTime();
          return dateB - dateA;
        });
        if (currentPage === 1) {
          setChats(newChats);
        } else {
          setChats((prev) => {
            const merged = [...prev, ...newChats];
            // re-sort again if needed
            return merged.sort((x, y) => {
              const dateX = new Date(x.last_updated).getTime();
              const dateY = new Date(y.last_updated).getTime();
              return dateY - dateX;
            });
          });
        }
        setPage(currentPage);
      }
    } catch (err) {
      console.error("Error fetching chat list:", err);
    } finally {
      setLoading(false);
    }
  }

  async function loadMore() {
    if (!hasMore || loading) return;
    await loadChats(page + 1);
  }

  function removeChatLocally(chatId: number) {
    setChats((prev) => prev.filter((c) => c.chat_id !== chatId));
  }

  function bumpChatToTop(chatId: number, content: string) {
    setChats((prev) => {
      const updated = [...prev];
      const idx = updated.findIndex((c) => c.chat_id === chatId);
      if (idx >= 0) {
        const item = { ...updated[idx] };
        if (item.latest_message) {
          item.latest_message.content = content;
          item.latest_message.created_at = new Date().toISOString();
        }
        item.last_updated = new Date().toISOString();

        updated.splice(idx, 1);
        updated.unshift(item);
      }
      return updated;
    });
  }

  function addChatOptimistically(chatId: number, receiver: {
    id: number;
    first_name: string;
    last_name: string;
    username: string;
    email: string;
    profile_picture_url: string;
  }) {
    setChats((prev) => {
      // Check if chat already exists
      const exists = prev.find((c) => c.chat_id === chatId);
      if (exists) {
        // If it exists, just bump it to top
        const updated = [...prev];
        const idx = updated.findIndex((c) => c.chat_id === chatId);
        if (idx >= 0) {
          const item = { ...updated[idx] };
          item.last_updated = new Date().toISOString();
          updated.splice(idx, 1);
          updated.unshift(item);
        }
        return updated;
      }

      // Create new chat item
      const newChat: ChatListItem = {
        chat_id: chatId,
        receiver,
        latest_message: null,
        last_updated: new Date().toISOString(),
      };

      // Add to the top of the list
      return [newChat, ...prev];
    });
  }

  return {
    chats,
    loading,
    hasMore,
    loadMore,
    removeChatLocally,
    bumpChatToTop,
    addChatOptimistically,
  };
}
