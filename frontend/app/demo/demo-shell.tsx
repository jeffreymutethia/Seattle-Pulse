"use client";

import { useEffect, useRef, type ReactNode } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Sidebar } from "@/components/sidebar";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";
import { useDemoSession } from "./demo-session";

export function DemoShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const { ready, isSignedIn, signOut } = useDemoSession();
  const mainRef = useRef<HTMLElement>(null);
  useEffect(() => {
    if (mainRef.current) mainRef.current.scrollTop = 0;
  }, [pathname]);
  if (pathname.startsWith("/auth")) return <main id="app-main" className="min-h-screen">{children}</main>;

  return (
    <div className="flex h-dvh bg-[#FAFBFF]">
      <Sidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <div className="flex flex-wrap items-center justify-between gap-x-4 gap-y-1 border-b border-emerald-100 bg-emerald-50 px-4 py-2 text-xs leading-5 text-emerald-950 md:px-8" data-cy="demo-disclosure">
          <p><span className="font-semibold">Demo edition</span> · Original guides, fictional publishers and reader account, sample conversations. Changes stay in this tab.</p>
          {ready && isSignedIn ? <button onClick={signOut} className="shrink-0 font-semibold underline underline-offset-2 md:hidden">Sign out</button> : <Link href="/auth/login/" className="shrink-0 font-semibold underline underline-offset-2 md:hidden">Sign in</Link>}
        </div>
        <main ref={mainRef} id="app-main" className="min-h-0 min-w-0 flex-1 overflow-auto pb-24 md:pb-0">{children}</main>
      </div>
      <MobileBottomNav />
    </div>
  );
}
