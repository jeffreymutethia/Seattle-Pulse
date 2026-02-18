"use client";

import { useState, useCallback } from "react";
import { useAuth } from "../context/auth-context";

interface UseAuthRequiredResult {
  showAuthModal: boolean;
  setShowAuthModal: (show: boolean) => void;
  requireAuth: (callback?: () => void) => boolean;
}

/**
 * Hook to handle authentication requirements for actions
 * Returns functions to check auth and show auth modal when needed
 */
export function useAuthRequired(): UseAuthRequiredResult {
  const { isAuthenticated } = useAuth();
  const [showAuthModal, setShowAuthModal] = useState(false);

  const requireAuth = useCallback(
    (callback?: () => void) => {
      if (isAuthenticated) {
        callback?.();
        return true;
      } else {
        setShowAuthModal(true);
        return false;
      }
    },
    [isAuthenticated]
  );

  return {
    showAuthModal,
    setShowAuthModal,
    requireAuth,
  };
}
