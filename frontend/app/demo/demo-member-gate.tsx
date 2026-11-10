"use client";

import Link from "next/link";
import { useDemoSession } from "./demo-session";

export function DemoMemberGate({ title }: { title: string }) {
  const { ready } = useDemoSession();
  if (!ready) return <p role="status" className="p-8 text-sm text-gray-600">Loading your demo session…</p>;
  return <section className="mx-auto max-w-xl rounded-3xl border bg-white p-6 text-center sm:p-10">
    <h2 className="text-xl font-semibold">Make {title === "My Pulse" ? "this feed" : "this profile"} yours</h2>
    <p className="mt-3 text-sm leading-6 text-gray-600">Continue as Alex, our sample Seattle reader. Follow local sources, save your reader details, and add a comment without creating an account.</p>
    <Link href="/auth/login/" className="mt-6 inline-flex min-h-11 items-center justify-center rounded-full bg-black px-6 text-sm font-semibold text-white hover:bg-gray-800">Sign in to try {title}</Link>
    <Link href="/" className="mt-4 block text-sm font-medium underline underline-offset-4">Keep browsing The Feed</Link>
  </section>;
}
