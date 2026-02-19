/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unused-vars */
import { API_BASE_URL } from "@/lib/config";

export const apiClient = {
  async request<T>(
    endpoint: string,
    method: "GET" | "POST" | "PUT" | "PATCH" | "DELETE" = "GET",
    data?: any
  ): Promise<T> {
    const url = `${API_BASE_URL}${endpoint.startsWith('/') ? '' : '/'}${endpoint}`;
    
    const options: RequestInit = {
      method,
      credentials: "include", // important for session auth
      headers: {
        "Accept": "application/json",
      },
    };

    if (data) {
      if (data instanceof FormData) {
        options.body = data;
      } else {
        options.headers = {
          "Content-Type": "application/json",
          ...options.headers,
        };
        options.body = JSON.stringify(data);
      }
    }

    const response = await fetch(url, options);
    if (!response.ok) {
      const errorText = await response.text(); // helpful to log
      console.error(`API error (${response.status}): ${errorText.substring(0, 500)}`);
      
      // Try to parse the error response as JSON to extract the message
      let errorMessage = `Request failed with status ${response.status}`;
      try {
        const errorData = JSON.parse(errorText);
        if (errorData.message) {
          errorMessage = errorData.message;
        }
      } catch (e) {
        // If parsing fails, use the raw text (truncated)
        errorMessage = errorText.substring(0, 200);
      }
      
      throw new Error(errorMessage);
    }

    // Check if the response is JSON
    const contentType = response.headers.get("content-type");
    if (contentType && contentType.includes("application/json")) {
      return response.json();
    } else {
      console.error(`Unexpected content type: ${contentType}`);
      const text = await response.text();
      console.error(`Response (first 500 chars): ${text.substring(0, 500)}`);
      throw new Error(`Expected JSON but got ${contentType || "unknown content type"}`);
    }
  },

  get<T>(endpoint: string) {
    return this.request<T>(endpoint, "GET");
  },
  post<T>(endpoint: string, data?: any) {
    return this.request<T>(endpoint, "POST", data);
  },
  put<T>(endpoint: string, data?: any) {
    return this.request<T>(endpoint, "PUT", data);
  },
  patch<T>(endpoint: string, data?: any) {
    return this.request<T>(endpoint, "PATCH", data);
  },
  delete<T>(endpoint: string) {
    return this.request<T>(endpoint, "DELETE");
  },
};
