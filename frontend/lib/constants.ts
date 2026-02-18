import type { Reaction } from "@/app/types/content"

export const REACTIONS: Reaction[] = [
  { name: "like", emoji: "👍", color: "text-blue-500", label: "Like" },
  { name: "love", emoji: "❤️", color: "text-red-500", label: "Love" },
  { name: "haha", emoji: "😄", color: "text-yellow-500", label: "Haha" },
  { name: "wow", emoji: "😲", color: "text-green-500", label: "Wow" },
  { name: "sad", emoji: "😢", color: "text-purple-500", label: "Sad" },
  { name: "angry", emoji: "😡", color: "text-orange-500", label: "Angry" },
]

