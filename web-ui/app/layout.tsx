import type { Metadata } from "next";
import "./globals.css";
import { AppProvider } from "./context/AppContext";

export const metadata: Metadata = {
  title: "LifeLine - Your Personal Timeline Assistant",
  description: "Capture, organize, and reflect on the meaningful moments of your life with AI",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full">
      <body className="h-full">
        <AppProvider>{children}</AppProvider>
      </body>
    </html>
  );
}

