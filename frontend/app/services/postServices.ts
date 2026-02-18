/* eslint-disable @typescript-eslint/no-explicit-any */
import type { Post, ExtendedPost } from "@/app/types/content";
import { apiClient } from "../api/api-client";

interface PostsResponse {
  status: string;
  data: {
    content: Post[];
  };
}

interface ReactionResponse {
  status: string;
  data: {
    user_has_reacted: boolean;
    user_reaction_type: string;
    total_reactions: number;
    top_reactions: string[];
  };
}

export const postService = {
  async fetchPosts(page: number, location?: string): Promise<ExtendedPost[]> {
    try {
      // Build query parameters
      const params = new URLSearchParams({
        page: page.toString(),
      });
      
      // Add location parameter if provided
      if (location && location !== "Seattle") {
        params.append('location', location);
      }
      
      const data = await apiClient.get<PostsResponse>(`/content/combined_feed?${params.toString()}`);
      
      if (!data || !data.data || !data.data.content) {
        return [];
      }
      
      const rawPosts: Post[] = data.data.content;

      return rawPosts.map((p) => ({
        ...p,
        userReaction: p.user_has_reacted ? p.user_reaction_type : null,
        totalReactions: p.reactions_count,
        top_reactions: p.top_reactions || [],
        has_user_reposted: p.has_user_reposted,
      }));
    } catch (error) {
      console.error("Error fetching posts:", error);
      return [];
    }
  },

  async reactToPost(
    postId: number,
    reactionType: string
  ): Promise<ReactionResponse> {
    return apiClient.post<ReactionResponse>(
      `/reaction/user_content/${postId}`,
      { reaction_type: reactionType }
    );
  },

  async repostContent(postId: number, thoughts = ""): Promise<any> {
    return apiClient.post(`/content/repost/${postId}`, { thoughts });
  },

  async undoRepost(postId: number): Promise<any> {
    return apiClient.post(`/content/undo_repost/${postId}`, {});
  },
};
