"use client";

import { useState } from "react";
import { useApp } from "../context/AppContext";

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function SettingsModal({ isOpen, onClose }: SettingsModalProps) {
  const { preferences, updatePreferences, isDark } = useApp();
  const [name, setName] = useState(preferences?.name || "");
  const [theme, setTheme] = useState<"system" | "light" | "dark">(
    preferences?.theme || "system"
  );

  if (!isOpen || !preferences) return null;

  const handleSave = async () => {
    try {
      await updatePreferences({ name: name || null, theme });
      onClose();
    } catch (error) {
      console.error("Failed to save settings:", error);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="sticky top-0 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 p-6">
          <div className="flex items-center justify-between">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
              Settings
            </h2>
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
            >
              <svg
                className="w-5 h-5 text-gray-600 dark:text-gray-300"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Profile Section */}
          <div>
            <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
              Profile
            </h3>
            <div>
              <label
                htmlFor="settings-name"
                className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
              >
                Name
              </label>
              <input
                type="text"
                id="settings-name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Your name"
                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
              />
            </div>
          </div>

          {/* Theme Section */}
          <div>
            <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
              Appearance
            </h3>
            <div className="grid grid-cols-3 gap-3">
              <button
                type="button"
                onClick={() => setTheme("light")}
                className={`p-4 rounded-xl border-2 transition-all ${
                  theme === "light"
                    ? "border-blue-500 bg-blue-50 dark:bg-blue-900/20"
                    : "border-gray-200 dark:border-gray-600 hover:border-blue-300"
                }`}
              >
                <div className="text-2xl mb-1">☀️</div>
                <div className="text-sm font-medium text-gray-900 dark:text-white">
                  Light
                </div>
              </button>

              <button
                type="button"
                onClick={() => setTheme("dark")}
                className={`p-4 rounded-xl border-2 transition-all ${
                  theme === "dark"
                    ? "border-blue-500 bg-blue-50 dark:bg-blue-900/20"
                    : "border-gray-200 dark:border-gray-600 hover:border-blue-300"
                }`}
              >
                <div className="text-2xl mb-1">🌙</div>
                <div className="text-sm font-medium text-gray-900 dark:text-white">
                  Dark
                </div>
              </button>

              <button
                type="button"
                onClick={() => setTheme("system")}
                className={`p-4 rounded-xl border-2 transition-all ${
                  theme === "system"
                    ? "border-blue-500 bg-blue-50 dark:bg-blue-900/20"
                    : "border-gray-200 dark:border-gray-600 hover:border-blue-300"
                }`}
              >
                <div className="text-2xl mb-1">💻</div>
                <div className="text-sm font-medium text-gray-900 dark:text-white">
                  System
                </div>
              </button>
            </div>
          </div>

          {/* Model Section */}
          <div>
            <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
              AI Model
            </h3>
            <div className="p-4 bg-gray-100 dark:bg-gray-700 rounded-xl">
              <div className="text-sm text-gray-700 dark:text-gray-300">
                Current model: <span className="font-mono font-medium">{preferences.model}</span>
              </div>
              <div className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                Temperature: {preferences.temperature} | Max tokens: {preferences.max_tokens}
              </div>
            </div>
          </div>

          {/* About Section */}
          <div>
            <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
              About
            </h3>
            <div className="p-4 bg-gray-100 dark:bg-gray-700 rounded-xl space-y-2 text-sm">
              <div className="flex justify-between text-gray-700 dark:text-gray-300">
                <span>Version</span>
                <span className="font-medium">0.2.0</span>
              </div>
              <div className="flex justify-between text-gray-700 dark:text-gray-300">
                <span>Account created</span>
                <span className="font-medium">
                  {preferences.created_at
                    ? new Date(preferences.created_at).toLocaleDateString()
                    : "N/A"}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="sticky bottom-0 bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 p-6">
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="flex-1 px-4 py-3 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-xl font-medium hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleSave}
              className="flex-1 px-4 py-3 bg-blue-600 text-white rounded-xl font-medium hover:bg-blue-700 transition-colors"
            >
              Save Changes
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
