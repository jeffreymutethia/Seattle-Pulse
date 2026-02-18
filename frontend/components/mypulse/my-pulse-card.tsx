"use client";

import { useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import { MapPin, MoreHorizontal, MessageCircle, Heart } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import type { ExtendedPost, Reaction } from "@/app/types/content";
import { useTimeAgo } from "@/app/hooks/use-time-ago";
import { REACTIONS } from "@/lib/constants";
import { useShareApi } from "@/app/hooks/use-share-api";

interface MyPulseCardProps {
  post: ExtendedPost;
  reactions: Reaction[];
  hoveredPostId: number | null;
  onHover: (postId: number | null) => void;
  onReactionSelect: (postId: number, reactionType: string) => void;
  onRepostSelect: (postId: number) => void;
  onOpenComments: (contentType: string, contentId: number) => void;
  onImageSelect: (imageUrl: string) => void;
  onShare: (postId: number) => void;
  onLinkCopied?: () => void;
}

export default function MyPulseCard({
  post,
  reactions,
  hoveredPostId,
  onHover,
  onReactionSelect,
  onRepostSelect,
  onOpenComments,
  onImageSelect,
  onLinkCopied,
}: MyPulseCardProps) {
  const router = useRouter();
  const { timeAgo } = useTimeAgo();
  const { createShare } = useShareApi();
  const [isShareAnimating, setIsShareAnimating] = useState(false);

  const userReaction = post.userReaction;
  const totalReactions = post.totalReactions ?? 0;

  // Function to detect video URLs
  const isVideoUrl = (url: string) => /\.(mp4|webm|ogg|mov)(\?.*)?$/.test(url);

  // Handle share - copy link directly
  const handleShare = async () => {
    setIsShareAnimating(true);
    try {
      const link = await createShare(post.id, "link");
      if (link) {
        await navigator.clipboard.writeText(link);
        onLinkCopied?.();
      }
    } catch (error) {
      console.error("Error copying link:", error);
    } finally {
      setTimeout(() => {
        setIsShareAnimating(false);
      }, 600);
    }
  };

  return (
    <div className="rounded-[24px] border border-[#E2E8F0] bg-card text-card-foreground shadow-sm">
      {/* Header */}
      <div className="flex items-center justify-between p-4">
        <div className="flex items-center gap-3">
          <div
            className="flex items-center gap-3 cursor-pointer"
            onClick={() => router.push(`/profile/${post.user.username}`)}
          >
            <Image
              src={
                post.user.profile_picture_url ||
                "https://t3.ftcdn.net/jpg/02/43/12/34/360_F_243123463_zTooub557xEWABDLk0jJklDyLSGl2jrr.jpg"
              }
              alt={post.user.username}
              width={40}
              height={40}
              className="rounded-full object-cover w-12 h-12"
            />
            <div>
              <div className="flex items-center space-x-2">
                <h3 className="font-semibold text-black text-lg">
                  {post.user.username}
                </h3>
                <p className="text-[#838B98] font-normal text-sm">Following</p>
              </div>
              {/* Mobile: location + time */}
              <div className="flex sm:hidden items-center text-sm text-muted-foreground space-x-2 mt-1">
                <div className="flex items-center max-w-[100px] truncate">
                  <MapPin className="mr-1 h-4 w-4 shrink-0" />
                  <span className="truncate text-xs">{post.location}</span>
                </div>
                <span>•</span>
                <span className="text-xs">{timeAgo(post.created_at)}</span>
              </div>
              {/* Desktop: time only */}
              <p className="hidden sm:block text-sm text-muted-foreground mt-1">
                {timeAgo(post.created_at)}
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {/* Desktop only: location */}
          <div className="hidden sm:flex items-center text-sm text-muted-foreground max-w-[200px]">
            <MapPin className="mr-1 h-4 w-4 shrink-0" />
            <span className="truncate">{post.location}</span>
          </div>

          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="px-2 py-1">
              <DropdownMenuItem
                onClick={() => onRepostSelect(post.id)}
                className="py-2 px-2 rounded hover:bg-muted"
              >
                {post.has_user_reposted ? "Undo Repost" : "Repost"}
              </DropdownMenuItem>
              <div className="my-1 h-px bg-[#ECF0F5]" />
              <DropdownMenuItem className="py-2 px-2 rounded hover:bg-muted">
                Report
              </DropdownMenuItem>
              <div className="my-1 h-px bg-[#ECF0F5]" />
              <DropdownMenuItem className="py-2 px-2 rounded hover:bg-muted">
                Hide
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>

      {/* Media Preview */}
      {isVideoUrl(post.thumbnail) ? (
        <div className="relative aspect-video w-full group">
          <video
            src={post.thumbnail}
            className="w-full h-full object-cover"
            muted={false}
            preload="metadata"
            controls={true}
            onLoadedData={(e) => {
              // Set the current frame as poster
              const video = e.target as HTMLVideoElement;
              video.currentTime = 1; // Go to 1 second to get a good frame
            }}
          />
        </div>
      ) : (
        <div
          className="relative aspect-video w-full cursor-pointer"
          onClick={() => onImageSelect(post.thumbnail)}
        >
          <Image
            src={post.thumbnail || "/placeholder.svg"}
            alt={post.title}
            fill
            className="object-cover"
          />
        </div>
      )}

      {/* Body */}
      <div className="px-4 py-2">
        <h4 className="font-semibold mb-2">{post.title}</h4>
        <p>{post.body}</p>
      </div>

      {/* Top Reactions */}
      <div className="px-4 pb-1">
        <div className="flex items-center">
          {post.top_reactions?.length ? (
            <div className="flex -space-x-2">
              {post.top_reactions!.slice(0, 3).map((r, idx) => {
                const found = REACTIONS.find((rr) => rr.name === r);
                return (
                  <div
                    key={`${post.id}-${r}-${idx}`}
                    className={`h-6 w-6 flex items-center justify-center rounded-full border-2 border-white bg-white shadow-sm ${
                      found?.color ?? ""
                    }`}
                  >
                    <span className="text-lg">{found?.emoji ?? "👍"}</span>
                  </div>
                );
              })}
            </div>
          ) : null}
          {totalReactions > 0 && (
            <span className="ml-3 text-sm text-gray-600">
              {totalReactions} {totalReactions === 1 ? "Reaction" : "Reactions"}
            </span>
          )}
        </div>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-2 p-4">
        {/* Reaction Button */}
        <div
          className="relative"
          onMouseEnter={() => onHover(post.id)}
          onMouseLeave={() => onHover(null)}
        >
          <Button
            variant="ghost"
            size="sm"
            className={`gap-2 transition-colors ${
              userReaction
                ? reactions.find((r) => r.name === userReaction)?.color
                : ""
            }`}
          >
            <div className="flex items-center gap-2">
              {userReaction ? (
                <span className="text-2xl">
                  {reactions.find((r) => r.name === userReaction)?.emoji}
                </span>
              ) : (
                <Heart className="h-6 w-6" />
              )}
              {totalReactions > 0 && <span>{totalReactions}</span>}
            </div>
          </Button>

          <AnimatePresence>
            {hoveredPostId === post.id && (
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 10 }}
                transition={{ duration: 0.1 }}
                className="absolute bottom-full left-0 mb-2 flex items-center gap-1 rounded-full bg-white p-1.5 shadow-lg"
              >
                {reactions.map((reaction) => (
                  <button
                    key={reaction.name}
                    onClick={() => onReactionSelect(post.id, reaction.name)}
                    className={`rounded-full p-2 transition-all hover:scale-110 active:scale-95 ${
                      userReaction === reaction.name
                        ? `${reaction.color} bg-gray-50`
                        : "hover:bg-gray-100"
                    }`}
                    title={reaction.label}
                  >
                    <span className="text-2xl">{reaction.emoji}</span>
                  </button>
                ))}
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Comments */}
        <Button
          variant="ghost"
          size="sm"
          className="flex items-center gap-1"
          onClick={() => onOpenComments("user_content", post.id)}
        >
          <MessageCircle className="h-4 w-4" />
          <span>{post.comments_count}</span>
        </Button>

        {/* Repost */}
        <Button
          variant="ghost"
          size="sm"
          onClick={() => onRepostSelect(post.id)}
        >
          {post.has_user_reposted ? (
            <Image
              src="/Repost.svg"
              alt="Undo Repost"
              width={20}
              height={20}
              style={{
                filter:
                  "invert(32%) sepia(100%) saturate(1000%) hue-rotate(180deg)",
              }}
            />
          ) : (
            <Image src="/Repost.svg" alt="Repost" width={20} height={20} />
          )}
        </Button>

        {/* Share */}
        <motion.div
          animate={{
            scale: isShareAnimating ? [1, 1.2, 1] : 1,
            rotate: isShareAnimating ? [0, 15, -15, 0] : 0,
          }}
          transition={{
            duration: 0.5,
            ease: "easeInOut",
          }}
          className="ml-auto"
        >
          <Button
            variant="ghost"
            size="sm"
            onClick={handleShare}
            disabled={isShareAnimating}
          >
            <Image
              src="https://img.icons8.com/ios/50/forward-arrow.png"
              alt="Share"
              width={20}
              height={20}
            />
          </Button>
        </motion.div>
      </div>
    </div>
  );
}
