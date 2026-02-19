/* eslint-disable @typescript-eslint/no-unused-vars */
"use client";

import { useState } from "react";
import {  Link2, MapPin, Check, Users } from "lucide-react";
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { useShareApi } from "@/app/hooks/use-share-api";

type User = {
  id: string;
  name: string;
  avatar: string;
};

type ShareModalProps = {
  isOpen: boolean;
  onClose: () => void;
  contentId: number;
  profileName?: string;
  profileLocation?: string;
  profileImage?: string;
  users?: User[];
};

export function ShareModal({
  isOpen,
  onClose,
  contentId,
  profileName = "Komo News",
  profileLocation = "Seattle",
  profileImage = "/placeholder.svg?height=40&width=40",
  users = [],
}: ShareModalProps) {
  const [message, setMessage] = useState("");
  const [copied, setCopied] = useState(false);
  const { createShare, loading: isLoading, error: shareError } = useShareApi();

  const handleCopyLink = async () => {
    const link = await createShare(contentId, "link");
    if (link) {
      await navigator.clipboard.writeText(link);
      setCopied(true);
      setTimeout(() => {
        setCopied(false);
        onClose(); // Close modal after copying
      }, 1100); // Reduced timeout to close faster
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-2xl p-0 gap-0 bg-white rounded-3xl border-none overflow-hidden">
        <DialogTitle className="sr-only">Share post</DialogTitle>
        {/* Header */}
        <div className="relative py-4">
          <p className="text-center font-semibold text-xl text-black">Share</p>
        </div>

        {/* Profile and message area */}
        <div className="bg-[#F1F4F9] p-4 ml-6 mr-6 rounded-b-[32px]">
          <div className="flex items-center gap-2 mb-4">
            <Avatar className="h-10 w-10 border">
              <AvatarImage src={profileImage} alt={profileName} />
              <AvatarFallback>{profileName.substring(0, 2)}</AvatarFallback>
            </Avatar>
            <div>
              <div className="font-semibold text-lg text-black">
                {profileName}
              </div>
              <div className="flex items-center text-sm text-[#838B98]">
                <MapPin className="h-3 w-3 mr-1 text-[#838B98]" />
                {profileLocation}
              </div>
            </div>
          </div>
          <Textarea
            placeholder="Say something about this..."
            className="min-h-[80px] bg-[#F1F4F9] text-[#5D6778] border-[#F1F4F9] resize-none focus-visible:ring-transparent focus-visible:ring-offset-transparent p-3 text-base"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            readOnly
          />
        </div>

        {/* Private message section */}
        <div className="px-6 py-4">
          <h3 className="font-semibold text-lg text-[#0C1024] mb-4">
            Send in Private Message
          </h3>
          <div className="flex gap-4 overflow-x-auto pb-2">
            {users.map((user) => (
              <div
                key={user.id}
                className="flex flex-col items-center space-y-1 min-w-[64px]"
              >
                <Avatar className="h-14 w-14 border">
                  <AvatarImage src={user.avatar} alt={user.name} />
                  <AvatarFallback>{user.name.substring(0, 2)}</AvatarFallback>
                </Avatar>
                <span className="text-xs text-[#0C1024] text-center line-clamp-2 max-w-[64px]">
                  {user.name}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Share to section */}
        <div className="px-6 py-4">
          <h3 className="font-medium mb-4">Share to</h3>
          <div className="flex gap-8 justify-start">
            {/* My Story - Commented out until feature is implemented */}
            {/* <div className="flex flex-col items-center space-y-2">
              <Button
                variant="outline"
                size="icon"
                className="h-14 w-14 rounded-full border-2"
              >
                <Plus className="h-6 w-6" />
              </Button>
              <span className="text-xs">My Story</span>
            </div> */}
            
            <div className="flex flex-col items-center space-y-2">
              <Button
                variant="outline"
                size="icon"
                onClick={handleCopyLink}
                disabled={isLoading}
                className={`h-14 w-14 rounded-full border-2 ${
                  copied ? "border-green-500" : ""
                }`}
              >
                {copied ? (
                  <Check className="h-6 w-6 text-green-600" />
                ) : (
                  <Link2 className="h-6 w-6" />
                )}
              </Button>
              <span className="text-xs">
                {copied ? "Copied!" : "Copy Link"}
              </span>
            </div>
            
            {/* Group - Commented out until feature is implemented */}
            <div className="flex flex-col items-center space-y-2">
              <Button
                variant="outline"
                size="icon"
                className="h-14 w-14 rounded-full border-2"
              >
                <Users className="h-6 w-6" />
              </Button>
              <span className="text-xs">Group</span>
            </div>
            
            {/* My Pulse - Commented out until feature is implemented */}
            {/* <div className="flex flex-col items-center space-y-2">
              <Button
                variant="outline"
                size="icon"
                className="h-14 w-14 rounded-full border-2"
              >
                <Activity className="h-6 w-6" />
              </Button>
              <span className="text-xs">My Pulse</span>
            </div> */}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
