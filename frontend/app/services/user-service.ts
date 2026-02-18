import { apiClient } from "../api/api-client";

export interface FollowerUser {
  id: number;
  username: string;
  profile_picture_url: string;
  bio?: string;
  first_name?: string;
  last_name?: string;
}

export interface FollowersResponse {
  status: string;
  total: number;
  users: FollowerUser[];
}


export async function getFollowers(searchQuery?: string): Promise<FollowersResponse> {
  try {
    let endpoint = '/get_followers';
    if (searchQuery) {
      endpoint += `?query=${encodeURIComponent(searchQuery)}`;
    }
    
    const response = await apiClient.get<{
      status: string;
      total: number;
      users: FollowerUser[];
    }>(endpoint);
    
    return response;
  } catch (error) {
    console.error('Error fetching followers:', error);
    // Return empty response on error
    return { status: 'error', total: 0, users: [] };
  }
}

/**
 * Get following list with optional search
 */
export async function getFollowing(searchQuery?: string): Promise<FollowersResponse> {
  try {
    let endpoint = '/get_following';
    if (searchQuery) {
      endpoint += `?query=${encodeURIComponent(searchQuery)}`;
    }
    
    const response = await apiClient.get<{
      status: string;
      total: number;
      users: FollowerUser[];
    }>(endpoint);
    
    return response;
  } catch (error) {
    console.error('Error fetching following:', error);
    // Return empty response on error
    return { status: 'error', total: 0, users: [] };
  }
} 