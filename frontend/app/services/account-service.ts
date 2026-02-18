import { apiClient } from "../api/api-client";

export interface EditProfilePayload {
  first_name?: string;
  last_name?: string;
  username?: string;
  email?: string;
  bio?: string;
  home_location?: string;
  profile_picture?: File | null;
}

function buildEditProfileFormData(payload: EditProfilePayload): FormData {
  const formData = new FormData();
  if (payload.first_name) formData.append("first_name", payload.first_name);
  if (payload.last_name) formData.append("last_name", payload.last_name);
  if (payload.username) formData.append("username", payload.username);
  if (payload.email) formData.append("email", payload.email);
  if (payload.bio) formData.append("bio", payload.bio);
  if (payload.home_location) formData.append("location", payload.home_location);
  if (payload.profile_picture) {
    formData.append("profile_picture", payload.profile_picture);
  }
  return formData;
}

export const accountService = {
  async editProfile(
    payload: EditProfilePayload
  ): Promise<{ status: string; message: string; user: any }> {
    const formData = buildEditProfileFormData(payload);
    return apiClient.patch<{ status: string; message: string; user: any }>(
      "/profile/edit_profile",
      formData
    );
  },

  async deleteAccount(payload: {
    username?: string;
    email?: string;
    reason: string;
    comments?: string;
  }): Promise<{ status: string; message: string }> {
    return apiClient.delete<{ status: string; message: string }>(
      "/profile/delete_user"
      // { data: payload }
    );
  },
};

type UpdateCredentialsPayload = {
  user_id: number;
  email?: string;
  old_password?: string;
  new_password?: string;
  confirm_new_password?: string;
};

type UpdateCredentialsResponse = {
  status: string;
  message: string;
};

export async function updatePasswordAndEmail(
  payload: UpdateCredentialsPayload
): Promise<UpdateCredentialsResponse> {
  const { email, old_password, new_password, confirm_new_password, user_id } =
    payload;

  const isUpdatingEmail = typeof email === "string" && email.trim() !== "";
  const isUpdatingPassword =
    old_password && new_password && confirm_new_password;

  if (!isUpdatingEmail && !isUpdatingPassword) {
    throw new Error("Provide at least an email or all password fields.");
  }

  return apiClient.patch<UpdateCredentialsResponse>(
    "/auth/update_password_and_email",
    payload
  );
}

interface ToggleHomeLocationResponse {
  success: string;
  message: string;
  data: {
    show_home_location: boolean;
  } | null;
}

export async function toggleHomeLocationVisibility(
  showHomeLocation: boolean
): Promise<ToggleHomeLocationResponse> {
  return apiClient.patch<ToggleHomeLocationResponse>(
    "/profile/toggle-home-location",
    { show_home_location: showHomeLocation }
  );
}

type DeleteUserResponse = {
  status: string;
  message: string;
};

interface DeleteUserParams {
  username?: string;
  email?: string;
  reason: string;
  comments?: string;
}

export async function deleteUserAccount(params: DeleteUserParams) {
  const response = await apiClient.request<DeleteUserResponse>(
    "/profile/delete_user",
    "DELETE",
    params
  );
  return response;
}
