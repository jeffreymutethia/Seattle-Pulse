"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { User } from "lucide-react";
import { FULL_LOGO_SRC } from "@/lib/brand-assets";
import { cn } from "@/lib/utils";
import { useDemoSession } from "./demo-session";

const destinations = [
  { href: "/", label: "The Feed", icon: "/Feed.svg" },
  { href: "/mypulse/", label: "My Pulse", icon: "/Pulse.svg" },
  { href: "/profile/", label: "Profile", icon: null },
];

function isCurrent(pathname: string, href: string) {
  return (pathname.replace(/\/$/, "") || "/") === (href.replace(/\/$/, "") || "/");
}

export function DemoSidebar() {
  const pathname = usePathname();
  const { ready, isSignedIn, reader, signOut } = useDemoSession();

  return (
    <aside className="hidden h-full w-[250px] flex-col border-r bg-white md:flex">
      <Link href="/" aria-label="Seattle Pulse home" className="flex justify-center px-12 py-5">
        <Image src={FULL_LOGO_SRC} alt="Seattle Pulse" width={150} height={150} priority />
      </Link>
      <nav aria-label="Product navigation" data-cy="demo-nav" className="flex-1 py-8">
        {destinations.map(destination => {
          const active = isCurrent(pathname, destination.href);
          return <Link key={destination.href} href={destination.href} aria-current={active ? "page" : "false"}
            className={cn("flex min-h-12 items-center gap-3 px-7 py-3 text-sm font-semibold transition-colors", active ? "bg-black text-white" : "text-black hover:bg-slate-100")}>
            {destination.icon ? <Image src={destination.icon} alt="" width={24} height={24} style={{ filter: active ? "invert(100%)" : undefined }} /> : <User aria-hidden="true" className="h-6 w-6" />}
            {destination.label}
          </Link>;
        })}
      </nav>
      <div className="border-t p-5">
        {ready && isSignedIn ? <>
          <Link href="/profile/" aria-label="Your demo profile" className="flex items-center gap-3">
            <Image src={reader.profile_picture_url} alt={`${reader.first_name} ${reader.last_name}`} width={44} height={44} className="h-11 w-11 rounded-full object-cover" />
            <div className="min-w-0"><p className="truncate text-sm font-semibold">{reader.first_name} {reader.last_name}</p><p className="text-xs text-gray-500">@{reader.username}</p></div>
          </Link>
          <button onClick={signOut} className="mt-4 text-sm font-semibold text-gray-600 underline underline-offset-4">Sign out</button>
        </> : <>
          <p className="mb-3 text-xs leading-5 text-gray-500">Browse freely. Try a local reader session to follow sources and join a discussion.</p>
          <Link href="/auth/login/" data-cy="demo-sign-in-link" className="flex min-h-11 items-center justify-center rounded-full bg-black px-4 text-sm font-semibold text-white hover:bg-gray-800">Sign in</Link>
        </>}
      </div>
    </aside>
  );
}

export function DemoMobileNavigation() {
  const pathname = usePathname();
  return (
    <nav aria-label="Mobile product navigation" data-cy="demo-nav" className="fixed inset-x-0 bottom-0 z-40 border-t bg-white md:hidden" style={{ paddingBottom: "env(safe-area-inset-bottom)" }}>
      <div className="grid h-16 grid-cols-3">
        {destinations.map(destination => {
          const active = isCurrent(pathname, destination.href);
          return <Link key={destination.href} href={destination.href} aria-current={active ? "page" : "false"}
            className={cn("flex flex-col items-center justify-center gap-1 text-xs", active ? "bg-slate-100 font-semibold text-black" : "text-gray-500")}>
            {destination.icon ? <Image src={destination.icon} alt="" width={24} height={24} style={{ opacity: active ? 1 : 0.55 }} /> : <User aria-hidden="true" className="h-6 w-6" />}
            {destination.label}
          </Link>;
        })}
      </div>
    </nav>
  );
}
