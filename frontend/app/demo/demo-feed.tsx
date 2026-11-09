"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { usePosts } from "@/app/hooks/use-posts";
import { useContentDetails } from "@/app/hooks/use-content-details";
import NavBar from "@/components/nav-bar";
import { PostList } from "@/components/feed/post-list";
import CommentModal from "@/components/comments/comment-modal";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "@/components/ui/dialog";
import { FULL_LOGO_SRC } from "@/lib/brand-assets";
import { demoNeighborhoods } from "./fixtures";
import { demoPhotography, photoCredit } from "./photography";

const sessionKey = "seattle-pulse-demo-reader";
const commentsKey = "seattle-pulse-demo-comments";

export function DemoFeed() {
  const { posts, loading, locationLoading, location, handleLocationChange, hoveredPostId, setHoveredPostId } = usePosts("Seattle");
  const { contentDetails, loadings, error, getContentDetails } = useContentDetails();
  const [discussionOpen, setDiscussionOpen] = useState(false);
  const [signInOpen, setSignInOpen] = useState(false);
  const [signedIn, setSignedIn] = useState(false);
  const [localComments, setLocalComments] = useState<Record<number, string[]>>({});

  useEffect(() => {
    setSignedIn(sessionStorage.getItem(sessionKey) === "yes");
    const saved = sessionStorage.getItem(commentsKey);
    if (saved) {
      try {
        setLocalComments(JSON.parse(saved));
      } catch {
        sessionStorage.removeItem(commentsKey);
      }
    }
  }, []);

  function signIn() {
    sessionStorage.setItem(sessionKey, "yes");
    setSignedIn(true);
    setSignInOpen(false);
  }

  function signOut() {
    sessionStorage.removeItem(sessionKey);
    setSignedIn(false);
  }

  function addComment(postId: number, content: string) {
    const next = { ...localComments, [postId]: [...(localComments[postId] ?? []), content] };
    sessionStorage.setItem(commentsKey, JSON.stringify(next));
    setLocalComments(next);
  }

  function openDiscussion(type: string, id: number) {
    void getContentDetails(type, id);
    setDiscussionOpen(true);
  }

  const noop = () => {};
  const feedLabel = location === "Seattle" ? "All Seattle" : location;
  const visiblePosts = posts.map(post => ({
    ...post,
    comments_count: post.comments_count + (localComments[post.id]?.length ?? 0),
  }));

  return (
    <div className="mx-auto w-full max-w-6xl px-4 pb-10 pt-4 md:px-8 md:pt-8">
      <section className="relative isolate mb-6 flex min-h-64 items-end overflow-hidden rounded-3xl bg-slate-950 p-6 text-white sm:min-h-72 md:p-10" aria-label="About this demo">
        <Image src="/demo/seattle-skyline.webp" alt="Seattle skyline and Mount Rainier from Kerry Park" fill priority sizes="(max-width: 768px) 100vw, 1152px" className="-z-20 object-cover object-center" />
        <div aria-hidden="true" className="absolute inset-0 -z-10 bg-gradient-to-r from-slate-950 via-slate-950/75 to-slate-950/15" />
        <div className="max-w-lg">
          <p className="text-xs font-semibold uppercase tracking-widest text-emerald-200">Seattle Pulse · Demo edition</p>
          <h1 className="mt-3 text-4xl font-bold tracking-tight sm:text-5xl">Seattle, block by block.</h1>
          <p className="mt-3 text-sm leading-6 text-slate-100 sm:text-base">Start with the whole city, then zoom in on a neighborhood. Real places, original local guides, and sample conversations.</p>
          <div className="mt-5 flex flex-wrap items-center gap-3">
            {signedIn ? <>
              <span role="status" className="text-sm font-medium text-emerald-200">Demo reader signed in</span>
              <Button variant="outline" className="border-white/60 bg-slate-950/40 text-white hover:bg-white hover:text-slate-950" onClick={signOut}>Sign out</Button>
            </> : (
              <Button className="bg-white text-slate-950 hover:bg-emerald-100" onClick={() => setSignInOpen(true)}>Try demo sign-in</Button>
            )}
          </div>
        </div>
      </section>

      {loading ? <p role="status" className="p-8 text-sm text-gray-600">Loading the Seattle feed…</p> : <>
        <NavBar title="Explore Seattle Pulse" location={location} onLocationChange={handleLocationChange}
          showSearch={false} showNotification={false} showMessage={false} />
        <div aria-live="polite" className="mx-auto mb-3 max-w-xl text-sm text-gray-600">
          {locationLoading ? "Loading neighborhood…" : `${visiblePosts.length} ${visiblePosts.length === 1 ? "story" : "stories"} · ${feedLabel} · ${demoNeighborhoods.length - 1} areas in this edition`}
        </div>
        <PostList posts={visiblePosts} loading={loading} locationLoading={locationLoading} hasMore={false}
          hoveredPostId={hoveredPostId} setHoveredPostId={setHoveredPostId}
          onReactionSelect={noop} onRepostSelect={noop} onShare={noop} onLoadMore={noop}
          onDeletePost={noop} onHidePost={noop} onReportPost={noop}
          onOpenComments={openDiscussion}
          onImageClick={(url) => { const story = visiblePosts.find((post) => post.thumbnail === url); if (story) openDiscussion("user_content", story.id); }}
          isAuthenticated={false} />
      </>}

      <details className="mx-auto mt-4 max-w-xl rounded-xl border p-4 text-xs leading-6 text-gray-600">
        <summary className="cursor-pointer font-semibold text-gray-800">About this edition and photo credits</summary>
        <p className="my-2">The guides are original copy about real places. Conversation and engagement are simulated. Demo comments stay in this tab’s session.</p>
        <ul className="list-disc pl-4">
          {Object.keys(demoPhotography).map(key => {
            const credit = photoCredit(key as keyof typeof demoPhotography);
            return <li key={key}><a className="underline" href={credit.source}>{credit.title}</a> by {credit.author} · <a className="underline" href={credit.licenseUrl}>{credit.license}</a> · resized and converted to WebP</li>;
          })}
        </ul>
      </details>

      <Dialog open={signInOpen} onOpenChange={setSignInOpen}>
        <DialogContent className="w-[calc(100vw-2rem)] max-w-xl overflow-hidden rounded-3xl border-0 p-0">
          <div className="relative flex min-h-44 items-center justify-center bg-slate-950 sm:min-h-56">
            <Image src="/demo/sign-in.webp" alt="" fill sizes="(max-width: 640px) 100vw, 576px" className="object-cover" />
            <div className="absolute inset-0 bg-slate-950/25" aria-hidden="true" />
            <Image src={FULL_LOGO_SRC} alt="Seattle Pulse" width={104} height={104} className="relative rounded-2xl bg-white/95 p-2" />
          </div>
          <div className="space-y-4 p-6 sm:p-8">
            <DialogTitle>Welcome to Seattle Pulse</DialogTitle>
            <DialogDescription>Continue as a demo reader to join a sample discussion. Comments stay in this browser tab.</DialogDescription>
            <Button className="w-full" onClick={signIn}>Continue as demo reader</Button>
          </div>
        </DialogContent>
      </Dialog>

      <CommentModal isOpen={discussionOpen} onClose={() => setDiscussionOpen(false)} contentDetails={contentDetails}
        isLoading={loadings} error={error} isAuthenticated={false}
        demoReader={{
          signedIn,
          comments: contentDetails ? localComments[contentDetails.id] ?? [] : [],
          onAddComment: addComment,
        }} />
    </div>
  );
}
