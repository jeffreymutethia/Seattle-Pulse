import { apiClient } from "../api/api-client";

export interface DeleteStoryResponse {
  success: string;
  message: string;
}

export async function deleteStoryService(
  contentId: number
): Promise<DeleteStoryResponse> {
  return apiClient.delete<DeleteStoryResponse>(
    `/content/delete_story/${contentId}`
  );
}
