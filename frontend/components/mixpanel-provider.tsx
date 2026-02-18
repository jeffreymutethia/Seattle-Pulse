"use client";

import { useEffect } from "react";
import { initMixpanel, storeUTMParams, loadStoredUTMParams, identifyUser } from "@/lib/mixpanel";
import { useAuth } from "@/app/context/auth-context";
import mixpanel from "mixpanel-browser";

export function MixpanelProvider({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, user } = useAuth();

  useEffect(() => {
    // Initialize Mixpanel
    initMixpanel();
    
    // Store UTM parameters from URL if present
    storeUTMParams();
    
    // Load and register stored UTM parameters
    const storedUTM = loadStoredUTMParams();
    if (Object.keys(storedUTM).length > 0 && typeof window !== "undefined") {
      // Wait a bit for mixpanel to initialize, then register UTM params
      setTimeout(() => {
        try {
          mixpanel.register(storedUTM);
        } catch {
          // Ignore if not initialized yet
        }
      }, 100);
    }
  }, []);

  // Identify user when authenticated
  useEffect(() => {
    if (isAuthenticated) {
      // Try to get user ID from user object or sessionStorage
      let userId: number | string | null = null;
      
      if (user?.id) {
        userId = user.id;
      } else if (typeof window !== "undefined") {
        // Fallback to sessionStorage
        const userIdStr = sessionStorage.getItem("user_id");
        if (userIdStr) {
          userId = userIdStr;
        } else {
          // Try to get from user object in sessionStorage
          try {
            const userStr = sessionStorage.getItem("user");
            if (userStr) {
              const userObj = JSON.parse(userStr);
              userId = userObj.user_id || userObj.id;
            }
          } catch {
            // Ignore errors
          }
        }
      }
      
      if (userId) {
        identifyUser(userId);
      }
    }
  }, [isAuthenticated, user]);

  return <>{children}</>;
}

