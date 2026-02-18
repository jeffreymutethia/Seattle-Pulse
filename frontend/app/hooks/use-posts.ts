/* eslint-disable @typescript-eslint/no-unused-vars */
"use client";

import { useState, useCallback, useEffect, useRef } from "react";
import { postService } from "../services/postServices";
import { trackEvent } from "@/lib/mixpanel";
import { ExtendedPost } from "../types/content";

export function usePosts(initialLocation?: string) {
  const [posts, setPosts] = useState<ExtendedPost[]>([]);
  const postsRef = useRef<ExtendedPost[]>([]); // Ref to track current posts for error handling
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [locationLoading, setLocationLoading] = useState(false); // Separate loading state for location changes
  const [hasMore, setHasMore] = useState(true);
  const [hoveredPostId, setHoveredPostId] = useState<number | null>(null);
  
  // Keep ref in sync with state
  useEffect(() => {
    postsRef.current = posts;
  }, [posts]);
  
  // Check for saved location from a newly posted story, otherwise use initialLocation or default
  const getInitialLocation = () => {
    if (typeof window !== "undefined") {
      const savedLocation = sessionStorage.getItem("feedLocation");
      if (savedLocation) {
        return savedLocation;
      }
    }
    return initialLocation || "Seattle";
  };
  
  const [location, setLocation] = useState<string>(getInitialLocation());

  // Helper function to get newly posted story ID from sessionStorage
  const getNewlyPostedStoryId = (): number | null => {
    if (typeof window === "undefined") return null;
    const newlyPostedStory = sessionStorage.getItem("newlyPostedStory");
    if (newlyPostedStory) {
      try {
        const newPost = JSON.parse(newlyPostedStory);
        return newPost.id || null;
      } catch (error) {
        return null;
      }
    }
    return null;
  };

  const fetchPosts = useCallback(async (pageNum: number, loc?: string) => {
    const posts = await postService.fetchPosts(pageNum, loc);
    // Filter out the newly posted story if it exists (to avoid duplicates)
    const newlyPostedId = getNewlyPostedStoryId();
    if (newlyPostedId) {
      return posts.filter((post: ExtendedPost) => post.id !== newlyPostedId);
    }
    return posts;
  }, []);

  // Load initial posts - only on mount, not on location change
  useEffect(() => {
    async function loadInitial() {
      setLoading(true);
      try {
        // Get the location to use (saved location from post, or current location state)
        const savedLocation = typeof window !== "undefined" 
          ? sessionStorage.getItem("feedLocation") 
          : null;
        const locationToUse = savedLocation || location;
        
        // Update location state if we have a saved location
        if (savedLocation && savedLocation !== location) {
          setLocation(savedLocation);
        }
        
        const initialPosts = await fetchPosts(1, locationToUse);
        
        // Check if there's a newly posted story in sessionStorage
        // Note: fetchPosts already filters out this post from API results to avoid duplicates
        const newlyPostedStory = sessionStorage.getItem("newlyPostedStory");
        if (newlyPostedStory) {
          try {
            const newPost = JSON.parse(newlyPostedStory);
            // Add the new post to the top of the fetched posts (API results already filtered)
            setPosts([newPost, ...initialPosts]);
          } catch (error) {
            console.error("Error parsing newly posted story:", error);
            setPosts(initialPosts);
          }
        } else {
          setPosts(initialPosts);
        }
      } catch (error) {
        setPosts([]);
      } finally {
        setLoading(false);
      }
    }
    loadInitial();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fetchPosts]); // Intentionally exclude location to prevent duplicate calls on mount

  // Reset posts when location changes - with optimistic UI updates
  const handleLocationChange = useCallback(async (newLocation: string) => {
    // Don't do anything if location hasn't actually changed
    if (newLocation === location) {
      return;
    }

    // Update location state immediately for optimistic UI
    setLocation(newLocation);
    setPage(1);
    setHasMore(true);
    setLocationLoading(true); // Use separate loading state, don't clear posts
    
    // Save the new location to sessionStorage
    if (typeof window !== "undefined") {
      sessionStorage.setItem("feedLocation", newLocation);
    }
    
    // Store current posts snapshot for error handling (using ref to avoid stale closure)
    const previousPosts = [...postsRef.current];
    
    // Check if there's a newly posted story to preserve
    const newlyPostedStory = sessionStorage.getItem("newlyPostedStory");
    if (newlyPostedStory) {
      try {
        const newPost = JSON.parse(newlyPostedStory);
        // Check if the new post's location matches the selected location
        // Handle cases where location might be "Queen Anne" vs "Queen Anne, Seattle, WA"
        const postLocation = newPost.location?.toLowerCase() || "";
        const selectedLocation = newLocation.toLowerCase();
        const locationMatches = 
          postLocation === selectedLocation ||
          postLocation.startsWith(selectedLocation.split(',')[0].trim()) ||
          selectedLocation.startsWith(postLocation.split(',')[0].trim());
        
        if (locationMatches) {
          // Fetch posts for the location and add new post at top
          try {
            const newPosts = await fetchPosts(1, newLocation);
            // fetchPosts already filters out the newPost.id, so just add it at the top
            setPosts([newPost, ...newPosts]);
            setHasMore(newPosts.length > 0);
          } catch (error) {
            console.error("Error fetching posts for new location:", error);
            // On error, keep previous posts visible (optimistic UI fallback)
            // Only update if we had no posts before, otherwise keep showing old ones
            if (previousPosts.length === 0) {
              setPosts([newPost]);
            }
          } finally {
            setLocationLoading(false);
          }
        } else {
          // New post doesn't match location, fetch posts normally
          try {
            const newPosts = await fetchPosts(1, newLocation);
            setPosts(newPosts);
            setHasMore(newPosts.length > 0);
          } catch (error) {
            console.error("Error fetching posts for new location:", error);
            // On error, keep previous posts visible (optimistic UI fallback)
            // Only clear if we had no posts before
            if (previousPosts.length === 0) {
              setPosts([]);
            }
          } finally {
            setLocationLoading(false);
          }
        }
      } catch (error) {
        console.error("Error parsing newly posted story:", error);
        setLocationLoading(false);
      }
    } else {
      // Fetch new posts for the location - keep old posts visible while loading
      try {
        const newPosts = await fetchPosts(1, newLocation);
        setPosts(newPosts);
        setHasMore(newPosts.length > 0);
      } catch (error) {
        console.error("Error fetching posts for new location:", error);
        // On error, keep previous posts visible (optimistic UI fallback)
        // Only clear if we had no posts before
        if (previousPosts.length === 0) {
          setPosts([]);
        }
      } finally {
        setLocationLoading(false);
      }
    }
  }, [fetchPosts, location]);

  const handlePostReaction = async (postId: number, reactionType: string) => {
    const currentPost = posts.find((p) => p.id === postId);
    if (!currentPost) return;

    // Save old values in case we need to revert on error
    const oldReaction = currentPost.userReaction;
    const oldTotal = currentPost.totalReactions ?? 0;
    const oldTopReactions = [...(currentPost.top_reactions ?? [])];

    const isUnreacting = oldReaction === reactionType; // user clicked the same reaction
    const newReaction = isUnreacting ? null : reactionType;

    // Decide how total should update
    let newTotal = oldTotal;
    if (!oldReaction && !isUnreacting) {
      // No old reaction, user picks a new one => total + 1
      newTotal = oldTotal + 1;
    } else if (isUnreacting) {
      // User had a reaction and clicked the same => unreact => total - 1
      newTotal = Math.max(oldTotal - 1, 0);
    } else if (oldReaction && oldReaction !== reactionType) {
      // Switch from one reaction to another => total stays the same
      newTotal = oldTotal;
    }

    // Update top reactions
    let newTopReactions = [...oldTopReactions];
    // Remove the old reaction if it existed
    if (oldReaction) {
      newTopReactions = newTopReactions.filter((r) => r !== oldReaction);
    }
    // If not unreacting, add the new reaction
    if (newReaction) {
      if (!newTopReactions.includes(newReaction)) {
        newTopReactions.unshift(newReaction);
      }
    }
    // Keep only top 3
    newTopReactions = newTopReactions.slice(0, 3);

    // Optimistic UI update
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
      // Actual API call
      await postService.reactToPost(postId, reactionType);
      
      // Track reaction event
      trackEvent("post_reacted", {
        post_id: postId,
        reaction_type: reactionType,
        is_unreacting: isUnreacting,
      });
    } catch (error) {
      console.error("Error reacting to post:", error);
      // Revert local state on error
      setPosts((prevPosts) =>
        prevPosts.map((p) =>
          p.id === postId
            ? {
                ...p,
                userReaction: oldReaction,
                totalReactions: oldTotal,
                top_reactions: oldTopReactions,
              }
            : p
        )
      );
    }
  };

  const handleRepost = async (postId: number) => {
    const currentPost = posts.find((p) => p.id === postId);
    if (!currentPost) return;

    const isUndoing = currentPost.has_user_reposted;

    // Optimistic UI update
    setPosts((prevPosts) =>
      prevPosts.map((p) =>
        p.id === postId ? { ...p, has_user_reposted: !p.has_user_reposted } : p
      )
    );

    try {
      if (!isUndoing) {
        await postService.repostContent(postId);
        // Track repost event
        trackEvent("post_reposted", { post_id: postId });
      } else {
        await postService.undoRepost(postId);
        // Track undo repost event
        trackEvent("post_unreposted", { post_id: postId });
      }
    } catch (error) {
      console.error("Error updating repost:", error);
      // revert local state
      setPosts((prevPosts) =>
        prevPosts.map((p) =>
          p.id === postId
            ? { ...p, has_user_reposted: currentPost.has_user_reposted }
            : p
        )
      );
    }
  };

  const loadMorePosts = async () => {
    if (loading || !hasMore) return;
    setLoading(true);

    const nextPage = page + 1;
    const newPosts = await fetchPosts(nextPage, location);

    if (newPosts.length === 0) {
      setHasMore(false);
    } else {
      setPosts((prev) => {
        // Check if there's a newly posted story that should stay at the top
        const newlyPostedStory = sessionStorage.getItem("newlyPostedStory");
        if (newlyPostedStory) {
          try {
            const newPost = JSON.parse(newlyPostedStory);
            // Keep the new post at the top, add other posts after it
            const otherPosts = prev.filter((post: ExtendedPost) => post.id !== newPost.id);
            return [newPost, ...otherPosts, ...newPosts];
          } catch (error) {
            console.error("Error parsing newly posted story:", error);
            return [...prev, ...newPosts];
          }
        }
        return [...prev, ...newPosts];
      });
      setPage(nextPage);
    }

    setLoading(false);
  };

  return {
    posts,
    setPosts, // <--- Now exposed so parent components can remove or update posts
    loading,
    locationLoading, // Separate loading state for location changes
    hasMore,
    hoveredPostId,
    setHoveredPostId,
    handlePostReaction,
    handleRepost,
    loadMorePosts,
    location,
    handleLocationChange,
  };
}
