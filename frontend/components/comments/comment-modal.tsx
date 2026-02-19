/* eslint-disable @typescript-eslint/no-unused-vars */
"use client"

import { useEffect, useState } from "react"
import Image from "next/image"
import { motion, AnimatePresence } from "framer-motion"
import { useRouter } from "next/navigation"
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Heart, MessageCircle, Share2, MoreHorizontal, MapPin, X } from "lucide-react"
import { type CommentModalProps, type ExtendedComment, transformComment } from "@/app/types/comment"
import { REACTIONS } from "@/lib/constants"
import { commentService } from "@/app/services/comment-service"
import CommentItem from "./comment-item"
import { useAuthRequired } from "@/app/hooks/use-auth-required"
import { AuthPopup } from "../auth/auth-popup"
import { CommentForm } from "./comment-form"
import ReactPlayer from "react-player"
import { useShareApi } from "@/app/hooks/use-share-api"
import { Toast } from "@/components/ui/toast"
import { toast } from "react-hot-toast"
import { trackEvent } from "@/lib/mixpanel"

interface ExtendedCommentModalProps extends CommentModalProps {
  onPostReactionSelect?: (postId: number, reactionType: string) => void
}

function useMediaQuery(query: string) {
  const [matches, setMatches] = useState(false)

  useEffect(() => {
    const media = window.matchMedia(query)
    if (media.matches !== matches) {
      setMatches(media.matches)
    }
    const listener = () => setMatches(media.matches)
    window.addEventListener('resize', listener)
    return () => window.removeEventListener('resize', listener)
  }, [matches, query])

  return matches
}

export default function CommentModal({
  isOpen,
  onClose,
  contentDetails,
  isLoading,
  error,
  isAuthenticated,
  requireAuth,
  onPostReactionSelect,
}: ExtendedCommentModalProps) {
  const [postReaction, setPostReaction] = useState<string | null>(null)
  const [postTotalReactions, setPostTotalReactions] = useState<number>(0)
  const [postTopReactions, setPostTopReactions] = useState<string[]>([])
  const [showPostReactions, setShowPostReactions] = useState(false)
  const [comments, setComments] = useState<ExtendedComment[]>([])
  const { showAuthModal, setShowAuthModal } = useAuthRequired()
  const [replyingTo, setReplyingTo] = useState<{
    username: string
    commentId: number
  } | null>(null)
  const [commentText, setCommentText] = useState("")
  const [parentId, setParentId] = useState<number | null>(null)
  const [postId, setPostId] = useState<number>(0)
  const [submitting, setSubmitting] = useState(false)
  const isDesktop = useMediaQuery('(min-width: 768px)')
  const { createShare, loading: shareLoading } = useShareApi()
  const [showToast, setShowToast] = useState(false)

  const isVideoUrl = (url: string) => /\.(mp4|webm|ogg|mov)(\?.*)?$/.test(url) || ReactPlayer.canPlay(url)

  const router = useRouter()

  useEffect(() => {
    if (!contentDetails) return

    setPostReaction(contentDetails.user_reaction || null)
    setPostTotalReactions(contentDetails.total_reactions)
    setPostTopReactions(contentDetails.top_reactions ?? [])
    setComments(contentDetails.comments.map(transformComment))
  }, [contentDetails])

  async function handleAddComment(text: string) {
    if (!text.trim() || !contentDetails) return

    try {
      // Create and submit the API request
      const requestBody = {
        content_id: contentDetails.id,
        content_type: "user_content",
        content: text.trim(),
        parent_id: replyingTo ? replyingTo.commentId : null,
      }

      const response = await commentService.postComment(requestBody)

      // Track comment event
      trackEvent("comment_posted", {
        content_id: contentDetails.id,
        is_reply: !!replyingTo,
        parent_comment_id: replyingTo?.commentId || null,
      })

      // Handle reply case
      if (replyingTo) {
        // Update the parent comment's reply count
        setComments((prevComments) =>
          prevComments.map((c) =>
            c.id === replyingTo.commentId
              ? {
                  ...c,
                  replies_count: (c.replies_count || 0) + 1,
                }
              : c,
          ),
        )

        // Reset reply state
        setReplyingTo(null)
      } else {
        // Add top-level comment to the beginning of the list
        setComments((prev) => [response, ...prev])
      }

      // Clear input
      setCommentText("")
    } catch (err) {
      console.error("Error adding comment:", err)
      toast("Failed to add comment. Please try again.")
    }
  }

  function handleUpdateComment(updated: ExtendedComment) {
    // Handle reply targets
    if (updated.isReplyTarget) {
      setReplyingTo({
        username: updated.replyingTo!,
        commentId: updated.id,
      })
      return
    }

    // Update comments state if this is one of our top-level comments
    setComments((prevComments) => prevComments.map((comment) => (comment.id === updated.id ? updated : comment)))
  }

  async function handlePostReactionSelect(reaction: string) {
    if (!contentDetails) return

    const unreacting = postReaction === reaction
    const oldReaction = postReaction
    const newReaction = unreacting ? null : reaction

    let newTotal = postTotalReactions
    if (unreacting) {
      newTotal = Math.max(0, newTotal - 1)
    } else if (!oldReaction) {
      newTotal += 1
    }

    let newTop = [...postTopReactions]
    if (unreacting) {
      newTop = newTop.filter((r) => r !== reaction)
    } else {
      if (oldReaction) {
        newTop = newTop.filter((r) => r !== oldReaction)
      }

      if (!newTop.includes(reaction)) {
        newTop.unshift(reaction)
      }
    }
    newTop = newTop.slice(0, 3)

    setPostReaction(newReaction)
    setPostTotalReactions(newTotal)
    setPostTopReactions(newTop)
    setShowPostReactions(false)

    if (onPostReactionSelect) {
      if (requireAuth) {
        requireAuth(() => onPostReactionSelect?.(contentDetails.id, reaction))
      }
    }
  }

  const handleShareClick = async () => {
    if (!contentDetails) return
    
    try {
      const shareLink = await createShare(contentDetails.id, "link");
      if (shareLink) {
        await navigator.clipboard.writeText(shareLink);
        setShowToast(true);
        setTimeout(() => {
          setShowToast(false);
        }, 2000);
      }
    } catch (error) {
      console.error("Error sharing post:", error);
    }
  };

  if (!isOpen) return null

  if (isLoading || error || !contentDetails) {
    if (isLoading) {
      return
    }
    return (
      <Dialog open={isOpen} onOpenChange={onClose}>
        <DialogContent className="max-w-lg bg-white flex items-center justify-center">
          <DialogTitle className="sr-only">Comments</DialogTitle>
          {isLoading && <p>Loading content details...</p>}
          {error && <p className="text-red-600">Error: {error}</p>}
          {!contentDetails && <p>No content details available.</p>}
        </DialogContent>
      </Dialog>
    )
  }

  return (
    <>
      <Toast 
        message="Post link copied to clipboard!" 
        isVisible={showToast} 
        onClose={() => setShowToast(false)} 
      />
      {isDesktop ? (
        <Dialog open={isOpen} onOpenChange={onClose}>
          <div className="fixed top-4 right-4 z-[9999]">
            <Button
              variant="ghost"
              onClick={onClose}
              className="rounded-full p-2 bg-black/50 hover:bg-black/70 text-white"
            >
              <X className="h-5 w-5" />
            </Button>
          </div>

          <div className="fixed inset-0 flex items-center justify-center z-[9999]">
            <DialogContent className="w-[1276px] max-w-none h-[827px] p-0 bg-transparent border-none rounded-[24px] z-[9999]">
              <DialogTitle className="sr-only">
                {contentDetails.title ? `Comments for ${contentDetails.title}` : "Comments"}
              </DialogTitle>
              <Card className="w-full h-full bg-transparent shadow-none rounded-[24px] border-0 overflow-hidden">
                <div className="flex flex-row h-full">
                  <div className="w-1/2 relative h-full bg-gray-100">
                    {contentDetails.image_url && isVideoUrl(contentDetails.image_url) ? (
                      <div className="relative w-full h-full aspect-video bg-gray-100">
                        <ReactPlayer
                          url={contentDetails.image_url}
                          width="100%"
                          style={{ position: "absolute", top: 0, left: 0 }}
                          height="100%"
                          controls
                          playing={false}
                          light={true}
                          playIcon={
                            <div className="flex justify-center items-center h-full w-full bg-black/40 text-white text-6xl">
                              ▶
                            </div>
                          }
                          className="!absolute !top-0 !left-0"
                        />
                      </div>
                    ) : (
                      <div className="relative w-full h-full bg-gray-100 flex items-center justify-center">
                        <Image
                          src={
                            contentDetails.image_url ||
                            "https://cdn.pixabay.com/photo/2018/01/14/23/12/nature-3082832_1280.jpg" 
                          }
                          alt={contentDetails.title}
                          fill
                          priority={false}
                          loading="lazy"
                          quality={90}
                          className="object-cover"
                        />
                      </div>
                    )}
                  </div>

                  <div className="w-1/2 flex flex-col bg-white p-10 h-full">
                    <div className="flex justify-between mb-4">
                      <div
                        className="flex items-center space-x-2"
                        onClick={() => router.push(`/profile/${contentDetails.user.username}`)}
                      >
                        <Avatar className="h-12 w-12">
                          <AvatarImage src={contentDetails.user.profile_picture_url || "/placeholder.svg"} />
                          <AvatarFallback>U</AvatarFallback>
                        </Avatar>
                        <div>
                          <p className="font-semibold text-base">{contentDetails.user.username}</p>
                          <p className="text-base text-muted-foreground">A moment ago</p>
                        </div>
                      </div>
                      <div className="flex gap-4">
                        <div className="flex items-center space-x-2">
                          <MapPin className="text-gray-400" size={16} />
                          <span className="text-base text-muted-foreground">{contentDetails.location}</span>
                        </div>
                        <MoreHorizontal className="mt-1" size={16} />
                      </div>
                    </div>

                    <p className="text-base mb-4">{contentDetails.description}</p>

                    <div className="border-t border-[#ECF0F5] border-b py-3 mb-4">
                      <div className="flex items-center justify-between">
                        <div className="flex space-x-4">
                          <div
                            className="relative"
                            onMouseEnter={() => setShowPostReactions(true)}
                            onMouseLeave={() => setShowPostReactions(false)}
                          >
                            <Button variant="ghost" size="sm" className="text-black">
                              {postReaction ? (
                                <span className="text-lg">
                                  {REACTIONS.find((r) => r.name === postReaction)?.emoji ?? "👍"}
                                </span>
                              ) : (
                                <>
                                  <Heart className="h-5 w-5 mr-1" />
                                  {postTotalReactions > 0 && (
                                    <span className="text-base font-bold">{postTotalReactions}</span>
                                  )}
                                </>
                              )}
                            </Button>
                            <AnimatePresence>
                              {showPostReactions && (
                                <motion.div
                                  initial={{ opacity: 0, y: 10 }}
                                  animate={{ opacity: 1, y: 0 }}
                                  exit={{ opacity: 0, y: 10 }}
                                  className="absolute bottom-full left-0 bg-white rounded-full shadow-lg p-1 flex space-x-1"
                                >
                                  {REACTIONS.map((reaction) => (
                                    <Button
                                      key={reaction.name}
                                      variant="ghost"
                                      className="h-8 w-8 p-0 hover:scale-125 transition-transform"
                                      onClick={() => handlePostReactionSelect(reaction.name)}
                                    >
                                      <span className="text-xl">{reaction.emoji}</span>
                                    </Button>
                                  ))}
                                </motion.div>
                              )}
                            </AnimatePresence>
                          </div>

                          <Button variant="ghost" size="sm" className="text-black">
                            <MessageCircle className="h-4 w-4 mr-1" />
                            <span className="text-base font-bold">{comments.length == 0 ? "" : comments.length}</span>
                          </Button>
                        </div>

                        <Button 
                          variant="ghost" 
                          size="sm" 
                          className="ml-auto"
                          onClick={handleShareClick}
                          disabled={shareLoading}
                        >
                          {shareLoading ? (
                            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-gray-600"></div>
                          ) : (
                            <Share2 className="h-4 w-4" />
                          )}
                        </Button>
                      </div>

                      {postTopReactions.length > 0 && (
                        <div className="flex items-center mt-2 ml-1">
                          <div className="flex -space-x-2">
                            {postTopReactions.map((r, idx) => {
                              const found = REACTIONS.find((rr) => rr.name === r)
                              return (
                                <div
                                  key={`post-reaction-${r}-${idx}`}
                                  className="h-6 w-6 flex items-center justify-center rounded-full border-2 border-white bg-white shadow-sm"
                                >
                                  <span className="text-sm">{found?.emoji ?? "👍"}</span>
                                </div>
                              )
                            })}
                          </div>
                          {postTotalReactions > 0 && (
                            <p className="text-xs text-gray-500 ml-3">
                              {postReaction
                                ? `You and ${Math.max(0, postTotalReactions - 1)} others`
                                : `${postTotalReactions} Reactions`}
                            </p>
                          )}
                        </div>
                      )}
                    </div>

                    <div className="flex-1 overflow-y-auto space-y-4 pr-1">
                      {comments.map((comment) => (
                        <CommentItem
                          key={comment.id}
                          comment={comment}
                          contentId={contentDetails.id}
                          contentType="user_content"
                          onUpdateComment={handleUpdateComment}
                        />
                      ))}
                    </div>

                    <div className="pt-4">
                      <CommentForm
                        onSubmit={handleAddComment}
                        placeholder={replyingTo ? `Reply to @${replyingTo.username}...` : "Share your thoughts here..."}
                        onCancel={replyingTo ? () => setReplyingTo(null) : undefined}
                        showCancel={!!replyingTo}
                      />
                      {replyingTo && (
                        <p className="text-xs text-gray-500 mt-1 ml-12">Replying to @{replyingTo.username}</p>
                      )}
                    </div>
                  </div>
                </div>
              </Card>
            </DialogContent>
          </div>
        </Dialog>
      ) : (
        <AnimatePresence>
          {isOpen && (
            <>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.2 }}
                className="fixed inset-0 bg-black/50 z-[10000]"
                onClick={onClose}
              />
              <motion.div
                initial={{ y: "100%" }}
                animate={{ y: 0 }}
                exit={{ y: "100%" }}
                transition={{ 
                  type: "spring",
                  damping: 25,
                  stiffness: 300,
                  duration: 0.3
                }}
                className="fixed bottom-0 left-0 right-0 z-[10001] bg-white rounded-t-[20px] max-h-[90vh] overflow-hidden flex flex-col"
                drag="y"
                dragConstraints={{ top: 0 }}
                dragElastic={0.2}
                onDragEnd={(_, info) => {
                  if (info.offset.y > 100) {
                    onClose();
                  }
                }}
              >
                {/* <div className="flex justify-center py-2">
                  <div className="w-10 h-1 bg-gray-300 rounded-full"></div>
                </div> */}

                <div className="absolute top-2 right-2">
                  <Button variant="ghost" size="sm" onClick={onClose} className="rounded-full h-8 w-8 p-0">
                    <X className="h-5 w-5" />
                  </Button>
                </div>

                <div className="flex flex-col h-full overflow-hidden">
                <div className="relative w-full h-64 bg-gray-100">
                    {contentDetails.image_url && isVideoUrl(contentDetails.image_url) ? (
                      <div className="relative w-full h-full bg-gray-100">
                        <ReactPlayer
                          url={contentDetails.image_url}
                          width="100%"
                          height="100%"
                          controls
                          playing={false}
                          light={true}
                          playIcon={
                            <div className="flex justify-center items-center h-full w-full bg-black/40 text-white text-6xl">
                              ▶
                            </div>
                          }
                        />
                      </div>
                    ) : (
                      <div className="relative w-full h-full bg-gray-100 flex items-center justify-center">
                        <Image
                          src={
                            contentDetails.image_url ||
                            "https://cdn.pixabay.com/photo/2018/01/14/23/12/nature-3082832_1280.jpg" 
                          }
                          alt={contentDetails.title || "Post image"}
                          fill
                          className="object-cover"
                          priority={false}
                          loading="lazy"
                          quality={90}
                        />
                      </div>
                    )}
                  </div>
                  <div className="px-4 py-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <Avatar className="h-10 w-10">
                          <AvatarImage src={contentDetails.user.profile_picture_url || "/placeholder.svg"} />
                          <AvatarFallback>U</AvatarFallback>
                        </Avatar>
                        <div>
                          <p className="font-semibold text-base">{contentDetails.user.username}</p>
                          <p className="text-sm text-muted-foreground">A moment ago</p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                      <div className="flex items-center space-x-1 max-w-[200px] overflow-hidden">
  <MapPin className="text-gray-400" size={16} />
  <span className="text-sm text-muted-foreground truncate">
    {contentDetails.location || "Seattle"}
  </span>
</div>

                        <MoreHorizontal className="text-gray-500" size={20} />
                      </div>
                    </div>
                  </div>


                  <div className="px-4 py-2 border-b">
                    <p className="text-sm">{contentDetails.description}</p>
                  </div>

                  <div className="px-4 py-2 border-b">
                    <div className="flex items-center justify-between">
                      <div className="flex space-x-4">
                        <div
                          className="relative"
                          onTouchStart={() => setShowPostReactions(true)}
                          onTouchEnd={() => setShowPostReactions(false)}
                        >
                          <Button variant="ghost" size="sm" className="text-black">
                            {postReaction ? (
                              <span className="text-lg">
                                {REACTIONS.find((r) => r.name === postReaction)?.emoji ?? "👍"}
                              </span>
                            ) : (
                              <>
                                <Heart className="h-4 w-4 mr-1" />
                                {postTotalReactions > 0 && (
                                  <span className="text-sm font-bold">{postTotalReactions}</span>
                                )}
                              </>
                            )}
                          </Button>
                          <AnimatePresence>
                            {showPostReactions && (
                              <motion.div
                                initial={{ opacity: 0, y: 10 }}
                                animate={{ opacity: 1, y: 0 }}
                                exit={{ opacity: 0, y: 10 }}
                                className="absolute bottom-full left-0 bg-white rounded-full shadow-lg p-1 flex space-x-1"
                              >
                                {REACTIONS.map((reaction) => (
                                  <Button
                                    key={reaction.name}
                                    variant="ghost"
                                    className="h-8 w-8 p-0 hover:scale-125 transition-transform"
                                    onClick={() => handlePostReactionSelect(reaction.name)}
                                  >
                                    <span className="text-xl">{reaction.emoji}</span>
                                  </Button>
                                ))}
                              </motion.div>
                            )}
                          </AnimatePresence>
                        </div>

                        <Button variant="ghost" size="sm" className="text-black">
                          <MessageCircle className="h-4 w-4 mr-1" />
                          <span className="text-sm font-bold">{comments.length == 0 ? "" : comments.length}</span>
                        </Button>
                      </div>

                      <Button 
                        variant="ghost" 
                        size="sm" 
                        className="ml-auto"
                        onClick={handleShareClick}
                        disabled={shareLoading}
                      >
                        {shareLoading ? (
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-gray-600"></div>
                        ) : (
                          <Share2 className="h-4 w-4" />
                        )}
                      </Button>
                    </div>

                    {postTopReactions.length > 0 && (
                      <div className="flex items-center mt-1">
                        <div className="flex -space-x-2">
                          {postTopReactions.map((r, idx) => {
                            const found = REACTIONS.find((rr) => rr.name === r)
                            return (
                              <div
                                key={`post-reaction-${r}-${idx}`}
                                className="h-5 w-5 flex items-center justify-center rounded-full border-2 border-white bg-white shadow-sm"
                              >
                                <span className="text-xs">{found?.emoji ?? "👍"}</span>
                              </div>
                            )
                          })}
                        </div>
                        {postTotalReactions > 0 && (
                          <p className="text-xs text-gray-500 ml-2">
                            {postReaction
                              ? `You and ${Math.max(0, postTotalReactions - 1)} others`
                              : `${postTotalReactions} Reactions`}
                          </p>
                        )}
                      </div>
                    )}
                  </div>

                  <div className="flex-1 overflow-y-auto px-4 py-2 space-y-4">
                    {comments.map((comment) => (
                      <CommentItem
                        key={comment.id}
                        comment={comment}
                        contentId={contentDetails.id}
                        contentType="user_content"
                        onUpdateComment={handleUpdateComment}
                      />
                    ))}
                  </div>

                  <div className="px-4 py-3 border-t bg-white">
                    <CommentForm
                      onSubmit={handleAddComment}
                      placeholder={replyingTo ? `Reply to @${replyingTo.username}...` : "Share your thoughts here..."}
                      onCancel={replyingTo ? () => setReplyingTo(null) : undefined}
                      showCancel={!!replyingTo}
                    />
                    {replyingTo && (
                      <p className="text-xs text-gray-500 mt-1 ml-12">Replying to @{replyingTo.username}</p>
                    )}
                  </div>
                </div>
              </motion.div>
            </>
          )}
        </AnimatePresence>
      )}

      <AuthPopup isOpen={showAuthModal} onClose={() => setShowAuthModal(false)} action="comment" />
    </>
  )
}
