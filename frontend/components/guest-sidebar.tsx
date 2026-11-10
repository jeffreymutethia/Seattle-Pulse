"use client";

import Image from "next/image";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { trackEvent } from "@/lib/mixpanel";
import { FULL_LOGO_SRC } from "@/lib/brand-assets";
import { IS_DEMO } from "@/lib/demo";

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

      {IS_DEMO ? <div className="flex-1 px-7 py-6 text-sm leading-6 text-gray-600">
        <p className="text-xs font-semibold uppercase tracking-widest text-emerald-800">Explore Seattle Pulse</p>
        <p className="mt-4 font-semibold text-gray-950">A city is many neighborhoods.</p>
        <p className="mt-2">Find the stories and conversations that matter on your own streets.</p>
        <ol className="mt-6 list-decimal space-y-3 pl-4"><li>Browse All Seattle</li><li>Pick a neighborhood</li><li>Open a discussion</li></ol>
        <div className="mt-8 border-t pt-5"><p className="font-semibold text-gray-950">Built by Jeffrey Mutethia</p><p className="mt-2 text-xs leading-5">Web · backend · mobile · infrastructure</p>
          <a href="https://github.com/jeffreymutethia/Seattle-Pulse" className="mt-4 inline-block font-medium text-emerald-800 underline underline-offset-4">Inspect the project ↗</a>
        </div>
      </div> : <div className="flex-1 flex flex-col items-center justify-center gap-4 p-4">
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
      </div>}
    </div>
  );
}
