// group-service.ts

import { apiClient } from "../api/api-client";

export interface Group {
  id: number;
  name: string;
  created_by: number;
  created_at: string;
  // optional fields
  members?: GroupMember[];
  messages?: GroupMessage[];
}

export interface GroupMember {
  id: number;
  user_id: number;
  group_chat_id: number;
  joined_at?: string;
  role?: string; // "admin", "owner", "member"
  // etc
}

export interface GroupMessage {
  id: number;
  group_chat_id: number;
  sender_id: number;
  content: string;
  created_at: string;
  sender?: {
    id: number;
    first_name: string;
    last_name: string;
    username: string;
    profile_picture_url?: string;
  };
}

// 1) CREATE GROUP
export async function createGroupChat(name: string): Promise<Group> {
  const result = await apiClient.post<{
    status: string;
    message: string;
    data: { group: Group };
  }>("/group/create", { name });
  return result.data.group;
}

// 2) SEND GROUP MESSAGE
export async function sendGroupMessage(payload: {
  group_chat_id: number;
  content: string;
}): Promise<GroupMessage> {
  const result = await apiClient.post<{
    status: string;
    message: string;
    data: { message: GroupMessage };
  }>("/group/message/send", payload);
  return result.data.message;
}

// 3) FETCH GROUP MESSAGES
export async function fetchGroupMessages(
  group_chat_id: number,
  page = 1,
  limit = 20
): Promise<GroupMessage[]> {
  const endpoint = `/group/messages/${group_chat_id}?page=${page}&limit=${limit}`;
  const result = await apiClient.get<{
    status: string;
    message: string;
    data: {
      current_page: number;
      messages: GroupMessage[];
      total_messages: number;
      total_pages: number;
    };
  }>(endpoint);
  return result.data.messages; // docs: in descending order
}

// 4) FETCH USER GROUPS
export async function fetchUserGroups(page = 1, limit = 10): Promise<Group[]> {
  const endpoint = `/group/list?page=${page}&limit=${limit}`;
  const result = await apiClient.get<{
    status: string;
    message: string;
    data: {
      current_page: number;
      total_groups: number;
      total_pages: number;
      groups: Group[];
    };
  }>(endpoint);
  return result.data.groups;
}

// 5) ADD MEMBER TO GROUP
export async function addMemberToGroup(payload: {
  group_chat_id: number;
  user_id: number;
}): Promise<any> {
  const result = await apiClient.post<{
    status: string;
    message: string;
    data: { member: any };
  }>("/group/member/add", payload);
  return result.data.member;
}

// 6) REMOVE MEMBER FROM GROUP
export async function removeMemberFromGroup(payload: {
  group_chat_id: number;
  user_id: number;
}): Promise<number> {
  const result = await apiClient.request<{
    status: string;
    message: string;
    data: { removed_user_id: number };
  }>("/group/member/remove", "DELETE", payload);
  return result.data.removed_user_id;
}

// 7) JOIN GROUP CHAT
export async function joinGroupChat(group_chat_id: number): Promise<{
  group_id: number;
}> {
  const result = await apiClient.post<{
    status: string;
    message: string;
    data: { group_id: number };
  }>("/group/group/join", { group_chat_id });
  return result.data;
}

// 8) LEAVE GROUP CHAT
export async function leaveGroupChat(payload: {
  group_chat_id: number;
  delete_group_confirmation?: boolean;
}): Promise<{
  group_id: number;
  group_deleted: boolean;
}> {
  const result = await apiClient.post<{
    status: string;
    message: string;
    data: { group_id: number; group_deleted: boolean };
  }>("/group/group/leave", payload);
  return result.data;
}

// 9) ASSIGN OR DEMOTE ADMIN
export async function assignOrDemoteAdmin(payload: {
  group_chat_id: number;
  user_id: number;
  role: "member" | "admin" | "owner";
}): Promise<{
  user_id: number;
  role: string;
}> {
  const result = await apiClient.patch<{
    status: string;
    message: string;
    data: { user_id: number; role: string };
  }>("/group/admin/assign", payload);
  return result.data;
}

// 10) DELETE GROUP MESSAGE
export async function deleteGroupMessage(payload: {
  message_id: number;
  delete_for_all?: boolean;
}): Promise<{ status: string; message: string }> {
  const result = await apiClient.request<{
    status: string;
    message: string;
  }>("/group/message/delete", "DELETE", payload);
  return { status: result.status, message: result.message };
}

// 11) DELETE GROUP
export async function deleteGroup(payload: {
  group_chat_id: number;
}): Promise<number> {
  const result = await apiClient.request<{
    status: string;
    message: string;
    data: { group_chat_id: number };
  }>("/group/delete", "DELETE", payload);
  return result.data.group_chat_id;
}

// 12) GET GROUP MEMBERS
export interface GroupMemberProfile {
  id: number;
  first_name: string;
  last_name: string;
  username: string;
  email: string;
  profile_picture_url?: string;
  role: string; // "member", "admin", "owner"
}
export async function getGroupMembers(group_chat_id: number): Promise<{
  group_id: number;
  total_members: number;
  members: GroupMemberProfile[];
}> {
  const endpoint = `/group/group/members?group_chat_id=${group_chat_id}`;
  const result = await apiClient.get<{
    status: string;
    message: string;
    data: {
      group_id: number;
      total_members: number;
      members: GroupMemberProfile[];
    };
  }>(endpoint);
  return result.data;
}

// 13) GET GROUP MEMBER COUNT
export async function getGroupMemberCount(group_chat_id: number): Promise<{
  group_id: number;
  total_members: number;
}> {
  const endpoint = `/group/group/member-count?group_chat_id=${group_chat_id}`;
  const result = await apiClient.get<{
    status: string;
    message: string;
    data: { group_id: number; total_members: number };
  }>(endpoint);
  return result.data;
}

// 14) EDIT GROUP CHAT MESSAGE
export async function editGroupChatMessage(
  message_id: number,
  content: string
): Promise<{
  status: string;
  message: string;
}> {
  const endpoint = `/group/group-chat/edit-message/${message_id}`;
  const result = await apiClient.put<{
    status: string;
    message: string;
    // optionally result
  }>(endpoint, { content });
  return result;
}

// 15) GENERATE GROUP INVITE LINK
export async function generateGroupInviteLink(
  group_chat_id: number
): Promise<string> {
  const result = await apiClient.post<{
    status: string;
    message: string;
    data: { invite_link: string };
  }>("/group/invite/generate", { group_chat_id });
  return result.data.invite_link;
}

// 16) JOIN GROUP FROM INVITATION
export async function joinGroupFromInvitation(token: string): Promise<{
  status: string;
  message: string;
}> {
  const endpoint = `/group/invite/join/${encodeURIComponent(token)}`;
  const result = await apiClient.get<{
    status: string;
    message: string;
  }>(endpoint);
  return result;
}
