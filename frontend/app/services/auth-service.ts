/* eslint-disable @typescript-eslint/no-explicit-any */
import { apiClient } from "../api/api-client";
import { ChangePasswordReqRequest } from "../types/auth";

export interface AuthResponse {
  status: string;
  message: string;
  data?: {
    authenticated?: boolean;
    user_id?: number;
    username?: string;
  };
}

export interface User {
  id: number;
  username: string;
}

export interface RegisterRequest {
  first_name: string;
  last_name: string;
  username: string;
  emailOrPhoneNumber: string;
  password: string;
  accepted_terms_and_conditions: boolean;
  home_location: string;
}

export interface RegisterResponse {
  status: string;
  message: string;
  data: {
    email: string;
    user_id: number;
    username: string;
  };
}

export interface VerifyOTPRequest {
  token: string;
}

export interface VerifyOTPResponse {
  status: string;
  message: string;
}

export interface LoginResponse {
  status: string;
  message: string;
  data: {
    user_id: number;
    token: string;
    email: string;
    last_name: string;
    first_name: string;
    username: string;
    profile_picture_url: string;
  };
}

export interface ResetPasswordReqRequest {
  email: string;
}

export interface ResetPasswordResponse {
  status: string;
  message: string;
}

export interface ResendEmailVerificationRequest {
  email: string;
}

export interface ResendEmailVerificationResponse {
  status: string;
  message: string;
}

export const authService = {
  /**
   * Check if the user is authenticated
   */
  async checkAuthentication(): Promise<{
    isAuthenticated: boolean;
    user: User | null;
  }> {
    try {
      const response = await apiClient.get<AuthResponse>(
        "/auth/is_authenticated"
      );
      if (response.status === "success" && response.data?.authenticated) {
        return {
          isAuthenticated: true,
          user: {
            id: response.data.user_id!,
            username: response.data.username!,
          },
        };
      }
      return { isAuthenticated: false, user: null };
    } catch (error) {
      console.error("Authentication check failed:", error);
      return { isAuthenticated: false, user: null };
    }
  },

  /**
   * Register a new user
   */
  async register(data: RegisterRequest): Promise<RegisterResponse> {
    try {
      const response = await apiClient.post<RegisterResponse>(
        "/auth/register",
        data
      );
      return response;
    } catch (error: any) {
      
      
      // Extract the actual error message from the API response
      const errorMessage = error?.response?.data?.message || 
                          error?.message || 
                          "Registration failed";
      
      throw new Error(errorMessage);
    }
  },

  /**
   * Resend OTP for verification
   */
  async resendOTP(
    user_id: string
  ): Promise<{ status: string; message: string }> {
    try {
      const response = await apiClient.post<{
        status: string;
        message: string;
      }>("/auth/resend_otp", { user_id });
      return response;
    } catch (error: any) {
      console.error("Resend OTP failed:", error);
      throw new Error(error?.message || "Resend OTP failed");
    }
  },

  async verifyEmail(data: VerifyOTPRequest): Promise<VerifyOTPResponse> {
    try {
      const response = await apiClient.post<VerifyOTPResponse>(
        "/auth/verify-account",
        data
      );
      return response;
    } catch (error: any) {
      console.error("Email verification failed:", error.message);
      throw new Error(
        error?.message || "Account verification failed"
      );
    }
  },

  async resendEmailVerification(
    data: ResendEmailVerificationRequest
  ): Promise<ResendEmailVerificationResponse> {
    try {
      const response = await apiClient.post<ResendEmailVerificationResponse>(
        `/auth/resend-email-verification`,
        { email: data.email }
      );
      return response;
    } catch (error: any) {
      console.error("Resend Email Verification failed:", error);
      throw new Error(
        error?.message || "Resend Email Verification failed"
      );
    }
  },
  
  async login(email: string, password: string): Promise<LoginResponse> {
    try {
      const response = await apiClient.post<LoginResponse>("/auth/login", {
        email,
        password,
      });
      if (response?.data?.user_id) {
        const userData = {
          user_id: response.data.user_id,
          username: response.data.username,
          email: response.data.email,
          last_name: response.data.last_name,
          first_name: response.data.first_name,
          profile_picture_url: response.data.profile_picture_url,
        };
        sessionStorage.setItem("user_id", response.data.user_id.toString());
        sessionStorage.setItem("user", JSON.stringify(userData));
      }
      return response;
    } catch (error: any) {
      console.error("Login error details:", error);
      // Extract only the user-friendly message, not the full API error
      const errorMessage = error?.response?.data?.message || 
                          error?.message || 
                          "Login failed. Please check your credentials and try again.";
      throw new Error(errorMessage);
    }
  },

  /**
   * Log out the current user
   */
  async logout(): Promise<boolean> {
    try {
      await apiClient.post("/auth/logout");
      return true;
    } catch (error) {
      console.error("Logout failed:", error);
      return false;
    }
  },

  /**
   * Reset password request
   */
  async resetPasswordRequest(
    data: ResetPasswordReqRequest
  ): Promise<ResetPasswordResponse> {
    try {
      const response = await apiClient.post<ResetPasswordResponse>(
        "/auth/reset_password_request",
        data
      );
      return response;
    } catch (error: any) {
      console.error("Reset Password failed:", error);
      throw new Error(
        error?.response?.data?.message || "Reset Password failed"
      );
    }
  },

  async changePassword(
    data: ChangePasswordReqRequest
  ): Promise<ResetPasswordResponse> {
    try {
      const response = await apiClient.post<ResetPasswordResponse>(
        `/auth/reset_password?token=${data.token}`,
        {
          password: data.password,
          confirm_password: data.confirm_password,
        }
      );
      return response;
    } catch (error: any) {
      console.error("Reset Password failed:", error);
      throw new Error(
        error?.response?.data?.message || "Reset Password failed"
      );
    }
  },

  /**
   * Fetch feed content (should this be in auth?)
   */
  async fetchFeed(): Promise<any> {
    try {
      const response = await apiClient.get("/content");
      return response;
    } catch (error: any) {
      console.error("Fetching feed failed:", error);
      throw new Error(error?.response?.data?.message || "Fetching feed failed");
    }
  },
};
