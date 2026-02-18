"use client";
import { ProfileData } from "@/app/types/profile";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { MapPin } from "lucide-react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { startDirectChat } from "@/app/services/chat-service";
import { useState } from "react";
import { Toast } from "@/components/ui/toast";

export default function ProfileHeader({
  userData,
  onFollowToggle,
  isMyProfile,
}: ProfileData) {
  const router = useRouter();
  const [isStartingChat, setIsStartingChat] = useState(false);
  const [isSharing, setIsSharing] = useState(false);
  const [showToast, setShowToast] = useState(false);
  
  const {
    is_following,
    user_data: {
      id: userId,
      username,
      first_name,
      last_name,
      bio,
      profile_picture_url,
      location,
      show_home_location,
      email,
    },
    relationships: { followers, following, total_posts },
  } = userData.data;

  const handleMessageClick = async () => {
    if (isMyProfile) return; // Don't allow messaging yourself
    
    try {
      setIsStartingChat(true);
      const chatId = await startDirectChat(userId);
      
      if (!chatId) {
        alert("Could not create chat - no chat ID returned");
        return;
      }
      
      // Store user info in sessionStorage for optimistic update
      const userInfo = {
        id: userId,
        username,
        first_name,
        last_name,
        profile_picture_url,
        email: email || "",
      };
      sessionStorage.setItem(`pending_chat_${chatId}`, JSON.stringify(userInfo));
      
      // Navigate to messages page with the specific chat
      router.push(`/message?chat=${chatId}`);
    } catch (error) {
      console.error("Error starting chat:", error);
      // You could show a toast notification here
      alert("Failed to start chat. Please try again.");
    } finally {
      setIsStartingChat(false);
    }
  };

  const handleShareClick = async () => {
    try {
      setIsSharing(true);
      
      const profileUrl = `${window.location.origin}/profile/${username}`;
      
      // Copy to clipboard
      await navigator.clipboard.writeText(profileUrl);
      
      // Show toast notification
      setShowToast(true);
      
    } catch (error) {
      console.error("Error sharing profile:", error);
    } finally {
      setIsSharing(false);
    }
  };

  return (
    <>
      <Toast 
        message="Profile link copied to clipboard!" 
        isVisible={showToast} 
        onClose={() => setShowToast(false)} 
      />
      <div className="space-y-4 mb-8">
      {/* ------------------- DESKTOP LAYOUT ------------------- */}
      <div className="hidden md:grid grid-cols-[auto,1fr] mr-5 gap-8 items-center w-full max-w-4xl mx-auto">
        {/* Avatar (large, left) */}
        <Avatar className="w-[198px] h-[198px] border overflow-hidden">
          <AvatarImage
            src={profile_picture_url || "/default-avatar.png"}
            alt="Profile picture"
            className="w-full h-full object-cover"
          />
          <AvatarFallback>{first_name?.charAt(0) || "?"}</AvatarFallback>
        </Avatar>

        {/* Profile Info (right) */}
        <div className="space-y-3">
          {/* Name & Username */}
          <div className="flex gap-2">
            <h1 className="text-xl font-extrabold text-[#27364b] m-0 p-0">
              {first_name} {last_name}
            </h1>
            <p className="text-sm text-[#677080] m-0 py-1">/ @{username}</p>
          </div>

          {/* Location */}
          {show_home_location && (
            <div className="flex gap-1">
              <MapPin className="w-5 h-5 text-[#677080]" />
              <p>{location ?? "No location"}</p>
            </div>
          )}

          {/* Follow / Message / Share buttons */}
          <div className="flex gap-2">
            {isMyProfile ? (
              <Button
                onClick={() => {
                  window.location.href = "/setting";
                }}
                className="px-8 py-5 rounded-xl border-black border-2 text-lg bg-transparent text-black hover:bg-transparent"
              >
                Edit Profile
              </Button>
            ) : (
              <>
                <Button
                  onClick={onFollowToggle}
                  className={`px-5 py-5 rounded-3xl border-2 border-[#4C68D5] text-lg ${
                    is_following
                      ? "border-black bg-white text-slate-950 hover:bg-transparent"
                      : "bg-[#4C68D5] text-white hover:bg-[#4C68D5]"
                  }`}
                >
                  {is_following ? "Unfollow" : "Follow"}
                </Button>

                <Button
                  variant="outline"
                  onClick={handleMessageClick}
                  disabled={isStartingChat}
                  className="border-slate-950 px-5 py-5 rounded-3xl border-2 text-lg"
                >
                  {isStartingChat ? "Starting..." : "Message"}
                </Button>
              </>
            )}

            <button
              onClick={handleShareClick}
              disabled={isSharing}
              className="border-black rounded-lg border-2 py-2 px-4 hover:bg-gray-50 disabled:opacity-50"
            >
              <Image
                src="/Forward.png"
                alt="Share"
                width={20}
                height={20}
                priority
              />
            </button>
          </div>

          {/* Stats */}
          <div className="flex gap-4">
            <div className="flex text-center gap-1">
              <div className="font-extrabold text-[#27364b]">{total_posts}</div>
              <span className="text-sm font-semibold text-[#677080] py-0.5 px-1">
                Posts
              </span>
            </div>
            <div className="flex text-center gap-1">
              <div className="font-extrabold text-[#27364b]">{followers}</div>
              <div className="text-sm font-semibold text-[#677080] py-0.5 px-1">
                Followers
              </div>
            </div>
            <div className="flex text-center gap-1">
              <div className="font-extrabold text-[#27364b]">{following}</div>
              <div className="text-sm font-semibold text-[#677080] py-0.5 px-1">
                Following
              </div>
            </div>
          </div>

          {/* Bio */}
          <p className="text-sm text-muted-foreground">
            {bio || "This user has no bio."}
          </p>
        </div>
      </div>

      {/* ------------------- MOBILE LAYOUT ------------------- */}
      <div className="md:hidden flex flex-col gap-2 ml-6">
        <div className="flex items-start gap-1">
          {/* Smaller avatar (left) */}
          <Avatar className="w-16 h-16 border overflow-hidden">
            <AvatarImage
              src={profile_picture_url || "/default-avatar.png"}
              alt="Profile picture"
              className="w-full h-full object-cover"
            />
            <AvatarFallback>{first_name?.charAt(0) || "?"}</AvatarFallback>
          </Avatar>

          {/* Name / Username / Location / Stats (right) */}
          <div>
            {/* Name & Username */}
            <div className="flex items-baseline gap-2">
              <h1 className="text-base font-extrabold text-[#27364b]">
                {first_name} {last_name}
              </h1>
              <span className="text-sm text-[#677080]">/ @{username}</span>
            </div>
            {/* Location */}
            {show_home_location && (
              <div className="flex ml-4 items-center gap-2">
                <MapPin className="w-4 h-4 text-[#677080]" />
                <span className="text-sm text-[#677080]">
                  {location ?? "No location"}
                </span>
              </div>
            )}
            {/* Stats */}
            <div className="flex gap-6 mt-2 ml-2">
              <div className="text-center">
                <div className="text-base font-extrabold text-[#27364b]">
                  {total_posts}
                </div>
                <div className="text-xs font-semibold text-[#677080]">
                  Posts
                </div>
              </div>
              <div className="text-center">
                <div className="text-base font-extrabold text-[#27364b]">
                  {followers}
                </div>
                <div className="text-xs font-semibold text-[#677080]">
                  Followers
                </div>
              </div>
              <div className="text-center">
                <div className="text-base font-extrabold text-[#27364b]">
                  {following}
                </div>
                <div className="text-xs font-semibold text-[#677080]">
                  Following
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Bio */}
        <p className="text-sm text-[#677080]">
          {bio || "This user has no bio."}
        </p>

        {/* Buttons (Follow, Message, Share) */}
        <div className="flex items-center gap-2">
          {isMyProfile ? (
            <Button
              onClick={() => {
                window.location.href = "/setting";
              }}
              className="border-2 w-full border-black text-black bg-transparent hover:bg-transparent rounded-3xl px-4 py-3 text-sm"
            >
              Edit Profile
            </Button>
          ) : (
            <>
              <Button
                onClick={onFollowToggle}
                className={`rounded-3xl w-full px-5 py-3 text-sm ${
                  is_following
                    ? "border-2 border-black bg-white text-slate-950 hover:bg-transparent"
                    : "bg-[#4C68D5] text-white hover:bg-[#4C68D5]"
                }`}
              >
                {is_following ? "Unfollow" : "Follow"}
              </Button>

              <Button
                variant="outline"
                onClick={handleMessageClick}
                disabled={isStartingChat}
                className="border-2 w-full border-black text-black rounded-3xl px-5 py-3 text-sm"
              >
                {isStartingChat ? "Starting..." : "Message"}
              </Button>
            </>
          )}

          <button
            onClick={handleShareClick}
            disabled={isSharing}
            className="border-black rounded-lg border-2 py-2 px-3 hover:bg-gray-50 disabled:opacity-50"
          >
            <Image
              src="/Forward.png"
              alt="Share"
              width={18}
              height={18}
              priority
            />
          </button>
        </div>
      </div>
      </div>
    </>
  );
}
