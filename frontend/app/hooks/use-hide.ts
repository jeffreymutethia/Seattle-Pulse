// use-hide.ts

import { useState } from "react";
import { HideContentResponse, hideContentService } from "../services/hide-service";


export function useHideContent() {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
  
    const hideContent = async (contentId: number): Promise<HideContentResponse | null> => {
      try {
        setLoading(true);
        const response = await hideContentService(contentId);
        return response;
      } catch (err) {
        setError(err instanceof Error ? err.message : "Unknown error");
        return null;
      } finally {
        setLoading(false);
      }
    };
  
    return { hideContent, loading, error };
  }