"use client";

import Link from "next/link";
import Image from "next/image";
import {  LogOut, Settings, Menu } from "lucide-react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/app/context/auth-context";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu";
import { apiClient } from "@/app/api/api-client";

export function MobileHeader() {
  const router = useRouter();
  const { isAuthenticated } = useAuth();

  const handleLogout = async () => {
    try {
      await apiClient.post("/auth/logout");
      sessionStorage.removeItem("user");
      window.location.href = "/";
    } catch (error) {
      console.error("Logout failed:", error);
    }
  };

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-white border-b border-gray-200 md:hidden">
      <div className="flex items-center justify-between px-4 h-14">
        {/* Seattle Pulse Logo - links to home */}
        <Link href="/" className="flex items-center">
          <Image
            src="/sp-micro-icon.svg"
            alt="Seattle Pulse"
            width={32}
            height={32}
            className="object-contain"
          />
          <span className="ml-2 text-lg font-bold text-black">Seattle Pulse</span>
        </Link>
        
        {/* More menu - only for authenticated users */}
        {isAuthenticated && (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button
                size="icon"
                variant="ghost"
                className="rounded-full bg-white w-11 h-11 border-[#E2E8F0] border-2"
                aria-label="More"
              >
                <Menu className="h-5 w-5 text-black" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-56">
              <DropdownMenuItem onClick={() => router.push("/setting")}> 
                <Settings className="mr-2 h-4 w-4" />
                <span>Settings</span>
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={handleLogout} className="text-red-600 focus:text-red-600">
                <LogOut className="mr-2 h-4 w-4" />
                <span>Logout</span>
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        )}
      </div>
    </header>
  );
}

