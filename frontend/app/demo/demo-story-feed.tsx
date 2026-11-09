"use client";

import { useState } from "react";
import { PostList } from "@/components/feed/post-list";
import CommentModal from "@/components/comments/comment-modal";
import { useContentDetails } from "@/app/hooks/use-content-details";
import type { ExtendedPost } from "@/app/types/content";
import { useDemoSession } from "./demo-session";

export function DemoStoryFeed({ posts }: { posts: ExtendedPost[] }) {
  const { isSignedIn, comments, addComment } = useDemoSession();
  const { contentDetails, loadings, error, getContentDetails } = useContentDetails();
  const [discussionOpen, setDiscussionOpen] = useState(false);
  const [hoveredPostId, setHoveredPostId] = useState<number | null>(null);
  const visiblePosts = posts.map(post => ({ ...post, comments_count: post.comments_count + (comments[post.id]?.length ?? 0) }));
  const noop = () => {};

  function openDiscussion(type: string, id: number) {
    void getContentDetails(type, id);
    setDiscussionOpen(true);
  }

  return <>
    <PostList posts={visiblePosts} loading={false} locationLoading={false} hasMore={false}
      hoveredPostId={hoveredPostId} setHoveredPostId={setHoveredPostId}
      onReactionSelect={noop} onRepostSelect={noop} onShare={noop} onLoadMore={noop}
      onDeletePost={noop} onHidePost={noop} onReportPost={noop}
      onOpenComments={openDiscussion}
      onImageClick={url => { const story = posts.find(post => post.thumbnail === url); if (story) openDiscussion("user_content", story.id); }}
      isAuthenticated={isSignedIn} />
    <CommentModal isOpen={discussionOpen} onClose={() => setDiscussionOpen(false)} contentDetails={contentDetails}
      isLoading={loadings} error={error} isAuthenticated={false}
      demoReader={{ signedIn: isSignedIn, comments: contentDetails ? comments[contentDetails.id] ?? [] : [], onAddComment: addComment }} />
  </>;
}
