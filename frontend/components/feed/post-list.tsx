"use client";
import { useCallback, useEffect, useRef } from "react";
import { useInView } from "react-intersection-observer";
import { PostCard } from "./post-card";
import type { ExtendedPost } from "@/app/types/content";

interface PostListProps {
  posts: ExtendedPost[];
  loading: boolean;
  locationLoading?: boolean; // Optional loading state for location changes
  hasMore: boolean;
  hoveredPostId: number | null;
  setHoveredPostId: (id: number | null) => void;
  onReactionSelect: (postId: number, reactionType: string) => void;
  onRepostSelect: (postId: number) => void;
  onOpenComments: (contentType: string, contentId: number) => void;
  onImageClick: (imageUrl: string) => void;
  onShare: (postId: number) => void;
  onLoadMore: () => void;
  isAuthenticated: boolean;

  // NEW
  onDeletePost: (postId: number) => void;
  onHidePost: (postId: number) => void;
  onReportPost: (postId: number) => void;
  onLinkCopied?: () => void;
}

export function PostList({
  posts,
  loading,
  hasMore,
  hoveredPostId,
  setHoveredPostId,
  onReactionSelect,
  onRepostSelect,
  onOpenComments,
  onImageClick,
  onShare,
  onLoadMore,
  isAuthenticated,

  onDeletePost,
  onHidePost,
  onReportPost,
  onLinkCopied,
}: PostListProps) {
  const { ref, inView } = useInView({
    threshold: 0.1,  // Trigger when 10% of the element is visible
    rootMargin: '100px', // Add margin to detect earlier
  });
  
  // Use a separate observer for the third post
  const thirdPostObserverRef = useRef<IntersectionObserver | null>(null);
  const thirdPostRef = useRef<HTMLDivElement | null>(null);
  const hasTriggeredThirdPost = useRef(false);
  
  // Setup observer for detecting when third post becomes visible
  useEffect(() => {
    // Only setup for guests when we have 3 posts
    if (isAuthenticated || posts.length < 3 || hasTriggeredThirdPost.current) {
      return;
    }
    
    // Clean up previous observer
    if (thirdPostObserverRef.current) {
      thirdPostObserverRef.current.disconnect();
    }
    
    // Create new observer for third post
    thirdPostObserverRef.current = new IntersectionObserver(
      (entries) => {
        // Check if third post is visible
        if (entries[0]?.isIntersecting && !hasTriggeredThirdPost.current) {
          // Add a small delay before showing the modal
          setTimeout(() => {
            hasTriggeredThirdPost.current = true;
            onLoadMore(); // This will trigger the waitlist modal
          }, 800);
        }
      },
      {
        threshold: 0.8,  // 80% of the third post must be visible
        rootMargin: '0px'
      }
    );
    
    // Observe the third post if ref is available
    if (thirdPostRef.current) {
      thirdPostObserverRef.current.observe(thirdPostRef.current);
    }
    
    return () => {
      if (thirdPostObserverRef.current) {
        thirdPostObserverRef.current.disconnect();
      }
    };
  }, [posts.length, isAuthenticated, onLoadMore]);
  
  // Normal infinite scroll
  useEffect(() => {
    if (inView && hasMore && !loading) {
      onLoadMore();
    }
  }, [inView, hasMore, loading, onLoadMore]);
  
  // Function to set ref for the third post
  const setThirdPostRef = useCallback((el: HTMLDivElement | null) => {
    thirdPostRef.current = el;
    
    // Re-observe if observer exists
    if (el && thirdPostObserverRef.current && !hasTriggeredThirdPost.current) {
      thirdPostObserverRef.current.observe(el);
    }
  }, []);

  return (
    <div className="space-y-6 max-w-xl mx-auto">
      {posts.map((post, idx) => {
        const isLast = idx === posts.length - 1;
        const isThird = idx === 2;
        
        return (
          <div 
            key={post.id}
            ref={isThird ? setThirdPostRef : isLast ? ref : undefined}
            className="post-item"
          >
            <PostCard
              post={post}
              hoveredPostId={hoveredPostId}
              setHoveredPostId={setHoveredPostId}
              onReactionSelect={onReactionSelect}
              onRepostSelect={onRepostSelect}
              onOpenComments={onOpenComments}
              onImageClick={onImageClick}
              onShare={onShare}
              onDeletePost={onDeletePost}
              onHidePost={onHidePost}
              onReportPost={onReportPost}
              isFirst={idx === 0}
              onLinkCopied={onLinkCopied}
              isAuthenticated={isAuthenticated}
            />
          </div>
        );
      })}

      {/* Infinite Scroll Loading Indicator */}
      {loading && (
        <div className="py-4 flex justify-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
        </div>
      )}

      {!hasMore && posts.length > 0 && (
        <div className="text-center text-muted-foreground py-4">
          No more posts to load
        </div>
      )}

      {!loading && posts.length === 0 && (
        <div className="text-center text-muted-foreground py-4">
          No posts available
        </div>
      )}
    </div>
  );
}
