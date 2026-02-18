"use client";

import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  type ReactNode,
} from "react";
import { authService, User } from "../services/auth-service";

interface AuthContextType {
  isAuthenticated: boolean;
  user: User | null;
  isLoading: boolean;
  checkAuth: () => Promise<void>;
  logout: () => Promise<void>;
  requireAuth: (callback?: () => void) => boolean; // Add this function
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const checkAuth = useCallback(async () => {
    setIsLoading(true);
    try {
      const { isAuthenticated, user } = await authService.checkAuthentication();
      setIsAuthenticated(isAuthenticated);
      setUser(user);
    } catch (error) {
      console.error("Failed to check authentication:", error);
      setIsAuthenticated(false);
      setUser(null);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const logout = async () => {
    try {
      const success = await authService.logout();
      if (success) {
        setIsAuthenticated(false);
        setUser(null);
      }
    } catch (error) {
      console.error("Logout error:", error);
    }
  };

  // Add requireAuth function
  const requireAuth = useCallback(
    (callback?: () => void) => {
      if (isAuthenticated) {
        callback?.();
        return true;
      }
      return false;
    },
    [isAuthenticated]
  );

  // Check authentication on initial load
  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  return (
    <AuthContext.Provider
      value={{
        isAuthenticated,
        user,
        isLoading,
        checkAuth,
        logout,
        requireAuth,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
