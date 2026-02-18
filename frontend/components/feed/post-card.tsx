/* eslint-disable @typescript-eslint/no-explicit-any */
"use client";
import { useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import {  MoreHorizontal, MessageCircle, Heart, MapPin } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

import { Button } from "@/components/ui/button";
import { AvatarWithFallback } from "@/components/ui/avatar-with-fallback";
import { useShareApi } from "@/app/hooks/use-share-api";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ExtendedPost } from "@/app/types/content";
import { REACTIONS } from "@/lib/constants";
import { useTimeAgo } from "@/app/hooks/use-time-ago";

// const ReactPlayer = dynamic(() => import("react-player"), {
//   ssr: false,
//   loading: () => null,
// });

interface PostCardProps {
  post: ExtendedPost;
  onReactionSelect: (postId: number, reactionType: string) => void;
  onRepostSelect: (postId: number) => void;
  onOpenComments: (contentType: string, contentId: number) => void;
  onImageClick: (imageUrl: string) => void;
  onShare: (postId: number) => void;
  hoveredPostId: number | null;
  setHoveredPostId: (id: number | null) => void;
  isAuthenticated?: boolean;

  // NEW
  onDeletePost: (postId: number) => void;
  onHidePost: (postId: number) => void;
  onReportPost: (postId: number) => void;
  isFirst?: boolean;
  onLinkCopied?: () => void;
}

export function PostCard({
  post,
  onReactionSelect,
  onRepostSelect,
  onOpenComments,
  onImageClick,
  onShare,
  hoveredPostId,
  setHoveredPostId,
  isAuthenticated = true,

  onDeletePost,
  onHidePost,
  onReportPost,
  isFirst = false,
  onLinkCopied,
}: PostCardProps) {
  const router = useRouter();
  const { timeAgo } = useTimeAgo();
  const userReaction = post.userReaction;
  const totalReactions = post.totalReactions ?? 0;
  const { createShare } = useShareApi();
  const [isShareAnimating, setIsShareAnimating] = useState(false);

  // Handle user profile click
  const handleUserProfileClick = () => {
    if (isAuthenticated) {
      // Normal behavior - navigate to user profile
      router.push(`/profile/${post.user.username}`);
    } else {
      // Guest behavior - trigger waitlist modal
      onShare(post.id); // Using onShare to trigger the waitlist modal for guests
    }
  };

  // Check ownership for "Delete Post"
  const sessionUserId =
    typeof window !== "undefined" ? sessionStorage.getItem("user_id") : null;
  const isOwner = sessionUserId && sessionUserId === String(post.user.id);

  const isVideoUrl = (url: string) => /\.(mp4|webm|ogg|mov)(\?.*)?$/.test(url);

  // Helper function to safely display time
  const getDisplayTime = () => {
    // Check if time_since_post contains negative values or invalid format
    if (post.time_since_post && !post.time_since_post.includes('-') && !post.time_since_post.includes('Invalid')) {
      return post.time_since_post;
    }
    // Fallback to calculated time from created_at
    return timeAgo(post.created_at);
  };

  // Handle share - copy link directly
  const handleShare = async () => {
    if (!isAuthenticated) {
      onShare(post.id);
      return;
    }

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
    <div data-cy="post-card" className={`rounded-[24px] border text-card-foreground shadow-sm ${
      (post as any).isNewlyPosted 
        ? 'border-green-100  text-card-foreground shadow-sm ' 
        : 'border-[#E2E8F0] bg-card'
    }`}>
     
      
      {/* Post Header */}
      <div className="flex items-center justify-between p-4">
        <div className="flex items-center gap-3">
          <div
            className="flex items-center gap-3 cursor-pointer"
            onClick={handleUserProfileClick}
          >
            <AvatarWithFallback
              data-cy="user-avatar"
              src={post.user.profile_picture_url || undefined}
              alt={post.user.username}
              fallbackText={post.user.username?.[0] || "?"}
              size="lg"
            />
           <div>
              <h3 className="font-semibold text-black">{post.user.username}</h3>
              {/* Mobile: location + time */}
              <div className="flex sm:hidden items-center text-sm text-muted-foreground space-x-2 mt-1">
                <div className="flex items-center max-w-[100px] truncate">
                  <MapPin className="mr-1 h-4 w-4 shrink-0" />
                  <span className="truncate text-xs">{post.location}</span>
                </div>
                <span>•</span>
                <span className="text-xs">{getDisplayTime()}</span>
              </div>
              {/* Desktop: time only */}
              <p className="hidden sm:block text-sm text-muted-foreground mt-1">
                {getDisplayTime()}
              </p>
            </div>

          </div>
        </div>

        {/* Right - Location & Menu */}
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
              {/* Copy link */}
              <DropdownMenuItem
                onClick={() =>
                  navigator.clipboard.writeText(window.location.href)
                }
              >
                <div className="flex items-center gap-x-4 text-base font-medium">
                  <Image src="/link.png" alt="Copy link" width={16} height={16} />
                  <span>Copy link</span>
                </div>
              </DropdownMenuItem>

              <div className="my-1 h-px bg-[#ECF0F5]" />

              <DropdownMenuItem onClick={() => onHidePost(post.id)}>
                <div className="flex items-center gap-x-4 text-base font-medium">
                  <Image
                    src="/circle-close.png"
                    alt="Hide Post"
                    width={16}
                    height={16}
                  />
                  <span>Hide Post</span>
                </div>
              </DropdownMenuItem>

              <div className="my-1 h-px bg-[#ECF0F5]" />

              {/* Report Post */}
              <DropdownMenuItem onClick={() => onReportPost(post.id)}>
                <div className="flex items-center gap-x-4 text-base font-medium">
                  <Image src="/flag.png" alt="Report Post" width={16} height={16} />
                  <span>Report Post</span>
                </div>
              </DropdownMenuItem>

              <div className="my-1 h-px bg-[#ECF0F5]" />

              {/* Delete Post - only if the post belongs to current user */}
              {isOwner && (
                <>
                  <DropdownMenuItem onClick={() => onDeletePost(post.id)}>
                    <div className="flex items-center gap-x-4 text-base font-medium">
                      <Image
                        src="https://img.icons8.com/color/96/cancel--v1.png"
                        alt="Delete Post"
                        width={16}
                        height={16}
                      />
                      <span>Delete Post</span>
                    </div>
                  </DropdownMenuItem>
                </>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>

      {/* Post Image */}
      {/* Post Media Preview */}
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
          onClick={() => onImageClick(post.thumbnail)}
        >
          <Image
            src={
              post.thumbnail ||
              "https://cdn.pixabay.com/photo/2018/01/14/23/12/nature-3082832_1280.jpg"
            }
            alt={post.title}
            fill
            className="object-cover"
            priority={isFirst}
            loading={isFirst ? "eager" : undefined}
            fetchPriority={isFirst ? "high" : undefined}
            sizes="(max-width: 768px) 100vw, 640px"
          />
        </div>
      )}

      {/* Title / Body */}
      <div className="px-4 py-2">
        {/* <h4 className="font-semibold mb-2">{post.title}</h4> */}
        <p>{post.body}</p>
      </div>

      {/* Reactions Row */}
      <div className="px-4 pb-1">
        <div className="flex items-center">
          {post.top_reactions && post.top_reactions.length > 0 && (
            <div className="flex -space-x-2">
              {post.top_reactions.slice(0, 3).map((r, idx) => {
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
          )}
          {totalReactions > 0 && (
            <span className="ml-3 text-sm text-gray-600">
              {totalReactions} {totalReactions === 1 ? "Reaction" : "Reactions"}
            </span>
          )}
        </div>
      </div>

      {/* Buttons Row */}
      <div className="flex items-center gap-0 p-4">
        {/* Reaction button with popover */}
        <div
          className="relative"
          onMouseEnter={() => setHoveredPostId(post.id)}
          onMouseLeave={() => setHoveredPostId(null)}
        >
          <Button
            variant="ghost"
            size="sm"
            data-cy="react-button"
            className={`gap-2 transition-colors ${
              userReaction
                ? REACTIONS.find((r) => r.name === userReaction)?.color
                : ""
            }`}
          >
            <div className="flex items-center gap-2">
              {userReaction ? (
                <span className="text-2xl">
                  {REACTIONS.find((r) => r.name === userReaction)?.emoji}
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
                {REACTIONS.map((reaction) => (
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
          data-cy="comment-button"
          size="sm"
          className="gap-2"
          onClick={() => onOpenComments("user_content", post.id)}
        >
          <MessageCircle className="h-4 w-4" />
          {post.comments_count}
        </Button>

        {/* Repost */}
        <Button
          onClick={() => onRepostSelect(post.id)}
          variant="ghost"
          data-cy="repost-button"
          size="sm"
        >
          {post.has_user_reposted ? (
            <Image
              src="/Repost.svg"
              alt="Share"
              width={25}
              height={25}
              style={{
                filter:
                  "invert(32%) sepia(100%) saturate(1000%) hue-rotate(180deg)",
              }}
            />
          ) : (
            <Image src="/Repost.svg" alt="Share" width={25} height={25} />
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
            onClick={handleShare}
            variant="ghost"
            size="sm"
            data-cy="share-button"
            disabled={isShareAnimating}
          >
            <Image
              src="https://img.icons8.com/ios/50/forward-arrow.png"
              alt="Share"
              width={25}
              height={25}
            />
          </Button>
        </motion.div>
      </div>
    </div>
  );
}
