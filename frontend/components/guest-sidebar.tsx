"use client";

import Image from "next/image";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { trackEvent } from "@/lib/mixpanel";
import { FULL_LOGO_SRC } from "@/lib/brand-assets";

export function GuestSidebar() {
  return (
    <div className="hidden md:flex h-full w-[250px] flex-col border-r bg-white">
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

      <div className="flex-1 flex flex-col items-center justify-center gap-4 p-4">
        <Button
          className="w-full h-12 rounded-full text-white  hover:bg-none hover:text-white max-w-[200px]"
          asChild
        >
          <Link 
            href="/auth/login"
            onClick={() => trackEvent("signup_cta_clicked", { source: "guest_sidebar", action: "login" })}
          >
            Log In
          </Link>
        </Button>
        <div className="flex items-center ">
          <span className="px-4 text-sm text-gray-900 font-medium">OR</span>
        </div>
        <Button
          variant="outline"
          className="w-full h-12 rounded-full border-black border-2 text-black hover:bg-none max-w-[200px]"
          asChild
        >
          <Link 
            href="/auth/signup"
            onClick={() => trackEvent("signup_cta_clicked", { source: "guest_sidebar", action: "signup" })}
          >
            Sign Up
          </Link>
        </Button>
      </div>
    </div>
  );
}
