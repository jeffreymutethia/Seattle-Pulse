"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Check } from "lucide-react"
import type { ExtendedComment } from "@/app/types/comment"
import { commentService } from "@/app/services/comment-service"
import CommentActions from "./comment-action"
import { REACTIONS } from "@/lib/constants"
import { transformComment } from "@/app/types/comment"

interface CommentItemProps {
  comment: ExtendedComment
  contentId: number
  contentType: string
  onUpdateComment?: (updated: ExtendedComment) => void
}

export default function CommentItem({ comment, contentId, contentType, onUpdateComment }: CommentItemProps) {
  const router = useRouter()

  const [editMode, setEditMode] = useState(false)
  const [editingText, setEditingText] = useState(comment.content)

  const [expanded, setExpanded] = useState(false)
  const [replies, setReplies] = useState<ExtendedComment[]>([])
  const [repliesLoaded, setRepliesLoaded] = useState(false)
  const [currentPage, setCurrentPage] = useState(1)
  const [hasNext, setHasNext] = useState(false)

  const goToProfile = () => {
    router.push(`/profile/${comment.user.username}`)
  }

  async function loadReplies(page: number) {
    try {
      const rawResponse = await commentService.fetchReplies(comment.id, page)
      const transformed: ExtendedComment[] = rawResponse.replies.map(transformComment)
      
      if (page === 1) {
        setReplies(transformed)
      } else {
        setReplies(prev => [...prev, ...transformed])
      }
      
      setCurrentPage(rawResponse.pagination.current_page)
      setHasNext(rawResponse.pagination.has_next)
      setRepliesLoaded(true)
    } catch (error) {
      console.error(`Error loading replies:`, error)
    }
  }

  function handleToggleReplies() {
    if (!expanded) {
      setExpanded(true)
      if (!repliesLoaded && comment.replies_count > 0) {
        loadReplies(1)
      }
    } else {
      setExpanded(false)
    }
  }

  async function loadMoreReplies() {
    await loadReplies(currentPage + 1)
  }

  async function handleSaveEdit() {
    if (!editingText.trim()) {
      setEditMode(false)
      setEditingText(comment.content)
      return
    }
    try {
      const updated = await commentService.updateComment({
        comment_id: comment.id,
        content: editingText.trim(),
      })
      setEditingText(updated.content)
      setEditMode(false)
      onUpdateComment?.(updated)
    } catch (err) {
      console.error("Error updating comment:", err)
    }
  }

  function handleChildUpdate(updatedComment: ExtendedComment) {
    onUpdateComment?.(updatedComment)
  }

  return (
    <div className="flex gap-2">
      <div onClick={goToProfile} className="cursor-pointer">
        <Avatar className="h-10 w-10 flex-shrink-0">
          <AvatarImage src={comment.user.profile_picture_url || "/placeholder.svg"} />
          <AvatarFallback>U</AvatarFallback>
        </Avatar>
      </div>

      <div className="flex-1">
        {editMode ? (
          <div>
            <Input value={editingText} onChange={(e) => setEditingText(e.target.value)} className="mb-2" />
            <div className="space-x-2">
              <Button variant="default" size="sm" onClick={handleSaveEdit}>
                <Check className="h-4 w-4 mr-1" />
                Save
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setEditMode(false)
                  setEditingText(comment.content)
                }}
              >
                Cancel
              </Button>
            </div>
          </div>
        ) : (
          <>
            <p onClick={goToProfile} className="text-sm font-semibold cursor-pointer">
              {comment.user.username}
            </p>
            {comment.replied_to && (
              <p className="text-xs text-gray-500 mb-1">
                Replying to <span className="text-blue-500 font-semibold">@{comment.replied_to.username}</span>
              </p>
            )}
            <p className="text-base text-black">{comment.content}</p>
          </>
        )}

        <CommentActions
          comment={comment}
          contentId={contentId}
          contentType={contentType}
          onReply={() => {
            onUpdateComment?.({
              ...comment,
              replyingTo: comment.user.username,
              isReplyTarget: true,
            })
          }}
          onEdit={() => setEditMode(true)}
          onUpdateComment={handleChildUpdate}
        />

        {comment.top_reactions.length > 0 && (
          <div className="flex items-center mt-1 ml-2">
            <div className="flex -space-x-2">
              {comment.top_reactions.slice(0, 3).map((r, idx) => {
                const found = REACTIONS.find((rr) => rr.name === r)
                return (
                  <div
                    key={`${comment.id}-reaction-${r}-${idx}`}
                    className="h-5 w-5 flex items-center justify-center rounded-full border-2 border-white bg-white shadow-sm"
                  >
                    <span className="text-xs">{found?.emoji ?? "👍"}</span>
                  </div>
                )
              })}
            </div>
            {comment.totalReactions > 0 && (
              <p className="text-[11px] text-gray-500 ml-2">
                {comment.userReaction
                  ? `You and ${Math.max(0, comment.totalReactions - 1)} others`
                  : `${comment.totalReactions} Reactions`}
              </p>
            )}
          </div>
        )}

        {comment.replies_count > 0 && (
          <div className="mt-2 ml-1">
            <Button variant="ghost" size="sm" className="px-2 h-6 text-xs" onClick={handleToggleReplies}>
              {expanded ? "Hide replies" : `View replies (${comment.replies_count})`}
            </Button>
          </div>
        )}

        {expanded && (
          <div className="mt-2 ml-6 border-l border-gray-200 pl-2 space-y-3">
            {replies.map((r) => (
              <CommentItem
                key={r.id}
                comment={r}
                contentId={contentId}
                contentType={contentType}
                onUpdateComment={handleChildUpdate}
              />
            ))}
            {hasNext && (
              <div className="mt-2">
                <Button variant="ghost" size="sm" onClick={loadMoreReplies}>
                  Load more replies
                </Button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
