/* eslint-disable @typescript-eslint/no-explicit-any */
import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import {
  authService,
} from "../services/auth-service";
import type {
  ChangePasswordReqRequest,
  LoginRequest,
  RegisterRequest,
  ResetPasswordReqRequest,
} from "../types/auth";

export function useRegister() {
  const router = useRouter();
  const [error, setError] = useState<string>("");
  const [loading, setLoading] = useState(false);

  const register = async (data: RegisterRequest) => {
    try {
      setLoading(true);
      setError("");
      await authService.register(data);
      
      // Use the email from the form data since the API response might not have it
      const email = data.emailOrPhoneNumber;
      router.push(`/auth/verify-email?email=${email}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setLoading(false);
    }
  };

  return { register, error, loading };
}

export function useResendOTP() {
  const router = useRouter();
  const [error, setError] = useState<string>("");
  const [loading, setLoading] = useState(false);

  const resendOTP = async (userId: string) => {
    try {
      setLoading(true);
      setError("");
      await authService.resendOTP(userId);
      router.push(`/auth/verify-otp?user_id=${userId}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setLoading(false);
    }
  };

  return { resendOTP, error, loading };
}
export function useLogin() {
  const [error, setError] = useState<string>("");
  const [loading, setLoading] = useState(false);

  const login = async (data: LoginRequest) => {
    try {
      setLoading(true);
      setError("");
      await authService.login(data.email, data.password);

      window.location.href = "/";
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setLoading(false);
    }
  };

  return { login, error, loading };
}

export function useResetPasswordRequest() {
  const [error, setError] = useState<string>("");
  const [loading, setLoading] = useState(false);

  const resetPasswordReq = async (data: ResetPasswordReqRequest) => {
    try {
      setLoading(true);
      setError("");

      const response = await authService.resetPasswordRequest(data); // <-- Get actual API response

      if (response?.status === "error") {
        throw new Error(response.message || "Failed to send reset email.");
      }

      return response; // <-- Return actual response (not just "success")
    } catch (err) {
      const errorMessage =
        err instanceof Error ? err.message : "Something went wrong";
      setError(errorMessage);
      throw new Error(errorMessage); // <-- Ensure error is thrown
    } finally {
      setLoading(false);
    }
  };

  return { resetPasswordReq, error, loading };
}

export function usePasswordChange() {
  const [error, setError] = useState<string>("");
  const [loading, setLoading] = useState(false);

  const changePassword = async (data: ChangePasswordReqRequest) => {
    try {
      setLoading(true);
      setError("");
      await authService.changePassword(data);
      return "success";
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setLoading(false);
    }
  };

  return { changePassword, error, loading };
}

export function useVerifyEmail() {
  const [error, setError] = useState<string>("");
  const [loading, setLoading] = useState(false);

  const verifyEmail = useCallback(async (token: string) => {
    try {
      setLoading(true);
      setError("");

      const response = await authService.verifyEmail({ token });

      console.log("response", response);

      if (response?.status === "error") {
        setError(response.message || "Email verification failed.");
        throw new Error(response.message || "Email verification failed.");
      }

      return response; // ✅ Return actual API response
    } catch (err: any) {
      const errorMessage = err?.message || "Something went wrong";
      setError(errorMessage);
      throw new Error(errorMessage);
    } finally {
      setLoading(false);
    }
  }, []);

  return { verifyEmail, error, loading };
}

export function useResendEmailVerification() {
  const [error, setError] = useState<string>("");
  const [loading, setLoading] = useState(false);

  const resendEmailVerification = useCallback(
    async ({ email }: { email: string }) => {
      try {
        setLoading(true);
        setError("");
        await authService.resendEmailVerification({ email });
        return "success";
      } catch (err) {
        setError(err instanceof Error ? err.message : "Something went wrong");
        throw err;
      } finally {
        setLoading(false);
      }
    },
    []
  );

  return { resendEmailVerification, error, loading };
}
