"use client";

import { useState } from "react";

interface OnboardingModalProps {
  onComplete: (name: string, theme: "system" | "light" | "dark") => void;
}

export function OnboardingModal({ onComplete }: OnboardingModalProps) {
  const [name, setName] = useState("");
  const [theme, setTheme] = useState<"system" | "light" | "dark">("system");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (name.trim()) {
      onComplete(name.trim(), theme);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl max-w-md w-full p-8">
        <div className="text-center mb-6">
          <div className="text-6xl mb-4">🧬</div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
            Welcome to LifeLine
          </h1>
          <p className="text-gray-600 dark:text-gray-300">
            Let's personalize your experience
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label
              htmlFor="name"
              className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
            >
              What should I call you?
            </label>
            <input
              type="text"
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Your name"
              className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
              autoFocus
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
              Choose your theme
            </label>
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

          <button
            type="submit"
            disabled={!name.trim()}
            className="w-full bg-blue-600 text-white rounded-xl py-3 font-medium hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
          >
            Get Started
          </button>
        </form>
      </div>
    </div>
  );
}
