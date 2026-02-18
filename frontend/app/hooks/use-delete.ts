// use-delete.ts

// hooks/use-delete.ts
import { useState } from "react";
import {
  deleteStoryService,
  DeleteStoryResponse,
} from "../services/delete-service";

export function useDeleteStory() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const deleteStory = async (
    contentId: number
  ): Promise<DeleteStoryResponse | null> => {
    try {
      setLoading(true);
      const response = await deleteStoryService(contentId);
      return response;
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
      return null;
    } finally {
      setLoading(false);
    }
  };

  return { deleteStory, loading, error };
}
