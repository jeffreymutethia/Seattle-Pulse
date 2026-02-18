"use client";

import { useState, useEffect, useRef } from "react";
import { useAuth } from "../context/auth-context";
import { useMobile } from "./use-mobile";

interface UseMobileAuthPromptResult {
  showPrompt: boolean;
  setShowPrompt: (show: boolean) => void;
}

export function useMobileAuthPrompt(): UseMobileAuthPromptResult {
  const { isAuthenticated } = useAuth();
  const isMobile = useMobile();
  const [showPrompt, setShowPrompt] = useState(false);
  const hasShownPromptRef = useRef<boolean>(false);

  useEffect(() => {
    console.log("useMobileAuthPrompt effect running:", {
      isAuthenticated,
      isMobile,
      hasShownPromptRef: hasShownPromptRef.current,
    });

    // Only show for unauthenticated mobile users
    if (isAuthenticated || !isMobile) {
      console.log("Mobile auth prompt disabled:", { isAuthenticated, isMobile });
      return;
    }

    // Always show once per mount on mobile (no storage)
    if (!hasShownPromptRef.current) {
      const timer = setTimeout(() => {
        console.log("Showing mobile onboarding popup immediately (no storage)");
        setShowPrompt(true);
        hasShownPromptRef.current = true;
      }, 600); // slight delay to allow layout to stabilize

      return () => clearTimeout(timer);
    }
  }, [isAuthenticated, isMobile]);

  return {
    showPrompt,
    setShowPrompt,
  };
}

