"use client";

import Image from "next/image";
import Link from "next/link";
import { usePosts } from "@/app/hooks/use-posts";
import NavBar from "@/components/nav-bar";
import { Button } from "@/components/ui/button";
import { demoNeighborhoods } from "./fixtures";
import { demoPhotography, photoCredit } from "./photography";
import { useDemoSession } from "./demo-session";
import { DemoStoryFeed } from "./demo-story-feed";

export function DemoFeed() {
  const { posts, loading, locationLoading, location, handleLocationChange } = usePosts("Seattle");
  const { ready, isSignedIn, reader } = useDemoSession();
  const feedLabel = location === "Seattle" ? "All Seattle" : location;

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
            {ready && isSignedIn ? <p role="status" className="text-sm font-medium text-emerald-200">Welcome back, {reader.first_name} · demo reader</p> : (
              <Button asChild className="bg-white text-slate-950 hover:bg-emerald-100"><Link href="/auth/login/">Try demo sign-in</Link></Button>
            )}
          </div>
        </div>
      </section>

      {loading ? <p role="status" className="p-8 text-sm text-gray-600">Loading the Seattle feed…</p> : <>
        <NavBar title="The Feed" location={location} onLocationChange={handleLocationChange}
          showSearch={false} showNotification={false} showMessage={false} />
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
