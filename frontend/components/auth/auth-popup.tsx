"use client";

import Link from "next/link";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogTitle,
} from "@/components/ui/dialog";
import Image from "next/image";
import { trackEvent } from "@/lib/mixpanel";

export type AuthAction = "interact" | "comment" | "react" | "repost" | "scroll";

interface AuthPopupProps {
  isOpen: boolean;
  onClose: () => void;
  action?: AuthAction;
}

// const actionMessages = {
//   interact: "Sign in or create an account to interact with posts.",
//   comment: "Sign in or create an account to comment on posts.",
//   react: "Sign in or create an account to react to posts.",
//   repost: "Sign in or create an account to repost content.",
//   scroll: "Create an account to get the full experience.",
// };

export function AuthPopup({
  isOpen,
  onClose,
  // action = "interact",
}: AuthPopupProps) {
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent
        className="!flex !flex-col !items-center !justify-center !rounded-2xl overflow-visible border-none bg-white px-4 py-0 max-w-[95vw] sm:max-w-md sm:px-6 sm:py-0"
        style={{
          paddingLeft: "1.25rem",
          paddingRight: "1.25rem",
        }}
      >
        <DialogTitle className="sr-only">Authentication required</DialogTitle>
        
        {/* Close Button */}
        

        {/* Logo - floating above the card */}
        <div className="flex justify-center w-full">
          <div
            className="absolute -top-8 left-1/2 -translate-x-1/2 z-20"
            style={{}}
          >
            <div className="w-20 pb-3 h-20 rounded-full bg-white flex items-center justify-center  border-4 border-white">
              <Image
                src="/sp-light-bg.svg"
                alt="Seattle Pulse"
                width={64}
                height={64}
                
                className="object-contain"
                priority
              />
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="flex flex-col items-center w-full pt-12 pb-6 px-2 text-center">
          <h2 className="text-xl font-semibold text-black mb-2">
          Join the Seattle Pulse community 🌆
          </h2>
          <DialogDescription className="text-base text-gray-600 mb-6">
          Log in or create an account to explore what’s happening around Seattle.
          </DialogDescription>

          {/* Action Buttons */}
          <div className="flex flex-col gap-3 w-full">
            <Button
              className="w-full h-12 rounded-lg text-base font-semibold bg-[#FF0050] hover:bg-[#e60047] text-white shadow-md"
              asChild
            >
              <Link 
                href="/auth/signup"
                onClick={() => trackEvent("signup_cta_clicked", { source: "auth_popup", action: "signup" })}
              >
                Create account
              </Link>
            </Button>
            <Button
              className="w-full h-12 rounded-lg text-base font-semibold border border-gray-300 bg-white text-gray-700 hover:bg-white shadow-sm"
              asChild
            >
              <Link 
                href="/auth/login"
                onClick={() => trackEvent("signup_cta_clicked", { source: "auth_popup", action: "login" })}
              >
                Log in
              </Link>
            </Button>
           
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
