import { apiClient } from "../api/api-client";
import {
  ProfileResponse,
  PostsResponse,
  RepostsResponse,
  ProfileData,
} from "../types/profile";

export const fetchUserProfile = async (
  username: string
): Promise<ProfileData> => {
  return apiClient.get<ProfileData>(`/profile/${username}`);
};

export const fetchUserPosts = async (
  username: string,
  page: number = 1,
  perPage: number = 20
): Promise<PostsResponse> => {
  return apiClient.get<PostsResponse>(`/profile/${username}/posts?page=${page}&per_page=${perPage}`);
};

export const fetchUserReposts = async (
  username: string,
  page: number = 1,
  perPage: number = 20
): Promise<RepostsResponse> => {
  return apiClient.get<RepostsResponse>(`/profile/${username}/reposts?page=${page}&per_page=${perPage}`);
};

export const toggleFollow = async (
  userId: number,
  isFollowing: boolean
): Promise<ProfileResponse> => {
  const endpoint = isFollowing ? `/unfollow/${userId}` : `/follow/${userId}`;
  return apiClient.post<ProfileResponse>(endpoint);
};
