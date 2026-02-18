"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import React from "react";
import { Bell, Plus, User } from "lucide-react";
import { useAuth } from "@/app/context/auth-context";
import { AuthPopup } from "@/components/auth/auth-popup";
import Image from "next/image";

export function MobileBottomNav() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, isAuthenticated } = useAuth();
  const [showAuthPopup, setShowAuthPopup] = React.useState(false);

  React.useEffect(() => {
    // No-op now; kept if we want to reintroduce session updates later
  }, []);

  const isActive = (href: string) => pathname === href;

  const requireAuthOr = (action: () => void) => {
    if (!isAuthenticated) {
      setShowAuthPopup(true);
      return;
    }
    action();
  };

  const goToAddStory = () => requireAuthOr(() => router.push("/add-story"));

  const profileHref = user?.username
    ? `/profile/${encodeURIComponent(user.username)}`
    : "/auth/login";

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 md:hidden bg-white border-t border-gray-200">
      <div className="h-16 grid grid-cols-5 items-center">
        {/* Feed */}
        <Link
          href="/"
          className="flex flex-col items-center justify-center text-xs"
        >
          <Image
            src="/Feed.svg"
            alt="Feed"
            width={24}
            height={24}
            className="h-6 w-6"
            style={{ filter: isActive("/") ? "invert(0%)" : "invert(30%)" }}
          />
          <span className={`${isActive("/") ? "text-black" : "text-gray-500"}`}>Feed</span>
        </Link>

        {/* MyPulse */}
        <button
          onClick={() => requireAuthOr(() => router.push("/mypulse"))}
          className="flex flex-col items-center justify-center text-xs"
        >
          <Image
            src="/Pulse.svg"
            alt="MyPulse"
            width={24}
            height={24}
            className="h-6 w-6"
            style={{ filter: isActive("/mypulse") ? "invert(0%)" : "invert(30%)" }}
          />
          <span className={`${isActive("/mypulse") ? "text-black" : "text-gray-500"}`}>MyPulse</span>
        </button>

        {/* Add Story - Center Floating Button */}
        <button
          onClick={goToAddStory}
          className="relative -mt-8 mx-auto flex items-center justify-center h-14 w-14 rounded-full bg-black text-white shadow-lg focus:outline-none"
          aria-label="Add story"
        >
          <Plus className="h-7 w-7" />
        </button>

       

        <button
          onClick={() => requireAuthOr(() => router.push("/notification"))}
          className="flex flex-col items-center justify-center text-xs"
        >
          <Bell className={`h-6 w-6 ${pathname?.startsWith("/notification") ? "text-black" : "text-gray-500"}`} />
          <span className={`${isActive("/notification") ? "text-black" : "text-gray-500"}`}>Notification</span>
        </button>

        <button
          onClick={() => requireAuthOr(() => router.push(profileHref))}
          className="flex flex-col items-center justify-center text-xs"
        >
          <User
            className={`h-6 w-6 ${pathname?.startsWith("/profile") ? "text-black" : "text-gray-500"}`}
          />
          <span className={`${pathname?.startsWith("/profile") ? "text-black" : "text-gray-500"}`}>Profile</span>
        </button>

      </div>

      {/* Auth Popup */}
      <AuthPopup
        isOpen={showAuthPopup}
        onClose={() => setShowAuthPopup(false)}
        action="interact"
      />
    </nav>
  );
}


