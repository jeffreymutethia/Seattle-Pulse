class ApiEndpoints {
  static const String login = "/auth/login";
  static const String register = "/auth/register";
  static const String verifyAccount = "/auth/verify-account";
  static const String resendOtp = "/auth/resend_otp";

  // Chat endpoints
  static const String directChatStart = "/chat/direct/start"; // POST /:userId
  static const String directChatSend = "/chat/direct/send"; // POST
  static const String directChatMessages =
      "/chat/direct"; // GET /:chatId/messages
  static const String directChatDelete =
      "/chat/direct-chat/delete-chat"; // DELETE /:chatId
  static const String directMessageDelete =
      "/chat/direct-chat/delete-message"; // DELETE /:messageId
  static const String directMessageEdit =
      "/chat/direct-chat/edit-message"; // PUT /:messageId
  static const String allChats = "/chat/list/all"; // GET ?page=1&limit=10

  // Group Chat endpoints
  static const String groupCreate = "/group/create"; // POST
  static const String groupSendMessage = "/group/message/send"; // POST
  static const String groupMessages =
      "/group/messages"; // GET /:groupId?page=1&limit=20
  static const String groupList = "/group/list"; // GET ?page=1&limit=10
  static const String groupAddMember = "/group/member/add"; // POST
  static const String groupRemoveMember = "/group/member/remove"; // DELETE
  static const String groupJoin = "/group/group/join"; // POST
  static const String groupLeave = "/group/group/leave"; // POST
  static const String groupAssignAdmin = "/group/admin/assign"; // PATCH
  static const String groupDeleteMessage = "/group/message/delete"; // DELETE
  static const String groupDeleteGroup = "/group/delete"; // DELETE
  static const String groupMembers =
      "/group/group/members"; // GET ?group_chat_id=1
  static const String groupMemberCount =
      "/group/group/member-count"; // GET ?group_chat_id=1
  static const String groupEditMessage =
      "/group/group-chat/edit-message"; // PUT /:messageId
  static const String groupGenerateInvite = "/group/invite/generate"; // POST
  static const String groupJoinInvite = "/group/invite/join"; // GET ?token=...

  // User endpoints
  static const String getFollowers = "/get_followers"; // GET
  static const String getFollowing = "/get_following"; // GET ?query=searchterm
}
