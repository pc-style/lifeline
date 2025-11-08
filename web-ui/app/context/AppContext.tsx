"use client";

import { createContext, useContext, useEffect, useState, ReactNode } from "react";

interface UserPreferences {
  user_id: string;
  name: string | null;
  theme: "system" | "light" | "dark";
  model: string;
  temperature: number;
  max_tokens: number;
  onboarded: boolean;
  created_at: string | null;
  updated_at: string | null;
}

interface ChatSession {
  id: number;
  user_id: string;
  title: string;
  created_at: string;
  updated_at: string;
  message_count: number;
}

interface AppContextType {
  preferences: UserPreferences | null;
  sessions: ChatSession[];
  currentSessionId: number | null;
  isLoading: boolean;
  isDark: boolean;
  updatePreferences: (updates: Partial<UserPreferences>) => Promise<void>;
  completeOnboarding: (name: string, theme: string) => Promise<void>;
  createSession: () => Promise<number | null>;
  setCurrentSession: (id: number | null) => void;
  deleteSession: (id: number) => Promise<void>;
  refreshSessions: () => Promise<void>;
  setTheme: (theme: "system" | "light" | "dark") => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

const API_BASE = "http://localhost:8000";

export function AppProvider({ children }: { children: ReactNode }) {
  const [preferences, setPreferences] = useState<UserPreferences | null>(null);
  const [sessions, setSessions] = useState<ChatSession[]>([]);
  const [currentSessionId, setCurrentSessionId] = useState<number | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isDark, setIsDark] = useState(false);

  // Load preferences on mount
  useEffect(() => {
    loadPreferences();
    loadSessions();
  }, []);

  // Handle theme changes
  useEffect(() => {
    if (!preferences) return;

    const applyTheme = () => {
      if (preferences.theme === "dark") {
        document.documentElement.classList.add("dark");
        setIsDark(true);
      } else if (preferences.theme === "light") {
        document.documentElement.classList.remove("dark");
        setIsDark(false);
      } else {
        // System preference
        const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
        if (prefersDark) {
          document.documentElement.classList.add("dark");
          setIsDark(true);
        } else {
          document.documentElement.classList.remove("dark");
          setIsDark(false);
        }
      }
    };

    applyTheme();

    // Listen for system theme changes
    const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    const handler = () => {
      if (preferences.theme === "system") {
        applyTheme();
      }
    };
    mediaQuery.addEventListener("change", handler);
    return () => mediaQuery.removeEventListener("change", handler);
  }, [preferences?.theme]);

  const loadPreferences = async () => {
    try {
      const response = await fetch(`${API_BASE}/api/preferences`);
      const data = await response.json();
      setPreferences(data);
    } catch (error) {
      console.error("Failed to load preferences:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const loadSessions = async () => {
    try {
      const response = await fetch(`${API_BASE}/api/sessions`);
      const data = await response.json();
      setSessions(data);
    } catch (error) {
      console.error("Failed to load sessions:", error);
    }
  };

  const updatePreferences = async (updates: Partial<UserPreferences>) => {
    try {
      const response = await fetch(`${API_BASE}/api/preferences`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(updates),
      });
      const data = await response.json();
      setPreferences(data);
    } catch (error) {
      console.error("Failed to update preferences:", error);
      throw error;
    }
  };

  const completeOnboarding = async (name: string, theme: string) => {
    try {
      const response = await fetch(`${API_BASE}/api/onboarding`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, theme }),
      });
      const data = await response.json();
      setPreferences(data);
    } catch (error) {
      console.error("Failed to complete onboarding:", error);
      throw error;
    }
  };

  const createSession = async (): Promise<number | null> => {
    try {
      const response = await fetch(`${API_BASE}/api/sessions`, {
        method: "POST",
      });
      const data = await response.json();
      await loadSessions();
      return data.id || null;
    } catch (error) {
      console.error("Failed to create session:", error);
      return null;
    }
  };

  const setCurrentSession = (id: number | null) => {
    setCurrentSessionId(id);
  };

  const deleteSession = async (id: number) => {
    try {
      await fetch(`${API_BASE}/api/sessions/${id}`, {
        method: "DELETE",
      });
      if (currentSessionId === id) {
        setCurrentSessionId(null);
      }
      await loadSessions();
    } catch (error) {
      console.error("Failed to delete session:", error);
      throw error;
    }
  };

  const refreshSessions = async () => {
    await loadSessions();
  };

  const setTheme = (theme: "system" | "light" | "dark") => {
    updatePreferences({ theme });
  };

  return (
    <AppContext.Provider
      value={{
        preferences,
        sessions,
        currentSessionId,
        isLoading,
        isDark,
        updatePreferences,
        completeOnboarding,
        createSession,
        setCurrentSession,
        deleteSession,
        refreshSessions,
        setTheme,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error("useApp must be used within AppProvider");
  }
  return context;
}
