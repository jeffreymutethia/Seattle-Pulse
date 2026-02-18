/* eslint-disable @typescript-eslint/no-explicit-any */
"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { useResetPasswordRequest } from "@/app/hooks/use-auth";
import { ResetPasswordReqRequest } from "@/app/services/auth-service";

export default function ResetPassword() {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState(""); 
  const [isError, setIsError] = useState(false); 
  const [loading, setLoading] = useState(false);
  const { resetPasswordReq } = useResetPasswordRequest();

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage(""); 
    setIsError(false);
    setLoading(true);

    const formData = new FormData(event.currentTarget);
    const data: ResetPasswordReqRequest = {
      email: formData.get("email") as string,
    };

    try {
      const response = await resetPasswordReq(data);

      if (response?.status === "error") {
        setIsError(true);
        setMessage(response.message || "Failed to send reset email.");
      } else {
        setIsError(false);
        setMessage("Email sent successfully! Please check your inbox.");
      }
    } catch (err: any) {
      setIsError(true);
      setMessage(err?.message || "Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  }

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
          href="/auth/login"
          className="absolute top-4 left-4 text-white flex items-center gap-2 hover:opacity-80 transition-opacity"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back</span>
        </Link>

        <div className="w-full p-8 flex justify-center">
          <img
            src="https://seattlepulse-logos.s3.us-east-1.amazonaws.com/Seattle+Pulse_Logo/sp_full+color/sp_full+color_light+background/sp_logo_color_light_bg_1024px_PNG24.png"
            className="w-36 h-36" alt={""}          />
        </div>

        <Card className="w-full max-w-lg h-[420px] mx-auto p-8 rounded-3xl ">
          <CardHeader className="space-y-6">
            <CardTitle className="font-semibold text-xl">
              Recover Password
            </CardTitle>
          </CardHeader>
          <CardContent>
            {/* Show error or success message dynamically */}
            {message && (
              <p
                className={`text-sm mb-4 ${
                  isError ? "text-red-600" : "text-green-600"
                }`}
              >
                {message}
              </p>
            )}

            {/* Default message when no success or error */}
            {!message && (
              <p className="text-sm text-muted-foreground mb-4">
                Enter your email below to recover your password
              </p>
            )}

            <form onSubmit={onSubmit}>
              <div className="">
                <p className="mb-1">Email</p>
                <Input
                  name="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="email@email.com"
                  className="rounded-3xl h-12 border-[1px] border-[#ABB0B9]"
                />
              </div>
              <Button
                className="w-full h-12 bg-[#0a0a0a] hover:bg-gray-500 rounded-full mt-6"
                disabled={loading} // Disable button while loading
              >
                {loading ? "Sending..." : "Send reset link"}
              </Button>
            </form>

            <div className="text-center text-sm ">
              <div className="mt-4">
                <span>Remembered your password? </span>
                <Link
                  href="/auth/login"
                  className="text-gray-900 font-semibold"
                >
                  Login
                </Link>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
