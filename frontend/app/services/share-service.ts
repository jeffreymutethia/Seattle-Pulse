import { apiClient } from "../api/api-client";

export interface ShareUser {
  id: number;
  username: string;
  profile_picture_url: string;
}

export interface ShareComment {
  id: number;
  content: string;
  user_id: number;
  created_at: string;
  user: ShareUser;
  replies_count: number;
}

export interface ShareReactionBreakdown {
  LIKE: number;
  LOVE: number;
  HAHA: number;
  WOW: number;
  SAD: number;
  ANGRY: number;
}

export interface SharePagination {
  current_page: number;
  total_pages: number;
  total_items: number;
  has_next: boolean;
  has_prev: boolean;
}

export interface ShareContentData {
  id: number;
  title: string;
  description: string;
  image_url: string;
  location: string;
  user: ShareUser;
  total_reactions: number;
  reaction_breakdown: ShareReactionBreakdown;
  user_reaction: string | null;
  total_comments: number;
  comments: ShareComment[];
  pagination: SharePagination;
}

export interface ShareResponse {
  success: string;
  message: string;
  data: ShareContentData | null;
}

export const shareService = {
  async getSharedContent(shareId: string): Promise<ShareResponse> {
    try {
      const response = await apiClient.get<ShareResponse>(
        `/content/share/content-detail/${shareId}`
      );

      return response;
    } catch (error) {
      console.error("Error fetching shared content:", error);
      throw error;
    }
  },
};