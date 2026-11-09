"use client";

import { usePosts } from "@/app/hooks/use-posts";
import NavBar from "@/components/nav-bar";
import { demoNeighborhoods } from "./fixtures";
import { demoPhotography, photoCredit } from "./photography";
import { DemoStoryFeed } from "./demo-story-feed";

export function DemoFeed() {
  const { posts, loading, locationLoading, location, handleLocationChange } = usePosts("Seattle");
  const feedLabel = location === "Seattle" ? "All Seattle" : location;

  return (
    <div className="mx-auto w-full max-w-6xl px-4 pb-10 pt-4 md:px-8 md:pt-8">
      {loading ? <p role="status" className="p-8 text-sm text-gray-600">Loading the Seattle feed…</p> : <>
        <NavBar title="The Feed" location={location} onLocationChange={handleLocationChange}
          showSearch={false} showNotification={false} showMessage={false} />
        <h1 className="sr-only md:hidden">The Feed</h1>
        <div aria-live="polite" className="mx-auto mb-3 max-w-xl text-sm text-gray-600">
          {locationLoading ? "Loading neighborhood…" : `${posts.length} ${posts.length === 1 ? "story" : "stories"} · ${feedLabel} · ${demoNeighborhoods.length - 1} areas in this edition`}
        </div>
        <DemoStoryFeed posts={posts} />
      </>}

      <details className="mx-auto mt-4 max-w-xl rounded-xl border p-4 text-xs leading-6 text-gray-600">
        <summary className="cursor-pointer font-semibold text-gray-800">About this edition and photo credits</summary>
        <p className="my-2">The guides are original copy about real places, published here by fictional demo publishers. Conversation and engagement are simulated. Your session, follows, profile edits and comments stay in this browser tab.</p>
        <ul className="list-disc pl-4">
          {Object.keys(demoPhotography).map(key => {
            const credit = photoCredit(key as keyof typeof demoPhotography);
            return <li key={key}><a className="underline" href={credit.source} target="_blank" rel="noreferrer">{credit.title}</a> by {credit.author} · <a className="underline" href={credit.licenseUrl} target="_blank" rel="noreferrer">{credit.license}</a> · resized and converted to WebP</li>;
          })}
        </ul>
      </details>
    </div>
  );
}
