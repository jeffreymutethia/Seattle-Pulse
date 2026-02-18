import type React from "react";
import MyPulseCard from "./my-pulse-card";
import { REACTIONS } from "@/lib/constants";
import { ExtendedPost } from "@/app/types/content";

interface MyPulseListProps {
  posts: ExtendedPost[];
  loading: boolean;
  hasMore: boolean;
  hoveredPostId: number | null;
  setHoveredPostId: (postId: number | null) => void;
  handlePostReactionSelect: (postId: number, reactionType: string) => void;
  handleRepostSelect: (postId: number) => void;
  onOpenComments: (contentType: string, contentId: number) => void;
  onImageSelect: (imageUrl: string) => void;
  loadingRef: () => void;
  onLinkCopied?: () => void;
}

export default function MyPulseList({
  posts,
  loading,
  hasMore,
  hoveredPostId,
  setHoveredPostId,
  handlePostReactionSelect,
  handleRepostSelect,
  onOpenComments,
  onImageSelect,
  loadingRef,
  onLinkCopied,
}: MyPulseListProps) {
  return (
    <div className="space-y-6 max-w-xl flex-1">
      {posts.map((post) => (
        <MyPulseCard
          key={post.id}
          post={post}
          reactions={REACTIONS}
          hoveredPostId={hoveredPostId}
          onHover={setHoveredPostId}
          onReactionSelect={handlePostReactionSelect}
          onRepostSelect={handleRepostSelect}
          onOpenComments={onOpenComments}
          onImageSelect={onImageSelect}
          onShare={() => {}}
          onLinkCopied={onLinkCopied}
        />
      ))}

      <div ref={loadingRef} className="py-4">
        {loading && (
          <div className="flex justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
          </div>
        )}
      </div>

      {!hasMore && posts.length > 0 && (
        <div className="text-center text-muted-foreground py-4">
        
        </div>
      )}
    </div>
  );
}
