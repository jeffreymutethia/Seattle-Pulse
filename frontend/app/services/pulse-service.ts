import { apiClient } from "../api/api-client";
import { ExtendedPost, Post } from "../types/content";

export const postService = {
  async fetchPosts(page: number): Promise<ExtendedPost[]> {
    try {
      const data = await apiClient.get<{ data: { content: Post[] } }>(
        `/feed/mypulse?page=${page}`
      );

      const rawPosts: Post[] = data.data.content;

      return rawPosts.map((p) => ({
        ...p,
        userReaction: p.user_has_reacted ? p.user_reaction_type : null,
        totalReactions: p.reactions_count,
        top_reactions: p.top_reactions || [],
      }));
    } catch (error) {
      console.error("Error fetching posts:", error);
      return [];
    }
  },

  async reactToPost(
    postId: number,
    reactionType: string
  ): Promise<{
    user_has_reacted: boolean;
    user_reaction_type: string | null;
    total_reactions: number;
    top_reactions: string[];
  }> {
    const response = await apiClient.post<{
      status: string;
      data: {
        user_has_reacted: boolean;
        user_reaction_type: string | null;
        total_reactions: number;
        top_reactions: string[];
      };
    }>(`/reaction/user_content/${postId}`, { reaction_type: reactionType });

    return response.data;
  },

  async repostContent(postId: number, thoughts = ""): Promise<void> {
    await apiClient.post<any>(`/content/repost/${postId}`, { thoughts });
  },

  async undoRepost(postId: number): Promise<void> {
    await apiClient.post<any>(`/content/undo_repost/${postId}`, {});
  },
};
