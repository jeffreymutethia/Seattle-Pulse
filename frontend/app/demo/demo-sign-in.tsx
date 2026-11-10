"use client";

import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { FULL_LOGO_SRC } from "@/lib/brand-assets";
import { useDemoSession } from "./demo-session";

/** The original login artwork and card, with a browser-local demo entry point. */
export function DemoSignIn() {
  const router = useRouter();
  const { signIn } = useDemoSession();

  const continueAsReader = () => {
    signIn();
    router.push("/");
  };

  return (
    <div
      className="flex min-h-screen w-full items-center justify-center bg-cover bg-center"
      style={{ backgroundImage: "url('/bg-up.png')" }}
    >
      <div className="w-full max-w-lg p-4 py-8">
        <div className="flex justify-center pb-8">
          <Link href="/" aria-label="Seattle Pulse — back to browsing">
            <Image
              src={FULL_LOGO_SRC}
              alt="Seattle Pulse"
              width={144}
              height={144}
              className="h-36 w-36"
              priority
            />
          </Link>
        </div>
        <section
          aria-labelledby="demo-sign-in-title"
          className="mx-auto w-full max-w-lg space-y-6 rounded-3xl bg-white p-6 shadow-sm sm:p-8"
        >
          <div className="space-y-3">
            <p className="text-xs font-semibold uppercase tracking-widest text-emerald-800">Portfolio demo</p>
            <h1 id="demo-sign-in-title" className="text-xl font-semibold">Sign in — welcome back!</h1>
            <p className="text-sm leading-6 text-gray-600">
              Step into Seattle Pulse as a demo reader. Explore the sources you follow in My Pulse and a populated sample profile.
            </p>
          </div>

          <Button
            type="button"
            onClick={continueAsReader}
            data-cy="continue-as-demo-reader"
            className="h-12 w-full rounded-full bg-black py-2 text-white hover:bg-gray-800"
          >
            Continue as demo reader
          </Button>

          <p className="text-xs leading-5 text-gray-500">
            Fictional demo account. No password or personal information needed. Your demo session and interactions stay in this browser.
          </p>

          <div className="border-t pt-5 text-center">
            <Link href="/" className="inline-flex items-center gap-2 text-sm font-medium text-gray-900 underline underline-offset-4">
              <ArrowLeft className="h-4 w-4" aria-hidden="true" />
              Back to browsing
            </Link>
          </div>
        </section>
      </div>
    </div>
  );
}
