"use client";

import { useState, useEffect, useRef } from "react";
import { useAuth } from "../context/auth-context";

interface UseScrollAuthPromptResult {
  showPrompt: boolean;
  setShowPrompt: (show: boolean) => void;
}

export function useScrollAuthPrompt(): UseScrollAuthPromptResult {
  const { isAuthenticated } = useAuth();
  const [showPrompt, setShowPrompt] = useState(false);
  const lastPromptTimeRef = useRef<number>(0);
  const MIN_INTERVAL = 60000; // 1 minute between prompts
  const scrollPositionsRef = useRef<Set<number>>(new Set()); // Track shown positions

  useEffect(() => {
    if (isAuthenticated) return;

    const handleScroll = () => {
      const now = Date.now();
      if (now - lastPromptTimeRef.current < MIN_INTERVAL) return;

      const scrollPosition = window.scrollY;
      const windowHeight = window.innerHeight;
      const documentHeight = document.documentElement.scrollHeight;
      const scrollPercentage =
        (scrollPosition / (documentHeight - windowHeight)) * 100;

      // Show prompt at 30% and 70% scroll if not shown before at these positions
      const checkPosition = (percentage: number) => {
        if (
          scrollPercentage >= percentage &&
          scrollPercentage <= percentage + 5 &&
          !scrollPositionsRef.current.has(percentage)
        ) {
          setShowPrompt(true);
          lastPromptTimeRef.current = now;
          scrollPositionsRef.current.add(percentage);
        }
      };

      checkPosition(30);
      checkPosition(70);
    };

    // Throttle the scroll event
    let ticking = false;
    const throttledScroll = () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          handleScroll();
          ticking = false;
        });
        ticking = true;
      }
    };

    window.addEventListener("scroll", throttledScroll, { passive: true });

    return () => {
      window.removeEventListener("scroll", throttledScroll);
      scrollPositionsRef.current.clear();
    };
  }, [isAuthenticated]);

  // Reset scroll positions when showPrompt changes to false
  useEffect(() => {
    if (!showPrompt) {
      scrollPositionsRef.current.clear();
    }
  }, [showPrompt]);

  return {
    showPrompt,
    setShowPrompt,
  };
}
