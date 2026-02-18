import { apiClient } from "../api/api-client";
import { StoryPayload, AddStoryResponse, UploadCompletePayload } from "../types/story";

function buildFormData(payload: StoryPayload): FormData {
  const formData = new FormData();

  if (payload.title) {
    formData.append("title", payload.title);
  }
  if (payload.body) {
    formData.append("body", payload.body);
  }

  if (payload.location) {
    formData.append("location", payload.location);
  }

  if (payload.latitude !== undefined) {
    formData.append("latitude", String(payload.latitude));
  }

  if (payload.longitude !== undefined) {
    formData.append("longitude", String(payload.longitude));
  }

  if (payload.thumbnail_url) {
    formData.append("thumbnail_url", payload.thumbnail_url);
  }

  return formData;
}

export const storyService = {
  async postStory(
    payload: StoryPayload
  ): Promise<AddStoryResponse> {
    const formData = buildFormData(payload);
    return apiClient.post<AddStoryResponse>(
      "/content/add_story",
      formData
    );
  },

  async completeUpload(
    payload: UploadCompletePayload
  ): Promise<{ success: boolean; message?: string; data?: any }> {
    return apiClient.post<{ success: boolean; message?: string; data?: any }>(
      "/upload/complete",
      payload
    );
  },
};
