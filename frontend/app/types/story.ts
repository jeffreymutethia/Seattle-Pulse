/* eslint-disable @typescript-eslint/no-explicit-any */
// Types for the multi-step form
export type UploadState = "idle" | "uploading" | "success" | "error";

export interface FormData {
  media: any;
  caption: string;
  location: string;
}

export interface LocationSuggestion {
  label: string;
  dropdownValue: string;
  latitude: number;
  longitude: number;
}

export interface Step {
  id: number;
  name: string;
  icon: string;
}

export interface StoryPayload {
  title?: string;
  body?: string;
  location: string;
  latitude?: number;
  longitude?: number;
  thumbnail_url?: string;
}

// New types for the updated API flow
export interface UploadPrepareResponse {
  presigned_url: string;
  file_url: string;
  upload_key: string;
}

export interface AddStoryResponse {
  data: {
    post: {
      id: number; // This is the content_id
      body: string;
      created_at: string;
      is_in_seattle: boolean;
      latitude: number;
      location: string;
      longitude: number;
      news_link: string | null;
      thumbnail: string;
      title: string;
      unique_id: number;
      updated_at: string;
      user: {
        email: string;
        first_name: string;
        id: number;
        last_name: string;
        username: string;
      };
      user_id: number;
    };
  };
  message: string;
  success: string;
}

export interface UploadCompletePayload {
  upload_key: string;
  content_id: number;
  metadata: {
    content_type: string;
  };
}
