// hooks/useContentDetails.ts
import { useState } from 'react';
import { ContentDetails } from '../types/content';
import { contentService } from '../services/contentService'


export function useContentDetails() {
  const [contentDetails, setContentDetails] = useState<ContentDetails | null>(null);
  const [loadings, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const getContentDetails = async (contentType: string, contentId: string | number) => {
    setLoading(true);
    setError(null);

    try {
      const data = await contentService.fetchContentDetails(contentType, contentId);
      setContentDetails(data);
    } catch (err: any) {
      setError(err.message || 'Error fetching content details');
    } finally {
      setLoading(false);
    }
  };

  const addComment = async (contentId: number | string, contentType: string, commentText: string) => {
    try {
      const response = await contentService.addComment(contentId, contentType, commentText)
      // The server returns { status, comments: [...] } on success
      if (contentDetails) {
        setContentDetails({ ...contentDetails, comments: response.comments })
      }
    } catch (err: any) {
      console.error("Error adding comment:", err)
      throw err
    }
  }

  // Update a comment (and update state with the updated comment)
  const updateComment = async (commentId: number | string, newContent: string) => {
    try {
      const response = await contentService.updateComment(commentId, newContent)
      // The server returns { status, comment: {...} }
      if (contentDetails) {
        // We'll replace the old comment in the array with the updated one
        const updatedComment = response.comment
        const newComments = contentDetails.comments.map((c) =>
          c.id === updatedComment.id ? updatedComment : c
        )
        setContentDetails({ ...contentDetails, comments: newComments })
      }
    } catch (err: any) {
      console.error("Error updating comment:", err)
      throw err
    }
  }


  return { contentDetails, loadings, error, getContentDetails, addComment, updateComment }
}
