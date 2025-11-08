"use client";

import { useEffect, useRef, useState } from "react";
import { useWebSocket } from "./hooks/useWebSocket";
import { useApp } from "./context/AppContext";
import { ChatMessage } from "./components/ChatMessage";
import { ChatInput } from "./components/ChatInput";
import { Header } from "./components/Header";
import { ThinkingIndicator } from "./components/ThinkingIndicator";
import { OnboardingModal } from "./components/OnboardingModal";
import { Sidebar } from "./components/Sidebar";
import { SettingsModal } from "./components/SettingsModal";

const WS_URL = "ws://localhost:8000/ws/chat";

export default function Home() {
  const {
    preferences,
    currentSessionId,
    createSession,
    setCurrentSession,
    refreshSessions,
    completeOnboarding,
    isLoading,
  } = useApp();

  const { messages, isConnected, isThinking, sendMessage } = useWebSocket(WS_URL);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, isThinking]);

  // Show onboarding modal if not onboarded
  const showOnboarding = !isLoading && preferences && !preferences.onboarded;

  const handleOnboardingComplete = async (name: string, theme: string) => {
    await completeOnboarding(name, theme as any);
  };

  const handleNewChat = async () => {
    const sessionId = await createSession();
    if (sessionId) {
      setCurrentSession(sessionId);
    }
  };

  const toggleSidebar = () => setIsSidebarOpen(!isSidebarOpen);
  const openSettings = () => setIsSettingsOpen(true);
  const closeSettings = () => setIsSettingsOpen(false);

  // Loading state
  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-screen bg-gray-50 dark:bg-gray-900">
        <div className="text-center">
          <div className="text-6xl mb-4 animate-pulse">🧬</div>
          <div className="text-gray-600 dark:text-gray-400">Loading LifeLine...</div>
        </div>
      </div>
    );
  }

  return (
    <>
      {showOnboarding && <OnboardingModal onComplete={handleOnboardingComplete} />}

      <div className="flex h-screen bg-gray-50 dark:bg-gray-900">
        {/* Sidebar */}
        <Sidebar
          isOpen={isSidebarOpen}
          onClose={() => setIsSidebarOpen(false)}
          onNewChat={handleNewChat}
          onOpenSettings={openSettings}
        />

        {/* Main Chat Area */}
        <div className="flex-1 flex flex-col min-w-0">
          {/* Header */}
          <Header isConnected={isConnected} onMenuClick={toggleSidebar} />

          {/* Messages Container */}
          <div className="flex-1 overflow-y-auto">
            <div className="max-w-4xl mx-auto py-6">
              {messages.length === 0 && !isThinking && (
                <div className="text-center py-12 px-4">
                  <div className="text-6xl mb-4">🧬</div>
                  <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
                    {preferences?.name
                      ? `Welcome back, ${preferences.name}!`
                      : "Welcome to LifeLine"}
                  </h2>
                  <p className="text-gray-600 dark:text-gray-400 max-w-md mx-auto">
                    I'm here to help you capture, organize, and reflect on the meaningful
                    moments of your life. What would you like to log or ask about today?
                  </p>
                  <div className="mt-8 grid grid-cols-1 sm:grid-cols-2 gap-3 max-w-2xl mx-auto px-4">
                    <button
                      onClick={() => sendMessage("What can you help me with?")}
                      className="p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl hover:border-blue-500 dark:hover:border-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors text-left"
                    >
                      <div className="font-medium text-gray-900 dark:text-white">
                        What can you do?
                      </div>
                      <div className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                        Learn about LifeLine features
                      </div>
                    </button>
                    <button
                      onClick={() =>
                        sendMessage("Log: Today I started working on a new project")
                      }
                      className="p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl hover:border-blue-500 dark:hover:border-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors text-left"
                    >
                      <div className="font-medium text-gray-900 dark:text-white">
                        Log an event
                      </div>
                      <div className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                        Start capturing your timeline
                      </div>
                    </button>
                    <button
                      onClick={() => sendMessage("Show my recent events")}
                      className="p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl hover:border-blue-500 dark:hover:border-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors text-left"
                    >
                      <div className="font-medium text-gray-900 dark:text-white">
                        Recent events
                      </div>
                      <div className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                        View your latest memories
                      </div>
                    </button>
                    <button
                      onClick={() => sendMessage("Show me my timeline statistics")}
                      className="p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl hover:border-blue-500 dark:hover:border-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors text-left"
                    >
                      <div className="font-medium text-gray-900 dark:text-white">
                        Statistics
                      </div>
                      <div className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                        See your timeline stats
                      </div>
                    </button>
                  </div>
                </div>
              )}

              {messages.map((message) => (
                <ChatMessage key={message.id} message={message} />
              ))}

              {isThinking && <ThinkingIndicator />}

              <div ref={messagesEndRef} />
            </div>
          </div>

          {/* Input Area */}
          <ChatInput
            onSend={sendMessage}
            disabled={!isConnected || isThinking}
            placeholder={
              isConnected
                ? "Tell me what happened today..."
                : "Connecting to LifeLine..."
            }
          />
        </div>
      </div>

      {/* Settings Modal */}
      <SettingsModal isOpen={isSettingsOpen} onClose={closeSettings} />
    </>
  );
}
