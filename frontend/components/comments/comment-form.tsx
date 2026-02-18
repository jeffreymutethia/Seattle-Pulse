"use client"

import { useState } from "react"
import { Send, X } from "lucide-react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

interface CommentFormProps {
  onSubmit: (text: string) => void
  onCancel?: () => void
  showCancel?: boolean
  placeholder?: string
  defaultValue?: string
  userAvatar?: string
}

export function CommentForm({
  onSubmit,
  onCancel,
  showCancel = true,
  placeholder = "Share your thoughts here...",
  defaultValue = "",
  userAvatar = "/user-icon.png",
}: CommentFormProps) {
  const [text, setText] = useState(defaultValue)

  const handleSubmit = () => {
    if (text.trim()) {
      onSubmit(text.trim())
      setText("")
    }
  }

  return (
    <div className="flex items-center space-x-2">
      <Avatar className="h-10 w-10 flex-shrink-0">
        <AvatarImage src={userAvatar} />
        <AvatarFallback>U</AvatarFallback>
      </Avatar>
      <div className="flex items-center w-full relative">
        <Input
          className="flex-1 text-sm h-12 rounded-full pr-10 pl-5"
          placeholder={placeholder}
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey) {
              e.preventDefault()
              handleSubmit()
            }
          }}
        />
        {showCancel && onCancel && (
          <Button
            variant="ghost"
            size="sm"
            onClick={onCancel}
            className="absolute right-12 top-1/2 -translate-y-1/2 p-1"
          >
            <X className="h-4 w-4 text-gray-500" />
          </Button>
        )}
        <Button
          variant="ghost"
          size="sm"
          onClick={handleSubmit}
          className="absolute right-2 top-1/2 -translate-y-1/2 p-1"
        >
          <Send className="h-4 w-4 text-gray-500" />
        </Button>
      </div>
    </div>
  )
}

