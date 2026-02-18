/* eslint-disable @typescript-eslint/no-explicit-any */
// /app/services/chat-service.ts

import { apiClient } from "../api/api-client";

/////////////////////////////////////////////////
// Types
/////////////////////////////////////////////////

// The server's direct chat listing
export interface ChatListItem {
  chat_id: number;
  receiver: {
    id: number;
    first_name: string;
    last_name: string;
    username: string;
    email: string;
    profile_picture_url: string;
  };
  latest_message: {
    id: number;
    chat_id: number;
    sender_id: number;
    content: string;
    created_at: string;
    sender?: {
      id: number;
      first_name: string;
      last_name: string;
      username: string;
      profile_picture_url: string;
    };
  } | null;
  last_updated: string;
}

// Combined chat list item (direct and group chats)
export interface CombinedChatItem {
  chat_id: number;
  type: 'direct' | 'group';
  name: string;
  profile_picture_url: string;
  receiver: {
    id: number;
    first_name: string;
    last_name: string;
    username: string;
    email: string;
    profile_picture_url: string;
  } | null;
  latest_message: {
    sender_id: number;
    content: string;
    created_at: string;
  } | null;
  last_updated: string;
}

// Individual chat message
export interface DirectMessage {
  id: number;
  chat_id: number;
  sender_id: number;
  content: string;
  created_at: string;
  sender?: {
    id: number;
    first_name: string;
    last_name: string;
    username: string;
    profile_picture_url: string;
  };
}

// For sending new message
export interface SendMessagePayload {
  chat_id: number;
  content: string;
}

/////////////////////////////////////////////////
// API Calls
/////////////////////////////////////////////////

// 1) Fetch all direct chats
export async function fetchDirectChats(page = 1, limit = 10) {
  const response = await apiClient.get<{
    status: string;
    message: string;
    data: {
      pagination: any;
      chats: ChatListItem[];
    };
  }>(`/chat/direct/list?page=${page}&limit=${limit}`);
  return response.data.chats || [];
}

// 1.5) Fetch combined chat list (direct and group)
export async function fetchCombinedChats(page = 1, limit = 10) {
  try {
    // Use the exact endpoint provided in the API documentation
    const endpoint = `/chat/list/all?page=${page}&limit=${limit}`;
    
    // Use any type to avoid TS errors
    const response: any = await apiClient.get(endpoint);
    
    // Direct access to the chats array, handling different possible structures
    if (response?.data?.data?.chats) {
      return response.data.data.chats;
    }
    
    // Fallback to direct data.chats if that structure exists
    if (response?.data?.chats) {
      return response.data.chats;
    }
    
    // Log warning and return empty array if structure is unexpected
    console.warn('Could not find chats in response. Structure:', response?.data ? JSON.stringify(response.data) : 'undefined');
    return [];
  } catch (error) {
    console.error('Error fetching combined chats:', error);
    return [];
  }
}

// 2) Start (or get existing) direct chat with a user
export async function startDirectChat(otherUserId: number) {
  try {
    // Make a basic POST request
    const response = await apiClient.post(`/chat/direct/start/${otherUserId}`);
    
    
    // Use safe type casting to access nested properties
    const responseObj = response as any;
    
    // Extract the chat ID based on the observed response structure
    // {"data":{"chat":{"id":8,"user1_id":13,"user2_id":16,"created_at":"...","messages":[]}},"message":"...","status":"success"}
    const chatId = responseObj?.data?.data?.chat?.id;
    
    if (chatId) {
      return chatId;
    }
    
    // Fallback to other possible paths in case the API response structure changes
    const fallbackId = responseObj?.data?.chat?.id;
    if (fallbackId) {
      return fallbackId;
    }
    
    console.error('Failed to get chat ID from response:', response);
    throw new Error('Failed to get chat ID from server response');
  } catch (error) {
    console.error('Error starting direct chat:', error);
    throw error;
  }
}

// 3) Fetch messages in a direct chat
export async function fetchDirectMessages(
  chatId: number,
  page = 1,
  limit = 20
) {
  const response = await apiClient.get<{
    status: string;
    message: string;
    data: {
      chat_id: number;
      receiver: any;
      messages: DirectMessage[];
      pagination: any;
    };
  }>(`/chat/direct/${chatId}/messages?page=${page}&limit=${limit}`);
  return {
    messages: response.data.messages || [],
    receiver: response.data.receiver,
    chatId: response.data.chat_id
  };
}

// 4) Send a new message
export async function sendDirectMessage(payload: SendMessagePayload) {
  const response = await apiClient.post<{
    status: string;
    message: string;
    data: { message_data: DirectMessage };
  }>("/chat/direct/send", payload);
  return response.data.message_data;
}

// 5) Edit a message
export async function editDirectMessage(messageId: number, content: string) {
  // PUT /v1/chat/direct-chat/edit-message/{message_id}
  await apiClient.put(`/chat/direct-chat/edit-message/${messageId}`, {
    content,
  });
  return true;
}

// 6) Delete a message
// We must send a DELETE request with optional body: { delete_for_all: boolean }
export async function deleteDirectMessage(
  messageId: number,
  deleteForAll = false
) {
  // The easiest approach with our `apiClient` might be:
  const response = await apiClient.request(
    `/chat/direct-chat/delete-message/${messageId}`,
    "DELETE",
    {
      delete_for_all: deleteForAll,
    }
  );
  return response; // adapt if needed
}

// 7) Delete entire chat
export async function deleteChat(chatId: number) {
  // DELETE /v1/chat/direct-chat/delete-chat/{chat_id}
  return apiClient.delete(`/chat/direct-chat/delete-chat/${chatId}`);
}
