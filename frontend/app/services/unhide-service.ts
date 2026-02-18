// unhide-service.ts

import { apiClient } from "../api/api-client";



export interface UnhideContentResponse {
  success: string;
  message: string;
  data: {
    content_id: number;
  };
}

export async function unhideContentService(contentId: number): Promise<UnhideContentResponse> {
  // DELETE /unhide_content/{content_id}
  return apiClient.delete<UnhideContentResponse>(`/unhide_content/${contentId}`);
}
