export type ReactionType = "like" | "love" | "haha" | "wow" | "sad" | "angry"

export interface Reaction {
  type: ReactionType
  emoji: string
  label: string
  color: string
}

export interface ReactionCount {
  type: ReactionType
  count: number
}

export interface PostReactions {
  userReaction: ReactionType | null
  totalReactions: number
  topReactions: ReactionCount[]
}

