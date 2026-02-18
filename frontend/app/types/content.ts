import { ReactionType } from "./reaction";

export interface User {
  id: number;
  profile_picture_url: string | null;
  username: string;
}

export interface Post {
  body: string;
  comments_count: number;
  created_at: string;
  id: number;
  location: string;
  reactions_count: number;
  score: string;
  thumbnail: string;
  time_since_post: string;
  title: string;
  updated_at: string;
  user: User;
  top_reactions?: string[];
  user_has_reacted: boolean;
  user_reaction_type: ReactionType;
  has_user_reposted: boolean;
}

export interface ApiResponse {
  data: {
    content: Post[];
    reactions: any[];
  };
  message: string;
  pagination: {
    current_page: number;
    has_next: boolean;
    has_prev: boolean;
    total_items: number;
    total_pages: number;
  };
  query: {
    location: string;
    page: number;
    per_page: number;
  };
  success: string;
}

export interface Comment {
  id: number;
  content: string;
  user_id: number;
  created_at: string;
  user_reaction: string | null;
  reactions: {
    user_reaction: string;
  };
  total_reactions: number;
  user: {
    id: number;
    username: string;
    profile_picture_url: string;
  };
  parent_id: number | null;

  replies_count: number;
  replies?: Comment[];
}

export interface ContentDetails {
  id: number;
  unique_id: number;
  title: string;
  description: string;
  image_url: string;
  location: string;
  source_url: string;
  created_at: string;
  user: {
    id: number;
    username: string;
    profile_picture_url: string;
  };
  user_reaction?: string | null;

  total_reactions: number;
  comments: Comment[];
}

export interface ExtendedPost extends Post {
  userReaction?: string | null;
  totalReactions?: number;
  top_reactions?: string[];
}

export interface Reaction {
  name: string;
  emoji: string;
  color: string;
  label: string;
}
