import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Heart, MessageCircle, MoreHorizontal } from "lucide-react";
import { AnimatePresence, motion } from "framer-motion";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ExtendedComment } from "@/app/types/comment";
import { commentService } from "@/app/services/comment-service";
import { REACTIONS } from "@/lib/constants";

interface CommentActionsProps {
  comment: ExtendedComment;
  contentId: number;
  contentType: string;
  onReply: () => void;
  onEdit: () => void;
  onUpdateComment?: (updated: ExtendedComment) => void;
}

export default function CommentActions({
  comment,
  contentId,
  contentType,
  onReply,
  onEdit,
  onUpdateComment,
}: CommentActionsProps) {
  const [showReactions, setShowReactions] = useState(false);

  async function handleCommentReactionSelect(clickedReaction: string) {
    // 1. Save old values for revert
    const oldReaction = comment.userReaction;
    const oldTotal = comment.totalReactions;
    const oldTop = [...comment.top_reactions];

    // 2. Determine newReaction, newCount, newTop
    const unreacting = oldReaction === clickedReaction;
    const newReaction = unreacting ? null : clickedReaction;

    let newCount = oldTotal;
    if (unreacting) {
      newCount = Math.max(0, oldTotal - 1);
    } else if (!oldReaction) {
      newCount = oldTotal + 1;
    }
    // If switching from one reaction to another => total stays the same

    let newTop = [...oldTop];
    if (unreacting) {
      newTop = newTop.filter((r) => r !== clickedReaction);
    } else {
      // remove old if switching
      if (oldReaction) {
        newTop = newTop.filter((r) => r !== oldReaction);
      }
      // add new if not included
      if (!newTop.includes(clickedReaction)) {
        newTop.unshift(clickedReaction);
      }
    }
    newTop = newTop.slice(0, 3);

    // 3. Optimistically update local comment
    const updatedComment = {
      ...comment,
      userReaction: newReaction,
      totalReactions: newCount,
      top_reactions: newTop,
    };

    // If parent is storing comment in state, let them know
    if (onUpdateComment) {
      onUpdateComment(updatedComment);
    }
    // Also directly mutate the local comment object if needed
    Object.assign(comment, updatedComment);

    // 4. Send request
    try {
      await commentService.reactToComment(
        contentId,
        comment.id,
        clickedReaction
      );
      // success => do nothing. We keep local changes.
    } catch (err) {
      console.error("Error reacting to comment:", err);

      // 5. Revert local if there was an error
      const revertedComment = {
        ...comment,
        userReaction: oldReaction,
        totalReactions: oldTotal,
        top_reactions: oldTop,
      };
      if (onUpdateComment) {
        onUpdateComment(revertedComment);
      }
      Object.assign(comment, revertedComment);
    } finally {
      setShowReactions(false);
    }
  }

  return (
    <div className="flex items-center mt-1 space-x-3">
      <div
        className="relative"
        onMouseEnter={() => setShowReactions(true)}
        onMouseLeave={() => setShowReactions(false)}
      >
        <Button
          variant="ghost"
          size="sm"
          className="h-auto p-1 text-muted-foreground text-xs"
        >
          {comment.userReaction ? (
            <span className="text-base">
              {REACTIONS.find((r) => r.name === comment.userReaction)?.emoji ??
                "👍"}
            </span>
          ) : (
            <>
              <Heart className="h-3 w-3 mr-1" />
              {comment.totalReactions > 0 && (
                <span className="text-xs">{comment.totalReactions}</span>
              )}
            </>
          )}
        </Button>
        <AnimatePresence>
          {showReactions && (
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
                  onClick={() => handleCommentReactionSelect(reaction.name)}
                  title={reaction.label}
                >
                  <span className="text-xl">{reaction.emoji}</span>
                </Button>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <Button
        variant="ghost"
        size="sm"
        className="h-auto p-1 text-muted-foreground text-xs"
        onClick={onReply}
      >
        <MessageCircle className="h-3 w-3 mr-1" />
        <span className="text-xs">Reply</span>
      </Button>

      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button
            variant="ghost"
            size="sm"
            className="h-auto p-0 text-muted-foreground text-xs"
          >
            <MoreHorizontal className="h-3 w-3 text-gray-500" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-40">
          <DropdownMenuItem onClick={onEdit}>Edit</DropdownMenuItem>
          <DropdownMenuItem
            onClick={() => {
              alert(`Report comment #${comment.id}`);
            }}
            className="text-red-600"
          >
            Report
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  );
}
