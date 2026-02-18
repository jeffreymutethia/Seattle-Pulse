import { apiClient } from "../api/api-client";

export interface CreateShareRequest {
  platform: "facebook" | "twitter" | "email" | "whatsapp" | "link";
}

export interface CreateShareResponse {
  status: string;
  message: string;
  data: {
    sharable_link: string;
    platform: string;
  } | null;
}

export const shareApiService = {
  async createShare(contentId: number, platform: CreateShareRequest["platform"] = "link"): Promise<CreateShareResponse> {
    try {
      const response = await apiClient.post<CreateShareResponse>(
        `/content/share/${contentId}`,
        { platform }
      );

      return response;
    } catch (error) {
      console.error("Error creating share:", error);
      throw error;
    }
  },
};
