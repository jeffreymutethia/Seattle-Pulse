// group-hooks.ts

"use client";

import { useState, useEffect } from "react";
import { useNotificationContext } from "../context/notification-context";
import {
  Group,
  fetchUserGroups,
  GroupMessage,
  fetchGroupMessages,
  sendGroupMessage,
  editGroupChatMessage,
  deleteGroupMessage,
} from "../services/group-service";

// ^^^ adjust to wherever you define your NotificationContext

////////////////////////////////////////////////////////////////////////////////
// Hook #1: useGroupList
////////////////////////////////////////////////////////////////////////////////

/**
 * Fetches and manages the list of groups the user is a member of.
 * Supports basic pagination: page=1, limit=10 by default.
 */
export function useGroupList() {
  const [groups, setGroups] = useState<Group[]>([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  // Load first page on mount
  useEffect(() => {
    loadGroups(1);
  }, []);

  async function loadGroups(p: number) {
    setLoading(true);
    try {
      const fetched = await fetchUserGroups(p, 10); // page size = 10
      if (p === 1) {
        // first page => replace
        setGroups(fetched);
      } else {
        // subsequent page => append
        setGroups((prev) => [...prev, ...fetched]);
      }
      // if no new data => no more pages
      if (!fetched || fetched.length === 0) {
        setHasMore(false);
      }
      setPage(p);
    } catch (err) {
      console.error("Error fetching user groups:", err);
    } finally {
      setLoading(false);
    }
  }

  // For infinite scroll or "Load more" button
  async function loadMoreGroups() {
    if (loading || !hasMore) return;
    await loadGroups(page + 1);
  }

  // Manual refresh (sets back to page 1)
  async function refresh() {
    setHasMore(true);
    await loadGroups(1);
  }

  return {
    groups, // array of Group objects
    loading, // true while fetching
    hasMore, // if there are more pages
    loadMoreGroups, // function to load next page
    refresh, // optional refresh
    setGroups, // if you want to manually update groups
  };
}

////////////////////////////////////////////////////////////////////////////////
// Hook #2: useGroupMessages
////////////////////////////////////////////////////////////////////////////////

/**
 * Fetches + manages messages in a single group chat:
 *  - loads group messages from server in ascending order (newest at bottom)
 *  - handles sending new messages
 *  - listens to socket events for real-time updates
 */
export function useGroupMessages(groupId: number) {
  const [messages, setMessages] = useState<GroupMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [editing, setEditing] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  // If you store the socket in a NotificationContext
  const { globalSocket } = useNotificationContext();

  // 1) Load initial messages
  useEffect(() => {
    if (!groupId) return;
    loadMessages(1);
  }, [groupId]);

  async function loadMessages(p: number) {
    setLoading(true);
    try {
      const fetched = await fetchGroupMessages(groupId, p, 20);
      // The server returns messages in DESC order => newest first
      // We want oldest at index 0 => newest last => reverse them
      const inAsc = [...fetched].reverse();

      if (p === 1) {
        setMessages(inAsc);
      } else {
        setMessages((prev) => [...prev, ...inAsc]);
      }

      if (!fetched || fetched.length === 0) {
        setHasMore(false);
      }
      setPage(p);
    } catch (err) {
      console.error("Error fetching group messages:", err);
    } finally {
      setLoading(false);
    }
  }

  // Load next page (if you want "scroll up" for older messages, etc.)
  async function loadMore() {
    if (!hasMore || loading) return;
    await loadMessages(page + 1);
  }

  // 2) Send a new message
  async function send(content: string) {
    if (!groupId || !content.trim()) return;
    setSending(true);
    try {
      const newMsg = await sendGroupMessage({
        group_chat_id: groupId,
        content,
      });
      // Our array is in ascending => push new message at the end
      setMessages((prev) => [...prev, newMsg]);
    } catch (err) {
      console.error("Error sending group message:", err);
    } finally {
      setSending(false);
    }
  }

  // 3) Edit a message
  async function editMessage(messageId: number, newContent: string) {
    if (!groupId || !newContent.trim()) return;
    setEditing(true);
    try {
      await editGroupChatMessage(messageId, newContent);
      // Update local messages
      setMessages((prev) =>
        prev.map((msg) =>
          msg.id === messageId ? { ...msg, content: newContent } : msg
        )
      );
      return true;
    } catch (err) {
      console.error("Error editing group message:", err);
      return false;
    } finally {
      setEditing(false);
    }
  }

  // 4) Delete a message
  async function removeMessage(messageId: number, deleteForAll: boolean = true) {
    if (!groupId) return;
    setDeleting(true);
    try {
      await deleteGroupMessage({ message_id: messageId, delete_for_all: deleteForAll });
      // Remove from local messages
      setMessages((prev) => prev.filter((msg) => msg.id !== messageId));
      return true;
    } catch (err) {
      console.error("Error deleting group message:", err);
      return false;
    } finally {
      setDeleting(false);
    }
  }

  // 5) Listen for real-time socket events
  //    Your server apparently emits "notify_{userId}" with data => { type: 'group_onboarding', message: {...} }
  useEffect(() => {
    if (!globalSocket || !groupId) return;
    const userId = sessionStorage.getItem("user_id");
    if (!userId) return;

    // handle incoming events
    function handleIncoming(data: any) {
      if (data.type === "group_onboarding") {
        const msg = data.message; // { group_chat_id, content, sender, ...}
        if (msg.group_chat_id === groupId) {
          // append to the bottom
          setMessages((prev) => [...prev, msg]);
        }
      }
    }

    // subscribe to notify_{userId}
    globalSocket.on(`notify_${userId}`, handleIncoming);

    // cleanup
    return () => {
      globalSocket.off(`notify_${userId}`, handleIncoming);
    };
  }, [globalSocket, groupId]);

  return {
    messages,
    setMessages,
    loading,
    sending,
    editing,
    deleting,
    hasMore,
    loadMore,
    send,
    editMessage,
    removeMessage
  };
}
