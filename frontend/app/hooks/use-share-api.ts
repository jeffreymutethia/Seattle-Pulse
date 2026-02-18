"use client";

import { useState, useCallback } from "react";
import { shareApiService, CreateShareRequest } from "../services/share-api-service";

export function useShareApi() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const createShare = useCallback(async (
    contentId: number, 
    platform: CreateShareRequest["platform"] = "link"
  ) => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await shareApiService.createShare(contentId, platform);
      
      if (response.status === "success" && response.data) {
        return response.data.sharable_link;
      } else {
        setError(response.message || "Failed to create share link");
        return null;
      }
    } catch (err) {
      const errorMessage = "Failed to create share link";
      setError(errorMessage);
      console.error("Error creating share:", err);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  return {
    loading,
    error,
    createShare,
    clearError,
  };
}
