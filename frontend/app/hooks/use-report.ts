// use-report.ts

import { useState } from "react";
import {
  ReportContentParams,
  ReportContentResponse,
  reportContentService,
} from "../services/report-service";

export function useReportContent() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reportContent = async (
    params: ReportContentParams
  ): Promise<ReportContentResponse | null> => {
    try {
      setLoading(true);
      const response = await reportContentService(params);
      return response;
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
      return null;
    } finally {
      setLoading(false);
    }
  };

  return { reportContent, loading, error };
}
