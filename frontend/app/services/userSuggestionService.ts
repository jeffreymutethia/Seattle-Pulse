/* eslint-disable @typescript-eslint/no-explicit-any */

import { apiClient } from "../api/api-client";
import { Person } from "../types/user";

export const fetchUserSuggestions = async (
  page = 1,
  per_page = 10
): Promise<Person[]> => {
  const data = await apiClient.get<{ data: any }>(
    `/feed/suggestions?page=${page}&per_page=${per_page}`
  );

  const updatedUsers: Person[] = data.data.map((user: any) => ({
    ...user,
    followers: user.followers || 0,
    location: user.location || "Seattle",
    is_following: false,
  }));

  return updatedUsers;
};

export const toggleFollow = async (
  userId: number,
  isFollowing: boolean
): Promise<void> => {
  const endpoint = isFollowing ? `/unfollow/${userId}` : `/follow/${userId}`;
  await apiClient.post(endpoint);
};
