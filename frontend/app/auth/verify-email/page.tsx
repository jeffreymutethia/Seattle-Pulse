/* eslint-disable @typescript-eslint/no-unused-vars */
"use client";

import Image from "next/image";
import Link from "next/link";
import { useSearchParams, useRouter } from "next/navigation";
import { useEffect, useState, useCallback } from "react";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import {
  useResendEmailVerification,
  useVerifyEmail,
} from "@/app/hooks/use-auth";
import { useAuth } from "@/app/context/auth-context";
import { trackEvent, identifyUser } from "@/lib/mixpanel";
import { FULL_LOGO_SRC } from "@/lib/brand-assets";

export default function VerifyEmail() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const token = searchParams.get("token");
  const email = searchParams.get("email");

  const { verifyEmail } = useVerifyEmail();
  const {
    resendEmailVerification,
    error: resendError,
    loading,
  } = useResendEmailVerification();
  const { checkAuth } = useAuth();

  const [status, setStatus] = useState<
    "loading" | "success" | "error" | "info"
  >("loading");
  const [message, setMessage] = useState<string>("Verifying your email...");
  const [countdown, setCountdown] = useState(5);
  const [cooldown, setCooldown] = useState(0);

  useEffect(() => {
    let isMounted = true;

    if (token) {
      verifyEmail(token)
        .then((response) => {
          if (isMounted) {
            if (response?.status === "success") {
              setStatus("success");
              setMessage(response.message);

              // Store user data from verification response in sessionStorage
              // The response includes full user data (user_id, username, email, etc.)
              const responseWithData = response as {
                status: string;
                message: string;
                data?: {
                  user_id: number;
                  username: string;
                  email: string;
                  first_name: string;
                  last_name: string;
                  profile_picture_url?: string;
                  home_location?: string;
                };
              };
              
              if (responseWithData?.data) {
                const userData = {
                  user_id: responseWithData.data.user_id,
                  username: responseWithData.data.username,
                  email: responseWithData.data.email,
                  first_name: responseWithData.data.first_name,
                  last_name: responseWithData.data.last_name,
                  profile_picture_url: responseWithData.data.profile_picture_url || "",
                  home_location: responseWithData.data.home_location || "",
                };
                sessionStorage.setItem("user_id", responseWithData.data.user_id.toString());
                sessionStorage.setItem("user", JSON.stringify(userData));
              }

              //  Refresh authentication state after successful verification
              // The backend sets a session cookie, so we need to check auth status
              checkAuth()
                .then(() => {
                  // Track email_confirmed event after auth is refreshed
                  trackEvent("email_confirmed");

                  // Identify user in Mixpanel after auth state is updated
                  try {
                    const userStr = sessionStorage.getItem("user");
                    if (userStr) {
                      const user = JSON.parse(userStr);
                      const userId = user.user_id || user.id;
                      if (userId) {
                        identifyUser(userId);
                      }
                    }
                  } catch (error) {
                    console.error("Error identifying user in Mixpanel:", error);
                  }
                })
                .catch((error) => {
                  console.error("Error refreshing auth state:", error);
                  // Still track the event even if auth refresh fails
                  trackEvent("email_confirmed");
                });

              //  If already verified, redirect immediately
              if (response.message.includes("already verified")) {
                setTimeout(() => {
                  router.push("/");
                }, 2000);
                return;
              }

              //  If newly verified, start countdown
              let counter = 5;
              const interval = setInterval(() => {
                counter -= 1;
                if (isMounted) {
                  setCountdown(counter);
                }
                if (counter === 0) {
                  clearInterval(interval);
                  router.push("/");
                }
              }, 1000);
            } else {
              setStatus("error");
              setMessage(response?.message || "Email verification failed.");
            }
          }
        })
        .catch((err) => {
          if (isMounted) {
            setStatus("error");
            setMessage(
              err?.message || "Something went wrong during verification."
            );
          }
        });
    } else if (email) {
      setStatus("info");
      setMessage(`A verification email has been sent to ${email}.`);
      setCooldown(120); // Set resend cooldown to 60 seconds
    } else {
      setStatus("error");
      setMessage("Invalid verification request.");
    }

    return () => {
      isMounted = false;
    };
  }, [token, email, verifyEmail, router, checkAuth]);

  useEffect(() => {
    if (cooldown === 0) return;

    const timer = setInterval(() => {
      setCooldown((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);

    return () => clearInterval(timer);
  }, [cooldown]);

  const handleResendEmail = useCallback(async () => {
    if (!email || cooldown > 0) return;

    try {
      await resendEmailVerification({ email });
      setMessage("Verification email resent. Please check your inbox.");
    } catch (err) {
      setMessage("Failed to resend email. Please try again later.");
    } finally {
      setCooldown(120); // Reset cooldown to 120 seconds
    }
  }, [email, cooldown, resendEmailVerification]);

  return (
    <div className="min-h-screen relative bg-gray-100">
      <div className="absolute inset-0 z-0">
        <Image
          src="/bg-up.png"
          alt="Seattle Skyline"
          fill
          className="object-cover"
          priority
        />
      </div>

      <div className="relative z-10 min-h-screen">
        <Link
          href="/auth/signup"
          className="absolute top-4 left-4 text-white flex items-center gap-2 hover:opacity-80 transition-opacity"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back</span>
        </Link>

        <div className="w-full p-8 flex justify-center">
          <Image
                        src={FULL_LOGO_SRC}
            
            className="w-36 h-36 pb-8"
            width={144}
            height={144}
            alt="Seattle Pulse Logo"
          />
        </div>

        <Card className="w-full max-w-lg h-auto mx-auto p-8 rounded-3xl">
          <CardHeader>
            <CardTitle>Email Verification</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Show API response message */}
            <p
              className={`text-sm text-center ${
                status === "success"
                  ? "text-green-600"
                  : status === "error"
                  ? "text-red-600"
                  : "text-black"
              }`}
            >
              {message}
            </p>

            {/*  Show countdown only if email is newly verified */}
            {status === "success" &&
              !message.includes("already verified") &&
              countdown > 0 && (
                <p className="text-sm text-center text-green-500">
                  Redirecting in {countdown} seconds...
                </p>
              )}

            {/* Show Resend Email Button */}
            {email && status !== "success" && (
              <>
                <Button
                  onClick={handleResendEmail}
                  disabled={loading || cooldown > 0}
                  className="w-full rounded-3xl bg-black hover"
                  variant="default"
                >
                  {loading ? "Resending..." : "Resend Email"}
                </Button>
                {cooldown > 0 && (
                  <p className="text-sm font-normal text-[#707988] text-center mt-2">
                    Resend email after {cooldown}s
                  </p>
                )}
                {resendError && (
                  <p className="text-sm font-normal text-red-600 text-center mt-2">
                    {resendError}
                  </p>
                )}
              </>
            )}

            <p className="text-sm text-center">
              Need Help?{" "}
              <a
                href="mailto:support@seattlepulse.net"
                className="text-primary underline text-[#4C68D5] hover:text-[#4C68D5]"
              >
                Contact our Customer Support
              </a>
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
