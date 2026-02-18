"use client";

import { useState, useEffect } from "react";
import { fetchCombinedChats, CombinedChatItem } from "../services/chat-service";

/**
 * Hook for fetching and managing the combined chat list (direct + group chats)
 */
export function useCombinedChats() {
  const [chats, setChats] = useState<CombinedChatItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  // Load first page on mount
  useEffect(() => {
    loadChats(1);
  }, []);

  async function loadChats(p: number) {
    setLoading(true);
    try {
      const fetched = await fetchCombinedChats(p, 10); // Page size = 10
      
      if (p === 1) {
        // First page => replace
        setChats(fetched);
      } else {
        // Subsequent page => append
        setChats(prev => [...prev, ...fetched]);
      }

      // If no new data => no more pages
      if (!fetched || fetched.length === 0) {
        setHasMore(false);
      }

      setPage(p);
    } catch (err) {
      console.error("Error fetching combined chats:", err);
    } finally {
      setLoading(false);
    }
  }

  // For infinite scroll or "Load more" button
  async function loadMoreChats() {
    if (loading || !hasMore) return;
    await loadChats(page + 1);
  }

  // Manual refresh (sets back to page 1)
  async function refresh() {
    setHasMore(true);
    await loadChats(1);
  }

  return {
    chats,
    loading,
    hasMore,
    loadMoreChats,
    refresh,
  };
} 