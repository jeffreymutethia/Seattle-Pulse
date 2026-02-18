/* eslint-disable @typescript-eslint/no-explicit-any */
"use client";
import { useState, useEffect } from "react";
import { Eye, EyeOff } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { z } from "zod";
import { useRegister } from "@/app/hooks/use-auth";
import type { RegisterRequest } from "@/app/types/auth";
import Notification from "@/components/story/notification"; // Adjust path
import { useForm } from "react-hook-form";
import AsyncSelect from "react-select/async";
import { useHomeLocationSearch } from "@/app/hooks/use-location-search";
import { trackEvent } from "@/lib/mixpanel";

const signupSchema = z
  .object({
    firstName: z.string().min(1, { message: "First name is required" }),
    lastName: z.string().min(1, { message: "Last name is required" }),
    username: z.string().min(1, { message: "Username is required" }),
    emailOrPhoneNumber: z.string().min(1, { message: "Email or phone number is required" }),
    password: z
      .string()
      .min(8, { message: "Password must be at least 8 characters" })
      .regex(/[A-Z]/, { message: "Password must include an uppercase letter" })
      .regex(/[a-z]/, { message: "Password must include a lowercase letter" })
      .regex(/[0-9]|[^a-zA-Z0-9]/, {
        message: "Password must include a number or symbol",
      }),
    confirmPassword: z
      .string()
      .min(1, { message: "Confirm password is required" }),
    terms: z.boolean().refine((val) => val === true, {
      message: "You must agree to the terms",
    }),
    home_location: z.string().optional(), // Made optional as per spec
    latitude: z.number().optional(),
    longitude: z.number().optional(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords don't match",
    path: ["confirmPassword"],
  });

type SignupFormData = z.infer<typeof signupSchema>;

interface HomeLocationOption {
  value: string;
  label: string;
  isPreset?: boolean;
}

export default function Signup() {
  const { register, error, loading } = useRegister();
  const router = useRouter();
  const { setValue } = useForm<SignupFormData>();
  const { loadOptions, isLoading, launchSet } = useHomeLocationSearch();

  const [formData, setFormData] = useState<Partial<SignupFormData>>({
    firstName: "",
    lastName: "",
    username: "",
    emailOrPhoneNumber: "",
    password: "",
    confirmPassword: "",
    terms: false,
    home_location: "",
  });

  const [errors, setErrors] = useState<
    Partial<Record<keyof SignupFormData, string>>
  >({});
  const [touched, setTouched] = useState<
    Partial<Record<keyof SignupFormData, boolean>>
  >({});

  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const [notificationMessage, setNotificationMessage] = useState<string | null>(
    null
  );
  const [notificationTitle, setNotificationTitle] = useState<string | null>(
    null
  );

  useEffect(() => {
    if (error) {
      setNotificationMessage(error);
      setNotificationTitle("Registration Error");
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

  const calculatePasswordStrength = (password: string) => {
    if (!password) return 0;

    let strength = 0;
    if (password.length >= 8) strength += 25;
    if (/[A-Z]/.test(password)) strength += 25;
    if (/[a-z]/.test(password)) strength += 25;
    if (/[0-9]|[^a-zA-Z0-9]/.test(password)) strength += 25;

    return strength;
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    const newValue = type === "checkbox" ? checked : value;

    setFormData((prev: any) => ({
      ...prev,
      [name]: newValue,
    }));

    setTouched((prev) => ({
      ...prev,
      [name]: true,
    }));

    validateField(name, newValue);
  };

  const validateField = (name: string, value: any) => {
    try {
      const fieldSchema = z.object({
        [name]: signupSchema._def.schema.shape[name as keyof SignupFormData],
      });
      fieldSchema.parse({ [name]: value });

      if (name === "confirmPassword" && value !== formData.password) {
        setErrors((prev) => ({
          ...prev,
          [name]: "Passwords don't match",
        }));
        return;
      }

      setErrors((prev) => ({
        ...prev,
        [name]: undefined,
      }));
    } catch (error) {
      if (error instanceof z.ZodError) {
        const fieldError = error.errors.find((e) => e.path[0] === name);
        if (fieldError) {
          setErrors((prev) => ({
            ...prev,
            [name]: fieldError.message,
          }));
        }
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    try {
      const validatedData = signupSchema.parse(formData);

      const registerData: RegisterRequest = {
        first_name: validatedData.firstName,
        last_name: validatedData.lastName,
        username: validatedData.username,
        emailOrPhoneNumber: validatedData.emailOrPhoneNumber,
        password: validatedData.password,
        accepted_terms_and_conditions: validatedData.terms,
        home_location: validatedData.home_location || "",
        
      };

      await register(registerData);
    } catch (error) {
      if (error instanceof z.ZodError) {
        // Handle validation errors
        const newTouched: Partial<Record<keyof SignupFormData, boolean>> = {};
        Object.keys(formData).forEach((key) => {
          newTouched[key as keyof SignupFormData] = true;
        });
        setTouched(newTouched);

        const newErrors: Partial<Record<keyof SignupFormData, string>> = {};
        error.errors.forEach((err) => {
          const field = err.path[0] as keyof SignupFormData;
          newErrors[field] = err.message;
        });
        setErrors(newErrors);
      } else {
        // Handle API errors - these will be caught by the useRegister hook
      }
    }
  };

  return (
    <div
      className="min-h-screen w-full flex items-center justify-center bg-cover bg-center"
      style={{ backgroundImage: "url('/bg-up.png')" }}
    >
      <Notification
        title={notificationTitle}
        message={notificationMessage}
        type={error ? "error" : "success"}
        onClose={() => setNotificationMessage(null)}
        onHomeClick={() => null}
      />

      <div className="w-full max-w-lg p-4">
        <div className="flex justify-center pb-8">
          <img
            src="https://seattlepulse-logos.s3.us-east-1.amazonaws.com/Seattle+Pulse_Logo/sp_full+color/sp_full+color_light+background/sp_logo_color_light_bg_1024px_PNG24.png"
            className="w-36 h-36"
            alt="Logo"
          />
        </div>
        <div className="w-full max-w-xl mx-auto p-8 bg-white rounded-3xl">
          <div className="flex items-center mb-6">
            <button onClick={() => router.back()} className="mr-2">
              <svg width="24" height="24" viewBox="0 0 24 24">
                <path d="M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z" />
              </svg>
            </button>
            <p className="text-xl font-semibold">
              Sign Up – We&apos;re excited to have you!
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <span className="text-sm mb-2">First Name</span>
                <Input
                  name="firstName"
                  placeholder="First Name"
                  value={formData.firstName}
                  onChange={handleChange}
                  className={`rounded-3xl h-12 border-[1px] ${
                    touched.firstName && errors.firstName
                      ? "border-red-500"
                      : "border-[#ABB0B9]"
                  }`}
                />
                {touched.firstName && errors.firstName && (
                  <p className="text-red-500 text-xs mt-1">
                    {errors.firstName}
                  </p>
                )}
              </div>
              <div>
                <span className="text-sm mb-2">Last Name</span>
                <Input
                  name="lastName"
                  placeholder="Last Name"
                  value={formData.lastName}
                  onChange={handleChange}
                  className={`rounded-3xl h-12 border-[1px] ${
                    touched.lastName && errors.lastName
                      ? "border-red-500"
                      : "border-[#ABB0B9]"
                  }`}
                />
                {touched.lastName && errors.lastName && (
                  <p className="text-red-500 text-xs mt-1">{errors.lastName}</p>
                )}
              </div>
            </div>

            <div>
              <span className="text-sm mb-2">Username</span>
              <Input
                name="username"
                placeholder="Username"
                value={formData.username}
                onChange={handleChange}
                className={`rounded-3xl h-12 border-[1px] ${
                  touched.username && errors.username
                    ? "border-red-500"
                    : "border-[#ABB0B9]"
                }`}
              />
              {touched.username && errors.username && (
                <p className="text-red-500 text-xs mt-1">{errors.username}</p>
              )}
            </div>

            <div>
              <span className="text-sm mb-2">Email or Phone Number</span>
              <Input
                name="emailOrPhoneNumber"
                placeholder="Email or Phone Number"
                value={formData.emailOrPhoneNumber}
                onChange={handleChange}
                className={`rounded-3xl h-12 border-[1px] ${
                  touched.emailOrPhoneNumber && errors.emailOrPhoneNumber
                    ? "border-red-500"
                    : "border-[#ABB0B9]"
                }`}
              />
              {touched.emailOrPhoneNumber && errors.emailOrPhoneNumber && (
                <p className="text-red-500 text-xs mt-1">{errors.emailOrPhoneNumber}</p>
              )}
            </div>

            <div>
              <span className="text-sm mb-2">Neighborhood</span>
              <AsyncSelect<HomeLocationOption>
                loadOptions={loadOptions}
                defaultOptions={launchSet} // Show the hard-coded locations immediately
                onChange={(selected) => {
                  if (selected) {
                    setValue("home_location", selected.value);
                    setFormData(prev => ({
                      ...prev,
                      home_location: selected.value,
                    }));
                    setTouched(prev => ({
                      ...prev,
                      home_location: true,
                    }));
                    validateField("home_location", selected.value);
                  } else {
                    setValue("home_location", "");
                    setFormData(prev => ({
                      ...prev,
                      home_location: "",
                    }));
                    setTouched(prev => ({
                      ...prev,
                      home_location: true,
                    }));
                    validateField("home_location", "");
                  }
                }}
                className={`rounded-3xl h-12 border-[1px] ${
                  touched.home_location && errors.home_location
                    ? "border-red-500"
                    : "border-[#ABB0B9]"
                }`}
                classNamePrefix="select"
                placeholder="Choose a neighborhood..."
                isClearable
                isLoading={isLoading}
                loadingMessage={() => "Searching neighborhoods..."}
                noOptionsMessage={() => "No neighborhoods found"}
                cacheOptions={false} // Disable caching to ensure fresh results
                styles={{
                  control: (base) => ({
                    ...base,
                    borderRadius: '9999px',
                    height: '48px',
                    borderColor: touched.home_location && errors.home_location ? '#EF4444' : '#ABB0B9',
                    '&:hover': {
                      borderColor: touched.home_location && errors.home_location ? '#EF4444' : '#ABB0B9',
                    },
                  }),
                  option: (base) => ({
                    ...base,
                    padding: '8px 16px',
                  }),
                  menu: (base) => ({
                    ...base,
                    borderRadius: '12px',
                    boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
                  }),
                }}
              />
              {touched.home_location && errors.home_location && (
                <p className="text-red-500 text-xs mt-1">{errors.home_location}</p>
              )}
            </div>

            <div className="relative">
              <span className="text-sm mb-2">Create Password</span>
              <div className="relative inline-block w-full ">
                <Input
                  id="password"
                  name="password"
                  type={showPassword ? "text" : "password"}
                  placeholder="Password"
                  value={formData.password}
                  onChange={handleChange}
                  className={`!rounded-3xl  !w-full !h-12 !border-[1px]   ${
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

              {formData.password && (
                <>
                  <div className="w-full bg-gray-200 rounded-full h-2.5 mt-2">
                    <div
                      className={`h-2.5 rounded-full ${
                        calculatePasswordStrength(formData.password as string) <
                        50
                          ? "bg-red-500"
                          : calculatePasswordStrength(
                              formData.password as string
                            ) < 100
                          ? "bg-yellow-500"
                          : "bg-green-500"
                      }`}
                      style={{
                        width: `${calculatePasswordStrength(
                          formData.password as string
                        )}%`,
                      }}
                    ></div>
                  </div>

                  <div className="mt-2 space-y-1">
                    <div className="flex items-center">
                      <span
                        className={
                          (formData.password?.length || 0) >= 8
                            ? "text-green-500"
                            : "text-red-500"
                        }
                      >
                        {(formData.password?.length || 0) >= 8 ? "✓" : "✗"}
                      </span>
                      <span className="ml-2 text-xs">
                        Use at least 8 characters.
                      </span>
                    </div>
                    <div className="flex items-center">
                      <span
                        className={
                          /[A-Z]/.test(formData.password || "")
                            ? "text-green-500"
                            : "text-red-500"
                        }
                      >
                        {/[A-Z]/.test(formData.password || "") ? "✓" : "✗"}
                      </span>
                      <span className="ml-2 text-xs">
                        Include uppercase letters
                      </span>
                    </div>
                    <div className="flex items-center">
                      <span
                        className={
                          /[a-z]/.test(formData.password || "")
                            ? "text-green-500"
                            : "text-red-500"
                        }
                      >
                        {/[a-z]/.test(formData.password || "") ? "✓" : "✗"}
                      </span>
                      <span className="ml-2 text-xs">
                        Include lowercase letters
                      </span>
                    </div>
                    <div className="flex items-center">
                      <span
                        className={
                          /[0-9]|[^a-zA-Z0-9]/.test(formData.password || "")
                            ? "text-green-500"
                            : "text-red-500"
                        }
                      >
                        {/[0-9]|[^a-zA-Z0-9]/.test(formData.password || "")
                          ? "✓"
                          : "✗"}
                      </span>
                      <span className="ml-2 text-xs">
                        Include a number or a symbol
                      </span>
                    </div>
                  </div>
                </>
              )}
            </div>

            <div className="relative">
              <span className="text-sm mb-2">Confirm Password</span>

              <div className="relative inline-block w-full ">
                <Input
                  id="confirmPassword"
                  name="confirmPassword"
                  type={showConfirmPassword ? "text" : "password"}
                  placeholder="Confirm Password"
                  value={formData.confirmPassword}
                  onChange={handleChange}
                  className={`!rounded-3xl  !w-full !h-12 !border-[1px]   ${
                    touched.confirmPassword && errors.confirmPassword
                      ? "!border-red-500"
                      : "!border-[#ABB0B9]"
                  }`}
                />

                <button
                  type="button"
                  className="absolute right-6 top-1/2 transform -translate-y-1/2"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                >
                  {showConfirmPassword ? (
                    <EyeOff className="h-4 w-4 text-gray-500" />
                  ) : (
                    <Eye className="h-4 w-4 text-gray-500" />
                  )}
                </button>
              </div>

              {touched.confirmPassword && errors.confirmPassword && (
                <p className="text-red-500 text-xs mt-1">
                  {errors.confirmPassword}
                </p>
              )}
            </div>

            <div className="flex items-start space-x-2">
              <input
                id="terms-checkbox"
                name="terms"
                type="checkbox"
                checked={formData.terms}
                onChange={handleChange}
                className={`w-5 h-5 text-black border-gray-300 focus:ring-black rounded-2xl ${
                  touched.terms && errors.terms ? "border-red-500" : ""
                }`}
              />
              <div>
                <label htmlFor="terms" className="text-sm">
                  I agree to the{" "}
                  <a href="/terms" className="text-blue-600 hover:underline">
                    Terms
                  </a>{" "}
                  and{" "}
                  <a href="/privacy" className="text-blue-600 hover:underline">
                    Privacy Policy
                  </a>
                  .
                </label>
                {touched.terms && errors.terms && (
                  <p className="text-red-500 text-xs mt-1">{errors.terms}</p>
                )}
              </div>
            </div>

            <Button
              className="w-full h-12 bg-black text-white hover:bg-black/90 rounded-full"
              type="submit"
            >
              {loading ? "Loading..." : "Create Account"}
            </Button>

            <p className="text-center text-sm">
              Already Have an Account?{" "}
              <Link 
                href="/auth/login" 
                className="text-gray-900 font-semibold"
                onClick={() => trackEvent("signup_cta_clicked", { source: "signup_page", action: "login" })}
              >
                Login
              </Link>
            </p>
          </form>
        </div>
      </div>
    </div>
  );
}


