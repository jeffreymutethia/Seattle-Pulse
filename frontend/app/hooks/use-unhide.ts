
import { useState } from "react";
import { UnhideContentResponse, unhideContentService } from "../services/unhide-service";

export function useUnhideContent() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSuccess, setIsSuccess] = useState(false);

  const unhideContent = async (contentId: number): Promise<UnhideContentResponse> => {
    setIsLoading(true);
    setError(null);
    setIsSuccess(false);

    try {
      const response = await unhideContentService(contentId);
      setIsSuccess(true);
      return response;
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  return { unhideContent, isLoading, error, isSuccess };
}
