import mixpanel from "mixpanel-browser";

let isInitialized = false;

// Initialize Mixpanel
export const initMixpanel = () => {
  const token = process.env.NEXT_PUBLIC_MIXPANEL_TOKEN;
  
  if (!token) {
    console.warn("Mixpanel token not found. Analytics will be disabled.");
    return;
  }

  if (isInitialized) {
    return; // Already initialized
  }

  mixpanel.init(token, {
    debug: process.env.NODE_ENV === "development",
    ignore_dnt: true,
    loaded: (mp) => {
      isInitialized = true;
      // Set default super properties
      const env = getEnvironment();
      const release = process.env.NEXT_PUBLIC_RELEASE || process.env.NEXT_PUBLIC_GIT_SHA || "unknown";
      
      mp.register({
        env,
        release,
      });

      // Load and set UTM parameters if they exist
      const utmParams = getUTMParams();
      if (Object.keys(utmParams).length > 0) {
        mp.register(utmParams);
      }
    },
  });
};

// Get environment (prod or staging)
export const getEnvironment = (): string => {
  if (typeof window === "undefined") return "unknown";
  
  const hostname = window.location.hostname;
  if (hostname === "seattlepulse.net" || hostname === "www.seattlepulse.net") {
    return "prod";
  } else if (hostname.includes("staging")) {
    return "staging";
  }
  return "development";
};

// Get UTM parameters from URL
export const getUTMParams = (): Record<string, string> => {
  if (typeof window === "undefined") return {};
  
  const params = new URLSearchParams(window.location.search);
  const utmParams: Record<string, string> = {};
  
  const utmKeys = ["utm_source", "utm_medium", "utm_campaign"];
  utmKeys.forEach((key) => {
    const value = params.get(key);
    if (value) {
      utmParams[key] = value;
    }
  });
  
  return utmParams;
};

// Store UTM parameters in localStorage for persistence
export const storeUTMParams = () => {
  if (typeof window === "undefined") return;
  
  const utmParams = getUTMParams();
  if (Object.keys(utmParams).length > 0) {
    localStorage.setItem("mixpanel_utm_params", JSON.stringify(utmParams));
    
    // Also register with Mixpanel if initialized
    if (isInitialized) {
      mixpanel.register(utmParams);
    }
  }
};

// Load stored UTM parameters
export const loadStoredUTMParams = (): Record<string, string> => {
  if (typeof window === "undefined") return {};
  
  try {
    const stored = localStorage.getItem("mixpanel_utm_params");
    if (stored) {
      return JSON.parse(stored);
    }
  } catch (error) {
    console.error("Error loading stored UTM params:", error);
  }
  
  return {};
};

// Track event with automatic super properties
export const trackEvent = (
  eventName: string,
  properties?: Record<string, unknown>
) => {
  if (!isInitialized) {
    console.warn("Mixpanel not initialized. Event not tracked:", eventName);
    return;
  }

  // Get user location/neighborhood if available
  let location = "";
  try {
    const userStr = sessionStorage.getItem("user");
    if (userStr) {
      const user = JSON.parse(userStr);
      location = user.location || user.home_location || "";
    }
  } catch {
    // Ignore errors
  }

  const eventProperties = {
    ...properties,
    ...(location && { neighborhood: location }),
  };

  // Log event in development for debugging
  if (process.env.NODE_ENV === "development") {
    console.log("📊 Mixpanel Event:", eventName, eventProperties);
  }

  mixpanel.track(eventName, eventProperties);
};

// Identify user (call after email verification)
export const identifyUser = (userId: number | string) => {
  if (!isInitialized) {
    console.warn("Mixpanel not initialized. Cannot identify user.");
    return;
  }

  const userIdStr = String(userId);
  
  // Check if we've already aliased this user
  const hasAliased = localStorage.getItem(`mixpanel_aliased_${userIdStr}`);
  
  if (!hasAliased) {
    // Alias the anonymous ID to the user ID (first time only)
    mixpanel.alias(userIdStr);
    localStorage.setItem(`mixpanel_aliased_${userIdStr}`, "true");
  }
  
  // Identify the user
  mixpanel.identify(userIdStr);
  
  // Update user properties
  try {
    const userStr = sessionStorage.getItem("user");
    if (userStr) {
      const user = JSON.parse(userStr);
      mixpanel.people.set({
        $name: `${user.first_name || ""} ${user.last_name || ""}`.trim() || user.username,
        $email: user.email,
        username: user.username,
        location: user.location || user.home_location || "",
      });
    }
  } catch (error) {
    console.error("Error setting user properties:", error);
  }
};

// Set super property
export const setSuperProperty = (key: string, value: unknown) => {
  if (!isInitialized) return;
  mixpanel.register({ [key]: value });
};

// Reset (on logout)
export const resetMixpanel = () => {
  if (!isInitialized) return;
  mixpanel.reset();
};

