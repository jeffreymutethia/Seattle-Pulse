/* eslint-disable @typescript-eslint/no-explicit-any */
"use client";

import { useState, useEffect } from "react";
import { Eye, EyeOff } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import Notification from "@/components/story/notification";
import { useLogin } from "@/app/hooks/use-auth";
import type { LoginRequest } from "@/app/types/auth";
import { z } from "zod";
import { API_BASE_URL } from "@/lib/config";
import { trackEvent } from "@/lib/mixpanel";
import { FULL_LOGO_SRC } from "@/lib/brand-assets";
import Image from "next/image";
const loginSchema = z.object({
  email: z.string().email({ message: "Invalid email address" }),
  password: z.string().min(1, { message: "Password is required" }),
  remember: z.boolean().optional(),
});

type LoginFormData = z.infer<typeof loginSchema>;

export default function Login() {
  const { login, error, loading } = useLogin();
  const searchParams = useSearchParams();

  const [formData, setFormData] = useState<Partial<LoginFormData>>({
    email: "",
    password: "",
    remember: false,
  });

  const [errors, setErrors] = useState<
    Partial<Record<keyof LoginFormData, string>>
  >({});
  const [touched, setTouched] = useState<
    Partial<Record<keyof LoginFormData, boolean>>
  >({});
  const [showPassword, setShowPassword] = useState(false);
  const [notificationMessage, setNotificationMessage] = useState<string | null>(
    null
  );
  const [notificationTitle, setNotificationTitle] = useState<
    string | undefined
  >(undefined);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    const newValue = type === "checkbox" ? checked : value;

    setFormData((prev) => ({ ...prev, [name]: newValue }));
    setTouched((prev) => ({ ...prev, [name]: true }));
    validateField(name, newValue);
  };

  const validateField = (name: string, value: any) => {
    try {
      const fieldSchema = z.object({
        [name]: loginSchema.shape[name as keyof LoginFormData],
      });
      fieldSchema.parse({ [name]: value });
      setErrors((prev) => ({ ...prev, [name]: undefined }));
    } catch (error) {
      if (error instanceof z.ZodError) {
        const fieldError = error.errors.find((e) => e.path[0] === name);
        if (fieldError) {
          setErrors((prev) => ({ ...prev, [name]: fieldError.message }));
        }
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    try {
      const validatedData = loginSchema.parse(formData);
      const data: LoginRequest = {
        email: validatedData.email,
        password: validatedData.password,
      };
      await login(data);
    } catch (error) {
      if (error instanceof z.ZodError) {
        const newTouched: Partial<Record<keyof LoginFormData, boolean>> = {};
        Object.keys(formData).forEach((key) => {
          newTouched[key as keyof LoginFormData] = true;
        });
        setTouched(newTouched);

        const newErrors: Partial<Record<keyof LoginFormData, string>> = {};
        error.errors.forEach((err) => {
          const field = err.path[0] as keyof LoginFormData;
          newErrors[field] = err.message;
        });
        setErrors(newErrors);
      }
    }
  };

  useEffect(() => {
    const notification = searchParams.get("notification");
    if (notification === "success") {
      setNotificationMessage(
        "Please login with your new password to continue."
      );
      setNotificationTitle("Password reset successfully!");
    }
  }, [searchParams]);

  useEffect(() => {
    if (error) {
      setNotificationMessage(error);
      setNotificationTitle("Login Error");
    }
  }, [error]);

  useEffect(() => {
    if (notificationMessage) {
      const timer = setTimeout(() => {
        setNotificationMessage(null);
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [notificationMessage]);

  const handleGoogleLogin = () => {
    window.location.href = `${API_BASE_URL}/auth_social_login/login`;
  };

  return (
    <div
      className="min-h-screen w-full flex items-center justify-center bg-cover bg-center"
      style={{ backgroundImage: "url('/bg-up.png')" }}
    >
      <Notification
        title={notificationTitle || ""}
        message={notificationMessage}
        type={error ? "error" : "success"}
        onClose={() => setNotificationMessage(null)}
        onHomeClick={() => null}
      />

      <div className="w-full max-w-lg p-4">
        <div className="flex justify-center pb-8">
          <Image
            src={FULL_LOGO_SRC}
            className="w-36 h-36"
            width={144}
            height={144}
            alt="Logo"
          />
        </div>
        <div className="w-full mx-auto max-w-lg space-y-6 bg-white rounded-3xl p-8">
          <div>
            <p className="text-xl font-semibold">Login - Welcome Back!</p>
          </div>

          <form className="space-y-4" onSubmit={handleSubmit}>
            {/* Traditional Login Fields */}
            <div className="space-y-2">
              <Label htmlFor="email" className="font-normal text-md">
                Email
              </Label>
              <Input
                id="email"
                name="email"
                placeholder="Email"
                value={formData.email}
                onChange={handleChange}
                className={`rounded-3xl h-12 border-[1px] ${
                  touched.email && errors.email
                    ? "border-red-500"
                    : "border-[#ABB0B9]"
                }`}
              />
              {touched.email && errors.email && (
                <p className="text-red-500 text-xs mt-1">{errors.email}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="password" className="font-normal text-md">
                Password
              </Label>
              <div className="relative inline-block w-full ">
                <Input
                  id="password"
                  name="password"
                  type={showPassword ? "text" : "password"}
                  placeholder="Password"
                  value={formData.password}
                  onChange={handleChange}
                  className={`!rounded-3xl  !w-full !h-12 !border-[1px] ${
                    touched.password && errors.password
                      ? "!border-red-500"
                      : "!border-[#ABB0B9]"
                  }`}
                />
                <button
                  type="button"
                  className="absolute right-6 top-1/2 transform -translate-y-1/2"
                  onClick={() => setShowPassword(!showPassword)}
                >
                  {showPassword ? (
                    <EyeOff className="h-4 w-4 text-gray-500" />
                  ) : (
                    <Eye className="h-4 w-4 text-gray-500" />
                  )}
                </button>
              </div>
              {touched.password && errors.password && (
                <p className="text-red-500 text-xs mt-1">{errors.password}</p>
              )}
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="remember"
                  name="remember"
                  checked={formData.remember}
                  onCheckedChange={(checked) =>
                    setFormData((prev) => ({
                      ...prev,
                      remember: checked === true,
                    }))
                  }
                />
                <Label htmlFor="remember" className="text-sm">
                  Remember me
                </Label>
              </div>

              <Link
                href="/auth/forgot-password"
                className="text-sm text-blue-600 hover:text-blue-500 underline"
              >
                Forgot your password?
              </Link>
            </div>

            <Button
              type="submit"
              className="w-full h-12 bg-black text-white hover:bg-gray-800 rounded-full py-2"
            >
              {loading ? "Logging in..." : "Login"}
            </Button>

            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t"></div>
              </div>
              <div className="relative flex justify-center text-xs">
                <span className="bg-white px-2 text-gray-500">Or</span>
              </div>
            </div>

            {/* Social Login Buttons */}
            <Button
              type="button"
              onClick={handleGoogleLogin}
              variant="outline"
              className="w-full h-12 border border-[#000000] rounded-full"
            >
              <Image
                src="https://www.google.com/favicon.ico"
                alt="Google"
                className="mr-2 h-5 w-5"
                width={20}
                height={20}
              />
              Login with Google
            </Button>

          
            <div className="text-center text-sm">
              Don&apos;t Have an Account?{" "}
              <Link 
                href="/auth/signup" 
                className="text-gray-900 font-semibold"
                onClick={() => trackEvent("signup_cta_clicked", { source: "login_page", action: "signup" })}
              >
                Sign up
              </Link>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
