"use client";

import { useState, useEffect, useCallback } from "react";
import type { ExtendedPost, Reaction } from "@/app/types/content";
import { postService } from "@/app/services/pulse-service";
import { useInView } from "react-intersection-observer";

export function usePosts() {
  const [posts, setPosts] = useState<ExtendedPost[]>([]);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [hasMore, setHasMore] = useState(true);
  const [hoveredPostId, setHoveredPostId] = useState<number | null>(null);

  const { ref, inView } = useInView();

  const fetchPosts = useCallback(
    async (pageNum: number): Promise<ExtendedPost[]> => {
      return postService.fetchPosts(pageNum);
    },
    []
  );

  useEffect(() => {
    async function loadInitial() {
      setLoading(true);
      const initialPosts = await fetchPosts(1);
      setPosts(initialPosts);
      setLoading(false);
    }
    loadInitial();
  }, [fetchPosts]);

  useEffect(() => {
    let isFetching = false;

    async function loadMore() {
      if (inView && !loading && hasMore && !isFetching) {
        isFetching = true;
        setLoading(true);
        const nextPage = page + 1;
        const newPosts = await fetchPosts(nextPage);
        if (newPosts.length === 0) {
          setHasMore(false);
        } else {
          setPosts((prev) => [...prev, ...newPosts]);
          setPage(nextPage);
        }
        setLoading(false);
        isFetching = false;
      }
    }
    loadMore();
    return () => {
      isFetching = false;
    };
  }, [inView, loading, hasMore, page, fetchPosts]);

  const handlePostReactionSelect = async (
    postId: number,
    reactionType: string
  ) => {
    const currentPost = posts.find((p) => p.id === postId);
    if (!currentPost) return;

    const isUnreacting = currentPost.userReaction === reactionType;
    const previousReaction = currentPost.userReaction;
    const previousTotal = currentPost.totalReactions || 0;
    const previousTopReactions = [...(currentPost.top_reactions || [])];

    const newReaction = isUnreacting ? null : reactionType;
    const newTotal = isUnreacting
      ? previousTotal - 1
      : previousTotal + (previousReaction ? 0 : 1);

    let newTopReactions = [...previousTopReactions];
    if (isUnreacting) {
      newTopReactions = newTopReactions.filter((r) => r !== reactionType);
    } else {
      if (previousReaction) {
        newTopReactions = newTopReactions.filter((r) => r !== previousReaction);
      }
      if (!newTopReactions.includes(reactionType)) {
        newTopReactions.unshift(reactionType);
      }
    }
    newTopReactions = newTopReactions.slice(0, 3);

    setPosts((prevPosts) =>
      prevPosts.map((p) =>
        p.id === postId
          ? {
              ...p,
              userReaction: newReaction,
              totalReactions: newTotal,
              top_reactions: newTopReactions,
            }
          : p
      )
    );

    try {
      const data = await postService.reactToPost(postId, reactionType);

      if (
        data.user_has_reacted !== (newReaction !== null) ||
        data.user_reaction_type !== newReaction ||
        data.total_reactions !== newTotal ||
        JSON.stringify(data.top_reactions) !== JSON.stringify(newTopReactions)
      ) {
        setPosts((prevPosts) =>
          prevPosts.map((p) =>
            p.id === postId
              ? {
                  ...p,
                  userReaction: data.user_has_reacted
                    ? data.user_reaction_type
                    : null,
                  totalReactions: data.total_reactions,
                  top_reactions: data.top_reactions || [],
                }
              : p
          )
        );
      }
    } catch (err) {
      console.error("Error reacting to post:", err);
      setPosts((prevPosts) =>
        prevPosts.map((p) =>
          p.id === postId
            ? {
                ...p,
                userReaction: previousReaction,
                totalReactions: previousTotal,
                top_reactions: previousTopReactions,
              }
            : p
        )
      );
    }
  };

  const handleRepostSelect = async (postId: number) => {
    const currentPost = posts.find((p) => p.id === postId);
    if (!currentPost) return;

    const isUndoing = currentPost.has_user_reposted;

    setPosts((prevPosts) =>
      prevPosts.map((p) =>
        p.id === postId ? { ...p, has_user_reposted: !p.has_user_reposted } : p
      )
    );

    try {
      if (!isUndoing) {
        await postService.repostContent(postId);
      } else {
        await postService.undoRepost(postId);
      }
    } catch (error) {
      console.error("Error updating repost:", error);
      setPosts((prevPosts) =>
        prevPosts.map((p) =>
          p.id === postId
            ? { ...p, has_user_reposted: currentPost.has_user_reposted }
            : p
        )
      );
    }
  };

  const refreshPosts = useCallback(async () => {
    setLoading(true);
    setPage(1);
    setHasMore(true);
    const initialPosts = await fetchPosts(1);
    setPosts(initialPosts);
    setLoading(false);
  }, [fetchPosts]);

  return {
    posts,
    loading,
    hasMore,
    hoveredPostId,
    setHoveredPostId,
    handlePostReactionSelect,
    handleRepostSelect,
    loadingRef: ref,
    refreshPosts,
  };
}
