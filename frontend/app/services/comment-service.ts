import { apiClient } from "../api/api-client";
import { RawComment, ExtendedComment } from "../types/comment";

const COMMENTS_ENDPOINT = "/comments";
const REACTION_ENDPOINT = "/reaction";

export const transformComment = (raw: RawComment): ExtendedComment => {
  return {
    ...raw,
    userReaction: raw.comment_reaction_type ?? raw.user_reaction ?? null,
    totalReactions: raw.reaction_count ?? raw.total_reactions ?? 0,
    top_reactions: raw.top_reactions ?? [],
  };
};

export const commentService = {
  postComment: async (body: {
    content_id: number;
    content_type: string;
    content: string;
    parent_id: number | null;
  }): Promise<ExtendedComment> => {
    const data = await apiClient.post<{ status: string; data: RawComment }>(
      `${COMMENTS_ENDPOINT}/post_comment`,
      body
    );
    if (data.status === "success" && data.data) {
      return transformComment(data.data);
    }
    throw new Error("Failed to post comment.");
  },

  updateComment: async (body: {
    comment_id: number;
    content: string;
  }): Promise<ExtendedComment> => {
    const data = await apiClient.put<{ status: string; data: any }>(
      `${COMMENTS_ENDPOINT}/update_comment`,
      body
    );
    if (data.status === "success" && data.data) {
      const updated = data.data.comment || data.data;
      return transformComment(updated);
    }
    throw new Error("Failed to update comment.");
  },

  fetchReplies: async (
    commentId: number,
    page: number
  ): Promise<{
    replies: RawComment[];
    pagination: {
      current_page: number;
      has_next: boolean;
      total_pages: number;
    };
  }> => {
    const response = await apiClient.get<{
      success: string;
      data: RawComment[];
      pagination: {
        current_page: number;
        has_next: boolean;
        total_pages: number;
      };
    }>(`${COMMENTS_ENDPOINT}/${commentId}/replies?page=${page}&per_page=10`);
    if (response.success === "success" && Array.isArray(response.data)) {
      return {
        replies: response.data,
        pagination: response.pagination,
      };
    }
    throw new Error("Failed to fetch replies.");
  },

  reactToPost: async (
    contentId: number,
    reaction: string
  ): Promise<{
    user_reaction: string | null;
    total_reactions: number;
    top_reactions?: string[];
  }> => {
    const data = await apiClient.post<{
      success: string;
      data: any;
    }>(`${REACTION_ENDPOINT}/user_content/${contentId}`, {
      reaction_type: reaction,
    });
    if (data.success === "success" && data.data) {
      return data.data;
    }
    throw new Error("Failed to react to post");
  },

  reactToComment: async (
    contentId: number,
    commentId: number,
    reaction: string
  ): Promise<{
    comment_reaction_type: string | null;
    reaction_count: number;
    top_reactions?: string[];
  }> => {
    const data = await apiClient.post<{
      status: string;
      data: any;
    }>(`${REACTION_ENDPOINT}/comment/${contentId}/${commentId}`, {
      reaction_type: reaction,
    });
    if (data.status === "success" && data.data) {
      return data.data;
    }
    throw new Error("Failed to react to comment");
  },
};
