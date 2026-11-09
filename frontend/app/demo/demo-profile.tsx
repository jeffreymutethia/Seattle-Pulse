"use client";

import { useState } from "react";
import Image from "next/image";
import { BookOpen, MessageCircle } from "lucide-react";
import NavBar from "@/components/nav-bar";
import ProfileHeader from "@/app/profile/components/profile-Header";
import CommentModal from "@/components/comments/comment-modal";
import { useContentDetails } from "@/app/hooks/use-content-details";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { demoNeighborhoods, demoPosts } from "./fixtures";
import { useDemoSession } from "./demo-session";
import { DemoMemberGate } from "./demo-member-gate";

const savedGuideIds = [9101, 9102, 9201, 9401, 9501, 9601];

export function DemoProfile() {
  const { ready, isSignedIn, reader, followedSourceIds, comments, addComment, updateReader } = useDemoSession();
  const [activeTab, setActiveTab] = useState<"saved" | "comments">("saved");
  const [editOpen, setEditOpen] = useState(false);
  const [discussionOpen, setDiscussionOpen] = useState(false);
  const [savedMessage, setSavedMessage] = useState("");
  const { contentDetails, loadings, error, getContentDetails } = useContentDetails();
  const savedGuides = demoPosts.filter(post => savedGuideIds.includes(post.id));
  const ownComments = demoPosts.flatMap(post => (comments[post.id] ?? []).map((content, index) => ({ post, content, key: `${post.id}-${index}` })));

  function openDiscussion(id: number) {
    void getContentDetails("user_content", id);
    setDiscussionOpen(true);
  }

  return <div className="mx-auto w-full max-w-6xl p-4 md:p-8" data-cy="demo-profile">
    <NavBar title="Profile" showLocationSelector={false} showSearch={false} showNotification={false} showMessage={false} />
    {!ready || !isSignedIn ? <DemoMemberGate title="Profile" /> : <>
      <p className="mb-6 text-sm text-gray-600">Your demo reader profile · Fictional sample account</p>
      <ProfileHeader userData={{
        data: { is_following: false, user_data: reader, relationships: { followers: 18, following: followedSourceIds.length, total_posts: 0 } },
        message: "Demo reader profile", success: "success",
      }} isMyProfile onFollowToggle={() => {}} onEditProfile={() => { setEditOpen(true); setSavedMessage(""); }} hideShare />
      {savedMessage && <p role="status" className="mb-4 rounded-xl bg-emerald-50 px-4 py-3 text-sm text-emerald-900">{savedMessage}</p>}

      <div className="mt-6" data-cy="profile-content">
        <div role="tablist" aria-label="Reader activity" className="flex justify-center gap-6 border-t">
          <button role="tab" aria-selected={activeTab === "saved"} aria-controls="saved-guides-panel" id="saved-guides-tab" onClick={() => setActiveTab("saved")}
            className={`flex items-center gap-2 border-t-2 py-3 text-sm ${activeTab === "saved" ? "border-black font-semibold text-black" : "border-transparent text-gray-500"}`}><BookOpen className="h-5 w-5" aria-hidden="true" />Saved guides</button>
          <button role="tab" aria-selected={activeTab === "comments"} aria-controls="reader-comments-panel" id="reader-comments-tab" onClick={() => setActiveTab("comments")}
            className={`flex items-center gap-2 border-t-2 py-3 text-sm ${activeTab === "comments" ? "border-black font-semibold text-black" : "border-transparent text-gray-500"}`}><MessageCircle className="h-5 w-5" aria-hidden="true" />Your comments <span className="text-xs">({ownComments.length})</span></button>
        </div>
        {activeTab === "saved" ? <section role="tabpanel" aria-labelledby="saved-guides-tab" id="saved-guides-panel">
          <p className="mb-4 text-center text-xs leading-5 text-gray-500">A few places in Alex’s sample reading collection. Open any guide to join its discussion.</p>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
            {savedGuides.map(post => <button data-cy="saved-guide" key={post.id} onClick={() => openDiscussion(post.id)} aria-label={`Open ${post.title}`} className="overflow-hidden rounded-2xl border bg-white text-left transition-shadow hover:shadow-md focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-black">
              <Image src={post.thumbnail} alt={post.title} width={400} height={300} className="aspect-square w-full object-cover" sizes="(max-width: 640px) 50vw, 33vw" />
              <div className="p-3"><p className="text-sm font-semibold leading-5">{post.title}</p><div className="mt-3 flex items-center gap-2"><Image src={post.user.profile_picture_url || "/demo/neighbor.svg"} alt={post.user.username} width={24} height={24} className="h-6 w-6 rounded-full" /><span className="text-xs text-gray-500">{post.user.username}</span></div></div>
            </button>)}
          </div>
        </section> : <section role="tabpanel" aria-labelledby="reader-comments-tab" id="reader-comments-panel" className="mx-auto max-w-2xl">
          {ownComments.length ? <div className="space-y-4">{ownComments.map(item => <article key={item.key} className="rounded-2xl border bg-white p-5"><p className="text-sm leading-6">{item.content}</p><button className="mt-3 text-left text-sm font-semibold text-emerald-800 underline underline-offset-4" onClick={() => openDiscussion(item.post.id)}>{item.post.title}</button><p className="mt-2 text-xs text-gray-500">Your local demo comment</p></article>)}</div> : <div className="rounded-2xl border bg-white p-8 text-center"><h2 className="font-semibold">Your next conversation starts with a guide.</h2><p className="mt-2 text-sm leading-6 text-gray-600">Comments you add during this demo session appear here.</p><Button variant="outline" className="mt-4 rounded-full" onClick={() => setActiveTab("saved")}>Explore your saved guides</Button></div>}
        </section>}
      </div>

      <Dialog open={editOpen} onOpenChange={setEditOpen}>
        <DialogContent className="max-h-[90dvh] w-[calc(100vw-2rem)] overflow-y-auto rounded-3xl sm:max-w-lg">
          <DialogTitle>Edit your demo profile</DialogTitle><DialogDescription>Changes stay in this browser tab. This is a fictional account.</DialogDescription>
          <form className="mt-3 space-y-4" onSubmit={event => {
            event.preventDefault();
            const data = new FormData(event.currentTarget);
            updateReader({ first_name: String(data.get("first_name")).trim(), last_name: String(data.get("last_name")).trim(), bio: String(data.get("bio")).trim(), location: String(data.get("location")) });
            setEditOpen(false);
            setSavedMessage("Profile updated in this demo session.");
          }}>
            <div className="grid grid-cols-2 gap-3"><label className="space-y-2 text-sm font-medium" htmlFor="demo-first-name"><span>First name</span><Input id="demo-first-name" name="first_name" defaultValue={reader.first_name} maxLength={24} required /></label><label className="space-y-2 text-sm font-medium" htmlFor="demo-last-name"><span>Last name</span><Input id="demo-last-name" name="last_name" defaultValue={reader.last_name} maxLength={24} required /></label></div>
            <label className="block space-y-2 text-sm font-medium" htmlFor="demo-bio"><span>Bio</span><textarea className="block w-full rounded-xl border p-3 text-sm font-normal" id="demo-bio" name="bio" rows={3} defaultValue={reader.bio} maxLength={280} /></label>
            <label className="block space-y-2 text-sm font-medium" htmlFor="demo-home-location"><span>Home neighborhood</span><select id="demo-home-location" name="location" defaultValue={reader.location} className="block min-h-11 w-full rounded-xl border px-3 text-sm font-normal">{demoNeighborhoods.map(location => <option key={location.value} value={location.value}>{location.name}</option>)}</select></label>
            <div className="flex justify-end gap-3"><Button type="button" variant="outline" className="rounded-full" onClick={() => setEditOpen(false)}>Cancel</Button><Button type="submit" className="rounded-full">Save changes</Button></div>
          </form>
        </DialogContent>
      </Dialog>
      <CommentModal isOpen={discussionOpen} onClose={() => setDiscussionOpen(false)} contentDetails={contentDetails} isLoading={loadings} error={error} isAuthenticated={false}
        demoReader={{ signedIn: isSignedIn, comments: contentDetails ? comments[contentDetails.id] ?? [] : [], onAddComment: addComment }} />
    </>}
  </div>;
}
