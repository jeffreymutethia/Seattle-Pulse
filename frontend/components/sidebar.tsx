"use client";

import Image from "next/image";
import Link from "next/link";
import { useRouter, usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { MoreHorizontal, Download } from "lucide-react";
import { cn } from "@/lib/utils";
import { FULL_LOGO_SRC } from "@/lib/brand-assets";
import { Button } from "@/components/ui/button";
import { AvatarWithFallback } from "@/components/ui/avatar-with-fallback";
import { apiClient } from "@/app/api/api-client";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu";

interface User {
  user_id: number;
  username: string;
  email: string;
  first_name: string;
  last_name: string;
  profile_picture_url: string;
}

interface SidebarProps {
  isGuest?: boolean;
}

export function Sidebar({ isGuest = false }: SidebarProps) {
  const router = useRouter();
  const pathname = usePathname();
  const [user, setUser] = useState<User | null>(null);

  const SHOW_BETA_DOWNLOAD = false;

  useEffect(() => {
    // Only check for user if not in guest mode
    if (!isGuest) {
      const storedUser = sessionStorage.getItem("user");
      if (storedUser) {
        setUser(JSON.parse(storedUser));
      }
    }
  }, [isGuest]);

  const handleLogout = async () => {
    try {
      await apiClient.post("/auth/logout");

      sessionStorage.removeItem("user");
      window.location.href = "/";
    } catch (error) {
      console.error("Logout failed:", error);
    }
  };

  const handleTestFlightDownload = () => {
    // Placeholder for TestFlight link
    window.open("https://testflight.apple.com/placeholder", "_blank");
  };

  const handlePlayStoreDownload = () => {
    // Placeholder for Play Store link
    window.open("https://play.google.com/store/apps/placeholder", "_blank");
  };

  return (
    <>
      <div className="hidden md:flex flex-col h-full w-[250px] border-r bg-white">
        <div className="flex justify-center h-16 items-center p-16">
          <Image
            src={FULL_LOGO_SRC}
            alt="Seattle Pulse Logo"
            width={195}
            height={195}
            className="rounded-none"
            priority
          />
        </div>
        
      

        {/* Navigation */}
        <nav className="flex-1 py-20">
          <Button
            variant="ghost"
            className={cn(
              "w-full h-12 justify-start gap-2 rounded-none",
              pathname === "/"
                ? "bg-black text-white py-2 hover:bg-black hover:text-white"
                : "bg-white text-black"
            )}
            asChild
          >
            <Link href="/">
              <Image
                src="/Feed.svg"
                alt="feed"
                width={24}
                height={24}
                style={{
                  filter: pathname === "/" ? "invert(100%)" : "invert(0%)",
                }}
              />
              Feed
            </Link>
          </Button>

          <Button
            variant="ghost"
            className={cn(
              "w-full h-12 justify-start gap-2 rounded-none",
              pathname === "/add-story"
                ? "bg-black text-white py-2 hover:bg-black hover:text-white"
                : "bg-white text-black"
            )}
            asChild
          >
            <Link href="/add-story">
              <Image
                src="/AddCircle.svg"
                alt="add story"
                width={24}
                height={24}
                style={{
                  filter:
                    pathname === "/add-story"
                      ? "invert(100%)"
                      : "invert(0%)",
                }}
              />
              Add Your Story
            </Link>
          </Button>

          <Button
            variant="ghost"
            className={cn(
              "w-full h-12 justify-start gap-2 rounded-none",
              pathname === "/mypulse"
                ? "bg-black text-white py-2 hover:bg-black hover:text-white"
                : "bg-white text-black"
            )}
            asChild
          >
            <Link href="/mypulse">
              <Image
                src="/Pulse.svg"
                alt="my pulse"
                width={24}
                height={24}
                style={{
                  filter:
                    pathname === "/mypulse"
                      ? "invert(100%)"
                      : "invert(0%)",
                }}
              />
              My Pulse
            </Link>
          </Button>
        </nav>

        {/* Download Beta Section (Feature Flag Controlled) */}
        {SHOW_BETA_DOWNLOAD && (
          <div className="border-t p-4">
            <div className="text-center mb-3">
              <h3 className="text-sm font-semibold text-gray-900 mb-1">
                Download the Beta
              </h3>
              <p className="text-xs text-gray-500 mb-3">
                Try our latest features
              </p>
            </div>
            <div className="space-y-2">
              <Button
                variant="outline"
                size="sm"
                className="w-full h-10 text-xs"
                onClick={handleTestFlightDownload}
              >
                <Download className="w-4 h-4 mr-2" />
                TestFlight (iOS)
              </Button>
              <Button
                variant="outline"
                size="sm"
                className="w-full h-10 text-xs"
                onClick={handlePlayStoreDownload}
              >
                <Download className="w-4 h-4 mr-2" />
                Play Store (Android)
              </Button>
            </div>
          </div>
        )}

        {/* User Profile */}
        <div className="border-t p-2">
          {!isGuest && user ? (
            <div className="flex items-center gap-2 p-2">
              <AvatarWithFallback
                src={user.profile_picture_url}
                alt="Profile picture"
                fallbackText={`${user.first_name?.[0] || ""}${user.last_name?.[0] || ""}` || user.username?.[0] || "?"}
                size="md"
              />
              <div className="flex-1 truncate">
                <div className="font-medium">{user.username}</div>
                <div className="text-xs text-muted-foreground">
                  {user.email}
                </div>
              </div>
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="icon" className="h-8 w-8">
                    <MoreHorizontal className="h-4 w-4" />
                    <span className="sr-only">Open menu</span>
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem
                    onClick={() =>
                      router.push(`/profile/${user.username}`)
                    }
                  >
                    View profile
                  </DropdownMenuItem>
                  <DropdownMenuItem
                    onClick={() => router.push("/setting")}
                  >
                    Settings
                  </DropdownMenuItem>
                  {SHOW_BETA_DOWNLOAD && (
                    <>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem
                        onClick={handleTestFlightDownload}
                        className="text-xs"
                      >
                        <Download className="w-3 h-3 mr-2" />
                        TestFlight (iOS)
                      </DropdownMenuItem>
                      <DropdownMenuItem
                        onClick={handlePlayStoreDownload}
                        className="text-xs"
                      >
                        <Download className="w-3 h-3 mr-2" />
                        Play Store (Android)
                      </DropdownMenuItem>
                    </>
                  )}
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onClick={handleLogout}>
                    Sign out
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          ) : !isGuest ? (
            <div className="text-center text-sm text-muted-foreground p-2">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="icon" className="h-8 w-8">
                    <MoreHorizontal className="h-4 w-4" />
                    <span className="sr-only">Open menu</span>
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem
                    onClick={() => router.push("/setting")}
                  >
                    Settings
                  </DropdownMenuItem>
                  {SHOW_BETA_DOWNLOAD && (
                    <>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem
                        onClick={handleTestFlightDownload}
                        className="text-xs"
                      >
                        <Download className="w-3 h-3 mr-2" />
                        TestFlight (iOS)
                      </DropdownMenuItem>
                      <DropdownMenuItem
                        onClick={handlePlayStoreDownload}
                        className="text-xs"
                      >
                        <Download className="w-3 h-3 mr-2" />
                        Play Store (Android)
                      </DropdownMenuItem>
                    </>
                  )}
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onClick={handleLogout}>
                    Sign out
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
              {/* Loading... */}
            </div>
          ) : null}
        </div>
      </div>

      {/* === MOBILE BUBBLE BOTTOM NAV === */}
      <nav className="flex md:hidden fixed bottom-3 inset-x-4 z-50 bg-slate-500 rounded-full shadow-lg p-2 justify-around">
        {[
          { href: "/", icon: "/Feed.svg", alt: "Feed" },
          { href: "/add-story", icon: "/AddCircle.svg", alt: "Add" },
          { href: "/mypulse", icon: "/Pulse.svg", alt: "My Pulse" },
        ].map(({ href, icon, alt }) => {
          const active = pathname === href;
          return (
            <Link key={href} href={href}>
              <div
                className={cn(
                  "p-3 rounded-full transition",
                  active
                    ? "bg-black"
                    : "bg-gray-100 hover:bg-gray-200"
                )}
              >
                <Image
                  src={icon}
                  alt={alt}
                  width={24}
                  height={24}
                  style={{
                    filter: active
                      ? "invert(100%)"
                      : "invert(30%)",
                  }}
                />
              </div>
            </Link>
          );
        })}

        {/* Profile Bubble */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button
              className={cn(
                "p-3 rounded-full transition",
                pathname.startsWith("/profile") ||
                pathname === "/setting"
                  ? "bg-black"
                  : "bg-gray-100 hover:bg-gray-200"
              )}
            >
              <Image
                src={ "https://img.icons8.com/ios/100/guest-male.png"}
                alt="Me"
                width={24}
                height={24}
                className="w-6 h-6 rounded-full"
                style={{
                  filter:
                    pathname.startsWith("/profile") ||
                    pathname === "/setting"
                      ? "invert(100%)"
                      : "invert(30%)",
                }}
              />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            {user && (
              <DropdownMenuItem
                onClick={() =>
                  router.push(`/profile/${user.username}`)
                }
              >
                View profile
              </DropdownMenuItem>
            )}
            <DropdownMenuItem onClick={() => router.push("/setting")}>
              Settings
            </DropdownMenuItem>
            {SHOW_BETA_DOWNLOAD && (
              <>
                <DropdownMenuSeparator />
                <DropdownMenuItem
                  onClick={handleTestFlightDownload}
                  className="text-xs"
                >
                  <Download className="w-3 h-3 mr-2" />
                  TestFlight (iOS)
                </DropdownMenuItem>
                <DropdownMenuItem
                  onClick={handlePlayStoreDownload}
                  className="text-xs"
                >
                  <Download className="w-3 h-3 mr-2" />
                  Play Store (Android)
                </DropdownMenuItem>
              </>
            )}
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={handleLogout}>
              Sign out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </nav>
    </>
  );
}
