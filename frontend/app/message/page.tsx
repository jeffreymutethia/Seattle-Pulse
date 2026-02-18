/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unused-vars */
"use client";

import React, { useState, useRef, useEffect, JSX, useCallback } from "react";
import debounce from "lodash/debounce";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import NavBar from "@/components/nav-bar";
import { MessagePlaceholder } from "./components/message-placeholder";
import { motion, AnimatePresence } from "framer-motion";
import { useSearchParams } from "next/navigation";
import { useAuth } from "@/app/context/auth-context";
import {
  MoreHorizontal,
  X,
  Menu,
  Users,
  Link2,
  UserPlus,
  UserMinus,
  Send,
  AlertOctagon,
  Plus,
  Search,
  ArrowLeft,
  Trash,
} from "lucide-react";

// DIRECT Chat
import { startDirectChat } from "@/app/services/chat-service";
import { useChatList } from "../hooks/use-chat-list";
import { useDirectMessages } from "../hooks/use-direct-messages";
import { getFollowing, FollowerUser } from "../services/user-service";
import { useCombinedChats } from "../hooks/use-combined-chats";
import { apiClient } from "@/app/api/api-client";

// GROUP Chat
import { useGroupList, useGroupMessages } from "../hooks/group-hooks";
import {
  Group,
  GroupMemberProfile,
  getGroupMembers,
  getGroupMemberCount,
  addMemberToGroup,
  removeMemberFromGroup,
  leaveGroupChat,
  deleteGroup,
  generateGroupInviteLink,
  GroupMessage,
  joinGroupFromInvitation,
  createGroupChat,
} from "../services/group-service";

type StatusType = "online" | "offline" | "idle";
const statusColors: { [key in StatusType]: string } = {
  online: "bg-green-500",
  offline: "bg-gray-500",
  idle: "bg-yellow-500",
};

export default function ChatPage(): JSX.Element {
  const searchParams = useSearchParams();
  const { isAuthenticated } = useAuth();
  
  // Mobile responsiveness state
  const [isMobile, setIsMobile] = useState(false);
  const [isTablet, setIsTablet] = useState(false);
  const [showChatList, setShowChatList] = useState(true);

  // Check if mobile on mount and resize
  useEffect(() => {
    const checkMobile = () => {
      const width = window.innerWidth;
      setIsMobile(width < 1166); // Changed from 768 to 1166
      setIsTablet(width >= 1166 && width < 1400); // Adjusted tablet range
    };

    checkMobile();
    window.addEventListener("resize", checkMobile);
    return () => window.removeEventListener("resize", checkMobile);
  }, []);

  //////////////////////////////////////////////////////
  // Toggle: Tabs - Direct Chat, Group Chat, All
  //////////////////////////////////////////////////////
  const [activeTab, setActiveTab] = useState<'direct' | 'group' | 'all'>('all');
  
  // Helper for backward compatibility
  const isGroupMode = activeTab === 'group';

  //////////////////////////////////////////////////////
  // DIRECT CHAT
  //////////////////////////////////////////////////////
  const { chats, loading: chatsLoading, removeChatLocally, addChatOptimistically } = useChatList();

  interface Contact {
    id: number;
    name: string;
    avatar: string;
    status?: StatusType;
    lastMessage?: string;
  }
  const mappedContacts: Contact[] = chats.map((c) => {
    const displayName =
      `${c.receiver.first_name} ${c.receiver.last_name}`.trim() ||
      c.receiver.username ||
      "Unknown User";

    return {
      id: c.chat_id,
      name: displayName,
      avatar: c.receiver.profile_picture_url || "",
      status: "online",
      lastMessage: c.latest_message?.content || "",
    };
  });

  const [activeChat, setActiveChat] = useState<Contact | null>(null);
  const processedChatsRef = useRef<Set<number>>(new Set());
  const lastChatIdRef = useRef<string | null>(null);

  // Auto-open chat from URL parameter
  useEffect(() => {
    const chatId = searchParams.get('chat');
    const chatIdStr = chatId || null;
    
    // Only process if chat ID changed
    if (chatIdStr === lastChatIdRef.current) {
      // If chat ID hasn't changed, just check if we need to update activeChat from chats
      if (chatIdStr && chats.length > 0) {
        const chatIdNum = parseInt(chatIdStr);
        const chatToOpen = chats.find(chat => chat.chat_id === chatIdNum);
        if (chatToOpen) {
          setActiveChat((current) => {
            // Only update if current chat is loading or doesn't match
            if (!current || current.id !== chatIdNum || current.name === "Loading...") {
              return {
                id: chatToOpen.chat_id,
                name: `${chatToOpen.receiver.first_name} ${chatToOpen.receiver.last_name}`.trim() || chatToOpen.receiver.username || "Unknown User",
                avatar: chatToOpen.receiver.profile_picture_url || "",
                status: "online" as StatusType,
                lastMessage: chatToOpen.latest_message?.content || "",
              };
            }
            return current;
          });
        }
      }
      return;
    }
    
    lastChatIdRef.current = chatIdStr;
    
    if (chatId) {
      const chatIdNum = parseInt(chatId);
      
      // First try to find in existing chats
      const chatToOpen = chats.find(chat => chat.chat_id === chatIdNum);
      if (chatToOpen) {
        const contact: Contact = {
          id: chatToOpen.chat_id,
          name: `${chatToOpen.receiver.first_name} ${chatToOpen.receiver.last_name}`.trim() || chatToOpen.receiver.username || "Unknown User",
          avatar: chatToOpen.receiver.profile_picture_url || "",
          status: "online",
          lastMessage: chatToOpen.latest_message?.content || "",
        };
        setActiveChat(contact);
        return;
      }
      
      // If chat not found in existing chats and we haven't processed it yet
      if (!processedChatsRef.current.has(chatIdNum)) {
        processedChatsRef.current.add(chatIdNum);
        
        // Check sessionStorage for user info (from profile page)
        const pendingChatKey = `pending_chat_${chatIdNum}`;
        const pendingChatData = sessionStorage.getItem(pendingChatKey);
        
        if (pendingChatData) {
          try {
            const userInfo = JSON.parse(pendingChatData);
            // Add chat optimistically with user info from profile
            addChatOptimistically(chatIdNum, {
              id: userInfo.id,
              first_name: userInfo.first_name || "",
              last_name: userInfo.last_name || "",
              username: userInfo.username || "",
              email: userInfo.email || "",
              profile_picture_url: userInfo.profile_picture_url || "",
            });
            // Remove from sessionStorage after using it
            sessionStorage.removeItem(pendingChatKey);
          } catch (err) {
            console.error("Error parsing pending chat data:", err);
          }
        }
        
        // Create a temporary contact and let the direct messages hook handle the receiver info
        const newContact: Contact = {
          id: chatIdNum,
          name: "Loading...", // This will be updated when the chat loads
          avatar: "",
          status: "online",
          lastMessage: "",
        };
        setActiveChat(newContact);
      }
    } else {
      // No chat ID in URL, clear active chat
      setActiveChat(null);
      lastChatIdRef.current = null;
    }
  }, [searchParams, chats, addChatOptimistically]);

  const {
    messages: dmMessages,
    sending,
    send,
    editMessage,
    removeMessage,
    removeChat,
    setMessages,
    receiver,
  } = useDirectMessages(activeChat?.id || 0);

  // Update active chat with receiver information when messages load
  useEffect(() => {
    if (activeChat && activeChat.name === "Loading..." && receiver) {
      // Update the chat with the actual receiver information
      const updatedContact: Contact = {
        id: activeChat.id,
        name: `${receiver.first_name} ${receiver.last_name}`.trim() || receiver.username || "Unknown User",
        avatar: receiver.profile_picture_url || "",
        status: "online",
        lastMessage: activeChat.lastMessage,
      };
      setActiveChat(updatedContact);

      // Check if this chat exists in the chat list, if not, add it optimistically
      // Only add if we haven't already processed this chat
      if (!processedChatsRef.current.has(activeChat.id)) {
        const chatExists = chats.find((c) => c.chat_id === activeChat.id);
        if (!chatExists && receiver) {
          processedChatsRef.current.add(activeChat.id);
          addChatOptimistically(activeChat.id, {
            id: receiver.id,
            first_name: receiver.first_name || "",
            last_name: receiver.last_name || "",
            username: receiver.username || "",
            email: receiver.email || "",
            profile_picture_url: receiver.profile_picture_url || "",
          });
        }
      }
    }
  }, [receiver, activeChat, chats, addChatOptimistically]);

  // Listen for new DM message
  useEffect(() => {
    function handleNewChatMessage(e: any) {
      const data = e.detail; // { chat_id, sender_id, content, etc. }
      if (!activeChat) return;
      if (data.chat_id !== activeChat.id) return;

      const newMsg = {
        id: Date.now(),
        chat_id: data.chat_id,
        sender_id: data.sender_id,
        content: data.content,
        created_at: new Date().toISOString(),
      };
      setMessages((prev: any) => [...prev, newMsg]);
    }

    window.addEventListener("new_chat_message", handleNewChatMessage);
    return () => {
      window.removeEventListener("new_chat_message", handleNewChatMessage);
    };
  }, [activeChat, setMessages]);

  // Auto-scroll DM
  const dmEndRef = useRef<HTMLDivElement | null>(null);
  useEffect(() => {
    if (activeChat) {
      dmEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }
  }, [dmMessages, activeChat]);

  // DM input
  const [messageInput, setMessageInput] = useState("");
  async function handleSendMessage() {
    if (!activeChat || !messageInput.trim()) return;
    await send(messageInput);
    setMessageInput("");
  }
  
  // New message follower selection
  const [followers, setFollowers] = useState<FollowerUser[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [loadingFollowers, setLoadingFollowers] = useState(false);
  const [showNewMessageModal, setShowNewMessageModal] = useState(false);
  
  async function fetchFollowing(query?: string) {
    setLoadingFollowers(true);
    try {
      const response = await getFollowing(query);
      if (response && response.users && Array.isArray(response.users)) {
        setFollowers(response.users);
      } else {
        // Handle empty or unexpected response
        setFollowers([]);
        console.warn("Received unexpected following data structure:", response);
      }
    } catch (err) {
      console.error("Failed to load following list:", err);
      showFeedbackMessage("Failed to load your connections");
      setFollowers([]);
    } finally {
      setLoadingFollowers(false);
    }
  }
  
  async function handleNewMessage() {
    setShowNewMessageModal(true);
    fetchFollowing();
  }
  
  async function startChatWithUser(userId: number, userName: string, userAvatar: string) {
    try {
      showFeedbackMessage("Starting chat...");
      const chatId = await startDirectChat(userId);
      
      if (!chatId) {
        showFeedbackMessage("Could not create chat - no chat ID returned");
        return;
      }
      
      // Instead of reloading the page, manually add the new chat contact
      // and set it as active
      const newContact: Contact = {
        id: chatId,
        name: userName,
        avatar: userAvatar,
        status: "online",
        lastMessage: ""
      };
      
      // Check if this chat already exists in the contacts
      const existingChat = mappedContacts.find(c => c.id === chatId);
      if (existingChat) {
        // If it exists, just set it as active
        setActiveChat(existingChat);
        showFeedbackMessage("Chat opened successfully!");
      } else {
        // If it's a new chat, add it to contacts list and set it as active
        mappedContacts.unshift(newContact); // Update the existing array
        setActiveChat(newContact);
        showFeedbackMessage("New chat created successfully!");
      }
      
      setShowNewMessageModal(false);
    } catch (err: any) {
      console.error("Failed to start chat:", err);
      showFeedbackMessage(`Failed to start chat: ${err.message || 'Unknown error'}`);
    }
  }
  
  // Delete chat modal
  async function handleDeleteChat() {
    if (!activeChat) return;
    
    setConfirmModalData({
      title: "Delete Chat",
      message: `Delete entire direct chat with ${activeChat.name}?`,
      onConfirm: async () => {
    try {
      await removeChat();
      removeChatLocally(activeChat.id);
      setActiveChat(null);
          setShowConfirmationModal(false);
          showFeedbackMessage("Chat deleted successfully");
    } catch (err) {
      console.error("Error deleting DM chat:", err);
          showFeedbackMessage("Failed to delete chat");
          setShowConfirmationModal(false);
    }
      }
    });
    setShowConfirmationModal(true);
  }

  // DM editing
  const [editingMessageId, setEditingMessageId] = useState<number | null>(null);
  const [editText, setEditText] = useState("");
  function startEditing(msgId: number, currentText: string) {
    setEditingMessageId(msgId);
    setEditText(currentText);
  }
  async function confirmEdit(msgId: number) {
    if (!editText.trim()) return;
    await editMessage(msgId, editText);
    setEditingMessageId(null);
    setEditText("");
  }
  
  // DM message deletion
  async function handleDeleteDirectMessage(messageId: number) {
    setConfirmModalData({
      title: "Delete Message",
      message: "Are you sure you want to delete this message?",
      onConfirm: async () => {
        try {
          await removeMessage(messageId);
          setOpenDropdownId(null);
          setShowConfirmationModal(false);
          showFeedbackMessage("Message deleted");
        } catch (err) {
          console.error("Error deleting message:", err);
          showFeedbackMessage("Failed to delete message");
          setShowConfirmationModal(false);
        }
      }
    });
    setShowConfirmationModal(true);
  }
  
  const [openDropdownId, setOpenDropdownId] = useState<number | null>(null);

  //////////////////////////////////////////////////////
  // GROUP CHAT
  //////////////////////////////////////////////////////
  const { groups, loading: groupsLoading, refresh: refreshGroups } = useGroupList();
  const [activeGroup, setActiveGroup] = useState<Group | null>(null);

  // Reversed group messages + socket
  const {
    messages: groupMessages,
    sending: groupSending,
    send: sendGroupMsg,
    setMessages: setGroupMessages,
    editMessage: editGroupMessage,
    removeMessage: removeGroupMessage,
    editing: groupEditing,
    deleting: groupDeleting,
  } = useGroupMessages(activeGroup?.id || 0);

  // Group input
  const [groupInput, setGroupInput] = useState("");
  async function handleSendGroupMessage() {
    if (!activeGroup || !groupInput.trim()) return;
    await sendGroupMsg(groupInput);
    setGroupInput("");
  }

  // Auto-scroll group
  const groupEndRef = useRef<HTMLDivElement | null>(null);
  useEffect(() => {
    if (activeGroup) {
      groupEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }
  }, [groupMessages, activeGroup]);

  // Group message editing
  const [editingGroupMessageId, setEditingGroupMessageId] = useState<number | null>(null);
  const [groupEditText, setGroupEditText] = useState("");
  
  function startGroupEditing(msgId: number, currentText: string) {
    setEditingGroupMessageId(msgId);
    setGroupEditText(currentText);
  }
  
  async function confirmGroupEdit(msgId: number) {
    if (!groupEditText.trim()) return;
    const success = await editGroupMessage(msgId, groupEditText);
    if (success) {
      setEditingGroupMessageId(null);
      setGroupEditText("");
    } else {
      showFeedbackMessage("Failed to edit message. Try again later.");
    }
  }
  
  // Group message dropdown controls
  const [openGroupDropdownId, setOpenGroupDropdownId] = useState<number | null>(null);
  
  async function handleDeleteGroupMessage(messageId: number) {
    setConfirmModalData({
      title: "Delete Message",
      message: "Are you sure you want to delete this message?",
      onConfirm: async () => {
        const success = await removeGroupMessage(messageId, true);
        if (!success) {
          showFeedbackMessage("Failed to delete message. Try again later.");
        }
        setOpenGroupDropdownId(null);
        setShowConfirmationModal(false);
      }
    });
    setShowConfirmationModal(true);
  }

  // We store group members in local state. The user wants a modal, not a side panel.
  const [members, setMembers] = useState<GroupMemberProfile[]>([]);
  const [memberCount, setMemberCount] = useState(0);
  const [showMembersModal, setShowMembersModal] = useState(false);

  // Add modals for various actions
  const [showConfirmationModal, setShowConfirmationModal] = useState(false);
  const [confirmModalData, setConfirmModalData] = useState<{
    title: string;
    message: string;
    onConfirm: () => void;
  }>({ title: '', message: '', onConfirm: () => {} });

  // For add member modal
  const [showAddMemberModal, setShowAddMemberModal] = useState(false);
  const [newMemberId, setNewMemberId] = useState("");
  const [memberSearchQuery, setMemberSearchQuery] = useState("");
  const [memberSearchResults, setMemberSearchResults] = useState<FollowerUser[]>([]);
  const [loadingMemberSearch, setLoadingMemberSearch] = useState(false);
  const [selectedMember, setSelectedMember] = useState<FollowerUser | null>(null);

  // For create group modal  
  const [showCreateGroupModal, setShowCreateGroupModal] = useState(false);
  const [newGroupName, setNewGroupName] = useState("");

  // We'll store a text message here instead of using alerts
  const [feedback, setFeedback] = useState<string>("");
  const [showFeedback, setShowFeedback] = useState(false);

  // Helper to show feedback with auto-hide
  const showFeedbackMessage = (message: string) => {
    setFeedback(message);
    setShowFeedback(true);
    setTimeout(() => setShowFeedback(false), 3000);
  };

  // For retrieving group members & count
  async function loadGroupMembers() {
    if (!activeGroup) return;
    try {
      const data = await getGroupMembers(activeGroup.id);
      setMembers(data.members);
      setMemberCount(data.total_members);
    } catch (err) {
      console.error("Failed to load group members:", err);
      showFeedbackMessage("Could not load group members.");
    }
  }
  async function loadGroupCount() {
    if (!activeGroup) return;
    try {
      const data = await getGroupMemberCount(activeGroup.id);
      setMemberCount(data.total_members);
    } catch (err) {
      console.error("Failed to load group member count:", err);
      showFeedbackMessage("Could not load member count.");
    }
  }

  // Show the members modal
  async function openMembersModal() {
    if (!activeGroup) return;
    await loadGroupMembers();
    setShowMembersModal(true);
  }
  function closeMembersModal() {
    setShowMembersModal(false);
  }

  // Search users for adding to group
  const searchUsersForMember = useCallback(
    debounce(async (query?: string) => {
      if (!query || query.trim().length === 0) {
        setMemberSearchResults([]);
        return;
      }
      
      setLoadingMemberSearch(true);
      try {
        const endpoint = `/users/search?query=${encodeURIComponent(query)}&page=1&per_page=10`;
        const response = await apiClient.get<{
          success: string;
          message: string;
          data: Array<{
            id: number;
            username: string;
            first_name: string;
            last_name: string;
            profile_picture_url: string;
            bio?: string;
          }>;
        }>(endpoint);
        
        if (response.success === "success" && response.data) {
          // Convert to FollowerUser format
          const users: FollowerUser[] = response.data.map(user => ({
            id: user.id,
            username: user.username,
            first_name: user.first_name,
            last_name: user.last_name,
            profile_picture_url: user.profile_picture_url,
            bio: user.bio,
          }));
          setMemberSearchResults(users);
        } else {
          setMemberSearchResults([]);
        }
      } catch (err) {
        console.error("Failed to search users:", err);
        setMemberSearchResults([]);
      } finally {
        setLoadingMemberSearch(false);
      }
    }, 300),
    []
  );

  // Add member
  async function handleAddMember() {
    if (!activeGroup) return;
    if (!selectedMember) {
      showFeedbackMessage("Please select a user to add");
      return;
    }
    
    try {
      await addMemberToGroup({ group_chat_id: activeGroup.id, user_id: selectedMember.id });
      showFeedbackMessage("Member added successfully.");
      setShowAddMemberModal(false);
      setNewMemberId("");
      setMemberSearchQuery("");
      setMemberSearchResults([]);
      setSelectedMember(null);
      await loadGroupMembers(); // refresh
    } catch (err) {
      console.error(err);
      showFeedbackMessage("Failed to add member.");
    }
  }

  // Open add member modal
  function openAddMemberModal() {
    setShowAddMemberModal(true);
    setMemberSearchQuery("");
    setMemberSearchResults([]);
    setSelectedMember(null);
  }
  
  // Remove member
  async function handleRemoveMember(userId: number) {
    if (!activeGroup) return;
    
    setConfirmModalData({
      title: "Remove Member",
      message: "Are you sure you want to remove this member from the group?",
      onConfirm: async () => {
    try {
      await removeMemberFromGroup({
        group_chat_id: activeGroup.id,
            user_id: userId,
      });
          showFeedbackMessage("Member removed successfully.");
      await loadGroupMembers(); // refresh
          setShowConfirmationModal(false);
    } catch (err) {
      console.error(err);
          showFeedbackMessage("Failed to remove member.");
          setShowConfirmationModal(false);
    }
      }
    });
    setShowConfirmationModal(true);
  }

  // Leave group
  async function handleLeaveGroup() {
    if (!activeGroup) return;
    
    setConfirmModalData({
      title: "Leave Group",
      message: `Are you sure you want to leave group: ${activeGroup.name}?`,
      onConfirm: async () => {
    try {
      await leaveGroupChat({ group_chat_id: activeGroup.id });
          showFeedbackMessage(`You left the group ${activeGroup.name}.`);
          refreshGroups(); // Refresh group list
      setActiveGroup(null);
          setShowConfirmationModal(false);
    } catch (err) {
      console.error(err);
          showFeedbackMessage("Failed to leave group.");
          setShowConfirmationModal(false);
    }
      }
    });
    setShowConfirmationModal(true);
  }

  // Delete group
  async function handleDeleteGroup() {
    if (!activeGroup) return;
    
    setConfirmModalData({
      title: "Delete Group",
      message: `Are you sure you want to delete the group: ${activeGroup.name}?`,
      onConfirm: async () => {
    try {
      await deleteGroup({ group_chat_id: activeGroup.id });
          showFeedbackMessage(`Deleted group ${activeGroup.name}.`);
          refreshGroups(); // Refresh group list
      setActiveGroup(null);
          setShowConfirmationModal(false);
    } catch (err) {
      console.error(err);
          showFeedbackMessage("Failed to delete group.");
          setShowConfirmationModal(false);
    }
      }
    });
    setShowConfirmationModal(true);
  }

  // Generate invite
  const [inviteLink, setInviteLink] = useState<string>("");
  async function handleGenerateInvite() {
    if (!activeGroup) return;
    try {
      const link = await generateGroupInviteLink(activeGroup.id);
      setInviteLink(link);
      showFeedbackMessage("Invite link generated!");
    } catch (err) {
      console.error(err);
      showFeedbackMessage("Failed to generate invite link.");
    }
  }
  
  // Join from invite
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [inviteToken, setInviteToken] = useState("");
  
  async function handleJoinFromInvite() {
    if (!inviteToken.trim()) {
      showFeedbackMessage("Please enter an invite token");
      return;
    }
    
    try {
      await joinGroupFromInvitation(inviteToken);
      showFeedbackMessage("Successfully joined group!");
      setShowJoinModal(false);
      setInviteToken("");
      refreshGroups(); // Refresh the list of groups
    } catch (err) {
      console.error(err);
      showFeedbackMessage("Failed to join group from invitation.");
    }
  }
  
  // Create new group
  async function handleCreateGroup() {
    if (!newGroupName.trim()) {
      showFeedbackMessage("Please enter a group name");
      return;
    }
    
    try {
      await createGroupChat(newGroupName.trim());
      showFeedbackMessage(`Group "${newGroupName}" created!`);
      setShowCreateGroupModal(false);
      setNewGroupName("");
      refreshGroups(); // Refresh the list of groups
    } catch (err) {
      console.error(err);
      showFeedbackMessage("Failed to create group.");
    }
  }

  // Set active group and immediately load members
  const handleSetActiveGroup = async (group: Group) => {
    setActiveGroup(group);
    // Immediately fetch member count
    if (group) {
      try {
        const data = await getGroupMemberCount(group.id);
        setMemberCount(data.total_members);
        
        // Also load members in background for better UX
        loadGroupMembers();
      } catch (err) {
        console.error("Failed to load group data:", err);
      }
    }
  };

  //////////////////////////////////////////////////////
  // COMBINED CHATS (ALL)
  //////////////////////////////////////////////////////
  const {
    chats: combinedChats,
    loading: combinedLoading,
    refresh: refreshCombined
  } = useCombinedChats();

  // Add an effect to log the combined chats for debugging
  useEffect(() => {
  }, [combinedChats]);

  const [activeCombinedChat, setActiveCombinedChat] = useState<{
    id: number;
    type: 'direct' | 'group';
  } | null>(null);

  // Mobile navigation logic
  useEffect(() => {
    if (isMobile) {
      if (activeChat || activeGroup) {
        setShowChatList(false);
      }
    } else {
      setShowChatList(true);
    }
  }, [activeChat, activeGroup, isMobile]);

  // Handle chat selection with mobile navigation
  const handleChatSelect = (contact: Contact) => {
    setActiveChat(contact);
    setActiveGroup(null);
    setActiveCombinedChat({ id: contact.id, type: 'direct' });
    if (isMobile) {
      setShowChatList(false);
    }
  };

  // Handle group selection with mobile navigation
  const handleGroupSelect = (group: Group) => {
    setActiveGroup(group);
    setActiveChat(null);
    setActiveCombinedChat({ id: group.id, type: 'group' });
    if (isMobile) {
      setShowChatList(false);
    }
  };

  // Handle back to list for mobile
  const handleBackToList = () => {
    setActiveChat(null);
    setActiveGroup(null);
    setActiveCombinedChat(null);
    if (isMobile) {
      setShowChatList(true);
    }
  };

  // Handle combined chat selection
  const handleCombinedChatSelect = (chatId: number, type: 'direct' | 'group') => {
    // Set the active combined chat ID (updates the UI selection)
    setActiveCombinedChat({ id: chatId, type });

    if (type === 'direct') {
      // Find and set the direct chat
      const directChat = mappedContacts.find(c => c.id === chatId);
      if (directChat) {
        handleChatSelect(directChat);
        // We're using the useDirectMessages hook which automatically loads messages when activeChat changes
      } else {
        showFeedbackMessage("Could not find the selected direct chat. Try refreshing the page.");
      }
    } else if (type === 'group') {
      // Find and set the group chat
      const group = groups.find(g => g.id === chatId);
      if (group) {
        handleGroupSelect(group);
        // Load group members immediately
        if (group) {
          loadGroupMembers();
        }
      } else {
        showFeedbackMessage("Could not find the selected group. Try refreshing the page.");
      }
    }
  };

  //////////////////////////////////////////////////////
  // RENDER
  //////////////////////////////////////////////////////
  return (
    <div className="w-full mx-auto p-2 md:p-4">
      <NavBar 
      title="Messages" 
      showLocationSelector={false}
      showNotification={isAuthenticated}
      showMessage={isAuthenticated}
      isAuthenticated={isAuthenticated}
        />

      {/* Feedback message */}
      <AnimatePresence>
        {showFeedback && (
          <motion.div 
            className="fixed top-16 left-1/2 transform -translate-x-1/2 z-50 bg-gray-800 text-white px-4 py-2 rounded-md shadow-lg"
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
          >
          {feedback}
          </motion.div>
      )}
      </AnimatePresence>

      {/* Tabs: Direct, Groups, All - Hide on mobile when chat is open */}
      <div className={`flex items-center justify-center gap-2 lg:gap-4 mb-2 ${isMobile && !showChatList ? "hidden" : ""}`}>
        <Button
          variant={activeTab === 'direct' ? "default" : "outline"}
          onClick={() => setActiveTab('direct')}
          size={isMobile ? "sm" : "default"}
          className="text-xs lg:text-sm px-3 lg:px-4"
        >
          Inbox
        </Button>
        <Button
          variant={activeTab === 'group' ? "default" : "outline"}
          onClick={() => setActiveTab('group')}
          size={isMobile ? "sm" : "default"}
          className="text-xs lg:text-sm px-3 lg:px-4"
        >
          Groups
        </Button>
        <Button
          variant={activeTab === 'all' ? "default" : "outline"}
          onClick={() => setActiveTab('all')}
          size={isMobile ? "sm" : "default"}
          className="text-xs lg:text-sm px-3 lg:px-4"
        >
          All
        </Button>
      </div>

      <div className="flex h-[calc(100vh-140px)] mx-2 md:mx-10 rounded-xl lg:rounded-3xl border overflow-hidden mb-20 md:pb-0">
        {/* LEFT SIDEBAR - Full width on mobile when showChatList is true */}
        <div className={`${
          isMobile ? (showChatList ? "w-full" : "hidden") : isTablet ? "w-72" : "w-80"
        } bg-white border-r flex flex-col h-full transition-all duration-300`}>
          <div className="py-4 lg:py-6 px-4 lg:px-8">
            <p className="font-semibold text-base lg:text-lg">
              {activeTab === 'direct' ? "My Inbox" : 
               activeTab === 'group' ? "My Groups" : "All Chats"}
            </p>
          </div>

          <ScrollArea className="flex-grow">
            {/* Direct Chat List */}
            {activeTab === 'direct' && (
              <>
                {chatsLoading && (
                  <div className="px-8 py-4 text-gray-500 text-sm">
                    Loading Chats...
                  </div>
                )}
                {!chatsLoading && mappedContacts.length === 0 && (
                  <div className="px-8 py-4 text-gray-500 text-sm">
                    No chats found
                  </div>
                )}
                {mappedContacts.map((contact) => (
                  <motion.div
                    key={contact.id}
                    className={`py-3 md:py-4 px-4 md:px-8 hover:bg-[#F1F4F9] cursor-pointer ${
                      activeChat && activeChat.id === contact.id
                        ? "bg-gray-100"
                        : ""
                    }`}
                    onClick={() => handleChatSelect(contact)}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.1 }}
                  >
                    <div className="flex items-center gap-3">
                      <div className="relative">
                        <Avatar className="w-10 h-10 lg:w-12 lg:h-12">
                          <AvatarImage src={contact.avatar} />
                          <AvatarFallback>
                            {contact.name
                              .split(" ")
                              .map((n) => n[0])
                              .join("")}
                          </AvatarFallback>
                        </Avatar>
                        {contact.status && (
                          <div
                            className={`absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white ${
                              statusColors[contact.status]
                            }`}
                          />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-medium text-sm lg:text-base">{contact.name}</div>
                        <div className="text-xs lg:text-sm text-gray-500 truncate">
                          {contact.lastMessage}
                        </div>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </>
            )}

            {/* Group List */}
            {activeTab === 'group' && (
              <>
                {groupsLoading && (
                  <div className="px-8 py-4 text-gray-500 text-sm">
                    Loading Groups...
                  </div>
                )}
                {!groupsLoading && groups.length === 0 && (
                  <div className="px-8 py-4 text-gray-500 text-sm">
                    No groups found
                  </div>
                )}
                {groups.map((g) => {
                  // Get the latest message
                  const latestMessage = g.messages && g.messages.length > 0 
                    ? g.messages[g.messages.length - 1] 
                    : null;
                  
                  return (
                  <motion.div
                    key={g.id}
                    className={`py-3 md:py-4 px-4 md:px-8 hover:bg-[#F1F4F9] cursor-pointer ${
                      activeGroup && activeGroup.id === g.id
                        ? "bg-gray-100"
                        : ""
                    }`}
                      onClick={() => handleGroupSelect(g)}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.1 }}
                  >
                    <div className="flex items-center gap-3">
                      <div className="relative">
                        <Avatar className="w-10 h-10 lg:w-12 lg:h-12">
                          <AvatarImage src="" />
                          <AvatarFallback>
                            {g.name
                              .split(" ")
                              .map((n) => n[0])
                              .join("")}
                          </AvatarFallback>
                        </Avatar>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-medium text-sm lg:text-base">{g.name}</div>
                        <div className="text-xs lg:text-sm text-gray-500 truncate">
                            {latestMessage ? (
                              <>
                                {latestMessage.sender?.first_name && (
                                  <span className="font-medium">
                                    {latestMessage.sender.first_name}: 
                                  </span>
                                )}{" "}
                                {latestMessage.content}
                              </>
                            ) : (
                              `Group #${g.id}`
                            )}
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  );
                })}
              </>
            )}

            {/* Combined Chat List (All) */}
            {activeTab === 'all' && (
              <>
                {combinedLoading && (
                  <div className="px-8 py-4 text-gray-500 text-sm">
                    Loading Chats...
                  </div>
                )}
                {!combinedLoading && (!combinedChats || combinedChats.length === 0) && (
                  <div className="px-8 py-4 text-gray-500 text-sm">
                    No chats found. Start a new conversation!
                  </div>
                )}
                {combinedChats && combinedChats.length > 0 && combinedChats.map((chat, index) => (
                  <motion.div
                    key={`combined-${chat.type}-${chat.chat_id}-${index}`}
                    className={`py-3 md:py-4 px-4 md:px-8 hover:bg-[#F1F4F9] cursor-pointer ${
                      activeCombinedChat && 
                      activeCombinedChat.id === chat.chat_id && 
                      activeCombinedChat.type === chat.type
                        ? "bg-gray-100"
                        : ""
                    }`}
                    onClick={() => handleCombinedChatSelect(chat.chat_id, chat.type)}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.1 }}
                  >
                    <div className="flex items-center gap-3">
                      <div className="relative">
                        <Avatar className="w-10 h-10 lg:w-12 lg:h-12">
                          <AvatarImage src={chat.profile_picture_url || ""} />
                          <AvatarFallback>
                            {chat.name
                              ? chat.name.split(" ").map((n) => n[0]).join("")
                              : "??"
                            }
                          </AvatarFallback>
                        </Avatar>
                        {chat.type === 'group' && (
                          <div className="absolute bottom-0 right-0 w-3 h-3 bg-purple-500 rounded-full border-2 border-white" />
                        )}
                        {chat.type === 'direct' && (
                          <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-500 rounded-full border-2 border-white" />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-medium flex items-center text-sm lg:text-base">
                          {chat.name || "Unnamed Chat"}
                          <span className="ml-2 text-xs px-1.5 py-0.5 rounded bg-gray-200 text-gray-700">
                            {chat.type === 'direct' ? 'DM' : 'Group'}
                          </span>
                        </div>
                        <div className="text-xs lg:text-sm text-gray-500 truncate">
                          {chat.latest_message ? chat.latest_message.content : "No messages yet"}
                        </div>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </>
            )}
          </ScrollArea>

          {/* Bottom buttons */}
          <div className="border-t mt-auto w-full bg-white">
            {activeTab === 'direct' && (
              <div
                className="p-2.5 flex items-center justify-center gap-2 text-gray-600 cursor-pointer hover:bg-gray-50"
                onClick={handleNewMessage}
              >
                <Menu size={16} />
                <span className="text-sm">New Message</span>
              </div>
            )}

            {activeTab === 'group' && (
              <div className="flex">
                <div
                  className="p-2.5 flex-1 flex items-center justify-center gap-2 text-gray-600 cursor-pointer hover:bg-gray-50"
                  onClick={() => setShowCreateGroupModal(true)}
                >
                  <Plus size={16} />
                  <span className="text-xs md:text-sm">New Group</span>
                </div>
                <div
                  className="p-2.5 flex-1 flex items-center justify-center gap-2 text-gray-600 cursor-pointer hover:bg-gray-50 border-l"
                  onClick={() => setShowJoinModal(true)}
                >
                  <Link2 size={16} />
                  <span className="text-xs md:text-sm">Join Group</span>
                </div>
              </div>
            )}

            {activeTab === 'all' && (
              <div className="flex">
                <div
                  className="p-2.5 flex-1 flex items-center justify-center gap-2 text-gray-600 cursor-pointer hover:bg-gray-50"
                  onClick={handleNewMessage}
                >
                  <Menu size={16} />
                  <span className="text-xs md:text-sm">New Message</span>
                </div>
                <div
                  className="p-2.5 flex-1 flex items-center justify-center gap-2 text-gray-600 cursor-pointer hover:bg-gray-50 border-l"
                  onClick={() => setShowCreateGroupModal(true)}
                >
                  <Plus size={16} />
                  <span className="text-xs md:text-sm">New Group</span>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* RIGHT SIDE - Hidden on mobile when showChatList is true */}
        <div className={`${isMobile ? (showChatList ? "hidden" : "w-full ") : "flex-1"} transition-all duration-300`}>
          <AnimatePresence mode="wait">
            {/* Active Direct Chat - Show in any tab when a direct chat is selected */}
            {activeChat && (
              <motion.div
                key={`dm-${activeChat.id}`}
                className="flex flex-col h-full md:pb-0"
                initial={{ opacity: 0, x: 10 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 10 }}
                transition={{ duration: 0.2 }}
              >
                {/* DM Header */}
                <div className="py-3 px-4 lg:px-6 border-b bg-white sticky top-0 z-10 flex justify-between items-center">
                  <div className="flex items-center gap-3">
                    {/* Back button for mobile */}
                    {isMobile && (
                      <Button variant="ghost" size="icon" onClick={handleBackToList} className="mr-2">
                        <ArrowLeft size={20} />
                      </Button>
                    )}
                    <div className="relative">
                      <Avatar className="w-8 h-8 lg:w-10 lg:h-10">
                        <AvatarImage src={activeChat.avatar} />
                        <AvatarFallback>
                          {activeChat.name
                            .split(" ")
                            .map((n) => n[0])
                            .join("")}
                        </AvatarFallback>
                      </Avatar>
                      {activeChat.status && (
                        <div
                          className={`absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white ${
                            statusColors[activeChat.status]
                          }`}
                        />
                      )}
                    </div>
                    <div>
                      <div className="font-medium text-sm lg:text-base">{activeChat.name}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={handleDeleteChat}
                    >
                      <Trash size={16} />
                    </Button>
                    {!isMobile && (
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={handleBackToList}
                      >
                        <X size={16} />
                      </Button>
                    )}
                  </div>
                </div>

              {/* Messages area */}
              <ScrollArea className="flex-1 bg-white py-2 px-4 lg:px-6">
                <div className="space-y-2 max-w-4xl mx-auto">
                  {dmMessages.map((message: any) => {
                    const userId = sessionStorage.getItem("user_id");
                    const isMe = userId && String(message.sender_id) === userId;
                    const isEditing = editingMessageId === message.id;

                    return (
                      <motion.div
                        key={message.id}
                        className={`flex gap-2 md:gap-3 ${isMe ? "justify-end" : ""}`}
                        initial={{ opacity: 0, y: 5 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.1 }}
                      >
                        {/* If it's not me, show sender avatar */}
                        {!isMe && (
                          <div className="mt-2">
                            <Avatar className="w-8 h-8 lg:w-10 lg:h-10">
                              <AvatarImage src={activeChat.avatar || "/placeholder.svg"} />
                              <AvatarFallback>
                                {activeChat.name
                                  .split(" ")
                                  .map((n) => n[0])
                                  .join("")}
                              </AvatarFallback>
                            </Avatar>
                          </div>
                        )}
                        <div className="flex-1">
                          {/* If it's not me, show sender name */}
                          {!isMe && <div className="text-sm font-medium text-gray-700 mb-1">{activeChat.name}</div>}
                          <div
                            className={`relative rounded-2xl p-3 lg:p-4 m-1 w-fit max-w-[85%] lg:max-w-[75%] whitespace-pre-wrap ${
                              isMe
                                ? "bg-[#4C68D5] rounded-tr-none text-left text-white ml-auto"
                                : "bg-[#F1F4F9] rounded-tl-none text-[#27364B]"
                            }`}
                          >
                            {isEditing ? (
                              <div className="flex flex-col">
                                <textarea
                                  className="text-black rounded p-2 text-sm"
                                  value={editText}
                                  onChange={(e) => setEditText(e.target.value)}
                                />
                                <div className="flex justify-end gap-2 mt-1">
                                  <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => {
                                      setEditingMessageId(null);
                                      setEditText("");
                                    }}
                                  >
                                    Cancel
                                  </Button>
                                  <Button
                                    variant="default"
                                    size="sm"
                                    onClick={() => confirmEdit(message.id)}
                                  >
                                    Save
                                  </Button>
                                </div>
                              </div>
                            ) : (
                              <>
                                {message.content}
                                <div className="text-xs text-end mt-1 opacity-70">
                                  {message.created_at
                                    ? new Date(
                                        message.created_at
                                      ).toLocaleTimeString([], {
                                        hour: "2-digit",
                                        minute: "2-digit",
                                      })
                                    : ""}
                                </div>
                              </>
                            )}

                            {!isEditing && isMe && (
                              <div className="absolute top-2 right-2">
                                <div className="relative inline-block text-left">
                                  <button
                                    className="p-1 rounded-full hover:bg-black/10"
                                    onClick={() =>
                                      setOpenDropdownId(
                                        openDropdownId === message.id
                                          ? null
                                          : message.id
                                      )
                                    }
                                  >
                                    <MoreHorizontal
                                      size={14}
                                      className="text-white"
                                    />
                                  </button>

                                  <AnimatePresence>
                                    {openDropdownId === message.id && (
                                      <motion.div
                                        initial={{
                                          opacity: 0,
                                          scale: 0.95,
                                        }}
                                        animate={{
                                          opacity: 1,
                                          scale: 1,
                                        }}
                                        exit={{
                                          opacity: 0,
                                          scale: 0.95,
                                        }}
                                        transition={{ duration: 0.1 }}
                                        className="absolute right-0 mt-1 w-24 bg-slate-900 border rounded shadow-md z-10 text-right"
                                      >
                                        <button
                                          className="block w-full px-3 py-2 text-sm hover:bg-slate-800 text-white"
                                          onClick={() => {
                                            startEditing(
                                              message.id,
                                              message.content
                                            );
                                            setOpenDropdownId(null);
                                          }}
                                        >
                                          Edit
                                        </button>
                                        <button
                                          className="block w-full px-3 py-2 text-sm hover:bg-slate-800 text-white"
                                          onClick={() => {
                                            handleDeleteDirectMessage(message.id);
                                          }}
                                        >
                                          Delete
                                        </button>
                                      </motion.div>
                                    )}
                                  </AnimatePresence>
                                </div>
                              </div>
                            )}
                          </div>
                        </div>
                      </motion.div>
                    );
                  })}
                  <div ref={dmEndRef} />
                </div>
              </ScrollArea>

              {/* Input area */}
              <div className="flex bg-white p-3 sm:p-4 border-t border-gray-200 gap-2 sm:gap-3">
                {/* Avatar - Hidden on very small screens, visible on sm+ */}
                <div className="hidden xs:flex items-center">
                  <Avatar className="w-8 h-8 sm:w-10 sm:h-10 flex-shrink-0">
                    <AvatarImage src={activeChat.avatar || "/placeholder.svg"} />
                    <AvatarFallback />
                  </Avatar>
                </div>

                {/* Input Container */}
                <div className="flex items-center border border-gray-300 rounded-full px-3 py-2 flex-1 min-w-0">
                  <input
                    placeholder="Type a message..."
                    className="flex-1 px-2 sm:px-3 py-1 outline-none text-sm sm:text-base min-w-0"
                    value={messageInput}
                    onChange={(e) => setMessageInput(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        e.preventDefault();
                        handleSendMessage();
                      }
                    }}
                    disabled={sending}
                  />

                  {/* Send Button */}
                  <button
                    className="text-blue-500 p-1.5 sm:p-2 rounded-full hover:bg-blue-100 disabled:cursor-not-allowed disabled:opacity-50 flex-shrink-0 ml-1"
                    onClick={handleSendMessage}
                    disabled={sending || !messageInput.trim()}
                    aria-label="Send message"
                  >
                    {sending ? (
                      <div className="animate-spin rounded-full h-4 w-4 sm:h-5 sm:w-5 border-2 border-blue-500 border-t-transparent" />
                    ) : (
                      <Send size={16} className="sm:w-5 sm:h-5" />
                    )}
                  </button>
                </div>
              </div>
            </motion.div>
          )}

          {/* Active Group Chat - Show in any tab when a group is selected and no direct chat */}
          {activeGroup && !activeChat && (
            <motion.div
              key={`group-${activeGroup.id}`}
              className="flex flex-col h-full"
              initial={{ opacity: 0, x: 10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 10 }}
              transition={{ duration: 0.2 }}
            >
              {/* Group Header */}
              <div className="py-3 px-4 lg:px-6 border-b bg-white sticky top-0 z-10 flex justify-between items-center">
                <div className="flex items-center gap-3">
                  {/* Back button for mobile */}
                  {isMobile && (
                    <Button variant="ghost" size="icon" onClick={handleBackToList} className="mr-2">
                      <ArrowLeft size={20} />
                    </Button>
                  )}
                  <Avatar className="w-8 h-8 lg:w-10 lg:h-10">
                    <AvatarImage src="" />
                    <AvatarFallback>
                      {activeGroup.name
                        .split(" ")
                        .map((n) => n[0])
                        .join("")}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    {/* e.g. "Group #13 (10 members)" */}
                    <div className="font-medium text-sm lg:text-base">
                      {activeGroup.name} ({memberCount} members)
                    </div>
                    <p className="text-xs md:text-sm text-gray-500">
                      Group #{activeGroup.id}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2 relative">
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={handleDeleteChat}
                  >
                    <Trash size={16} />
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={openMembersModal}
                  >
                    <Users size={16} />
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={handleGenerateInvite}
                  >
                    <Link2 size={16} />
                  </Button>
                  {!isMobile && (
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={handleBackToList}
                    >
                      <X size={16} />
                    </Button>
                  )}
                </div>
              </div>

              {/* Group Messages area */}
              <ScrollArea className="flex-1 bg-white py-2 px-4 lg:px-6">
                <div className="space-y-2 max-w-4xl mx-auto">
                  {groupMessages.map((msg: GroupMessage) => {
                    const userId = sessionStorage.getItem("user_id");
                    const isMe = userId && String(msg.sender_id) === userId;
                    const isEditing = editingGroupMessageId === msg.id;
                    
                    return (
                      <motion.div
                        key={msg.id}
                        className={`flex gap-2 md:gap-3 ${isMe ? "justify-end" : ""}`}
                        initial={{ opacity: 0, y: 5 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.1 }}
                      >
                        {/* If it's not me, show sender avatar */}
                        {!isMe && (
                          <div className="mt-2">
                            <Avatar className="w-8 h-8 lg:w-10 lg:h-10">
                              <AvatarImage
                                src={msg.sender?.profile_picture_url || ""}
                              />
                              <AvatarFallback>
                                {msg.sender
                                  ? (msg.sender.first_name?.[0] || "") +
                                    (msg.sender.last_name?.[0] || "")
                                  : "??"}
                              </AvatarFallback>
                            </Avatar>
                          </div>
                        )}

                        <div className="flex-1">
                          {/* If it's not me, show sender name */}
                          {!isMe && msg.sender && (
                            <div className="text-sm font-medium text-gray-700 mb-1">
                              {msg.sender.first_name} {msg.sender.last_name}
                            </div>
                          )}

                          <div
                            className={`relative rounded-2xl p-3 lg:p-4 m-1 w-fit max-w-[85%] lg:max-w-[75%] whitespace-pre-wrap ${
                              isMe
                                ? "bg-[#4C68D5] rounded-tr-none text-left text-white ml-auto"
                                : "bg-[#F1F4F9] rounded-tl-none text-[#27364B]"
                            }`}
                          >
                            {isEditing ? (
                              <div className="flex flex-col">
                                <textarea
                                  className="text-black rounded p-2 text-sm"
                                  value={groupEditText}
                                  onChange={(e) => setGroupEditText(e.target.value)}
                                />
                                <div className="flex justify-end gap-2 mt-1">
                                  <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => {
                                      setEditingGroupMessageId(null);
                                      setGroupEditText("");
                                    }}
                                  >
                                    Cancel
                                  </Button>
                                  <Button
                                    variant="default"
                                    size="sm"
                                    onClick={() => confirmGroupEdit(msg.id)}
                                  >
                                    Save
                                  </Button>
                                </div>
                              </div>
                            ) : (
                              <>
                            {msg.content}
                            <div className="text-xs text-end mt-1 opacity-70">
                              {new Date(msg.created_at).toLocaleTimeString([], {
                                hour: "2-digit",
                                minute: "2-digit",
                              })}
                            </div>
                              </>
                            )}

                            {/* Message control dropdown */}
                            {!isEditing && isMe && (
                              <div className="absolute top-2 right-2">
                                <div className="relative inline-block text-left">
                                  <button
                                    className="p-1 rounded-full hover:bg-black/10"
                                    onClick={() =>
                                      setOpenGroupDropdownId(
                                        openGroupDropdownId === msg.id
                                          ? null
                                          : msg.id
                                      )
                                    }
                                  >
                                    <MoreHorizontal
                                      size={14}
                                      className="text-white"
                                    />
                                  </button>

                                  <AnimatePresence>
                                    {openGroupDropdownId === msg.id && (
                                      <motion.div
                                        initial={{
                                          opacity: 0,
                                          scale: 0.95,
                                        }}
                                        animate={{
                                          opacity: 1,
                                          scale: 1,
                                        }}
                                        exit={{
                                          opacity: 0,
                                          scale: 0.95,
                                        }}
                                        transition={{ duration: 0.1 }}
                                        className="absolute right-0 mt-1 w-24 bg-slate-900 border rounded shadow-md z-10 text-right"
                                      >
                                        <button
                                          className="block w-full px-3 py-2 text-sm hover:bg-slate-800 text-white"
                                          onClick={() => {
                                            startGroupEditing(
                                              msg.id,
                                              msg.content
                                            );
                                            setOpenGroupDropdownId(null);
                                          }}
                                        >
                                          Edit
                                        </button>
                                        <button
                                          className="block w-full px-3 py-2 text-sm hover:bg-slate-800 text-white"
                                          onClick={() => handleDeleteGroupMessage(msg.id)}
                                        >
                                          Delete
                                        </button>
                                      </motion.div>
                                    )}
                                  </AnimatePresence>
                                </div>
                              </div>
                            )}
                          </div>
                        </div>
                      </motion.div>
                    );
                  })}
                  <div ref={groupEndRef} />
                </div>
              </ScrollArea>

              {/* Group Input */}
              <div className="flex bg-white p-3 sm:p-4 border-t border-gray-200 gap-2 sm:gap-3">
                {/* Avatar - Hidden on very small screens, visible on sm+ */}
                <div className="hidden xs:flex items-center">
                  <Avatar className="w-8 h-8 sm:w-10 sm:h-10 flex-shrink-0">
                    <AvatarImage src="" />
                    <AvatarFallback>GC</AvatarFallback>
                  </Avatar>
                </div>

                {/* Input Container */}
                <div className="flex items-center border border-gray-300 rounded-full px-3 py-2 flex-1 min-w-0">
                  <input
                    placeholder="Type a message for the group..."
                    className="flex-1 px-2 sm:px-3 py-1 outline-none text-sm sm:text-base min-w-0 placeholder:text-gray-500"
                    value={groupInput}
                    onChange={(e) => setGroupInput(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        e.preventDefault();
                        handleSendGroupMessage();
                      }
                    }}
                    disabled={groupSending}
                  />

                  {/* Send Button */}
                  <button
                    className="text-blue-500 p-1.5 sm:p-2 rounded-full hover:bg-blue-100 disabled:cursor-not-allowed disabled:opacity-50 flex-shrink-0 ml-1 transition-colors"
                    onClick={handleSendGroupMessage}
                    disabled={groupSending || !groupInput.trim()}
                    aria-label="Send group message"
                  >
                    {groupSending ? (
                      <div className="animate-spin rounded-full h-4 w-4 sm:h-5 sm:w-5 border-2 border-blue-500 border-t-transparent" />
                    ) : (
                      <Send size={16} className="sm:w-5 sm:h-5" />
                    )}
                  </button>
                </div>
              </div>
            </motion.div>
          )}

          {/* If no active chat => placeholder */}
          {!activeChat && !activeGroup && !isMobile && <MessagePlaceholder />}
        </AnimatePresence>
      </div>
      </div>

      {/* MEMBERS MODAL */}
      {showMembersModal && (
        <AnimatePresence>
          {/* Basic overlay + modal with framer-motion */}
          <motion.div
            className="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50 p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <motion.div
              className="bg-white rounded-xl p-4 lg:p-5 w-full max-w-sm lg:max-w-md relative"
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
            >
              <div className="flex justify-between items-center mb-3">
                <h2 className="text-lg font-semibold">Group Members</h2>
                <button onClick={closeMembersModal}>
                  <X size={16} />
                </button>
              </div>
              <div className="text-sm text-gray-500 mb-2">
                Total: {memberCount}
              </div>

              <div className="max-h-60 overflow-auto">
                {members.map((m) => {
                  // only show role if admin or owner
                  const showRole =
                    m.role === "admin" || m.role === "owner" ? m.role : "";
                  return (
                    <div
                      key={m.id}
                      className="flex items-center justify-between gap-2 py-2 border-b last:border-none"
                    >
                      <div className="flex items-center gap-2">
                      <Avatar>
                        <AvatarImage src={m.profile_picture_url || ""} />
                        <AvatarFallback>
                          {(m.first_name?.[0] || "") + (m.last_name?.[0] || "")}
                        </AvatarFallback>
                      </Avatar>
                        <div>
                        {m.first_name} {m.last_name}
                        {showRole && (
                          <span className="ml-2 text-xs text-blue-600 font-medium">
                            {showRole}
                          </span>
                        )}
                      </div>
                      </div>
                      
                      {/* Remove button (only if current user is admin/owner) */}
                      {m.id !== parseInt(sessionStorage.getItem("user_id") || "0") && (
                        <Button 
                          variant="ghost" 
                          size="sm"
                          className="text-red-500"
                          onClick={() => handleRemoveMember(m.id)}
                        >
                          <UserMinus size={14} />
                        </Button>
                      )}
                    </div>
                  );
                })}
              </div>

              <div className="mt-4 flex flex-wrap gap-2">
                <Button variant="outline" size="sm" onClick={openAddMemberModal}>
                  <UserPlus size={14} className="mr-1" />
                  Add
                </Button>
                <Button
                  variant="destructive"
                  size="sm"
                  onClick={handleLeaveGroup}
                >
                  Leave
                </Button>
                <Button
                  variant="destructive"
                  size="sm"
                  onClick={handleDeleteGroup}
                >
                  Delete
                </Button>
              </div>
            </motion.div>
          </motion.div>
        </AnimatePresence>
      )}
      
      {/* CONFIRMATION MODAL */}
      {showConfirmationModal && (
        <AnimatePresence>
          <motion.div
            className="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <motion.div
              className="bg-white rounded-xl p-5 w-[400px] relative"
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
            >
              <div className="flex items-center gap-3 mb-4">
                <AlertOctagon className="text-red-500" size={24} />
                <h2 className="text-lg font-semibold">{confirmModalData.title}</h2>
              </div>
              
              <p className="mb-6 text-gray-700">{confirmModalData.message}</p>
              
              <div className="flex justify-end gap-3">
                <Button 
                  variant="outline" 
                  onClick={() => setShowConfirmationModal(false)}
                >
                  Cancel
                </Button>
                <Button 
                  variant="destructive" 
                  onClick={confirmModalData.onConfirm}
                >
                  Confirm
                </Button>
              </div>
            </motion.div>
          </motion.div>
        </AnimatePresence>
      )}
      
      {/* ADD MEMBER MODAL */}
      {showAddMemberModal && (
        <AnimatePresence>
          <motion.div
            className="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50 p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <motion.div
              className="bg-white rounded-xl p-4 lg:p-5 w-full max-w-sm lg:max-w-md relative max-h-[80vh] flex flex-col"
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
            >
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-lg font-semibold">Add New Member</h2>
                <button onClick={() => {
                  setShowAddMemberModal(false);
                  setMemberSearchQuery("");
                  setMemberSearchResults([]);
                  setSelectedMember(null);
                }}>
                  <X size={16} />
                </button>
              </div>
              
              <div className="mb-4">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
                  <input
                    type="text"
                    className="w-full p-2 pl-10 border rounded"
                    value={memberSearchQuery}
                    onChange={(e) => {
                      setMemberSearchQuery(e.target.value);
                      searchUsersForMember(e.target.value);
                    }}
                    placeholder="Search users by username or name"
                  />
                </div>
              </div>
              
              <div className="flex-1 overflow-y-auto mb-4">
                {loadingMemberSearch ? (
                  <div className="flex justify-center items-center p-4">
                    <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-500"></div>
                  </div>
                ) : memberSearchQuery.trim().length === 0 ? (
                  <div className="text-center p-4 text-gray-500">
                    Start typing to search for users
                  </div>
                ) : memberSearchResults.length === 0 ? (
                  <div className="text-center p-4 text-gray-500">
                    No users found
                  </div>
                ) : (
                  <div className="divide-y">
                    {memberSearchResults.map(user => (
                      <div 
                        key={user.id}
                        className={`flex items-center gap-3 py-3 px-2 hover:bg-gray-50 cursor-pointer ${
                          selectedMember?.id === user.id ? 'bg-blue-50' : ''
                        }`}
                        onClick={() => setSelectedMember(user)}
                      >
                        <Avatar>
                          <AvatarImage src={user.profile_picture_url} />
                          <AvatarFallback>
                            {(user.first_name?.[0] || "") + (user.last_name?.[0] || "") || user.username.substring(0, 2).toUpperCase()}
                          </AvatarFallback>
                        </Avatar>
                        <div className="flex-1">
                          <div className="font-medium">
                            {user.first_name && user.last_name 
                              ? `${user.first_name} ${user.last_name}`
                              : user.username}
                          </div>
                          {user.bio && (
                            <div className="text-sm text-gray-500 truncate max-w-xs">
                              {user.bio}
                            </div>
                          )}
                        </div>
                        {selectedMember?.id === user.id && (
                          <div className="text-blue-500">✓</div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
              
              <div className="flex justify-end">
                <Button 
                  variant="default" 
                  onClick={handleAddMember}
                  disabled={!selectedMember}
                >
                  Add Member
                </Button>
              </div>
            </motion.div>
          </motion.div>
        </AnimatePresence>
      )}

      {/* CREATE GROUP MODAL */}
      {showCreateGroupModal && (
        <AnimatePresence>
          <motion.div
            className="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50 p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <motion.div
              className="bg-white rounded-xl p-4 lg:p-5 w-full max-w-sm lg:max-w-md relative"
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
            >
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-lg font-semibold">Create New Group</h2>
                <button onClick={() => setShowCreateGroupModal(false)}>
                  <X size={16} />
                </button>
              </div>
              
              <div className="mb-4">
                <label className="block text-sm font-medium mb-1">
                  Group Name:
                </label>
                <input
                  type="text"
                  className="w-full p-2 border rounded"
                  value={newGroupName}
                  onChange={(e) => setNewGroupName(e.target.value)}
                  placeholder="Enter group name"
                />
              </div>
              
              <div className="flex justify-end">
                <Button 
                  variant="default" 
                  onClick={handleCreateGroup}
                >
                  Create Group
                </Button>
              </div>
            </motion.div>
          </motion.div>
        </AnimatePresence>
      )}
      
      {/* INVITE LINK MODAL */}
      {inviteLink && (
        <AnimatePresence>
          <motion.div
            className="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50 p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setInviteLink("")}
          >
            <motion.div
              className="bg-white rounded-xl p-4 lg:p-5 w-full max-w-md lg:max-w-lg relative"
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex justify-between items-center mb-3">
                <h2 className="text-lg font-semibold">Group Invite Link</h2>
                <button onClick={() => setInviteLink("")}>
                  <X size={16} />
                </button>
              </div>
              
              <div className="bg-gray-100 p-3 rounded text-sm mb-3 break-all">
                {inviteLink}
              </div>
              
              <div className="flex justify-end">
                <Button 
                  variant="default" 
                  onClick={() => {
                    navigator.clipboard.writeText(inviteLink);
                    showFeedbackMessage("Link copied to clipboard!");
                  }}
                >
                  Copy Link
                </Button>
              </div>
            </motion.div>
          </motion.div>
        </AnimatePresence>
      )}
      
      {/* JOIN FROM INVITE MODAL */}
      {showJoinModal && (
        <AnimatePresence>
          <motion.div
            className="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50 p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <motion.div
              className="bg-white rounded-xl p-4 lg:p-5 w-full max-w-sm lg:max-w-md relative"
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
            >
              <div className="flex justify-between items-center mb-3">
                <h2 className="text-lg font-semibold">Join Group</h2>
                <button onClick={() => setShowJoinModal(false)}>
                  <X size={16} />
                </button>
              </div>
              
              <div className="mb-4">
                <label className="block text-sm font-medium mb-1">
                  Paste invite token or link:
                </label>
                <input
                  type="text"
                  className="w-full p-2 border rounded"
                  value={inviteToken}
                  onChange={(e) => setInviteToken(e.target.value)}
                  placeholder="Enter token or paste link"
                />
              </div>
              
              <div className="flex justify-end">
                <Button 
                  variant="default" 
                  onClick={handleJoinFromInvite}
                >
                  Join Group
                </Button>
              </div>
            </motion.div>
          </motion.div>
        </AnimatePresence>
      )}

      {/* NEW MESSAGE MODAL */}
      {showNewMessageModal && (
        <AnimatePresence>
          <motion.div
            className="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50 p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <motion.div
              className="bg-white rounded-xl p-4 lg:p-5 w-full max-w-md lg:max-w-lg relative max-h-[80vh] flex flex-col"
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
            >
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-lg font-semibold">New Message</h2>
                <button onClick={() => setShowNewMessageModal(false)}>
                  <X size={16} />
                </button>
              </div>
              
              <div className="mb-4">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
                  <input
                    type="text"
                    className="w-full p-2 pl-10 border rounded"
                    value={searchQuery}
                    onChange={(e) => {
                      setSearchQuery(e.target.value);
                      fetchFollowing(e.target.value);
                    }}
                    placeholder="Search people you follow"
                  />
                </div>
              </div>
              
              <div className="flex-1 overflow-y-auto">
                {loadingFollowers ? (
                  <div className="flex justify-center items-center p-4">
                    <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-500"></div>
                  </div>
                ) : followers.length === 0 ? (
                  <div className="text-center p-4 text-gray-500">
                    No connections found
                  </div>
                ) : (
                  <div className="divide-y">
                    {followers.map(user => (
                      <div 
                        key={user.id}
                        className="flex items-center gap-3 py-3 px-2 hover:bg-gray-50 cursor-pointer"
                        onClick={() => startChatWithUser(
                          user.id, 
                          user.first_name && user.last_name 
                            ? `${user.first_name} ${user.last_name}` 
                            : user.username,
                          user.profile_picture_url
                        )}
                      >
                        <Avatar>
                          <AvatarImage src={user.profile_picture_url} />
                          <AvatarFallback>
                            {(user.first_name?.[0] || "") + (user.last_name?.[0] || "") || user.username.substring(0, 2).toUpperCase()}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <div className="font-medium">
                            {user.first_name && user.last_name 
                              ? `${user.first_name} ${user.last_name}`
                              : user.username}
                          </div>
                          {user.bio && (
                            <div className="text-sm text-gray-500 truncate max-w-xs">
                              {user.bio}
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </motion.div>
          </motion.div>
        </AnimatePresence>
      )}
    </div>
  );
}
