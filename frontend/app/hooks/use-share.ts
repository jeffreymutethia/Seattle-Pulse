/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unused-vars */
"use client";

import { useState, useCallback } from "react";
import { shareService, ShareContentData } from "../services/share-service";
import { ExtendedPost } from "../types/content";

export function useShare() {
  const [shareContent, setShareContent] = useState<ShareContentData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchSharedContent = useCallback(async (shareId: string) => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await shareService.getSharedContent(shareId);
      
      if (response.success === "success" && response.data) {
        setShareContent(response.data);
        return response.data;
      } else {
        setError(response.message || "Failed to fetch shared content");
        return null;
      }
    } catch (err) {
      const errorMessage = "Failed to fetch shared content";
      setError(errorMessage);
      console.error("Error fetching shared content:", err);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  // Convert share content to ExtendedPost format for compatibility with existing components
  const convertToExtendedPost = useCallback((shareData: ShareContentData): ExtendedPost => {
    return {
      id: shareData.id,
      title: shareData.title,
      body: shareData.description, // Use 'body' field as per Post interface
      thumbnail: shareData.image_url, // Use 'thumbnail' field as per Post interface
      location: shareData.location,
      user: {
        id: shareData.user.id,
        username: shareData.user.username,
        profile_picture_url: shareData.user.profile_picture_url,
      },
      created_at: new Date().toISOString(), // You might want to get actual creation date from API
      updated_at: new Date().toISOString(),
      time_since_post: "now",
      score: "0",
      reactions_count: shareData.total_reactions,
      comments_count: shareData.total_comments,
      user_has_reacted: !!shareData.user_reaction,
      user_reaction_type: shareData.user_reaction?.replace("ReactionType.", "") as any || null,
      has_user_reposted: false, // Default value, might need to be fetched separately
      userReaction: shareData.user_reaction,
      totalReactions: shareData.total_reactions,
      top_reactions: Object.entries(shareData.reaction_breakdown)
        .filter(([_, count]) => count > 0)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 3)
        .map(([reaction]) => reaction),
    };
  }, []);

  const clearShareContent = useCallback(() => {
    setShareContent(null);
    setError(null);
  }, []);

  return {
    shareContent,
    loading,
    error,
    fetchSharedContent,
    convertToExtendedPost,
    clearShareContent,
  };
}