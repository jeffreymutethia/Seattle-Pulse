export interface CommentModalProps {
  isOpen: boolean;
  onClose: () => void;
  contentDetails: ContentDetails | null;
  isLoading?: boolean;
  error?: string | null;
  isAuthenticated: boolean
  requireAuth?: (callback?: () => void) => boolean
}

export interface ContentDetails {
  id: number;
  title: string;
  description: string;
  image_url?: string;
  location: string;
  user: {
    id: number;
    username: string;
    profile_picture_url: string;
  };
  total_reactions: number;
  user_reaction?: string | null;
  top_reactions?: string[];
  comments: RawComment[];
}

export interface RawComment {
  id: number;
  content: string;
  user_id: number;
  created_at: string;
  parent_id?: number | null;
  user_reaction?: string | null;
  comment_reaction_type?: string | null;
  total_reactions?: number;
  reaction_count?: number;
  top_reactions?: string[];
  replied_to?: {
    first_name: string;
    id: number;
    last_name: string;
    profile_picture_url: string;
    username: string;
  };
  user: {
    id: number;
    username: string;
    profile_picture_url: string;
  };
  replies_count: number;
}

export interface ExtendedComment extends RawComment {
  userReaction: string | null;
  totalReactions: number;
  top_reactions: string[];
  replyingTo?: string;
  isReplyTarget?: boolean;
  isNewReply?: boolean;
  isSearchRequest?: boolean;
  searchForId?: number;
  newReplyData?: any;
  createdLocally?: boolean;
  forceDisplay?: boolean;
  forceExpanded?: boolean;
  forceReload?: boolean;
  timestamp?: number;
}

export const transformComment = (raw: RawComment): ExtendedComment => {
  return {
    ...raw,
    userReaction: raw.comment_reaction_type ?? raw.user_reaction ?? null,
    totalReactions: raw.reaction_count ?? raw.total_reactions ?? 0,
    top_reactions: raw.top_reactions ?? [],
  };
};