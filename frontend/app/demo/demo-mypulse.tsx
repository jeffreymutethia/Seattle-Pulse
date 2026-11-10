"use client";

import Image from "next/image";
import NavBar from "@/components/nav-bar";
import { Button } from "@/components/ui/button";
import { demoPosts, demoPublishers } from "./fixtures";
import { useDemoSession } from "./demo-session";
import { DemoStoryFeed } from "./demo-story-feed";
import { DemoMemberGate } from "./demo-member-gate";

export function DemoMyPulse() {
  const { ready, isSignedIn, followedSourceIds, toggleFollow } = useDemoSession();
  const posts = demoPosts.filter(post => followedSourceIds.includes(post.user.id));

  const sourceList = <div className="space-y-4" data-cy="demo-sources">
    {demoPublishers.map(publisher => {
      const following = followedSourceIds.includes(publisher.id);
      return <div key={publisher.id} data-cy="publisher-row" data-source-id={publisher.id} className="flex items-center gap-3">
        <Image src={publisher.avatar} alt={publisher.name} width={40} height={40} className="h-10 w-10 shrink-0 rounded-full object-cover" />
        <div className="min-w-0 flex-1"><p className="text-sm font-semibold">{publisher.name}</p><p className="truncate text-xs text-gray-500">{publisher.location.replace(", Seattle", "")}</p></div>
        <Button size="sm" variant={following ? "outline" : "default"} className="min-w-20 rounded-full text-xs"
          data-cy={`follow-source-${publisher.id}`} aria-label={`${following ? "Unfollow" : "Follow"} ${publisher.name}`} aria-pressed={following}
          onClick={() => toggleFollow(publisher.id)}>{following ? "Following" : "Follow"}</Button>
      </div>;
    })}
  </div>;

  return <div className="mx-auto w-full max-w-6xl p-4 md:p-8" data-cy="demo-mypulse">
    <NavBar title="My Pulse" showLocationSelector={false} showSearch={false} showNotification={false} showMessage={false} />
    <h1 className="sr-only md:hidden">My Pulse</h1>
    {!ready || !isSignedIn ? <DemoMemberGate title="My Pulse" /> : <>
      <div className="mb-6"><h2 className="text-xl font-medium">Posts from the sources you follow</h2><p className="mt-2 text-sm leading-6 text-gray-600">Your own corner of Seattle. Follow a source to bring its guides into this feed.</p></div>
      <div className="flex flex-col items-start justify-center gap-6 lg:flex-row">
        <div className="order-last min-w-0 w-full max-w-xl flex-1 lg:order-first">
          <p aria-live="polite" className="mb-3 text-sm text-gray-600">{posts.length} guides from {followedSourceIds.length} followed sources</p>
          {posts.length ? <DemoStoryFeed posts={posts} /> : <div className="rounded-3xl border bg-white p-8 text-center"><h3 className="font-semibold">Your next discovery starts with a follow.</h3><p className="mt-2 text-sm text-gray-600">Choose any source to see its guide here.</p></div>}
        </div>
        <aside className="w-full rounded-3xl border bg-white p-5 lg:w-80 lg:shrink-0">
          <h2 className="text-lg font-semibold">Sources for your Pulse</h2>
          <p className="mb-5 mt-1 text-xs leading-5 text-gray-500">Fictional publishers, original guides. Following changes only this tab.</p>
          <details className="lg:hidden"><summary className="cursor-pointer text-sm font-semibold">Manage sources</summary><div className="mt-5">{sourceList}</div></details>
          <div className="hidden lg:block">{sourceList}</div>
        </aside>
      </div>
    </>}
  </div>;
}
