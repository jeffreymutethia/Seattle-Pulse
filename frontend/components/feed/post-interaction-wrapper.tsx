"use client"

import type { ReactNode } from "react"
import { AuthPopup, type AuthAction } from "@/components/auth/auth-popup"
import { useAuthRequired } from "@/app/hooks/use-auth-required"

interface PostInteractionWrapperProps {
  children: (requireAuth: (callback?: () => void) => boolean) => ReactNode
  action?: AuthAction
}


export function PostInteractionWrapper({ children, action = "interact" }: PostInteractionWrapperProps) {
  const { showAuthModal, setShowAuthModal, requireAuth } = useAuthRequired()

  return (
    <>
      {children(requireAuth)}

      <AuthPopup isOpen={showAuthModal} onClose={() => setShowAuthModal(false)} action={action} />
    </>
  )
}

