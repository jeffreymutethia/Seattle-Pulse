import type { User } from "./user"

export interface Post {
  body: string
  comments_count: number
  created_at: string
  id: number
  location: string
  reactions_count: number
  score: string
  thumbnail: string
  time_since_post: string
  title: string
  updated_at: string
  user: User
}

export interface ApiResponse {
  data: {
    content: Post[]
    reactions: any[]
  }
  message: string
  pagination: {
    current_page: number
    has_next: boolean
    has_prev: boolean
    total_items: number
    total_pages: number
  }
  query: {
    location: string
    page: number
    per_page: number
  }
  success: string
}

