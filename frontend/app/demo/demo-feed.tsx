"use client";

import { useState } from "react";
import { usePosts } from "@/app/hooks/use-posts";
import { useContentDetails } from "@/app/hooks/use-content-details";
import NavBar from "@/components/nav-bar";
import { PostList } from "@/components/feed/post-list";
import CommentModal from "@/components/comments/comment-modal";

export function DemoFeed() {
  const { posts, loading, locationLoading, location, handleLocationChange, hoveredPostId, setHoveredPostId } = usePosts("Capitol Hill, Seattle");
  const { contentDetails, loadings, error, getContentDetails } = useContentDetails();
  const [discussionOpen, setDiscussionOpen] = useState(false);
  const openDiscussion = (type: string, id: number) => {
    void getContentDetails(type, id);
    setDiscussionOpen(true);
  };
  const noop = () => {};

  // Static HTML and hydration must agree before the saved neighborhood loads.
  // The shared hook may restore Ballard from sessionStorage on a return visit.
  if (loading) return <p role="status" className="p-8 text-sm text-gray-600">Loading neighborhood…</p>;

  return (
    <div className="mx-auto w-full max-w-5xl p-4 md:px-8 md:py-6">
      <NavBar title="Your neighborhood, in focus" location={location} onLocationChange={handleLocationChange}
        showSearch={false} showNotification={false} showMessage={false} />
      <h1 className="sr-only md:hidden">Your neighborhood, in focus</h1>
      <section className="mx-auto mb-6 max-w-xl rounded-2xl border border-emerald-200 bg-emerald-50 px-5 py-4" aria-label="About this demo">
        <p className="text-xs font-semibold uppercase tracking-widest text-emerald-800">Portfolio demo · Jeffrey Mutethia</p>
        <h2 className="mt-2 text-lg font-semibold text-gray-950">The stories closest to home.</h2>
        <p className="mt-1 text-sm leading-6 text-gray-700">Switch from Capitol Hill to Ballard, then open a story to read the discussion. All people, stories and conversations are fictional; illustrations are bundled with the app.</p>
      </section>
      <div aria-live="polite" className="mx-auto mb-3 max-w-xl text-sm text-gray-600">
        {locationLoading ? "Loading neighborhood…" : `${posts.length} fictional stories · ${location}`}
      </div>
      <PostList posts={posts} loading={loading} locationLoading={locationLoading} hasMore={false}
        hoveredPostId={hoveredPostId} setHoveredPostId={setHoveredPostId}
        onReactionSelect={noop} onRepostSelect={noop} onShare={noop} onLoadMore={noop}
        onDeletePost={noop} onHidePost={noop} onReportPost={noop}
        onOpenComments={openDiscussion}
        onImageClick={(url) => { const story = posts.find((post) => post.thumbnail === url); if (story) openDiscussion("user_content", story.id); }}
        isAuthenticated={false} />
      <p className="mx-auto mt-2 max-w-xl pb-6 text-center text-xs leading-5 text-gray-500">Reading walkthrough. Posting, accounts and live ingestion are available in the full local system.</p>
      <CommentModal isOpen={discussionOpen} onClose={() => setDiscussionOpen(false)} contentDetails={contentDetails}
        isLoading={loadings} error={error} isAuthenticated={false} />
    </div>
  );
}
