// story-service.ts
import { apiClient } from "../api/api-client";

// Convert your payload to FormData
function buildFormData(payload: any): FormData {
  const formData = new FormData();

  // Required fields
  formData.append("title", payload.title);
  formData.append("body", payload.body);

  // Location name OR lat/long
  if (payload.location) {
    formData.append("location", payload.location);
  }
  if (typeof payload.latitude !== "undefined") {
    formData.append("latitude", String(payload.latitude));
  }
  if (typeof payload.longitude !== "undefined") {
    formData.append("longitude", String(payload.longitude));
  }

  // If there's a file, append it
  if (payload.thumbnail) {
    formData.append("thumbnail", payload.thumbnail);
  }

  return formData;
}

interface ApiResponse {
  success: string;
  message: string;
  data: any;
}
async function postStory(payload: any) {
  // Create FormData
  const formData = buildFormData(payload);

  // Send via multipart/form-data
  const response = await apiClient.post<ApiResponse>("/content/add_story", formData);
  const data = response.data;

  // The API returns e.g. { success: "success", message: "...", data: ... }
  // For convenience, reformat into a single object
  return {
    success: data?.success === "success",
    message: data?.message,
    data: data?.data,
  };
}

// Export as an object if you like to keep the same import style:
export const storyService = {
  postStory,
  // ...other methods if you have them
};
