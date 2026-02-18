"use client";

import { useState, useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { usePasswordChange } from "@/app/hooks/use-auth";
import { ChangePasswordReqRequest } from "@/app/types/auth";

export default function ResetPassword() {
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const searchParams = useSearchParams();
  const token = searchParams.get("token");
  const router = useRouter();

  const { changePassword,  loading } = usePasswordChange();

  useEffect(() => {
    if (!token) {
      setTimeout(() => router.push("/auth/login"), 3000);
    }
  }, [token, router]);

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const data: ChangePasswordReqRequest = {
      password: formData.get("newpassword") as string,
      token: token ?? "",
      confirm_password: formData.get("confirmpassword") as string,
    };

    const result = await changePassword(data);
    if (result == "success") {
      router.push("/auth/login?notification=success");
    } else {
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
          href="/"
          className="absolute top-4 left-4 text-white flex items-center gap-2 hover:opacity-80 transition-opacity"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back</span>
        </Link>

        <div className="w-full  flex justify-center pb-8">
          <img
            src="https://seattlepulse-logos.s3.us-east-1.amazonaws.com/Seattle+Pulse_Logo/sp_full+color/sp_full+color_light+background/sp_logo_color_light_bg_1024px_PNG24.png"
            className="w-36 h-36"
          />
        </div>

        <Card className="w-full max-w-lg h-[442px] mx-auto p-8 rounded-3xl ">
          <CardHeader className="space-y-2">
            <CardTitle className="font-semibold text-xl">
              Reset your password
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={onSubmit}>
              <div className="">
                <p className="text-sm text-muted-foreground mb-4">
                  Create a new password to be able to login
                </p>

                <p className="mb-1">Create new password</p>
                <Input
                  name="newpassword"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  // placeholder="email@email.com"
                  className="rounded-3xl mb-4 h-12 border-[1px] border-[#ABB0B9]"
                />
                <p className="mb-1">Confirm Password</p>
                <Input
                  name="confirmpassword"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  // placeholder="email@email.com"
                  className="rounded-3xl h-12 border-[1px] border-[#ABB0B9]"
                />
              </div>
              <Button className="w-full h-12 bg-[#0a0a0a] hover:bg-gray-800 rounded-full mt-6 ">
                {loading ? "Sending..." : "Reset"}
              </Button>
            </form>

            <div className="text-center text-sm ">
            
              <div className="mt-4">
                <span>Remembered your password? </span>
                <Link
                  href="/auth/login"
                  className="text-gray-900  font-semibold"
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
