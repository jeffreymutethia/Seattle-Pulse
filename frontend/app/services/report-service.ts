// report-service.ts

import { apiClient } from "../api/api-client";

/**
 * Valid reasons can be:
 *  SPAM | HARASSMENT | VIOLENCE | INAPPROPRIATE_LANGUAGE
 *  | HATE_SPEECH | SEXUAL_CONTENT | FALSE_INFORMATION | OTHER
 */
export interface ReportContentParams {
  content_id: number;
  reason: string;
  custom_reason?: string;
}

export interface ReportContentResponse {
  success: string;
  message: string;
  data: {
    id: number;
    content_id: number;
    reporter_id: number;
    reason: string;
    custom_reason?: string;
    created_at: string;
  };
}

export async function reportContentService(
  params: ReportContentParams
): Promise<ReportContentResponse> {
  return apiClient.post<ReportContentResponse>(
    "/content/report_content",
    params
  );
}
