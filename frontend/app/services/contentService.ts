import { apiClient } from "@/app/api/api-client";

interface ContentDetailResponse {
  data: any;
}

class ContentService {
    async fetchContentDetails(contentType: string, contentId: string | number) {
        try {
          const endpoint = `/content/${contentType}/${contentId}`;
          const response = await apiClient.get<ContentDetailResponse>(endpoint);
          return response.data;
        } catch (error) {
          console.error('Error fetching content details:', error);
          throw error;
        }
      }

      async addComment(contentId: string | number, contentType: string, commentText: string) {
        const body = {
          content_id: contentId,
          content_type: contentType,
          content: commentText,
        }
    
        const endpoint = `/comments/post_comment`;
        const response = await apiClient.post<any>(endpoint, body);
        return response;
      }
    
      async updateComment(commentId: number | string, newContent: string) {
        const body = {
          comment_id: commentId,
          content: newContent,
        }
    
        const endpoint = `/comments/update_comment`;
        const response = await apiClient.put<any>(endpoint, body);
        return response;
      }
}

export const contentService = new ContentService();

