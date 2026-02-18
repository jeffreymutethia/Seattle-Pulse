// hide-service.ts

import { apiClient } from "../api/api-client";

export interface HideContentResponse {
  success: string;
  message: string;
  data: {
    content_id: number;
  };
}

export async function hideContentService(
  contentId: number
): Promise<HideContentResponse> {
  // POST /hide_content/{content_id}
  return apiClient.post<HideContentResponse>(
    `/content/hide_content/${contentId}`
  );
}
